#!/bin/bash
#SBATCH --job-name=pf_batch
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=32
#SBATCH --gres=gpu:2
#SBATCH --time=24:00:00
#SBATCH --partition=qgpu_3090
#SBATCH --mem=64GB
#SBATCH --output=pf_batch_%A_%a.out
#SBATCH --error=pf_batch_%A_%a.err
#SBATCH --array=1-10%3

# ParallelFold 批量预测脚本
# 支持数组作业并行处理多个FASTA文件
# 使用方法: sbatch --array=1-N pf-batch.slurm INPUT_DIR OUTPUT_DIR
# 其中 N 为输入目录中FASTA文件的数量

echo "============================================"
echo "ParallelFold 批量蛋白质结构预测"
echo "数组作业ID: ${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
echo "节点: $SLURMD_NODENAME"
echo "开始时间: $(date)"
echo "============================================"

# 加载模块
module load singularity

# 环境变量设置
export CUDA_VISIBLE_DEVICES=0,1
export PYTHONUNBUFFERED=1

# ParallelFold批量处理优化
export PF_NUM_WORKERS=16
export PF_BATCH_SIZE=1
export PF_USE_CACHE=true
export PF_PARALLEL_JOBS=2

# 路径配置
CONTAINER="/hpcfs/fpublic/container/singularity/app/parallelfold/parallelfold.sif"
DATABASE_PATH="/hpcfs/fpublic/database/alphafold/data"

# 输入输出目录
INPUT_DIR="${1:-batch_input}"
OUTPUT_BASE="${2:-batch_output}"

# 验证输入目录
if [[ ! -d "$INPUT_DIR" ]]; then
    echo "错误: 输入目录不存在: $INPUT_DIR"
    exit 1
fi

# 获取当前任务的输入文件
FASTA_FILES=($(find "$INPUT_DIR" -name "*.fasta" -o -name "*.fa" | sort))
TOTAL_FILES=${#FASTA_FILES[@]}

if [[ $TOTAL_FILES -eq 0 ]]; then
    echo "错误: 输入目录中没有找到FASTA文件"
    exit 1
fi

if [[ $SLURM_ARRAY_TASK_ID -gt $TOTAL_FILES ]]; then
    echo "任务ID超出文件数量范围，退出"
    exit 0
fi

# 当前处理的文件（数组索引从1开始，所以减1）
CURRENT_FASTA="${FASTA_FILES[$((SLURM_ARRAY_TASK_ID - 1))]}"
BASENAME=$(basename "$CURRENT_FASTA" .fasta)
BASENAME=${BASENAME%.fa}  # 也处理.fa后缀
CURRENT_OUTPUT="$OUTPUT_BASE/$BASENAME"

echo "当前处理文件: $CURRENT_FASTA"
echo "输出目录: $CURRENT_OUTPUT"
echo "任务进度: $SLURM_ARRAY_TASK_ID / $TOTAL_FILES"

# 创建输出目录
mkdir -p "$CURRENT_OUTPUT"

# 分析输入文件，自动选择预测模式
echo "分析输入文件..."
ANALYSIS_RESULT=$(python3 -c "
import sys
try:
    with open('$CURRENT_FASTA') as f:
        lines = f.readlines()
    
    sequences = []
    current_seq = ''
    
    for line in lines:
        if line.startswith('>'):
            if current_seq:
                sequences.append(current_seq)
            current_seq = ''
        else:
            current_seq += line.strip()
    
    if current_seq:
        sequences.append(current_seq)
    
    seq_count = len(sequences)
    lengths = [len(seq) for seq in sequences]
    total_length = sum(lengths)
    max_length = max(lengths) if lengths else 0
    
    # 自动决定预测模式
    if seq_count == 1:
        mode = 'monomer'
        complexity = 'simple' if max_length < 500 else 'medium' if max_length < 1500 else 'complex'
    elif seq_count <= 4 and total_length < 2000:
        mode = 'multimer'  
        complexity = 'medium'
    elif seq_count <= 6 and total_length < 3000:
        mode = 'multimer'
        complexity = 'complex'
    else:
        mode = 'multimer'
        complexity = 'very_complex'
    
    print(f'{mode}|{complexity}|{seq_count}|{total_length}|{max_length}')
    
except Exception as e:
    print(f'error|unknown|0|0|0')
    sys.exit(1)
")

if [[ "$ANALYSIS_RESULT" == "error"* ]]; then
    echo "错误: 无法解析FASTA文件"
    exit 1
fi

IFS='|' read -r MODE COMPLEXITY SEQ_COUNT TOTAL_LENGTH MAX_LENGTH <<< "$ANALYSIS_RESULT"

echo "文件分析结果:"
echo "  预测模式: $MODE"
echo "  复杂度: $COMPLEXITY"
echo "  序列数量: $SEQ_COUNT"
echo "  总长度: $TOTAL_LENGTH"
echo "  最大长度: $MAX_LENGTH"

# 根据复杂度调整资源和参数
case $COMPLEXITY in
    "simple")
        PF_NUM_WORKERS=8
        PF_BATCH_SIZE=2
        TIMEOUT="2h"
        ;;
    "medium")
        PF_NUM_WORKERS=16
        PF_BATCH_SIZE=1
        TIMEOUT="6h"
        ;;
    "complex")
        PF_NUM_WORKERS=16
        PF_BATCH_SIZE=1
        TIMEOUT="12h"
        ;;
    "very_complex")
        PF_NUM_WORKERS=32
        PF_BATCH_SIZE=1
        TIMEOUT="24h"
        echo "警告: 复杂度很高，可能需要很长时间"
        ;;
esac

