#!/bin/bash

# AlphaFold 3 作业监控脚本
# 用法: bash af3-monitor.sh [JOB_ID] [监控间隔秒数，默认30]

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
    echo -e "${BLUE}AlphaFold 3 作业监控面板 - 作业ID: $JOB_ID${NC}"
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
}

# 获取资源使用情况
get_resource_usage() {
    echo -e "\n${YELLOW}===== 资源使用情况 =====${NC}"
    
    # 内存和CPU使用
    sstat -j "$JOB_ID" --format=JobID,MaxRSS,AveRSS,AveCPU,MaxDiskRead,MaxDiskWrite 2>/dev/null | head -3
    
    # GPU使用情况（如果作业在运行）
    if squeue -j "$JOB_ID" -t R &>/dev/null; then
        echo -e "\n${BLUE}GPU使用情况:${NC}"
        NODE=$(squeue -j "$JOB_ID" -h -o "%N")
        if [[ -n "$NODE" ]]; then
            ssh "$NODE" "nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits" 2>/dev/null || echo "无法获取GPU信息"
        fi
    fi
}

# 获取作业输出
get_job_output() {
    echo -e "\n${YELLOW}===== 最近输出日志 (最后20行) =====${NC}"
    
    # 查找输出文件
    OUTPUT_FILE=""
    if [[ -f "af3_single_${JOB_ID}.out" ]]; then
        OUTPUT_FILE="af3_single_${JOB_ID}.out"
    elif [[ -f "af3_complex_${JOB_ID}.out" ]]; then
        OUTPUT_FILE="af3_complex_${JOB_ID}.out"
    elif [[ -f "af3_batch_${JOB_ID}_1.out" ]]; then
        OUTPUT_FILE="af3_batch_${JOB_ID}_1.out"
    else
        # 查找任何匹配的输出文件
        OUTPUT_FILE=$(find . -name "*${JOB_ID}*.out" -type f 2>/dev/null | head -1)
    fi
    
    if [[ -n "$OUTPUT_FILE" && -f "$OUTPUT_FILE" ]]; then
        echo -e "${BLUE}输出文件: $OUTPUT_FILE${NC}"
        tail -20 "$OUTPUT_FILE" | sed 's/^/  /'
    else
        echo "输出文件未找到或尚未生成"
    fi
}

# 获取错误信息
check_errors() {
    echo -e "\n${YELLOW}===== 错误检查 =====${NC}"
    
    # 查找错误文件
    ERROR_FILE=""
    if [[ -f "af3_single_${JOB_ID}.err" ]]; then
        ERROR_FILE="af3_single_${JOB_ID}.err"
    elif [[ -f "af3_complex_${JOB_ID}.err" ]]; then
        ERROR_FILE="af3_complex_${JOB_ID}.err"
    elif [[ -f "af3_batch_${JOB_ID}_1.err" ]]; then
        ERROR_FILE="af3_batch_${JOB_ID}_1.err"
    else
        ERROR_FILE=$(find . -name "*${JOB_ID}*.err" -type f 2>/dev/null | head -1)
    fi
    
    if [[ -n "$ERROR_FILE" && -f "$ERROR_FILE" && -s "$ERROR_FILE" ]]; then
        echo -e "${RED}发现错误信息 (最后10行):${NC}"
        tail -10 "$ERROR_FILE" | sed 's/^/  /'
    else
        echo -e "${GREEN}暂无错误信息${NC}"
    fi
}

