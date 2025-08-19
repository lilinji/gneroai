# ParallelFold 高性能蛋白质结构预测资源文件说明

本目录包含ParallelFold高性能并行蛋白质结构预测工具的相关资源文件。

## 目录结构

```
parallelfold/
├── README.md                       # 本说明文件
├── scripts/                        # SLURM作业脚本
│   ├── pf-monomer.slurm            # 单体蛋白预测脚本
│   ├── pf-multimer.slurm           # 复合物预测脚本
│   ├── pf-batch.slurm              # 批量处理脚本
│   └── pf-monitor.sh               # 作业监控脚本
├── examples/                       # 示例输入文件
│   ├── monomer_example.fasta       # 单体蛋白FASTA示例
│   ├── multimer_example.fasta      # 复合物FASTA示例
│   └── batch_input/                # 批量输入目录示例
├── configs/                        # 配置文件
│   ├── parallelfold_config.yaml    # ParallelFold配置示例
│   └── resource_config.yaml        # 资源配置文件
├── images/                         # 图片资源
│   ├── chess_platform/             # CHESS平台操作图片
│   ├── interface_screenshots/      # 界面截图
│   └── workflow_demo/              # 工作流程演示
└── attachments/                    # 附件文档
    ├── parallelfold_demo.gif       # 演示动画
    └── documentation/              # 相关文档
```

## ParallelFold 简介

ParallelFold是由上海交通大学开发的高性能并行蛋白质结构预测平台，基于AlphaFold架构进行了重要优化：

### 核心优势
- **极速预测** - 将原本数小时至数天的计算压缩至分钟级
- **并行流水线** - 支持大规模并行计算，显著提升吞吐量
- **智能调度** - 自动评估序列复杂度并动态分配最优GPU/CPU资源
- **显存优化** - 采用先进的显存管理策略，降低硬件要求

### 技术特点
- 集成AlphaFold单体与多体模型
- 支持monomer和multimer两种预测模式
- 自动资源调度和任务管理
- 完整的FASTA序列处理流水线

## 容器信息

### 集群部署配置
```bash
容器路径: /hpcfs/fpublic/container/singularity/app/parallelfold/parallelfold.sif
AlphaFold模型: 内置AlphaFold2单体和多体模型
参考数据库: /hpcfs/fpublic/database/alphafold/data/
CUDA版本: 11.8+
ParallelFold版本: 最新稳定版本
```

### 环境要求
- Singularity 3.6+
- CUDA 11.8+
- GPU: RTX 3090 或更高（推荐）
- 内存: 32GB+ (复合物需要64GB+)
- 存储: 50GB+ (数据库空间)

## 预测模式说明

### 1. Monomer模式（单体预测）
适用于单个蛋白质序列的结构预测：
- 自动拆分FASTA文件中的每条序列
- 并行处理多个单体蛋白
- 生成独立的预测结果
- 支持批量单体预测

### 2. Multimer模式（复合物预测）
适用于蛋白质复合物结构预测：
- 将所有序列作为整体处理
- 预测分子间相互作用
- 生成复合物三维结构
- 支持多链复合物

## 基础使用流程

