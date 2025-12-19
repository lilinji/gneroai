#!/bin/bash

# ParallelFold 作业监控脚本
# 用法: bash pf-monitor.sh [JOB_ID] [监控间隔秒数，默认30]

JOB_ID=${1}
INTERVAL=${2:-30}

if [[ -z "$JOB_ID" ]]; then
    echo "用法: $0 <作业ID> [监控间隔秒数]"
    echo "示例: $0 123456 30"
    exit 1
fi

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 清屏函数
clear_screen() {
    clear
    echo "================================================================="
    echo -e "${BLUE}ParallelFold 作业监控面板 - 作业ID: $JOB_ID${NC}"
    echo -e "${BLUE}监控间隔: ${INTERVAL}秒 | 当前时间: $(date)${NC}"
    echo "================================================================="
}

# 检查作业是否存在
check_job_exists() {
    squeue -j "$JOB_ID" &>/dev/null
    return $?
}

# 获取作业基本信息
get_job_info() {
    echo -e "\n${YELLOW}===== 作业基本信息 =====${NC}"
    sacct -j "$JOB_ID" --format=JobID,JobName,User,State,Elapsed,TimeLeft,NodeList,ExitCode 2>/dev/null | head -3
    
    # 如果是数组作业，显示数组状态
    if squeue -j "$JOB_ID" -h -o "%i" | grep -q "_"; then
        echo -e "\n${BLUE}数组作业状态统计:${NC}"
        sacct -j "$JOB_ID" --format=State -X -P | tail -n +2 | sort | uniq -c | awk '{printf "  %s: %d 个任务\n", $2, $1}'
    fi
}

# 获取资源使用情况
get_resource_usage() {
    echo -e "\n${YELLOW}===== 资源使用情况 =====${NC}"
    
    # 内存和CPU使用
    sstat -j "$JOB_ID" --format=JobID,MaxRSS,AveRSS,AveCPU,MaxDiskRead,MaxDiskWrite 2>/dev/null | head -3
    
    # GPU使用情况（如果作业在运行）
    if squeue -j "$JOB_ID" -t R &>/dev/null; then
        echo -e "\n${BLUE}GPU使用情况:${NC}"
        NODE=$(squeue -j "$JOB_ID" -h -o "%N" | head -1)
        if [[ -n "$NODE" ]]; then
            ssh "$NODE" "nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits" 2>/dev/null || echo "无法获取GPU信息"
        fi
    fi
}

# 获取ParallelFold特定进度信息
get_parallelfold_progress() {
    echo -e "\n${YELLOW}===== ParallelFold 预测进度 =====${NC}"
    
    # 查找输出文件
    OUTPUT_FILES=$(find . -name "*${JOB_ID}*.out" -type f 2>/dev/null)
    
    if [[ -n "$OUTPUT_FILES" ]]; then
        for file in $OUTPUT_FILES; do
            if [[ -f "$file" ]]; then
                echo -e "${BLUE}分析文件: $(basename $file)${NC}"
                
                # 检查ParallelFold特定的进度标志
                if grep -q "开始ParallelFold" "$file"; then
                    echo "  ✅ ParallelFold已启动"
                else
                    echo "  ⏳ 等待ParallelFold启动"
                    continue
                fi
                
                if grep -q "序列分析" "$file"; then
                    echo "  ✅ 序列分析完成"
                fi
                
                if grep -q "MSA搜索" "$file"; then
                    echo "  ✅ MSA搜索进行中"
                fi
                
                if grep -q "结构预测" "$file"; then
                    echo "  ✅ 结构预测进行中"
                fi
                
                if grep -q "后处理" "$file"; then
                    echo "  ✅ 后处理阶段"
                fi
                
                if grep -q "预测成功完成" "$file"; then
                    echo -e "  ${GREEN}✅ 预测已完成${NC}"
                elif grep -q "预测失败" "$file"; then
                    echo -e "  ${RED}❌ 预测失败${NC}"
                fi
                
                # 显示最新几行输出
                echo "  最近输出:"
                tail -3 "$file" | sed 's/^/    /'
            fi
        done
    else
        echo "未找到输出文件，作业可能尚未开始"
    fi
}

