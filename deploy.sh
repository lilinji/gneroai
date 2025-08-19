#!/bin/bash

# HPC 文档站点自动化部署脚本
# 用法: ./deploy.sh [环境: production|staging|dev]
# 默认环境: production

set -e  # 遇到错误立即退出

# 配置变量
ENVIRONMENT=${1:-production}
PROJECT_NAME="tibhpc-docs"
BUILD_DIR="build"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="/tmp/${PROJECT_NAME}_backup_${TIMESTAMP}"
LOG_FILE="deploy_${ENVIRONMENT}_${TIMESTAMP}.log"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

# 部署配置
DEPLOY_CONFIGS=(
    "production:/var/www/html/${PROJECT_NAME}:nginx:root"
    "staging:/var/www/html/${PROJECT_NAME}-staging:nginx:www-data"
    "dev:/var/www/html/${PROJECT_NAME}-dev:nginx:www-data"
)

# 获取当前环境配置
get_deploy_config() {
    for config in "${DEPLOY_CONFIGS[@]}"; do
        if [[ $config == ${ENVIRONMENT}:* ]]; then
            echo "$config"
            return
        fi
    done
    error "未找到环境 ${ENVIRONMENT} 的配置"
    exit 1
}

# 检查前置条件
check_prerequisites() {
    log "检查前置条件..."
    
    # 检查是否在正确的目录
    if [ ! -f "package.json" ] || [ ! -f "docusaurus.config.js" ]; then
        error "错误: 请在项目根目录运行此脚本"
        exit 1
    fi
    
    # 检查 Node.js
    if ! command -v node &> /dev/null; then
        error "错误: Node.js 未安装"
        exit 1
    fi
    
    # 检查 npm
    if ! command -v npm &> /dev/null; then
        error "错误: npm 未安装"
        exit 1
    fi
    
    # 检查 SSH (如果需要远程部署)
    if [ "$REMOTE_DEPLOY" = true ] && ! command -v ssh &> /dev/null; then
        error "错误: SSH 未安装，无法进行远程部署"
        exit 1
    fi
    
    log "前置条件检查完成"
}

# 构建项目
build_project() {
    log "开始构建项目..."
    
    # 清理之前的构建
    if [ -d "$BUILD_DIR" ]; then
        log "清理之前的构建目录..."
        rm -rf "$BUILD_DIR"
    fi
    
    # 安装依赖
    log "安装依赖..."
    npm ci
    
    # 构建项目
    log "运行构建命令..."
    npm run build
    
    if [ ! -d "$BUILD_DIR" ]; then
        error "构建失败: $BUILD_DIR 目录不存在"
        exit 1
    fi
    
    log "项目构建完成"
}

# 部署到本地服务器
deploy_local() {
    local deploy_path=$1
    local service_user=$2
    
    log "部署到本地服务器: $deploy_path"
    
    # 创建备份
    if [ -d "$deploy_path" ]; then
        log "创建备份..."
        sudo cp -r "$deploy_path" "$BACKUP_DIR" || {
            warn "备份失败，继续部署..."
        }
    fi
    
    # 创建部署目录
    sudo mkdir -p "$deploy_path"
    
    # 复制构建文件
    log "复制构建文件..."
    sudo cp -r "$BUILD_DIR/"* "$deploy_path/"
    
    # 设置正确的权限
    log "设置文件权限..."
    sudo chown -R "$service_user:$service_user" "$deploy_path"
    sudo chmod -R 755 "$deploy_path"
    
    # 重启服务 (如果是 Nginx)
    if command -v systemctl &> /dev/null; then
        log "重启 Nginx 服务..."
        sudo systemctl reload nginx || sudo systemctl restart nginx
    fi
    
    log "本地部署完成"
}

