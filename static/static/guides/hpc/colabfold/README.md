# ColabFold 资源文件说明

本目录包含ColabFold快速蛋白质结构预测工具的相关资源文件。

## 目录结构

```
colabfold/
├── README.md                      # 本说明文件
├── scripts/                       # SLURM作业脚本
│   ├── colabfold-basic.slurm     # 基础单体预测脚本
│   └── colabfold-multimer.slurm  # 复合物预测脚本
├── examples/                      # 示例输入文件
│   ├── single_protein.fasta      # 单体蛋白示例
│   └── protein_complex.fasta     # 蛋白复合物示例
├── configs/                       # 配置文件
│   └── colabfold_config.yaml     # ColabFold配置示例
├── images/                        # 图片资源（预留）
└── attachments/                   # 附件文档（预留）
```

## ColabFold 简介

ColabFold是基于AlphaFold2的快速蛋白质结构预测工具，主要优势：

### 核心特性
- **超快速度** - 比AlphaFold2快10-100倍
- **高精度** - 保持与AlphaFold2相当的预测精度
- **复合物支持** - 原生支持蛋白质复合物预测
- **开源免费** - 完全开源，可定制化

### 技术优势
- 使用MMseqs2替代传统MSA搜索
- 支持GPU加速计算
- 集成AMBER力场优化
- 提供详细的置信度评估

## 容器信息

### 集群部署配置
```bash
容器路径: /hpcfs/fpublic/container/singularity/app/colabfold/colabfold_1.5.5-cuda12.2.2.sif
参数路径: /hpcfs/fpublic/container/singularity/app/cobafold/params
CUDA版本: 12.2.2
ColabFold版本: 1.5.5
```

### 环境要求
- Singularity 3.6+
- CUDA 12.2+
- GPU: RTX 3090 或更高
- 内存: 32GB+ (复合物需要64GB+)

## 使用指南

### 1. 基础使用流程

#### 准备输入文件
```bash
# 单体蛋白
cat > protein.fasta << EOF
>MyProtein
MKTVRQERLKSIVRILERSKEPVSGAQLAEELSVSRQVIVQDIAYLR...
EOF

# 蛋白复合物
cat > complex.fasta << EOF
>ChainA
SEQUENCE_A
>ChainB
SEQUENCE_B
EOF
```

#### 选择合适的脚本
```bash
# 单体预测 - 使用基础脚本
cp /static/guides/hpc/colabfold/scripts/colabfold-basic.slurm ./

# 复合物预测 - 使用多体脚本  
cp /static/guides/hpc/colabfold/scripts/colabfold-multimer.slurm ./
```

#### 提交作业
```bash
# 修改脚本中的输入文件路径
vim colabfold-basic.slurm

# 提交作业
sbatch colabfold-basic.slurm
```

### 2. 资源配置建议

| 蛋白类型 | CPU核数 | 内存 | GPU | 时间 | 分区 |
|----------|---------|------|-----|------|------|
| 单体蛋白(<500aa) | 16 | 32GB | 1 | 2小时 | qgpu_3090 |
| 大单体(500-2000aa) | 32 | 64GB | 2 | 8小时 | qgpu_3090 |
| 蛋白复合物 | 32 | 64GB | 2 | 12小时 | qgpu_3090 |
| 大复合物(>2000aa) | 64 | 128GB | 4 | 24小时 | qgpu_3090 |

### 3. 参数优化建议

#### 高质量预测参数
```bash
--num-models 5          # 生成5个模型
--num-recycle 5         # 增加循环优化
--model-type AlphaFold2-ptm  # 使用PTM模型
--amber                 # AMBER力场优化
--templates            # 启用模板检索
```

#### 快速预测参数  
```bash
--num-models 1          # 只生成1个模型
--num-recycle 1         # 减少循环
--model-type auto       # 自动选择模型
```

## 输出结果说明

### 文件类型
- `*_relaxed_*.pdb` - 推荐使用的优化结构
- `*_unrelaxed_*.pdb` - 原始预测结构
- `*_scores_*.json` - 置信度评分数据
- `*_coverage_*.png` - 可视化图片

### 置信度评估
- **pLDDT > 90**: 非常高置信度（深蓝色）
- **pLDDT 70-90**: 高置信度（浅蓝色）
- **pLDDT 50-70**: 中等置信度（黄色）
- **pLDDT < 50**: 低置信度（红色）

## 常见问题解决

### 1. 内存不足
```bash
# 错误: CUDA out of memory
# 解决: 增加GPU数量或减少模型复杂度
#SBATCH --gres=gpu:2
--num-models 1
--num-recycle 1
```

### 2. 序列格式错误
```bash
# 错误: Invalid amino acid character
# 解决: 清理非标准氨基酸
sed 's/[XUO*]//g' input.fasta > cleaned.fasta
```

### 3. 网络连接问题
```bash
# 错误: MMseqs2 search failed
# 解决: 检查网络或使用本地数据库
--db-preset reduced_dbs
```

## 性能优化技巧

### 1. 批量处理
```bash
# 根据序列长度自动选择资源
for fasta in *.fasta; do
    length=$(grep -v "^>" "$fasta" | tr -d '\n' | wc -c)
    if [[ $length -lt 500 ]]; then
        sbatch --mem=32GB --gres=gpu:1 colabfold-basic.slurm "$fasta"
    else
        sbatch --mem=64GB --gres=gpu:2 colabfold-multimer.slurm "$fasta"
    fi
done
```

### 2. GPU内存优化
```bash
# 设置GPU内存限制
export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:256
export CUDA_MEM_LIMIT=20000M
```

## 最佳实践建议

### 1. 预测流程
1. **序列验证** - 检查FASTA格式和序列质量
2. **资源估算** - 根据序列长度选择合适资源
3. **快速测试** - 小规模验证参数设置
4. **正式预测** - 高质量参数运行
5. **结果验证** - 检查置信度和生物学合理性

### 2. 数据管理
```bash
project/
├── input/              # 输入序列
├── predictions/        # 预测结果
│   ├── run1/          # 按运行批次组织
│   └── run2/
├── analysis/          # 结果分析
└── scripts/           # 作业脚本
```

### 3. 质量控制
- pTM score > 0.5（推荐 > 0.8）
- 平均pLDDT > 70
- 关键区域pLDDT > 90
- 与已知结构比较验证

## 更新记录

- **2025-08-01** - 创建初始资源结构
- 支持ColabFold 1.5.5版本
- 提供基础和复合物预测脚本
- 添加配置文件和示例数据

## 参考资源

- **官方GitHub**: https://github.com/sokrypton/ColabFold
- **论文**: Mirdita M, et al. Nature Methods (2022)
- **AlphaFold数据库**: https://alphafold.ebi.ac.uk/