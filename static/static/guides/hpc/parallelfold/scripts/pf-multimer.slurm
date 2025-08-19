#!/bin/bash
#SBATCH --job-name=pf_multimer
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=32
#SBATCH --gres=gpu:2
#SBATCH --time=12:00:00
#SBATCH --partition=qgpu_3090
#SBATCH --mem=64GB
#SBATCH --output=pf_multimer_%j.out
#SBATCH --error=pf_multimer_%j.err

# ParallelFold 多体蛋白复合物预测脚本
# 适用于: 蛋白质复合物和多链结构预测

echo "============================================"
echo "ParallelFold 多体蛋白复合物预测"
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

# ParallelFold多体预测优化设置
export PF_NUM_WORKERS=16
export PF_BATCH_SIZE=1
export PF_MODEL_PARALLEL=true
export PF_USE_CACHE=true
export PF_COMPLEX_MODE=true

# 内存优化设置
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
export MKL_NUM_THREADS=$SLURM_CPUS_PER_TASK

# 路径配置
CONTAINER="/hpcfs/fpublic/container/singularity/app/parallelfold/parallelfold.sif"
DATABASE_PATH="/hpcfs/fpublic/database/alphafold/data"

# 输入输出路径
INPUT_FASTA="${1:-complex.fasta}"
OUTPUT_DIR="${2:-output/$(basename $INPUT_FASTA .fasta)_multimer}"

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 验证输入文件
echo "检查输入文件: $INPUT_FASTA"
if [[ ! -f "$INPUT_FASTA" ]]; then
    echo "错误: 输入文件不存在: $INPUT_FASTA"
    exit 1
fi

# 分析复合物复杂度
echo "分析复合物复杂度..."
python3 -c "
import sys
with open('$INPUT_FASTA') as f:
    lines = f.readlines()

sequences = []
current_seq = ''
chain_ids = []

for line in lines:
    if line.startswith('>'):
        if current_seq:
            sequences.append(current_seq)
        chain_ids.append(line.strip()[1:])
        current_seq = ''
    else:
        current_seq += line.strip()
        
if current_seq:
    sequences.append(current_seq)

chain_count = len(sequences)
lengths = [len(seq) for seq in sequences]
total_length = sum(lengths)

print(f'复合物分析结果:')
print(f'  链数量: {chain_count}')
print(f'  各链长度: {lengths}')
print(f'  总长度: {total_length} aa')

if chain_count > 5:
    print('  警告: 链数量较多，计算复杂度高')
if total_length > 2000:
    print('  警告: 总长度较大，建议增加计算资源')
if max(lengths) > 1000:
    print('  警告: 存在长链，可能需要更多时间')

# 预估计算时间
complexity_factor = chain_count * (total_length / 500) ** 1.5
estimated_hours = max(1, complexity_factor / 10)
print(f'  预计运行时间: {estimated_hours:.1f} 小时')
"

# 验证FASTA格式
echo "验证FASTA格式..."
if ! grep -q "^>" "$INPUT_FASTA"; then
    echo "错误: 不是有效的FASTA格式"
    exit 1
fi

# 检查序列质量
echo "序列质量检查..."
invalid_chars=$(grep -v "^>" "$INPUT_FASTA" | grep -o "[^ACDEFGHIKLMNPQRSTVWY]" | sort -u | tr '\n' ' ')
if [[ -n "$invalid_chars" ]]; then
    echo "警告: 发现非标准氨基酸字符: $invalid_chars"
    echo "建议清理序列后再进行预测"
fi

# 显示系统资源信息
echo "系统资源信息:"
nvidia-smi --query-gpu=index,name,memory.total,memory.free,utilization.gpu --format=csv,noheader,nounits
echo "CPU信息: $SLURM_CPUS_PER_TASK 核心"
echo "内存信息: $(free -h | grep Mem)"
echo "可用存储: $(df -h . | tail -1 | awk '{print $4}')"

# 开始复合物预测
echo "============================================"
echo "开始ParallelFold复合物预测"
echo "输入文件: $INPUT_FASTA"
echo "输出目录: $OUTPUT_DIR"
echo "预测模式: multimer"
echo "============================================"

start_time=$(date +%s)

singularity run --nv \
    -B "$DATABASE_PATH:/database" \
    -B "$(pwd):/workspace" \
    "$CONTAINER" \
    --input "/workspace/$INPUT_FASTA" \
    --output "/workspace/$OUTPUT_DIR" \
    --mode multimer \
    --num_workers "$PF_NUM_WORKERS" \
    --batch_size "$PF_BATCH_SIZE" \
    --database_dir "/database" \
    --use_model_parallel \
    --max_recycles 5 \
    --tolerance 0.0

# 检查执行结果
PREDICT_EXIT_CODE=$?
end_time=$(date +%s)
runtime=$((end_time - start_time))

echo "============================================"
echo "复合物预测完成"
echo "退出码: $PREDICT_EXIT_CODE"
echo "实际运行时间: $((runtime / 3600))h $((runtime % 3600 / 60))m $((runtime % 60))s"