# 部署到远程服务器
deploy_remote() {
    local remote_host=$1
    local deploy_path=$2
    local service_user=$3
    
    log "部署到远程服务器: $remote_host -> $deploy_path"
    
    # 打包构建文件
    local archive_name="${PROJECT_NAME}_${ENVIRONMENT}_${TIMESTAMP}.tar.gz"
    log "打包构建文件..."
    tar -czf "/tmp/$archive_name" -C "$BUILD_DIR" .
    
    # 上传到远程服务器
    log "上传文件到远程服务器..."
    scp "/tmp/$archive_name" "$remote_host:/tmp/"
    
    # 在远程服务器上执行部署
    log "在远程服务器上执行部署..."
    ssh "$remote_host" << EOF
        set -e
        # 创建备份
        if [ -d "$deploy_path" ]; then
            sudo cp -r "$deploy_path" "$BACKUP_DIR" || echo "备份失败，继续部署..."
        fi
        
        # 创建部署目录
        sudo mkdir -p "$deploy_path"
        
        # 解压文件
        sudo tar -xzf "/tmp/$archive_name" -C "$deploy_path"
        
        # 设置权限
        sudo chown -R "$service_user:$service_user" "$deploy_path"
        sudo chmod -R 755 "$deploy_path"
        
        # 重启服务
        if command -v systemctl &> /dev/null; then
            sudo systemctl reload nginx || sudo systemctl restart nginx
        fi
        
        # 清理临时文件
        rm -f "/tmp/$archive_name"
EOF
    
    # 清理本地临时文件
    rm -f "/tmp/$archive_name"
    
    log "远程部署完成"
}

# 验证部署
verify_deployment() {
    local deploy_path=$1
    local remote_host=$2
    
    log "验证部署..."
    
    if [ -n "$remote_host" ]; then
        # 远程验证
        if ssh "$remote_host" "[ -d '$deploy_path' ] && [ -f '$deploy_path/index.html' ]"; then
            log "远程部署验证成功"
        else
            error "远程部署验证失败"
            return 1
        fi
    else
        # 本地验证
        if [ -d "$deploy_path" ] && [ -f "$deploy_path/index.html" ]; then
            log "本地部署验证成功"
        else
            error "本地部署验证失败"
            return 1
        fi
    fi
}

# 显示部署信息
show_deployment_info() {
    local config=$1
    IFS=':' read -r env deploy_path service_type service_user <<< "$config"
    
    log "部署信息:"
    log "  环境: $env"
    log "  部署路径: $deploy_path"
    log "  服务用户: $service_user"
    log "  构建目录: $BUILD_DIR"
    log "  日志文件: $LOG_FILE"
}

# 主函数
main() {
    log "开始部署 $ENVIRONMENT 环境..."
    
    # 获取部署配置
    config=$(get_deploy_config)
    IFS=':' read -r env deploy_path service_type service_user <<< "$config"
    
    # 显示部署信息
    show_deployment_info "$config"
    
    # 检查前置条件
    check_prerequisites
    
    # 构建项目
    build_project
    
    # 根据配置决定部署方式
    if [[ "$deploy_path" == *:* ]]; then
        # 远程部署 (格式: user@host:path)
        IFS=':' read -r remote_host remote_deploy_path <<< "$deploy_path"
        deploy_remote "$remote_host" "$remote_deploy_path" "$service_user"
        verify_deployment "$remote_deploy_path" "$remote_host"
    else
        # 本地部署
        deploy_local "$deploy_path" "$service_user"
        verify_deployment "$deploy_path"
    fi
    
    log "部署完成！"
    
    # 显示访问信息
    if [ "$ENVIRONMENT" = "production" ]; then
        echo -e "${GREEN}🎉 生产环境部署完成！${NC}"
        echo -e "${BLUE}访问地址: https://your-domain.com${NC}"
    elif [ "$ENVIRONMENT" = "staging" ]; then
        echo -e "${GREEN}🎉 测试环境部署完成！${NC}"
        echo -e "${BLUE}访问地址: https://staging.your-domain.com${NC}"
    else
        echo -e "${GREEN}🎉 开发环境部署完成！${NC}"
        echo -e "${BLUE}访问地址: https://dev.your-domain.com${NC}"
    fi
}

# 脚本选项
while getopts "hvr" opt; do
    case $opt in
        h)
            echo "用法: $0 [环境] [选项]"
            echo "环境: production|staging|dev (默认: production)"
            echo "选项:"
            echo "  -h    显示帮助信息"
            echo "  -v    显示版本信息"
            echo "  -r    远程部署模式"
            exit 0
            ;;
        v)
            echo "HPC 文档部署脚本 v1.0.0"
            exit 0
            ;;
        r)
            REMOTE_DEPLOY=true
            ;;
        \?)
            error "无效选项: -$OPTARG"
            exit 1
            ;;
    esac
done

# 运行主函数
main "$@"