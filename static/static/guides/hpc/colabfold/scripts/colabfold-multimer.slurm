#!/bin/bash
#SBATCH --job-name=colabfold_multimer   # 作业名称
#SBATCH --nodes=1                       # 节点数量
#SBATCH --ntasks-per-node=1             # 每节点进程数  
#SBATCH --cpus-per-task=32              # 每任务CPU核数
#SBATCH --gres=gpu:2                    # 双GPU加速
#SBATCH --time=08:00:00                 # 长时间运行
#SBATCH --partition=qgpu_3090           # GPU分区
#SBATCH --mem=64GB                      # 大内存需求
#SBATCH --output=colabfold_multi_%j.out # 标准输出
#SBATCH --error=colabfold_multi_%j.err  # 错误输出

# 环境设置
module purge
module load singularity
module load cuda/11.8

# 环境变量
export CUDA_VISIBLE_DEVICES=$SLURM_LOCALID

# 作业信息
echo "===== ColabFold复合物预测作业 ====="
echo "作业ID: $SLURM_JOB_ID"
echo "GPU数量: $SLURM_GPUS"
echo "内存: $SLURM_MEM_PER_NODE"
echo "开始时间: $(date)"
echo "============================="

# 设置路径
INPUT_DIR="$PWD/input"
OUTPUT_DIR="$PWD/output"
TEMP_DIR="$PWD/temp"
CONTAINER_PATH="/hpcfs/fpublic/container/singularity/app/colabfold/colabfold_1.5.5-cuda12.2.2.sif"
PARAMS_PATH="/hpcfs/fpublic/container/singularity/app/cobafold/params"

# 创建必要目录
mkdir -p "$OUTPUT_DIR" "$TEMP_DIR"

# 检查输入文件
MULTIMER_FASTA="$INPUT_DIR/multimer.fasta"
if [[ ! -f "$MULTIMER_FASTA" ]]; then
    echo "错误: 复合物输入文件不存在: $MULTIMER_FASTA"
    exit 1
fi

# 验证FASTA格式（复合物需要多条序列）
seq_count=$(grep -c "^>" "$MULTIMER_FASTA")
if [[ $seq_count -lt 2 ]]; then
    echo "警告: 输入文件只包含 $seq_count 条序列，复合物预测通常需要多条序列"
fi

echo "检测到 $seq_count 条序列，开始复合物预测..."

# 运行ColabFold复合物预测
singularity run --nv \
    -B "$PARAMS_PATH:/cache" \
    -B "$PWD:/work" \
    -B "$TEMP_DIR:/tmp" \
    "$CONTAINER_PATH" \
    colabfold_batch \
    "$MULTIMER_FASTA" \
    "$OUTPUT_DIR" \
    --num-models 5 \
    --num-recycle 5 \
    --model-type AlphaFold2-multimer-v3 \
    --num-seeds 1 \
    --zip \
    --amber \
    --templates

# 检查运行结果
if [[ $? -eq 0 ]]; then
    echo "ColabFold复合物预测成功完成"
    echo "输出目录: $OUTPUT_DIR"
    echo "生成的文件:"
    find "$OUTPUT_DIR" -type f -name "*.pdb" -o -name "*.json" -o -name "*.zip" | head -10
else
    echo "ColabFold复合物预测失败"
    exit 1
fi

# 清理临时文件
rm -rf "$TEMP_DIR"

echo "完成时间: $(date)"