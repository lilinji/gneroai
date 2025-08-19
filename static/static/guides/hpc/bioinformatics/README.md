# 生物信息学工具资源说明

本目录包含HPC集群上生物信息学工具容器的相关资源文件。

## 目录结构

```
bioinformatics/
├── README.md              # 本说明文件
├── scripts/               # SLURM作业脚本模板
│   ├── singularity-basic.slurm    # 基础CPU作业模板
│   └── singularity-gpu.slurm      # GPU加速作业模板
├── configs/               # 配置文件
│   └── tool_config.yaml          # 通用工具配置
├── examples/              # 示例文件
│   └── sample_input.fasta         # 示例输入序列
├── images/                # 图片资源（预留）
└── attachments/           # 附件文档（预留）
```

## 工具分类

### 1. 蛋白质功能预测工具
- **DeepEC** - 深度学习酶功能预测
- **ECRECer** - 酶反应预测  
- **Clean** - 蛋白质序列清洗
- **CATFam** - 蛋白质家族分类
- **PRIAM** - 酶功能分类
- **ECPred** - EC编号预测
- **DeepGO2** - 基因本体功能预测
- **ECPN-HFGF** - 酶催化预测网络

### 2. 结构预测与分析工具
- **AlphaFold3** - 最新蛋白质结构预测
- **ESMFold** - 快速结构预测
- **ProteinMPNN** - 蛋白质序列设计
- **ESM-IF1** - 逆向蛋白质折叠
- **DeepFRI** - 功能-结构关系预测
- **DHR** - 同源结构检索

### 3. 序列与进化分析
- **ESM-1v** - 变异效应预测
- **MPEPE** - 蛋白质表达预测

### 4. 大语言模型与AI工具
- **Vector** - 生物信息学专用大语言模型

## 使用说明

### 1. 基础使用流程

1. **准备输入文件**
   ```bash
   mkdir -p input output temp
   cp your_sequences.fasta input/
   ```

2. **选择合适的脚本模板**
   ```bash
   # CPU工具
   cp /static/guides/hpc/bioinformatics/scripts/singularity-basic.slurm ./
   
   # GPU工具
   cp /static/guides/hpc/bioinformatics/scripts/singularity-gpu.slurm ./
   ```

3. **修改脚本参数**
   - 更新工具名称和容器路径
   - 调整计算资源需求
   - 设置正确的输入输出路径

4. **提交作业**
   ```bash
   sbatch your_tool.slurm
   ```

### 2. 资源配置指南

根据工具类型选择合适的计算资源：

| 工具类型 | CPU核数 | 内存 | GPU | 推荐时间 |
|----------|---------|------|-----|----------|
| 序列清洗 | 4-8 | 16GB | 否 | 1-2小时 |
| 深度学习预测 | 8-16 | 32-64GB | 推荐 | 4-8小时 |
| 结构预测 | 16-32 | 64-128GB | 必需 | 8-24小时 |

### 3. 容器路径说明

所有容器文件位于：`/hpcfs/fpublic/container/singularity/app/`

常用容器路径：
```bash
# 功能预测工具
/hpcfs/fpublic/container/singularity/app/deepec/deepec.sif
/hpcfs/fpublic/container/singularity/app/ecrecer/ecrecer.sif
/hpcfs/fpublic/container/singularity/app/clean/clean.sif

# 结构预测工具  
/hpcfs/fpublic/container/singularity/app/esmfold/esmfold.sif
/hpcfs/fpublic/container/singularity/app/alphafold3/
sandbox_af3  # AlphaFold3 沙箱
pmpnn_latest.sif  # ProteinMPNN
```

## 最佳实践

### 1. 文件组织建议

```bash
project_name/
├── 01-raw_data/          # 原始数据
├── 02-preprocessing/     # 预处理
├── 03-analysis/         # 主要分析
│   ├── deepec/         # 按工具分类
│   ├── alphafold/
│   └── esmfold/
├── 04-results/          # 最终结果
├── scripts/            # 作业脚本
└── logs/              # 运行日志
```

### 2. 批量处理策略

对于大量序列，建议：
1. 将输入文件分割成小块
2. 使用数组作业并行处理
3. 合并最终结果

### 3. 错误排除

常见问题：
- **容器权限错误** - 使用 `--bind` 挂载目录
- **GPU不可用** - 检查分区和CUDA环境
- **内存不足** - 增加内存申请或优化批大小
- **文件路径错误** - 确保绝对路径正确

## 更新记录

- **2025-08-01** - 创建初始资源结构
- 支持17个主要生信工具
- 提供CPU和GPU作业模板
- 添加配置文件示例