# 部署脚本使用说明

## 概述

`deploy.sh` 是一个专门为 HPC 文档站点设计的自动化部署脚本，支持本地和远程部署。

## 功能特性

- 🚀 **自动化构建和部署**: 一键完成项目构建和部署
- 🎯 **多环境支持**: 支持 production、staging、dev 三种环境
- 🔄 **自动备份**: 部署前自动备份现有文件
- 📝 **详细日志**: 完整的部署过程日志记录
- 🔍 **部署验证**: 自动验证部署是否成功
- 🌐 **远程部署**: 支持通过 SSH 部署到远程服务器
- 🎨 **彩色输出**: 清晰的命令行输出显示

## 使用方法

### 基本用法

```bash
# 部署到生产环境（默认）
./deploy.sh

# 部署到指定环境
./deploy.sh production    # 生产环境
./deploy.sh staging       # 测试环境  
./deploy.sh dev           # 开发环境
```

### 命令选项

```bash
# 显示帮助信息
./deploy.sh -h

# 显示版本信息
./deploy.sh -v

# 远程部署模式
./deploy.sh -r production
```

## 环境配置

脚本内置了三种环境的配置：

### 生产环境 (production)
- 部署路径: `/var/www/html/tibhpc-docs`
- 服务用户: `root`
- Web 服务器: Nginx

### 测试环境 (staging)
- 部署路径: `/var/www/html/tibhpc-docs-staging`
- 服务用户: `www-data`
- Web 服务器: Nginx

### 开发环境 (dev)
- 部署路径: `/var/www/html/tibhpc-docs-dev`
- 服务用户: `www-data`
- Web 服务器: Nginx

## 部署流程

1. **前置检查**: 验证 Node.js、npm 等必要工具
2. **项目构建**: 执行 `npm run build` 构建项目
3. **创建备份**: 备份现有部署文件
4. **文件部署**: 复制构建文件到目标目录
5. **权限设置**: 设置正确的文件权限
6. **服务重启**: 重启 Nginx 服务
7. **部署验证**: 验证部署是否成功

## 远程部署配置

如果需要部署到远程服务器，修改 `DEPLOY_CONFIGS` 数组中的配置：

```bash
# 格式: "环境:user@host:路径:服务类型:服务用户"
DEPLOY_CONFIGS=(
    "production:user@server.com:/var/www/html/tibhpc-docs:nginx:www-data"
)
```

## 日志文件

每次部署都会生成日志文件，格式为：
```
deploy_环境_时间戳.log
```

例如：`deploy_production_20241219_143022.log`

## 前置条件

### 本地部署
- Node.js (>=18.0)
- npm
- sudo 权限（用于文件操作和服务重启）
- Nginx web 服务器

### 远程部署
- SSH 访问远程服务器的权限
- 远程服务器上的 sudo 权限
- SSH key 认证（推荐）

## 错误处理

脚本包含完善的错误处理机制：
- 构建失败时自动停止
- 部署失败时保留备份
- 详细的错误信息输出
- 日志记录便于排查问题

## 自定义配置

如需修改部署配置，编辑脚本中的以下部分：

```bash
# 项目名称
PROJECT_NAME="tibhpc-docs"

# 构建输出目录
BUILD_DIR="build"

# 部署配置
DEPLOY_CONFIGS=(
    "production:/var/www/html/${PROJECT_NAME}:nginx:root"
    # 添加更多环境配置...
)
```

## 示例场景

### 1. 部署到生产环境
```bash
./deploy.sh production
```

### 2. 部署到测试环境
```bash
./deploy.sh staging
```

### 3. 查看部署日志
```bash
tail -f deploy_production_20241219_143022.log
```

### 4. 回滚部署（使用备份）
```bash
# 如果部署失败，可以从备份恢复
sudo cp -r /tmp/tibhpc-docs_backup_20241219_143022/* /var/www/html/tibhpc-docs/
```

## 故障排除

### 常见问题

1. **权限错误**: 确保用户有 sudo 权限
2. **SSH 连接失败**: 检查 SSH 配置和网络连接
3. **构建失败**: 检查 Node.js 版本和项目依赖
4. **Nginx 重启失败**: 检查 Nginx 配置语法

### 调试模式

如需更详细的调试信息，可以在脚本开头添加：
```bash
set -x  # 显示执行的命令
```

## 安全注意事项

- 脚本需要 sudo 权限，请确保在可信环境中运行
- 远程部署时使用 SSH key 认证，避免密码认证
- 定期清理备份文件释放磁盘空间
- 定期检查日志文件监控部署状态