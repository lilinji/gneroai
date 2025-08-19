#!/bin/bash
#SBATCH --job-name=pf_monomer
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --gres=gpu:1
#SBATCH --time=04:00:00
#SBATCH --partition=qgpu_3090
#SBATCH --mem=32GB
#SBATCH --output=pf_monomer_%j.out
#SBATCH --error=pf_monomer_%j.err

# ParallelFold 单体蛋白预测脚本
# 适用于: 单个蛋白质序列的高速结构预测

echo "============================================"
echo "ParallelFold 单体蛋白结构预测"
echo "作业ID: $SLURM_JOB_ID"
echo "节点: $SLURMD_NODENAME"
echo "开始时间: $(date)"
echo "============================================"

# 加载模块
module load singularity

# 环境变量设置
export CUDA_VISIBLE_DEVICES=0
export PYTHONUNBUFFERED=1

# ParallelFold性能优化设置
export PF_NUM_WORKERS=8
export PF_BATCH_SIZE=1
export PF_USE_CACHE=true

# 路径配置
CONTAINER="/hpcfs/fpublic/container/singularity/app/parallelfold/parallelfold.sif"
DATABASE_PATH="/hpcfs/fpublic/database/alphafold/data"

# 输入输出路径
INPUT_FASTA="${1:-input.fasta}"
OUTPUT_DIR="${2:-output/$(basename $INPUT_FASTA .fasta)}"

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 验证输入文件
echo "检查输入文件: $INPUT_FASTA"
if [[ ! -f "$INPUT_FASTA" ]]; then
    echo "错误: 输入文件不存在: $INPUT_FASTA"
    exit 1
fi

# 验证FASTA格式
echo "验证FASTA格式..."
if ! grep -q "^>" "$INPUT_FASTA"; then
    echo "错误: 不是有效的FASTA格式"
    exit 1
fi

# 统计序列信息
SEQ_COUNT=$(grep -c "^>" "$INPUT_FASTA")
echo "序列数量: $SEQ_COUNT"

# 分析序列长度
python3 -c "
import sys
with open('$INPUT_FASTA') as f:
    lines = f.readlines()

sequences = []
current_seq = ''
for line in lines:
    if line.startswith('>'):
        if current_seq:
            sequences.append(len(current_seq))
        current_seq = ''
    else:
        current_seq += line.strip()
        
if current_seq:
    sequences.append(len(current_seq))

print(f'序列长度统计:')
for i, length in enumerate(sequences, 1):
    print(f'  序列{i}: {length} aa')
    if length > 2000:
        print(f'  警告: 序列{i}较长，预测时间可能增加')

total_length = sum(sequences)
print(f'总长度: {total_length} aa')
estimated_time = max(10, total_length / 50)  # 经验公式
print(f'预计运行时间: {estimated_time:.0f} 分钟')
"

# 显示系统信息
echo "GPU信息:"
nvidia-smi --query-gpu=index,name,memory.total,memory.used --format=csv,noheader,nounits

echo "内存信息:"
free -h

# 运行ParallelFold预测
echo "开始ParallelFold单体预测..."
start_time=$(date +%s)

singularity run --nv \
    -B "$DATABASE_PATH:/database" \
    -B "$(pwd):/workspace" \
    "$CONTAINER" \
    --input "/workspace/$INPUT_FASTA" \
    --output "/workspace/$OUTPUT_DIR" \
    --mode monomer \
    --num_workers "$PF_NUM_WORKERS" \
    --batch_size "$PF_BATCH_SIZE" \
    --database_dir "/database"

# 检查执行结果
PREDICT_EXIT_CODE=$?
end_time=$(date +%s)
runtime=$((end_time - start_time))

echo "预测完成，退出码: $PREDICT_EXIT_CODE"
echo "实际运行时间: $((runtime / 60))分 $((runtime % 60))秒"

if [[ $PREDICT_EXIT_CODE -eq 0 ]]; then
    echo "✅ ParallelFold预测成功完成"
    
    # 显示输出结果
    echo "输出文件结构:"
    find "$OUTPUT_DIR" -name "*.pdb" -o -name "*.json" -o -name "*.txt" | head -10
    
    # 计算输出大小
    OUTPUT_SIZE=$(du -sh "$OUTPUT_DIR" | cut -f1)
    echo "输出目录大小: $OUTPUT_SIZE"
    
    # 生成结果摘要
    echo "正在生成结果摘要..."
    if [[ -f "$OUTPUT_DIR"/predictions/*/confidence.json ]]; then
        echo "置信度统计:"
        for conf_file in "$OUTPUT_DIR"/predictions/*/confidence.json; do
            if [[ -f "$conf_file" ]]; then
                echo "文件: $(dirname $conf_file)"
                python3 -c "
import json
try:
    with open('$conf_file') as f:
        data = json.load(f)
    if 'plddt' in data:
        scores = data['plddt']
        if isinstance(scores, list):
            avg_score = sum(scores) / len(scores)
            print(f'  平均pLDDT: {avg_score:.1f}')
            high_conf = sum(1 for s in scores if s > 90) / len(scores) * 100
            print(f'  高置信度区域: {high_conf:.1f}%')
except Exception as e:
    print(f'  无法解析置信度文件: {e}')
"
            fi
        done
    fi
    
    # 生成处理建议
    echo "后处理建议:"
    echo "1. 使用PyMOL或ChimeraX查看结构文件"
    echo "2. 检查置信度分数评估预测质量"
    echo "3. 对比多个预测结果验证一致性"
    
else
    echo "❌ ParallelFold预测失败"
    echo "请检查以下内容:"
    echo "1. FASTA文件格式是否正确"
    echo "2. 序列是否包含非标准氨基酸"
    echo "3. 计算资源是否充足"
    echo "4. 错误日志: pf_monomer_${SLURM_JOB_ID}.err"
    
    # 简单诊断
    echo "基础诊断:"
    echo "- 输入文件大小: $(du -h $INPUT_FASTA | cut -f1)"
    echo "- 可用GPU: $(nvidia-smi --list-gpus | wc -l)"
    echo "- 可用内存: $(free -h | grep Mem | awk '{print $7}')"
fi

echo "============================================"
echo "作业完成时间: $(date)"
echo "总运行时间: $((runtime / 60))分 $((runtime % 60))秒"
echo "============================================"

exit $PREDICT_EXIT_CODE