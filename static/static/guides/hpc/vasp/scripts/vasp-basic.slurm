#!/bin/bash
#SBATCH --job-name=vasp_calculation      # 任务名称
#SBATCH --nodes=1                        # 节点数量
#SBATCH --ntasks-per-node=16             # 每节点MPI进程数
#SBATCH --cpus-per-task=1                # 每任务CPU核数
#SBATCH --time=02:00:00                  # 运行时间限制 (HH:MM:SS)
#SBATCH --partition=qcpu_q18i            # 计算分区
#SBATCH --mem=32GB                       # 内存需求
#SBATCH --output=vasp_%j.out             # 标准输出文件
#SBATCH --error=vasp_%j.err              # 错误输出文件

# 环境设置
module purge                             # 清理环境
module load vasp/6.3.0/oneapi-cpu       # 加载VASP模块
module load mpi/openmpi-4.1.6            # 加载MPI库

# 设置运行环境
export OMP_NUM_THREADS=1                 # OpenMP线程数
export I_MPI_PIN_DOMAIN=omp              # Intel MPI绑定设置
export I_MPI_PIN=on                      # 启用CPU绑定

# 计算总进程数
NP=$(( $SLURM_NNODES * $SLURM_NTASKS_PER_NODE ))

# 打印作业信息
echo "===== VASP作业信息 ====="
echo "作业ID: $SLURM_JOB_ID"
echo "节点数: $SLURM_NNODES"  
echo "总进程数: $NP"
echo "工作目录: $PWD"
echo "开始时间: $(date)"
echo "======================"

# 检查必需文件
required_files=("INCAR" "POSCAR" "POTCAR" "KPOINTS")
missing_files=()

for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        missing_files+=("$file")
    fi
done

if [[ ${#missing_files[@]} -gt 0 ]]; then
    echo "错误: 缺少必需文件: ${missing_files[*]}"
    exit 1
fi

# 运行VASP计算
echo "开始VASP计算..."
mpirun -np $NP vasp_std

# 检查计算状态
if [[ $? -eq 0 ]]; then
    echo "VASP计算成功完成"
else
    echo "VASP计算失败，退出码: $?"
fi

echo "结束时间: $(date)"