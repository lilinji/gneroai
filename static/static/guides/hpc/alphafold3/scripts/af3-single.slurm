#!/bin/bash
#SBATCH --job-name=af3_single
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --gres=gpu:1
#SBATCH --time=04:00:00
#SBATCH --partition=qgpu_a40
#SBATCH --mem=64GB
#SBATCH --output=af3_single_%j.out
#SBATCH --error=af3_single_%j.err

# AlphaFold 3 单体蛋白预测脚本
# 适用于: 序列长度 < 500氨基酸的单体蛋白

echo "============================================"
echo "AlphaFold 3 单体蛋白结构预测"
echo "作业ID: $SLURM_JOB_ID"
echo "节点: $SLURMD_NODENAME"
echo "开始时间: $(date)"
echo "============================================"

# 加载模块
module load singularity

# 环境变量设置
export CUDA_VISIBLE_DEVICES=0
export PYTHONUNBUFFERED=1

# 路径配置
CONTAINER="/hpcfs/fpublic/container/singularity/app/af3/af3.sif"
MODEL_WEIGHTS="/hpcfs/fhome/${USER}/models_weight"
DATABASE_PATH="/hpcfs/fpublic/database/alphafold/af3/data"

# 输入输出路径
JSON_INPUT="${1:-input/fold_input.json}"
OUTPUT_DIR="${2:-output/$(basename $JSON_INPUT .json)}"

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 验证输入文件
echo "检查输入文件: $JSON_INPUT"
if [[ ! -f "$JSON_INPUT" ]]; then
    echo "错误: 输入文件不存在: $JSON_INPUT"
    exit 1
fi

# 验证权重目录
echo "检查模型权重: $MODEL_WEIGHTS"
if [[ ! -d "$MODEL_WEIGHTS" ]]; then
    echo "错误: 模型权重目录不存在: $MODEL_WEIGHTS"
    echo "请先申请并上传AlphaFold3模型权重"
    exit 1
fi

# 验证JSON格式
echo "验证JSON格式..."
python3 -c "import json; json.load(open('$JSON_INPUT'))" || {
    echo "错误: JSON文件格式无效"
    exit 1
}

# 显示系统信息
echo "GPU信息:"
nvidia-smi --query-gpu=index,name,memory.total,memory.used --format=csv,noheader,nounits

echo "内存信息:"
free -h

echo "CPU信息:"
lscpu | grep "Model name\|CPU(s)\|Thread"

# 运行AlphaFold 3预测
echo "开始AlphaFold 3预测..."
singularity exec --nv \
    -B "$MODEL_WEIGHTS:/af3/model_weight" \
    -B "$DATABASE_PATH:/af3/data" \
    -B "$(pwd):/work" \
    "$CONTAINER" \
    sh /opt/f3.sh \
    --json_path="$JSON_INPUT" \
    --output_dir="$OUTPUT_DIR" \
    --model_dir="/af3/model_weight" \
    --db_dir="/af3/data"

# 检查执行结果
PREDICT_EXIT_CODE=$?
echo "预测完成，退出码: $PREDICT_EXIT_CODE"

if [[ $PREDICT_EXIT_CODE -eq 0 ]]; then
    echo "✅ AlphaFold 3预测成功完成"
    
    # 显示输出结果
    echo "输出文件列表:"
    find "$OUTPUT_DIR" -type f -name "*.cif" -o -name "*.json" -o -name "*.csv" | sort
    
    # 计算输出大小
    OUTPUT_SIZE=$(du -sh "$OUTPUT_DIR" | cut -f1)
    echo "输出目录大小: $OUTPUT_SIZE"
    
    # 生成结果摘要
    echo "正在生成结果摘要..."
    if [[ -f "$OUTPUT_DIR"/*/summary_confidences.json ]]; then
        echo "置信度摘要:"
        python3 -c "
import json
import glob
summary_files = glob.glob('$OUTPUT_DIR/*/summary_confidences.json')
for f in summary_files:
    with open(f) as fh:
        data = json.load(fh)
        print(f'文件: {f}')
        if 'ptm' in data:
            print(f'  PTM分值: {data[\"ptm\"]:.3f}')
        if 'iptm' in data:
            print(f'  iPTM分值: {data[\"iptm\"]:.3f}')
"
    fi
else
    echo "❌ AlphaFold 3预测失败"
    echo "请检查错误日志: af3_single_${SLURM_JOB_ID}.err"
fi

echo "============================================"
echo "作业完成时间: $(date)"
echo "总运行时间: $(scontrol show job $SLURM_JOB_ID | grep RunTime)"
echo "============================================"

exit $PREDICT_EXIT_CODE