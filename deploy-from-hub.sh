#!/bin/bash

# 人情往来系统 - Docker Hub 一键部署脚本
# 适用于 Linux/Mac

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 配置变量
IMAGE_NAME="your-dockerhub-username/renqing-wanglai"
CONTAINER_NAME="renqing-wanglai"
DATA_DIR="$HOME/renqing-data"
PORT=3000

echo -e "${CYAN}======================================"
echo "  人情往来系统 - Docker Hub 部署"
echo "======================================${NC}"
echo ""

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: Docker 未安装${NC}"
    echo "请访问 https://docs.docker.com/get-docker/ 安装 Docker"
    exit 1
fi

# 检查 Docker 是否运行
if ! docker info &> /dev/null; then
    echo -e "${RED}错误: Docker 未运行${NC}"
    echo "请启动 Docker 服务"
    exit 1
fi

echo -e "${GREEN}✓ Docker 检查通过${NC}"
echo ""

# 询问配置
read -p "请输入数据存储目录 (默认: $DATA_DIR): " user_data_dir
DATA_DIR=${user_data_dir:-$DATA_DIR}

read -p "请输入访问端口 (默认: $PORT): " user_port
PORT=${user_port:-$PORT}

read -p "请输入 Docker Hub 用户名 (默认: your-dockerhub-username): " docker_user
DOCKER_USER=${docker_user:-your-dockerhub-username}
IMAGE_NAME="$DOCKER_USER/renqing-wanglai"

echo ""
echo -e "${YELLOW}配置信息:${NC}"
echo "  镜像名称: $IMAGE_NAME:latest"
echo "  容器名称: $CONTAINER_NAME"
echo "  数据目录: $DATA_DIR"
echo "  访问端口: $PORT"
echo ""

read -p "确认部署? (y/n): " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "部署已取消"
    exit 0
fi

echo ""
echo -e "${YELLOW}开始部署...${NC}"
echo ""

# 创建数据目录
echo -e "${CYAN}[1/5] 创建数据目录...${NC}"
mkdir -p "$DATA_DIR"
echo -e "${GREEN}✓ 数据目录创建成功: $DATA_DIR${NC}"
echo ""

# 停止并删除旧容器
echo -e "${CYAN}[2/5] 清理旧容器...${NC}"
if docker ps -a | grep -q $CONTAINER_NAME; then
    docker stop $CONTAINER_NAME 2>/dev/null || true
    docker rm $CONTAINER_NAME 2>/dev/null || true
    echo -e "${GREEN}✓ 旧容器已清理${NC}"
else
    echo -e "${GREEN}✓ 无需清理${NC}"
fi
echo ""

# 拉取最新镜像
echo -e "${CYAN}[3/5] 拉取最新镜像...${NC}"
if docker pull $IMAGE_NAME:latest; then
    echo -e "${GREEN}✓ 镜像拉取成功${NC}"
else
    echo -e "${RED}✗ 镜像拉取失败${NC}"
    echo "请检查:"
    echo "  1. Docker Hub 用户名是否正确"
    echo "  2. 镜像是否存在"
    echo "  3. 网络连接是否正常"
    exit 1
fi
echo ""

# 运行容器
echo -e "${CYAN}[4/5] 启动容器...${NC}"
docker run -d \
  --name $CONTAINER_NAME \
  -p $PORT:3000 \
  -v "$DATA_DIR:/app/data" \
  -e NODE_ENV=production \
  -e PORT=3000 \
  -e DATA_DIR=/app/data \
  --restart unless-stopped \
  $IMAGE_NAME:latest

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 容器启动成功${NC}"
else
    echo -e "${RED}✗ 容器启动失败${NC}"
    exit 1
fi
echo ""

# 等待服务启动
echo -e "${CYAN}[5/5] 等待服务启动...${NC}"
sleep 5

# 检查容器状态
if docker ps | grep -q $CONTAINER_NAME; then
    echo -e "${GREEN}✓ 服务运行正常${NC}"
    echo ""
    echo -e "${GREEN}======================================"
    echo "  部署成功！"
    echo "======================================${NC}"
    echo ""
    echo -e "${CYAN}访问信息:${NC}"
    echo -e "  本地访问: ${YELLOW}http://localhost:$PORT${NC}"
    
    # 获取本机IP
    if command -v hostname &> /dev/null; then
        IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "无法获取")
        if [ "$IP" != "无法获取" ]; then
            echo -e "  局域网访问: ${YELLOW}http://$IP:$PORT${NC}"
        fi
    fi
    
    echo -e "  默认密码: ${YELLOW}admin${NC}"
    echo ""
    echo -e "${CYAN}数据目录:${NC}"
    echo "  $DATA_DIR"
    echo ""
    echo -e "${CYAN}常用命令:${NC}"
    echo "  查看日志: docker logs -f $CONTAINER_NAME"
    echo "  停止服务: docker stop $CONTAINER_NAME"
    echo "  启动服务: docker start $CONTAINER_NAME"
    echo "  重启服务: docker restart $CONTAINER_NAME"
    echo "  删除容器: docker rm -f $CONTAINER_NAME"
    echo ""
    
    # 询问是否打开浏览器
    if command -v xdg-open &> /dev/null; then
        read -p "是否在浏览器中打开? (y/n): " open_browser
        if [ "$open_browser" = "y" ] || [ "$open_browser" = "Y" ]; then
            xdg-open "http://localhost:$PORT" 2>/dev/null || \
            open "http://localhost:$PORT" 2>/dev/null || \
            echo "请手动打开浏览器访问: http://localhost:$PORT"
        fi
    fi
else
    echo -e "${RED}✗ 服务启动失败${NC}"
    echo ""
    echo "请查看日志："
    echo "  docker logs $CONTAINER_NAME"
    exit 1
fi
