#!/bin/bash
#SBATCH --job-name=bio_gpu_job          # 作业名称
#SBATCH --nodes=1                       # 节点数量  
#SBATCH --ntasks-per-node=1             # 每节点进程数
#SBATCH --cpus-per-task=8               # 每任务CPU核数
#SBATCH --gres=gpu:1                    # GPU资源需求
#SBATCH --time=08:00:00                 # 运行时间限制
#SBATCH --partition=qgpu_3090           # GPU分区
#SBATCH --mem=64GB                      # 内存需求
#SBATCH --output=bio_gpu_%j.out         # 标准输出
#SBATCH --error=bio_gpu_%j.err          # 错误输出

# 环境设置
module purge  
module load singularity
module load cuda/11.8

# 环境变量
export CUDA_VISIBLE_DEVICES=$SLURM_LOCALID

# 作业信息
echo "===== GPU生信工具作业信息 ====="
echo "作业ID: $SLURM_JOB_ID"
echo "GPU设备: $CUDA_VISIBLE_DEVICES"
echo "CUDA版本: $(nvcc --version | grep release)"
echo "GPU信息: $(nvidia-smi --query-gpu=name --format=csv,noheader)"
echo "工作目录: $PWD"
echo "开始时间: $(date)"
echo "=========================="

# 设置目录
INPUT_DIR="$PWD/input"
OUTPUT_DIR="$PWD/output"
CHECKPOINT_DIR="$PWD/checkpoint"
CONTAINER_PATH="/hpcfs/fpublic/container/singularity/app"

# 创建必要目录
mkdir -p "$OUTPUT_DIR" "$CHECKPOINT_DIR"

# 工具配置（需要根据具体工具修改）
TOOL_NAME="your_gpu_tool"
CONTAINER_IMAGE="$CONTAINER_PATH/$TOOL_NAME/$TOOL_NAME.sif"

# 检查GPU可用性
if ! nvidia-smi > /dev/null 2>&1; then
    echo "错误: GPU不可用"
    exit 1
fi

# 检查容器文件
if [[ ! -f "$CONTAINER_IMAGE" ]]; then
    echo "错误: 容器文件不存在: $CONTAINER_IMAGE"
    exit 1
fi

# 运行GPU加速的生信工具（示例命令）
echo "开始运行GPU加速的 $TOOL_NAME..."
singularity exec --nv \
    --bind "$INPUT_DIR:/workspace/input" \
    --bind "$OUTPUT_DIR:/workspace/output" \
    --bind "$CHECKPOINT_DIR:/workspace/checkpoint" \
    "$CONTAINER_IMAGE" \
    python /workspace/tool_script.py \
    --input /workspace/input/input.fasta \
    --output /workspace/output/result.txt \
    --device cuda:0 \
    --batch-size 32

# 检查运行结果
if [[ $? -eq 0 ]]; then
    echo "GPU $TOOL_NAME 运行成功"
    echo "输出目录: $OUTPUT_DIR"
else
    echo "GPU $TOOL_NAME 运行失败"
    exit 1
fi

echo "完成时间: $(date)"