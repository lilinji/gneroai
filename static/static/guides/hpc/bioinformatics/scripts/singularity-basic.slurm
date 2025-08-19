#!/bin/bash
#SBATCH --job-name=bioinformatics_job   # 作业名称
#SBATCH --nodes=1                       # 节点数量
#SBATCH --ntasks-per-node=8             # 每节点进程数
#SBATCH --cpus-per-task=1               # 每任务CPU核数
#SBATCH --time=04:00:00                 # 运行时间限制
#SBATCH --partition=qcpu_q18i           # 计算分区
#SBATCH --mem=32GB                      # 内存需求
#SBATCH --output=bio_tool_%j.out        # 标准输出
#SBATCH --error=bio_tool_%j.err         # 错误输出

# 环境设置
module purge
module load singularity

# 作业信息
echo "===== 生信工具作业信息 ====="
echo "作业ID: $SLURM_JOB_ID"
echo "节点数: $SLURM_NNODES"
echo "总进程数: $(( $SLURM_NNODES * $SLURM_NTASKS_PER_NODE ))"
echo "工作目录: $PWD"
echo "开始时间: $(date)"
echo "========================"

# 设置输入输出目录
INPUT_DIR="$PWD/input"
OUTPUT_DIR="$PWD/output"
CONTAINER_PATH="/hpcfs/fpublic/container/singularity/app"

# 检查输入目录
if [[ ! -d "$INPUT_DIR" ]]; then
    echo "错误: 输入目录不存在: $INPUT_DIR"
    exit 1
fi

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 设置工具特定变量（需要根据具体工具修改）
TOOL_NAME="your_tool"
CONTAINER_IMAGE="$CONTAINER_PATH/$TOOL_NAME/$TOOL_NAME.sif"
INPUT_FILE="$INPUT_DIR/input.fasta"
OUTPUT_FILE="$OUTPUT_DIR/output.txt"

# 检查容器文件
if [[ ! -f "$CONTAINER_IMAGE" ]]; then
    echo "错误: 容器文件不存在: $CONTAINER_IMAGE"
    exit 1
fi

# 检查输入文件
if [[ ! -f "$INPUT_FILE" ]]; then
    echo "错误: 输入文件不存在: $INPUT_FILE"
    exit 1
fi

# 运行生信工具（示例命令，需要根据具体工具修改）
echo "开始运行 $TOOL_NAME..."
singularity exec "$CONTAINER_IMAGE" \
    tool_command \
    --input "$INPUT_FILE" \
    --output "$OUTPUT_FILE" \
    --threads $SLURM_NTASKS_PER_NODE

# 检查运行结果
if [[ $? -eq 0 ]]; then
    echo "$TOOL_NAME 运行成功"
    echo "输出文件: $OUTPUT_FILE"
else
    echo "$TOOL_NAME 运行失败"
    exit 1
fi

echo "完成时间: $(date)"