#!/bin/bash
#SBATCH --job-name=colabfold_basic      # 作业名称
#SBATCH --nodes=1                       # 节点数量
#SBATCH --ntasks-per-node=1             # 每节点进程数
#SBATCH --cpus-per-task=16              # 每任务CPU核数
#SBATCH --gres=gpu:1                    # GPU资源需求
#SBATCH --time=02:00:00                 # 运行时间限制
#SBATCH --partition=qgpu_3090           # GPU分区
#SBATCH --mem=32GB                      # 内存需求
#SBATCH --output=colabfold_%j.out       # 标准输出
#SBATCH --error=colabfold_%j.err        # 错误输出

# 环境设置
module purge
module load singularity

# 作业信息
echo "===== ColabFold作业信息 ====="
echo "作业ID: $SLURM_JOB_ID"
echo "GPU设备: $CUDA_VISIBLE_DEVICES"
echo "工作目录: $PWD"
echo "开始时间: $(date)"
echo "=========================="

# 设置路径
INPUT_DIR="$PWD/input"
OUTPUT_DIR="$PWD/output"
CONTAINER_PATH="/hpcfs/fpublic/container/singularity/app/colabfold/colabfold_1.5.5-cuda12.2.2.sif"
PARAMS_PATH="/hpcfs/fpublic/container/singularity/app/cobafold/params"

# 检查输入文件
FASTA_FILE="$INPUT_DIR/input.fasta"
if [[ ! -f "$FASTA_FILE" ]]; then
    echo "错误: 输入文件不存在: $FASTA_FILE"
    exit 1
fi

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 检查容器文件
if [[ ! -f "$CONTAINER_PATH" ]]; then
    echo "错误: 容器文件不存在: $CONTAINER_PATH"
    exit 1
fi

# 运行ColabFold
echo "开始ColabFold结构预测..."
singularity run --nv \
    -B "$PARAMS_PATH:/cache" \
    -B "$PWD:/work" \
    "$CONTAINER_PATH" \
    colabfold_batch \
    "$FASTA_FILE" \
    "$OUTPUT_DIR" \
    --num-models 5 \
    --num-recycle 3 \
    --model-type auto

# 检查运行结果
if [[ $? -eq 0 ]]; then
    echo "ColabFold预测成功完成"
    echo "输出目录: $OUTPUT_DIR"
    ls -la "$OUTPUT_DIR"
else
    echo "ColabFold预测失败"
    exit 1
fi

echo "完成时间: $(date)"