# 检查预测结果
check_prediction_results() {
    echo -e "\n${YELLOW}===== 预测结果检查 =====${NC}"
    
    # 查找可能的输出目录
    OUTPUT_DIRS=($(find . -maxdepth 3 -type d -name "*output*" -o -name "*result*" 2>/dev/null))
    
    if [[ ${#OUTPUT_DIRS[@]} -gt 0 ]]; then
        for dir in "${OUTPUT_DIRS[@]}"; do
            if [[ -d "$dir" ]]; then
                echo -e "${BLUE}输出目录: $dir${NC}"
                
                # 统计结果文件
                PDB_COUNT=$(find "$dir" -name "*.pdb" 2>/dev/null | wc -l)
                JSON_COUNT=$(find "$dir" -name "*.json" 2>/dev/null | wc -l)
                FASTA_COUNT=$(find "$dir" -name "*.fasta" 2>/dev/null | wc -l)
                DIR_SIZE=$(du -sh "$dir" 2>/dev/null | cut -f1)
                
                echo "  PDB结构文件: $PDB_COUNT 个"
                echo "  JSON数据文件: $JSON_COUNT 个"
                echo "  FASTA文件: $FASTA_COUNT 个"
                echo "  目录大小: $DIR_SIZE"
                
                # 检查最新生成的文件
                LATEST_PDB=$(find "$dir" -name "*.pdb" -type f -exec stat -f "%m %N" {} \; 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
                if [[ -n "$LATEST_PDB" ]]; then
                    LATEST_TIME=$(stat -f %Sm "$LATEST_PDB" 2>/dev/null)
                    echo "  最新PDB: $(basename "$LATEST_PDB") ($LATEST_TIME)"
                fi
                
                # 检查置信度文件
                CONF_FILE=$(find "$dir" -name "confidence.json" -type f | head -1)
                if [[ -f "$CONF_FILE" ]]; then
                    echo "  发现置信度文件，预测可能已完成"
                fi
            fi
        done
    else
        echo "未找到输出目录"
    fi
}

# 显示系统状态
show_system_status() {
    echo -e "\n${YELLOW}===== 系统状态 =====${NC}"
    
    # GPU队列状态
    echo "GPU队列状态:"
    squeue -p qgpu_3090 | head -10
    
    # 当前用户的相关作业
    echo -e "\n当前用户的ParallelFold作业:"
    squeue -u "$USER" | grep -i "pf_\|parallelfold\|parallel" | head -10
}

# 性能分析
analyze_performance() {
    echo -e "\n${YELLOW}===== 性能分析 =====${NC}"
    
    # 作业效率统计
    if sacct -j "$JOB_ID" --format=JobID,CPUTime,ElapsedTime -P &>/dev/null; then
        STATS=$(sacct -j "$JOB_ID" --format=CPUTime,ElapsedTime,MaxRSS -P --noheader | head -1)
        if [[ -n "$STATS" ]]; then
            echo "作业统计: $STATS"
        fi
    fi
    
    # 预估完成时间
    if squeue -j "$JOB_ID" -h -o "%M %L" &>/dev/null; then
        TIME_INFO=$(squeue -j "$JOB_ID" -h -o "%M %L")
        echo "时间信息: 已运行/剩余时间 = $TIME_INFO"
    fi
}

# 错误检查
check_errors() {
    echo -e "\n${YELLOW}===== 错误检查 =====${NC}"
    
    # 查找错误文件
    ERROR_FILES=$(find . -name "*${JOB_ID}*.err" -type f 2>/dev/null)
    
    if [[ -n "$ERROR_FILES" ]]; then
        for err_file in $ERROR_FILES; do
            if [[ -f "$err_file" && -s "$err_file" ]]; then
                echo -e "${RED}发现错误信息 ($(basename $err_file)):${NC}"
                tail -5 "$err_file" | sed 's/^/  /'
                echo ""
            fi
        done
    else
        echo -e "${GREEN}暂无错误信息${NC}"
    fi
}

# 主监控循环
main_monitor() {
    local job_completed=false
    
    while ! $job_completed; do
        clear_screen
        
        # 检查作业是否还存在
        if ! check_job_exists; then
            echo -e "${YELLOW}作业已完成，显示最终状态:${NC}"
            sacct -j "$JOB_ID" --format=JobID,JobName,State,Elapsed,ExitCode -P
            job_completed=true
        fi
        
        get_job_info
        get_resource_usage
        get_parallelfold_progress
        check_prediction_results
        analyze_performance
        check_errors
        show_system_status
        
        if ! $job_completed; then
            echo -e "\n${BLUE}监控中... 按 Ctrl+C 退出${NC}"
            echo "下次更新: $(date -d "+${INTERVAL} seconds" 2>/dev/null || date -v +${INTERVAL}S 2>/dev/null || date)"
            sleep "$INTERVAL"
        fi
    done
    
    echo -e "\n${GREEN}监控结束。${NC}"
}

# 快速状态检查模式
quick_check() {
    echo "ParallelFold作业快速状态检查"
    echo "================================"
    
    # 基本状态
    if check_job_exists; then
        squeue -j "$JOB_ID" --format="%.10i %.20j %.8u %.8T %.10M %.6D %R"
    else
        sacct -j "$JOB_ID" --format=JobID,JobName,State,ExitCode -P | tail -1
    fi
    
    # 简要进度
    OUTPUT_FILE=$(find . -name "*${JOB_ID}*.out" -type f | head -1)
    if [[ -f "$OUTPUT_FILE" ]]; then
        echo -e "\n最近输出:"
        tail -5 "$OUTPUT_FILE"
    fi
    
    # 结果统计
    RESULT_COUNT=$(find . -name "*.pdb" 2>/dev/null | wc -l)
    if [[ $RESULT_COUNT -gt 0 ]]; then
        echo -e "\n已生成 $RESULT_COUNT 个PDB文件"
    fi
}

# 信号处理
trap 'echo -e "\n\n${YELLOW}监控已停止。${NC}"; exit 0' INT TERM

# 检查是否为快速检查模式
if [[ "$2" == "quick" ]]; then
    quick_check
    exit 0
fi

# 开始监控
echo -e "${BLUE}开始监控ParallelFold作业 $JOB_ID...${NC}"
echo "提示: 使用 '$0 $JOB_ID quick' 进行快速状态检查"
echo ""
main_monitor