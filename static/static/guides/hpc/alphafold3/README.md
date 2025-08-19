# AlphaFold 3 批量结构预测资源文件说明

本目录包含AlphaFold 3批量蛋白质结构预测工具的相关资源文件。

## 目录结构

```
alphafold3/
├── README.md                       # 本说明文件
├── scripts/                        # SLURM作业脚本
│   ├── af3-single.slurm            # 单体蛋白预测脚本
│   ├── af3-complex.slurm           # 复合物预测脚本
│   ├── af3-batch.slurm             # 批量处理脚本
│   └── af3-monitor.sh              # 作业监控脚本
├── examples/                       # 示例输入文件
│   ├── single_protein.json         # 单体蛋白JSON示例
│   ├── protein_complex.json        # 蛋白复合物JSON示例
│   └── batch_input_dir/            # 批量输入目录示例
├── configs/                        # 配置文件
│   ├── af3_config.yaml             # AlphaFold3配置示例
│   └── database_config.yaml        # 数据库配置
├── images/                         # 图片资源
│   ├── weight_application/         # 权重申请流程图片
│   ├── chess_platform/             # CHESS平台操作图片
│   └── result_analysis/            # 结果分析图片
└── attachments/                    # 附件文档
    ├── af3_demo.gif                # 演示动画
    └── templates/                  # 模板文件
```

## AlphaFold 3 简介

AlphaFold 3是Google DeepMind开发的最新一代蛋白质结构预测工具，在AlphaFold2的基础上实现了重大突破：

### 核心优势
- **更高精度** - 在蛋白质、DNA、RNA、配体等分子预测上达到前所未有的精度
- **多元预测** - 支持蛋白质-DNA、蛋白质-RNA、蛋白质-配体的复合物预测
- **批量处理** - 原生支持大规模批量结构预测
- **更强泛化** - 在各种分子类型上展现出色的预测能力

### 技术突破
- 基于扩散模型的结构生成
- 支持多种分子类型的联合预测
- 改进的置信度评估体系
- 更高效的序列处理能力

## 容器信息

### 集群部署配置
```bash
容器路径: /hpcfs/fpublic/container/singularity/app/af3/af3.sif
模型权重: 用户需要自行申请（/hpcfs/fhome/用户名/models_weight/）
参考数据库: /hpcfs/fpublic/database/alphafold/af3/data/
CUDA版本: 12.2+
AlphaFold3版本: 最新版本
```

### 环境要求
- Singularity 3.6+
- CUDA 12.2+
- GPU: A40/A800 或更高
- 内存: 64GB+ (复合物需要128GB+)
- 存储: 100GB+

## 权重申请流程

### 1. 官方申请
AlphaFold3模型权重需要通过官方渠道申请：

