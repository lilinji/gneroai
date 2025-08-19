#!/bin/bash
#SBATCH --job-name=af3_batch
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=32
#SBATCH --gres=gpu:2
#SBATCH --time=48:00:00
#SBATCH --partition=qgpu_a40
#SBATCH --mem=128GB
#SBATCH --output=af3_batch_%A_%a.out
#SBATCH --error=af3_batch_%A_%a.err
#SBATCH --array=1-10%3

# AlphaFold 3 批量预测脚本
# 支持数组作业并行处理多个输入文件
# 使用方法: sbatch --array=1-N af3-batch.slurm INPUT_DIR OUTPUT_DIR
# 其中 N 为输入目录中JSON文件的数量

echo "============================================"
echo "AlphaFold 3 批量结构预测"
echo "数组作业ID: ${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
echo "节点: $SLURMD_NODENAME"
echo "开始时间: $(date)"
echo "============================================"

# 加载模块
module load singularity

# 环境变量设置
export CUDA_VISIBLE_DEVICES=0,1
export PYTHONUNBUFFERED=1
export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512

# 路径配置
CONTAINER="/hpcfs/fpublic/container/singularity/app/af3/af3.sif"
MODEL_WEIGHTS="/hpcfs/fhome/${USER}/models_weight"
DATABASE_PATH="/hpcfs/fpublic/database/alphafold/af3/data"

# 输入输出目录
INPUT_DIR="${1:-batch_input}"
OUTPUT_BASE="${2:-batch_output}"

# 验证输入目录
if [[ ! -d "$INPUT_DIR" ]]; then
    echo "错误: 输入目录不存在: $INPUT_DIR"
    exit 1
fi

# 获取当前任务的输入文件
JSON_FILES=($(find "$INPUT_DIR" -name "*.json" | sort))
TOTAL_FILES=${#JSON_FILES[@]}

if [[ $TOTAL_FILES -eq 0 ]]; then
    echo "错误: 输入目录中没有找到JSON文件"
    exit 1
fi

if [[ $SLURM_ARRAY_TASK_ID -gt $TOTAL_FILES ]]; then
    echo "任务ID超出文件数量范围，退出"
    exit 0
fi

# 当前处理的文件（数组索引从1开始，所以减1）
CURRENT_JSON="${JSON_FILES[$((SLURM_ARRAY_TASK_ID - 1))]}"
BASENAME=$(basename "$CURRENT_JSON" .json)
CURRENT_OUTPUT="$OUTPUT_BASE/$BASENAME"

echo "当前处理文件: $CURRENT_JSON"
echo "输出目录: $CURRENT_OUTPUT"
echo "任务进度: $SLURM_ARRAY_TASK_ID / $TOTAL_FILES"

# 创建输出目录
mkdir -p "$CURRENT_OUTPUT"

# 验证模型权重
if [[ ! -d "$MODEL_WEIGHTS" ]]; then
    echo "错误: 模型权重目录不存在: $MODEL_WEIGHTS"
    exit 1
fi

# 分析输入文件复杂度，自动调整参数
echo "分析输入文件复杂度..."
COMPLEXITY_RESULT=$(python3 -c "
import json
import sys

try:
    with open('$CURRENT_JSON') as f:
        data = json.load(f)
    
    sequences = data.get('sequences', [])
    total_length = 0
    chain_count = len(sequences)
    has_complex = False
    
    for seq in sequences:
        if 'protein' in seq:
            total_length += len(seq['protein']['sequence'])
        elif 'dna' in seq:
            total_length += len(seq['dna']['sequence'])
            has_complex = True
        elif 'rna' in seq:
            total_length += len(seq['rna']['sequence'])
            has_complex = True
    
    # 复杂度分类
    if total_length < 500 and chain_count == 1:
        complexity = 'simple'
    elif total_length < 1500 and not has_complex:
        complexity = 'medium'
    elif total_length < 3000:
        complexity = 'complex'
    else:
        complexity = 'very_complex'
    
    print(f'{complexity}|{total_length}|{chain_count}|{has_complex}')
    
except Exception as e:
    print(f'error|0|0|False')
    sys.exit(1)
")

if [[ "$COMPLEXITY_RESULT" == "error"* ]]; then
    echo "错误: 无法解析JSON文件"
    exit 1
fi

IFS='|' read -r COMPLEXITY TOTAL_LENGTH CHAIN_COUNT HAS_COMPLEX <<< "$COMPLEXITY_RESULT"

echo "复杂度分析结果:"
echo "  分类: $COMPLEXITY"
echo "  总长度: $TOTAL_LENGTH"
echo "  链数: $CHAIN_COUNT"
echo "  包含DNA/RNA: $HAS_COMPLEX"

# 根据复杂度调整预测参数
case $COMPLEXITY in
    "simple")
        NUM_SAMPLES=3
        NUM_SEEDS=1
        ;;
    "medium")
        NUM_SAMPLES=5
        NUM_SEEDS=2
        ;;
    "complex")
        NUM_SAMPLES=5
        NUM_SEEDS=3
        ;;
    "very_complex")
        NUM_SAMPLES=3
        NUM_SEEDS=1
        echo "警告: 序列非常复杂，可能需要更长时间"
        ;;
