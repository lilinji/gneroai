#!/bin/bash
#SBATCH --job-name=vasp_optimization     # 任务名称  
#SBATCH --nodes=2                        # 使用2个节点
#SBATCH --ntasks-per-node=32             # 每节点32个MPI进程
#SBATCH --cpus-per-task=1                # 每任务1个CPU核
#SBATCH --time=24:00:00                  # 24小时时间限制
#SBATCH --partition=qcpu_q18i            # 计算分区
#SBATCH --mem=64GB                       # 64GB内存
#SBATCH --output=vasp_opt_%j.out         # 输出文件
#SBATCH --error=vasp_opt_%j.err          # 错误文件
#SBATCH --mail-type=END,FAIL             # 邮件通知
#SBATCH --mail-user=your_email@domain.com # 邮件地址

# 加载模块
module purge
module load vasp/6.3.0/oneapi-cpu
module load mpi/openmpi-4.1.6

# 优化设置
export OMP_NUM_THREADS=1
export I_MPI_PIN_DOMAIN=omp
export I_MPI_PIN=on
export I_MPI_FABRICS=shm:ofi             # 网络优化

# 计算资源
NP=$(( $SLURM_NNODES * $SLURM_NTASKS_PER_NODE ))

# 作业信息
echo "===== VASP结构优化作业 ====="
echo "作业ID: $SLURM_JOB_ID"
echo "节点: $SLURM_NNODES, 总进程: $NP"
echo "开始时间: $(date)"
echo "=========================="

# 备份初始文件
cp POSCAR POSCAR.init
cp INCAR INCAR.init

# 运行结构优化
echo "开始结构优化计算..."
mpirun -np $NP vasp_std

# 检查收敛性
if grep -q "reached required accuracy" OUTCAR; then
    echo "结构优化收敛成功"
    cp CONTCAR POSCAR.optimized
else
    echo "警告: 结构优化可能未完全收敛"
fi

echo "计算完成时间: $(date)"