1. 访问 [AlphaFold3官方GitHub](https://github.com/google-deepmind/alphafold3)
2. 填写权重申请表
3. 等待审批通过（通常1-3个工作日）
4. 下载模型权重文件
5. 上传至集群指定目录

### 2. 权重部署
```bash
# 权重目录结构示例
/hpcfs/fhome/用户名/models_weight/
├── alphafold3_model
├── params/
└── LICENSE
```

## 输入数据格式

### JSON输入格式
AlphaFold3使用JSON格式定义预测目标：

#### 单体蛋白示例
```json
{
  "name": "2PV7",
  "sequences": [
    {
      "protein": {
        "id": ["A"],
        "sequence": "GMRESYANENQFGFKTINSDIHKIVIVGGYGKLGGLFARYLRASGYPISILDREDWAVAESILANADVVIVSVPINLTLETIERLKPYLTENMLLADLTSVKREPLAKMLEVHTGAVLGLHPMFGADIASMAKQVVVRCDGRFPERYEWLLEQIQIWGAKIYQTNATEHDHNMTYIQALRHFSTFANGLHLSKQPINLANLLALSSPIYRLELAMIGRLFAQDAELYADIIMDKSENLAVIETLKQTYDEALTFFENNDRQGFIDAFHKVRDWFGDYSEQFLKESRQLLQQANDLKQG"
      }
    }
  ],
  "modelSeeds": [1],
  "dialect": "alphafold3",
  "version": 1
}
```

#### 蛋白复合物示例
```json
{
  "name": "protein_complex",
  "sequences": [
    {
      "protein": {
        "id": ["A", "B"],
        "sequence": "SEQUENCE_A"
      }
    },
    {
      "protein": {
        "id": ["C"],
        "sequence": "SEQUENCE_B"
      }
    }
  ],
  "modelSeeds": [1, 2, 3],
  "dialect": "alphafold3",
  "version": 1
}
```

## 基础使用流程

### 1. 准备输入文件
```bash
# 创建输入目录
mkdir -p input output

# 准备JSON输入文件
cat > input/fold_input.json << 'EOF'
{输入JSON内容}
EOF
```

### 2. 提交预测作业
```bash
# 复制脚本模板
cp /static/guides/hpc/alphafold3/scripts/af3-single.slurm ./

# 修改脚本参数
vim af3-single.slurm

# 提交作业
sbatch af3-single.slurm
```

### 3. 监控作业进度
```bash
# 检查作业状态
squeue -u $USER

# 查看作业日志
tail -f af3_batch_*.out

# 使用监控脚本
bash /static/guides/hpc/alphafold3/scripts/af3-monitor.sh JOB_ID
```

## 输出结果说明

### 文件结构
```bash
output/hello_fold/
├── seed-1234_sample-0/
│   ├── hello_fold_seed-1234_sample-0_confidences.json
│   ├── hello_fold_seed-1234_sample-0_model.cif
│   └── hello_fold_seed-1234_sample-0_summary_confidences.json
├── TERMS_OF_USE.md
├── hello_fold_confidences.json
├── hello_fold_data.json
├── hello_fold_model.cif
├── hello_fold_ranking_scores.csv
└── hello_fold_summary_confidences.json
```

### 重要文件说明
- **`*_model.cif`** - 主要结构文件（PDB格式）
- **`*_confidences.json`** - 详细置信度数据  
- **`*_ranking_scores.csv`** - 模型排序评分
- **`*_summary_confidences.json`** - 置信度摘要

## 资源配置指南

### 计算资源建议

| 预测类型 | GPU | 内存 | CPU核数 | 时间 | 分区 |
|----------|-----|------|---------|------|------|
| 单体蛋白(<500aa) | 1 | 64GB | 16 | 4小时 | qgpu_a40 |
| 大单体(500-2000aa) | 2 | 128GB | 32 | 12小时 | qgpu_a40 |
| 蛋白复合物 | 2 | 128GB | 32 | 24小时 | qgpu_a40 |
| 大复合物(>2000aa) | 4 | 256GB | 64 | 48小时 | qgpu_a800 |

### 批量处理建议
- 根据序列长度自动选择资源配置
- 使用数组作业进行大规模批量处理
- 合理规划存储空间（每个预测约1-5GB）
- 定期清理中间文件节省空间

## CHESS平台使用

### GUI方式（推荐新手）
1. 登录CHESS平台（https://chess.tbhpc.org）
2. 进入应用中心，下载AlphaFold3应用
3. 配置输入参数（权重路径、JSON文件等）
4. 提交作业并监控进度
5. 下载预测结果

### 注意事项
- 权重文件需要用户自行申请和上传
- 支持单个JSON文件或目录批量输入
- 系统会自动分配最优GPU资源
- 提供实时运行日志查看

## 常见问题解决

### 1. 权重相关问题
```bash
# 错误: Model weights not found
# 解决: 检查权重路径和文件结构
ls -la /hpcfs/fhome/用户名/models_weight/
```

### 2. 内存不足
```bash
# 错误: CUDA out of memory  
# 解决: 增加GPU数量或调整batch size
#SBATCH --gres=gpu:2
```

### 3. JSON格式错误
```bash
# 错误: Invalid JSON format
# 解决: 验证JSON语法
python -m json.tool input.json
```

## 性能优化建议

### 1. 输入优化
- 合理组织序列长度
- 避免超长序列（>4000aa）
- 预处理清理异常字符

### 2. 资源优化
- 根据预测复杂度选择GPU类型
- 合理配置内存和存储空间
- 使用并行处理提高效率

### 3. 输出优化
- 及时转移大文件到长期存储
- 压缩不常用的中间文件
- 保留关键结果文件

## 更新记录

- **2025-08-01** - 创建初始资源结构
- 支持AlphaFold3最新版本
- 提供完整的批量处理流程
- 添加CHESS平台集成指南
- 包含详细的故障排除指南

## 参考资源

- **官方GitHub**: https://github.com/google-deepmind/alphafold3
- **论文**: Accurate structure prediction of biomolecular interactions with AlphaFold 3. Nature (2024)
- **容器路径**: `/hpcfs/fpublic/container/singularity/app/af3/`
- **脚本模板**: 位于 `/static/guides/hpc/alphafold3/scripts/` 目录
- **配置示例**: 位于 `/static/guides/hpc/alphafold3/configs/` 目录
- **权重申请**: https://github.com/google-deepmind/alphafold3/blob/main/WEIGHTS.md