esac

# 显示资源信息
echo "系统资源信息:"
nvidia-smi --query-gpu=index,name,memory.total,memory.free --format=csv,noheader,nounits
free -h

# 开始预测
echo "============================================"
echo "开始第 $SLURM_ARRAY_TASK_ID 个预测任务"
echo "文件: $(basename $CURRENT_JSON)"
echo "参数: samples=$NUM_SAMPLES, seeds=$NUM_SEEDS"
echo "============================================"

start_time=$(date +%s)

singularity exec --nv \
    -B "$MODEL_WEIGHTS:/af3/model_weight" \
    -B "$DATABASE_PATH:/af3/data" \
    -B "$(pwd):/work" \
    "$CONTAINER" \
    sh /opt/f3.sh \
    --json_path="$CURRENT_JSON" \
    --output_dir="$CURRENT_OUTPUT" \
    --model_dir="/af3/model_weight" \
    --db_dir="/af3/data" \
    --num_diffusion_samples="$NUM_SAMPLES" \
    --num_seed="$NUM_SEEDS"

# 检查结果
PREDICT_EXIT_CODE=$?
end_time=$(date +%s)
runtime=$((end_time - start_time))

echo "============================================"
echo "任务 $SLURM_ARRAY_TASK_ID 完成"
echo "退出码: $PREDICT_EXIT_CODE"
echo "运行时间: $((runtime / 3600))h $((runtime % 3600 / 60))m $((runtime % 60))s"

if [[ $PREDICT_EXIT_CODE -eq 0 ]]; then
    echo "✅ 预测成功完成"
    
    # 统计输出文件
    CIF_COUNT=$(find "$CURRENT_OUTPUT" -name "*.cif" | wc -l)
    JSON_COUNT=$(find "$CURRENT_OUTPUT" -name "*.json" | wc -l)
    OUTPUT_SIZE=$(du -sh "$CURRENT_OUTPUT" | cut -f1)
    
    echo "输出统计:"
    echo "  结构文件: $CIF_COUNT 个"
    echo "  JSON文件: $JSON_COUNT 个"
    echo "  总大小: $OUTPUT_SIZE"
    
    # 快速质量检查
    if [[ -f "$CURRENT_OUTPUT"/*/summary_confidences.json ]]; then
        python3 -c "
import json
import glob
summary_files = glob.glob('$CURRENT_OUTPUT/*/summary_confidences.json')
if summary_files:
    with open(summary_files[0]) as f:
        data = json.load(f)
    print('质量指标:')
    if 'ptm' in data:
        ptm = data['ptm']
        quality = 'excellent' if ptm > 0.8 else 'good' if ptm > 0.5 else 'poor'
        print(f'  PTM分值: {ptm:.3f} ({quality})')
    if 'iptm' in data:
        print(f'  iPTM分值: {data[\"iptm\"]:.3f}')
"
    fi
    
    # 记录成功任务
    echo "$(date '+%Y-%m-%d %H:%M:%S') SUCCESS $BASENAME $runtime" >> "$OUTPUT_BASE/batch_log.txt"
    
else
    echo "❌ 预测失败"
    echo "失败原因可能包括:"
    echo "1. 输入格式错误"
    echo "2. 序列过长或过复杂"  
    echo "3. 内存或GPU资源不足"
    echo "4. 模型权重问题"
    
    # 记录失败任务
    echo "$(date '+%Y-%m-%d %H:%M:%S') FAILED $BASENAME $PREDICT_EXIT_CODE" >> "$OUTPUT_BASE/batch_log.txt"
fi

# 资源使用统计
echo "资源使用情况:"
echo "  峰值内存: $(sstat -j $SLURM_JOB_ID.$SLURM_ARRAY_TASK_ID --format=MaxRSS --noheader 2>/dev/null || echo '未知')"
echo "  平均CPU利用率: $(sstat -j $SLURM_JOB_ID.$SLURM_ARRAY_TASK_ID --format=AveCPU --noheader 2>/dev/null || echo '未知')"

echo "============================================"
echo "任务完成时间: $(date)"
echo "============================================"

exit $PREDICT_EXIT_CODE