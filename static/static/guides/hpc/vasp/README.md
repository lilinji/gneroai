# VASP 资源文件说明

本目录包含VASP计算相关的示例文件、脚本和文档资源。

## 目录结构

```
vasp/
├── README.md              # 本说明文件
├── examples/              # 示例输入文件
│   ├── INCAR.basic       # 基础INCAR参数示例
│   ├── KPOINTS.example   # K点设置示例
│   └── POSCAR.silicon    # 硅晶体结构示例
├── scripts/               # SLURM作业脚本
│   ├── vasp-basic.slurm      # 基础计算脚本
│   └── vasp-optimization.slurm # 结构优化脚本
├── images/                # 图片资源（预留）
└── attachments/           # 附件文档（预留）
```

## 使用说明

### 示例文件使用

1. **复制示例文件到工作目录**
   ```bash
   cp /static/guides/hpc/vasp/examples/* ./
   ```

2. **根据具体计算需求修改参数**
   - 修改INCAR中的计算参数
   - 替换POSCAR中的结构信息
   - 调整KPOINTS网格密度

### 作业脚本使用

1. **选择合适的脚本模板**
   ```bash
   cp /static/guides/hpc/vasp/scripts/vasp-basic.slurm ./
   ```

2. **根据计算资源需求修改**
   - 调整节点数和核数
   - 修改内存和时间限制
   - 更新邮件通知地址

## 链接引用

在文档中引用这些资源时，请使用以下格式：

- 示例文件：`[INCAR示例](/static/guides/hpc/vasp/examples/INCAR.basic)`
- 脚本文件：`[基础脚本](/static/guides/hpc/vasp/scripts/vasp-basic.slurm)`

## 版本信息

- 创建日期：2025-08-01
- 适用VASP版本：6.3.0+
- 集群环境：SLURM调度系统