### CHESS平台使用（推荐）
1. **登录平台**
   - 访问CHESS平台 (https://chess.tbhpc.org)
   - 进入应用中心

2. **下载应用**
   - 搜索ParallelFold应用
   - 点击下载到桌面

3. **提交任务**
   - 打开ParallelFold应用
   - 选择预测类型（monomer/multimer）
   - 上传FASTA文件
   - 配置资源参数

4. **监控作业**
   - 查看作业列表
   - 监控运行状态
   - 获取预测结果

### 命令行使用
```bash
# 基础命令格式
singularity run --nv \
    -B /input/path:/data \
    -B /output/path:/results \
    parallelfold.sif \
    --input /data/input.fasta \
    --output /results \
    --mode [monomer|multimer]
```

## 输入格式要求

### FASTA文件格式
```fasta
# 单体蛋白示例
>protein1
MKLLNVINFVFLMFVSSCMENSTFVSCVLYIACTPKVQLWVDSTPPPGTRVRAMAIYK...

# 复合物示例  
>chainA
MKLLNVINFVFLMFVSSCMENSTFVSCVLYIACTPKVQLWVDSTPPPGTRVRAMAIYK...
>chainB
MKTVRQERLKSIVRILERSKEPVSGAQLAEELSVSRQVIVQDIAYLRSLGYNIVATPR...
```

### 序列要求
- 标准FASTA格式
- 支持标准20种氨基酸
- 序列长度建议: 50-2000个氨基酸
- 复合物总长度建议: < 3000个氨基酸

## 输出结果说明

### 文件结构
```bash
output/
├── fasta_id_map.txt               # 序列ID映射表
├── individual_sequences/          # 单体序列文件
│   ├── seq_0001.fasta
│   └── seq_0002.fasta
├── predictions/                   # 预测结果
│   ├── seq_0001/
│   │   ├── ranked_0.pdb          # 最佳预测结构
│   │   ├── confidence.json       # 置信度数据
│   │   └── timings.json          # 运行时间统计
│   └── seq_0002/
└── logs/                         # 运行日志
    ├── prediction.log
    └── error.log
```

### 重要文件说明
- **ranked_0.pdb** - 最高置信度的预测结构
- **confidence.json** - 详细置信度评估数据
- **fasta_id_map.txt** - 原始序列与处理文件的映射关系
- **timings.json** - 各阶段计算时间统计

## 性能优化建议

### 1. 资源配置
| 预测类型 | GPU | 内存 | CPU核数 | 预计时间 |
|----------|-----|------|---------|----------|
| 单体蛋白(<300aa) | 1 | 32GB | 16 | 10-30分钟 |
| 单体蛋白(300-1000aa) | 1 | 32GB | 16 | 30-60分钟 |
| 复合物(<500aa总长) | 1 | 64GB | 32 | 1-2小时 |
| 大复合物(>500aa) | 2 | 64GB | 32 | 2-4小时 |

### 2. 批量处理策略
```bash
# 根据序列长度自动选择资源
for fasta in *.fasta; do
    length=$(grep -v "^>" "$fasta" | tr -d '\n' | wc -c)
    if [[ $length -lt 300 ]]; then
        # 小序列使用基础配置
        sbatch --mem=32GB --gres=gpu:1 pf-monomer.slurm "$fasta"
    else
        # 大序列使用增强配置
        sbatch --mem=64GB --gres=gpu:2 pf-multimer.slurm "$fasta"
    fi
done
```

## 常见问题解决

### 1. FASTA格式错误
```bash
# 检查格式
grep -v "^>" input.fasta | grep -E "[^ACDEFGHIKLMNPQRSTVWY]"

# 清理非标准字符
sed '/^>/!s/[^ACDEFGHIKLMNPQRSTVWY]//g' input.fasta > cleaned.fasta
```

### 2. GPU内存不足
```bash
# 调整批次大小
export PF_BATCH_SIZE=1

# 使用模型并行
export PF_MODEL_PARALLEL=true
```

### 3. 网络连接问题
```bash
# 使用本地缓存
export PF_USE_LOCAL_CACHE=true

# 设置超时时间
export PF_TIMEOUT=3600
```

## 开发信息

### 项目来源
- **开发单位**: 上海交通大学 (Shanghai Jiao Tong University)
- **GitHub**: https://github.com/Zuricho/ParallelFold
- **论文**: ParallelFold: Accelerating AlphaFold by Parallelizing Multiple Sequence Alignment
- **许可**: 学术使用许可

### 技术支持
- **官方文档**: [项目README](https://github.com/Zuricho/ParallelFold/blob/main/README.md)
- **问题反馈**: [GitHub Issues](https://github.com/Zuricho/ParallelFold/issues)
- **集群支持**: hpc-support@your-institution.edu

## 更新记录

- **2025-08-01** - 创建初始资源结构
- 支持ParallelFold最新版本
- 提供完整的CHESS平台集成
- 添加批量处理和监控脚本
- 包含详细的使用指南和故障排除

## 使用示例

### 快速开始
```bash
# 1. 准备输入文件
echo ">test_protein
MKLLNVINFVFLMFVSSCMENSTFVSCVLYIACTPKVQL" > test.fasta

# 2. 提交预测
sbatch pf-monomer.slurm test.fasta

# 3. 查看结果
ls output/predictions/*/ranked_0.pdb
```

### 批量处理
```bash
# 处理目录中所有FASTA文件
sbatch --array=1-N pf-batch.slurm input_dir/ output_dir/
```

## 注意事项

1. **数据安全**: 确保输入序列不包含敏感信息
2. **资源使用**: 合理估算计算资源，避免资源浪费
3. **结果验证**: 检查置信度分数，评估预测质量
4. **版本兼容**: 确保使用兼容的AlphaFold数据库版本