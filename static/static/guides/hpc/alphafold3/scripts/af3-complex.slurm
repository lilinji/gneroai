#!/bin/bash
#SBATCH --job-name=af3_complex
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=32
#SBATCH --gres=gpu:2
#SBATCH --time=24:00:00
#SBATCH --partition=qgpu_a40
#SBATCH --mem=128GB
#SBATCH --output=af3_complex_%j.out
#SBATCH --error=af3_complex_%j.err

# AlphaFold 3 复合物预测脚本
# 适用于: 蛋白质-蛋白质、蛋白质-DNA/RNA、蛋白质-配体复合物

echo "============================================"
echo "AlphaFold 3 复合物结构预测"
echo "作业ID: $SLURM_JOB_ID"
echo "节点: $SLURMD_NODENAME"
echo "GPU数量: $SLURM_GPUS_ON_NODE"
echo "开始时间: $(date)"
echo "============================================"

# 加载模块
module load singularity

# 环境变量设置
export CUDA_VISIBLE_DEVICES=0,1
export PYTHONUNBUFFERED=1

# 内存优化设置
export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
export CUDA_MEM_LIMIT=40000M

# 路径配置
CONTAINER="/hpcfs/fpublic/container/singularity/app/af3/af3.sif"
MODEL_WEIGHTS="/hpcfs/fhome/${USER}/models_weight"
DATABASE_PATH="/hpcfs/fpublic/database/alphafold/af3/data"

# 输入输出路径
JSON_INPUT="${1:-input/complex_input.json}"
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

# 分析JSON输入复杂度
echo "分析输入复杂度..."
python3 -c "
import json
with open('$JSON_INPUT') as f:
    data = json.load(f)

total_length = 0
chain_count = len(data.get('sequences', []))
for seq in data.get('sequences', []):
    if 'protein' in seq:
        total_length += len(seq['protein']['sequence'])
    elif 'dna' in seq:
        total_length += len(seq['dna']['sequence'])
    elif 'rna' in seq:
        total_length += len(seq['rna']['sequence'])

print(f'分子链数量: {chain_count}')
print(f'总序列长度: {total_length}')

if total_length > 3000:
    print('警告: 序列总长度超过3000，计算可能需要更长时间')
if chain_count > 5:
    print('警告: 分子链数量较多，建议增加计算资源')
"

# 验证JSON格式
echo "验证JSON格式..."
python3 -c "import json; json.load(open('$JSON_INPUT'))" || {
    echo "错误: JSON文件格式无效"
    exit 1
}

# 显示系统信息
echo "GPU信息:"
nvidia-smi --query-gpu=index,name,memory.total,memory.used,utilization.gpu --format=csv,noheader,nounits

echo "内存信息:"
free -h

echo "磁盘空间:"
df -h $(pwd)

# 预估所需时间和空间
echo "资源预估:"
python3 -c "
import json
with open('$JSON_INPUT') as f:
    data = json.load(f)

total_length = sum(len(seq.get('protein', {}).get('sequence', '')) for seq in data.get('sequences', []))
estimated_time_hours = max(4, total_length / 200)  # 经验公式
estimated_disk_gb = max(2, total_length / 1000 * 3)  # 经验公式

print(f'预计运行时间: {estimated_time_hours:.1f} 小时')
print(f'预计存储需求: {estimated_disk_gb:.1f} GB')
"

# 运行AlphaFold 3复合物预测
echo "开始AlphaFold 3复合物预测..."
start_time=$(date +%s)

singularity exec --nv \
    -B "$MODEL_WEIGHTS:/af3/model_weight" \
    -B "$DATABASE_PATH:/af3/data" \
    -B "$(pwd):/work" \
    "$CONTAINER" \
    sh /opt/f3.sh \
    --json_path="$JSON_INPUT" \
    --output_dir="$OUTPUT_DIR" \
    --model_dir="/af3/model_weight" \
    --db_dir="/af3/data" \
    --num_diffusion_samples=5 \
    --num_seed=3

# 检查执行结果
PREDICT_EXIT_CODE=$?
end_time=$(date +%s)
runtime=$((end_time - start_time))

echo "预测完成，退出码: $PREDICT_EXIT_CODE"
echo "实际运行时间: $((runtime / 3600))h $((runtime % 3600 / 60))m $((runtime % 60))s"

if [[ $PREDICT_EXIT_CODE -eq 0 ]]; then
    echo "✅ AlphaFold 3复合物预测成功完成"
    
    # 显示输出结果
    echo "输出文件结构:"
    tree "$OUTPUT_DIR" 2>/dev/null || find "$OUTPUT_DIR" -type f | sort
    
    # 计算输出大小
    OUTPUT_SIZE=$(du -sh "$OUTPUT_DIR" | cut -f1)
    echo "输出目录大小: $OUTPUT_SIZE"
    
    # 生成详细结果摘要
    echo "正在生成详细结果摘要..."
    if [[ -f "$OUTPUT_DIR"/*_ranking_scores.csv ]]; then
        echo "模型排序结果:"
        head -5 "$OUTPUT_DIR"/*_ranking_scores.csv
    fi
    
    # 置信度分析
    if [[ -f "$OUTPUT_DIR"/*/summary_confidences.json ]]; then
        echo "详细置信度分析:"
        python3 -c "
import json
import glob
import numpy as np

summary_files = glob.glob('$OUTPUT_DIR/*/summary_confidences.json')
for f in summary_files:
    with open(f) as fh:
        data = json.load(fh)
        print(f'\\n文件: {f}')
        if 'ptm' in data:
            print(f'  整体PTM分值: {data[\"ptm\"]:.3f}')
        if 'iptm' in data:
            print(f'  界面PTM分值: {data[\"iptm\"]:.3f}')
        if 'plddt' in data:
            plddt = data['plddt']
            if isinstance(plddt, list):
                avg_plddt = np.mean(plddt)
                high_conf = sum(1 for x in plddt if x > 90) / len(plddt) * 100
                print(f'  平均pLDDT: {avg_plddt:.1f}')
                print(f'  高置信度区域: {high_conf:.1f}%')
        
        # 接触界面分析
        if 'interface_ptm' in data:
            print(f'  接触界面PTM: {data[\"interface_ptm\"]:.3f}')
"
    fi
    
    # 生成后处理建议
    echo "后处理建议:"
    echo "1. 使用ChimeraX或PyMOL可视化结构"
    echo "2. 检查关键残基的置信度分数"
    echo "3. 分析分子间接触界面"
    echo "4. 对比不同样本的预测结果"
    
else
    echo "❌ AlphaFold 3复合物预测失败"
    echo "请检查以下内容:"
    echo "1. 输入JSON格式是否正确"
    echo "2. 序列长度是否过长"
    echo "3. 内存资源是否充足"
    echo "4. 错误日志: af3_complex_${SLURM_JOB_ID}.err"
fi

# 清理临时文件（可选）
# echo "清理临时文件..."
# find "$OUTPUT_DIR" -name "*.tmp" -delete 2>/dev/null

echo "============================================"
echo "作业完成时间: $(date)"
echo "总运行时间: $((runtime / 3600))h $((runtime % 3600 / 60))m $((runtime % 60))s"
echo "峰值内存使用: $(sstat -j $SLURM_JOB_ID --format=MaxRSS --noheader 2>/dev/null || echo '未知')"
echo "============================================"

exit $PREDICT_EXIT_CODE