echo "运行参数:"
echo "  Workers: $PF_NUM_WORKERS"
echo "  Batch Size: $PF_BATCH_SIZE"
echo "  预计时间: $TIMEOUT"

# 显示资源信息
echo "系统资源:"
nvidia-smi --query-gpu=index,name,memory.total,memory.free --format=csv,noheader,nounits
free -h | grep Mem

# 开始预测
echo "============================================"
echo "开始第 $SLURM_ARRAY_TASK_ID 个预测任务"
echo "文件: $(basename $CURRENT_FASTA)"
echo "模式: $MODE"
echo "============================================"

start_time=$(date +%s)

# 设置超时机制
timeout_seconds=$(($(echo $TIMEOUT | grep -o '[0-9]*') * 3600))
if [[ $TIMEOUT == *"h"* ]]; then
    timeout_seconds=$(($(echo $TIMEOUT | grep -o '[0-9]*') * 3600))
else
    timeout_seconds=$(($(echo $TIMEOUT | grep -o '[0-9]*') * 60))
fi

# 运行ParallelFold预测
timeout "$timeout_seconds" singularity run --nv \
    -B "$DATABASE_PATH:/database" \
    -B "$(pwd):/workspace" \
    "$CONTAINER" \
    --input "/workspace/$CURRENT_FASTA" \
    --output "/workspace/$CURRENT_OUTPUT" \
    --mode "$MODE" \
    --num_workers "$PF_NUM_WORKERS" \
    --batch_size "$PF_BATCH_SIZE" \
    --database_dir "/database"

# 检查结果
PREDICT_EXIT_CODE=$?
end_time=$(date +%s)
runtime=$((end_time - start_time))

echo "============================================"
echo "任务 $SLURM_ARRAY_TASK_ID 完成"
echo "退出码: $PREDICT_EXIT_CODE"
echo "运行时间: $((runtime / 3600))h $((runtime % 3600 / 60))m $((runtime % 60))s"

# 处理超时情况
if [[ $PREDICT_EXIT_CODE -eq 124 ]]; then
    echo "⚠️ 预测超时 (${TIMEOUT})"
    RESULT_STATUS="TIMEOUT"
elif [[ $PREDICT_EXIT_CODE -eq 0 ]]; then
    echo "✅ 预测成功完成"
    RESULT_STATUS="SUCCESS"
    
    # 统计输出文件
    PDB_COUNT=$(find "$CURRENT_OUTPUT" -name "*.pdb" | wc -l)
    JSON_COUNT=$(find "$CURRENT_OUTPUT" -name "*.json" | wc -l)
    OUTPUT_SIZE=$(du -sh "$CURRENT_OUTPUT" 2>/dev/null | cut -f1 || echo "0")
    
    echo "输出统计:"
    echo "  PDB文件: $PDB_COUNT 个"
    echo "  JSON文件: $JSON_COUNT 个"
    echo "  总大小: $OUTPUT_SIZE"
    
    # 快速质量检查
    BEST_PDB=$(find "$CURRENT_OUTPUT" -name "ranked_0.pdb" -o -name "*.pdb" | head -1)
    if [[ -f "$BEST_PDB" ]]; then
        ATOM_COUNT=$(grep "^ATOM" "$BEST_PDB" | wc -l)
        echo "  最佳结构原子数: $ATOM_COUNT"
    fi
    
    # 检查置信度
    CONF_FILE=$(find "$CURRENT_OUTPUT" -name "confidence.json" | head -1)
    if [[ -f "$CONF_FILE" ]]; then
        AVG_PLDDT=$(python3 -c "
import json
try:
    with open('$CONF_FILE') as f:
        data = json.load(f)
    if 'plddt' in data and isinstance(data['plddt'], list):
        print(f'{sum(data[\"plddt\"]) / len(data[\"plddt\"]):.1f}')
    else:
        print('N/A')
except:
    print('N/A')
")
        echo "  平均pLDDT: $AVG_PLDDT"
    fi
    
else
    echo "❌ 预测失败"
    RESULT_STATUS="FAILED"
    
    echo "可能的失败原因:"
    echo "1. FASTA格式错误"
    echo "2. 序列过长或复杂"
    echo "3. 内存不足"
    echo "4. GPU资源冲突"
fi

# 记录任务结果到日志
LOG_FILE="$OUTPUT_BASE/batch_log.txt"
mkdir -p "$OUTPUT_BASE"
echo "$(date '+%Y-%m-%d %H:%M:%S') TASK_$SLURM_ARRAY_TASK_ID $RESULT_STATUS $(basename $CURRENT_FASTA) ${runtime}s $MODE" >> "$LOG_FILE"

# 资源使用统计
echo "资源使用情况:"
echo "  峰值内存: $(sstat -j $SLURM_JOB_ID.$SLURM_ARRAY_TASK_ID --format=MaxRSS --noheader 2>/dev/null || echo '未知')"
echo "  平均CPU: $(sstat -j $SLURM_JOB_ID.$SLURM_ARRAY_TASK_ID --format=AveCPU --noheader 2>/dev/null || echo '未知')"

# GPU使用统计
if command -v nvidia-smi >/dev/null; then
    echo "  GPU状态:"
    nvidia-smi --query-gpu=utilization.gpu,memory.used --format=csv,noheader,nounits | head -2
fi

# 清理临时文件（可选）
if [[ "$RESULT_STATUS" == "SUCCESS" && -d "$CURRENT_OUTPUT/tmp" ]]; then
    echo "清理临时文件..."
    rm -rf "$CURRENT_OUTPUT/tmp"
fi

echo "============================================"
echo "任务完成时间: $(date)"
echo "============================================"

exit $PREDICT_EXIT_CODE