if [[ $PREDICT_EXIT_CODE -eq 0 ]]; then
    echo "✅ ParallelFold复合物预测成功完成"
    
    # 显示输出结果结构
    echo "输出文件结构:"
    find "$OUTPUT_DIR" -name "*.pdb" -o -name "*.json" -o -name "*.txt" | head -15
    
    # 统计结果文件
    PDB_COUNT=$(find "$OUTPUT_DIR" -name "*.pdb" | wc -l)
    JSON_COUNT=$(find "$OUTPUT_DIR" -name "*.json" | wc -l)
    OUTPUT_SIZE=$(du -sh "$OUTPUT_DIR" | cut -f1)
    
    echo "结果统计:"
    echo "  PDB文件: $PDB_COUNT 个"
    echo "  JSON文件: $JSON_COUNT 个"
    echo "  总大小: $OUTPUT_SIZE"
    
    # 分析最佳预测结果
    echo "正在分析预测质量..."
    BEST_PDB=$(find "$OUTPUT_DIR" -name "ranked_0.pdb" | head -1)
    if [[ -f "$BEST_PDB" ]]; then
        echo "最佳预测结构: $BEST_PDB"
        
        # 统计原子数量
        ATOM_COUNT=$(grep "^ATOM" "$BEST_PDB" | wc -l)
        echo "  原子数量: $ATOM_COUNT"
        
        # 提取链信息
        CHAINS=$(grep "^ATOM" "$BEST_PDB" | awk '{print $5}' | sort -u | tr '\n' ' ')
        echo "  预测链: $CHAINS"
    fi
    
    # 检查置信度数据
    CONFIDENCE_FILE=$(find "$OUTPUT_DIR" -name "confidence.json" | head -1)
    if [[ -f "$CONFIDENCE_FILE" ]]; then
        echo "置信度分析:"
        python3 -c "
import json
try:
    with open('$CONFIDENCE_FILE') as f:
        data = json.load(f)
    
    if 'plddt' in data:
        scores = data['plddt']
        if isinstance(scores, list):
            avg_plddt = sum(scores) / len(scores)
            print(f'  平均pLDDT: {avg_plddt:.1f}')
            
            # 分置信度区间统计
            high = sum(1 for s in scores if s > 90)
            medium = sum(1 for s in scores if 70 <= s <= 90) 
            low = sum(1 for s in scores if s < 70)
            total = len(scores)
            
            print(f'  高置信度(>90): {high/total*100:.1f}%')
            print(f'  中等置信度(70-90): {medium/total*100:.1f}%') 
            print(f'  低置信度(<70): {low/total*100:.1f}%')
    
    if 'ptm' in data:
        print(f'  PTM分数: {data[\"ptm\"]:.3f}')
    
    if 'iptm' in data:
        print(f'  iPTM分数: {data[\"iptm\"]:.3f}')
        
except Exception as e:
    print(f'  无法解析置信度文件: {e}')
"
    fi
    
    # 检查运行时间统计
    TIMING_FILE=$(find "$OUTPUT_DIR" -name "timings.json" | head -1)
    if [[ -f "$TIMING_FILE" ]]; then
        echo "性能统计:"
        python3 -c "
import json
try:
    with open('$TIMING_FILE') as f:
        data = json.load(f)
    for stage, time_val in data.items():
        if isinstance(time_val, (int, float)):
            print(f'  {stage}: {time_val:.1f}s')
except Exception as e:
    print(f'  无法解析时间统计: {e}')
"
    fi
    
    # 提供后处理建议
    echo "后处理建议:"
    echo "1. 使用PyMOL查看复合物结构和界面"
    echo "2. 分析分子间接触和相互作用"
    echo "3. 检验预测结构的生物学合理性"
    echo "4. 对比实验结构数据（如有）"
    
else
    echo "❌ ParallelFold复合物预测失败"
    echo "可能的失败原因:"
    echo "1. 复合物过于复杂，超出计算能力"
    echo "2. 内存或GPU资源不足"
    echo "3. 序列格式或质量问题"
    echo "4. 数据库访问问题"
    
    echo "建议解决方案:"
    echo "1. 减少链数量或序列长度"
    echo "2. 增加内存和GPU资源"
    echo "3. 清理和验证输入序列"
    echo "4. 检查数据库路径和权限"
    
    # 诊断信息
    echo "诊断信息:"
    echo "- 峰值内存使用: $(cat /proc/$$/status | grep VmPeak || echo '未知')"
    echo "- GPU内存状态:"
    nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits
fi

echo "============================================"
echo "作业完成时间: $(date)"
echo "总计算时间: $((runtime / 3600))h $((runtime % 3600 / 60))m $((runtime % 60))s"
echo "平均GPU利用率: $(sstat -j $SLURM_JOB_ID --format=AveCPU --noheader 2>/dev/null || echo '未知')"
echo "============================================"

exit $PREDICT_EXIT_CODE