# 预测进度估算（基于日志内容）
estimate_progress() {
    echo -e "\n${YELLOW}===== 进度估算 =====${NC}"
    
    # 查找输出文件并估算进度
    OUTPUT_FILES=$(find . -name "*${JOB_ID}*.out" -type f 2>/dev/null)
    
    if [[ -n "$OUTPUT_FILES" ]]; then
        for file in $OUTPUT_FILES; do
            if [[ -f "$file" ]]; then
                echo -e "${BLUE}分析文件: $(basename $file)${NC}"
                
                # 检查关键进度指标
                if grep -q "开始AlphaFold 3预测" "$file"; then
                    echo "  ✅ 预测已开始"
                else
                    echo "  ⏳ 等待预测开始"
                    continue
                fi
                
                if grep -q "MSA search" "$file"; then
                    echo "  ✅ MSA搜索进行中"
                fi
                
                if grep -q "Structure prediction" "$file"; then
                    echo "  ✅ 结构预测进行中"
                fi
                
                if grep -q "confidence.*json" "$file"; then
                    echo "  ✅ 置信度计算完成"
                fi
                
                if grep -q "预测成功完成\|预测完成" "$file"; then
                    echo -e "  ${GREEN}✅ 预测已完成${NC}"
                elif grep -q "预测失败" "$file"; then
                    echo -e "  ${RED}❌ 预测失败${NC}"
                fi
            fi
        done
    else
        echo "未找到输出文件，作业可能尚未开始"
    fi
}

# 检查输出结果
check_outputs() {
    echo -e "\n${YELLOW}===== 输出文件检查 =====${NC}"
    
    # 查找可能的输出目录
    OUTPUT_DIRS=($(find . -maxdepth 2 -type d -name "*output*" 2>/dev/null))
    
    if [[ ${#OUTPUT_DIRS[@]} -gt 0 ]]; then
        for dir in "${OUTPUT_DIRS[@]}"; do
            if [[ -d "$dir" ]]; then
                echo -e "${BLUE}输出目录: $dir${NC}"
                
                CIF_COUNT=$(find "$dir" -name "*.cif" 2>/dev/null | wc -l)
                JSON_COUNT=$(find "$dir" -name "*.json" 2>/dev/null | wc -l)
                DIR_SIZE=$(du -sh "$dir" 2>/dev/null | cut -f1)
                
                echo "  结构文件(.cif): $CIF_COUNT 个"
                echo "  JSON文件: $JSON_COUNT 个"
                echo "  目录大小: $DIR_SIZE"
                
                # 检查最新生成的文件
                LATEST_FILE=$(find "$dir" -type f -name "*.cif" -o -name "*.json" 2>/dev/null | head -1)
                if [[ -n "$LATEST_FILE" ]]; then
                    echo "  最新文件: $(basename $LATEST_FILE) ($(stat -c %y "$LATEST_FILE" 2>/dev/null || stat -f %Sm "$LATEST_FILE" 2>/dev/null))"
                fi
            fi
        done
    else
        echo "未找到输出目录"
    fi
}

# 显示队列中相关作业
show_related_jobs() {
    echo -e "\n${YELLOW}===== 相关作业状态 =====${NC}"
    echo "当前用户的AF3作业:"
    squeue -u "$USER" | grep -i "af3\|alphafold" | head -10
}

# 主监控循环
main_monitor() {
    local job_completed=false
    
    while ! $job_completed; do
        clear_screen
        
        # 检查作业是否还存在
        if ! check_job_exists; then
            # 作业已完成，显示最终状态
            echo -e "${YELLOW}作业已完成，显示最终状态:${NC}"
            sacct -j "$JOB_ID" --format=JobID,JobName,State,Elapsed,ExitCode -P
            job_completed=true
        fi
        
        get_job_info
        get_resource_usage
        estimate_progress
        check_outputs
        get_job_output
        check_errors
        show_related_jobs
        
        if ! $job_completed; then
            echo -e "\n${BLUE}监控中... 按 Ctrl+C 退出${NC}"
            echo "下次更新: $(date -d "+${INTERVAL} seconds" 2>/dev/null || date)"
            sleep "$INTERVAL"
        fi
    done
    
    echo -e "\n${GREEN}监控结束。${NC}"
}

# 信号处理
trap 'echo -e "\n\n${YELLOW}监控已停止。${NC}"; exit 0' INT TERM

# 开始监控
echo -e "${BLUE}开始监控作业 $JOB_ID...${NC}"
main_monitor