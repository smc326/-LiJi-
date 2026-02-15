#!/bin/bash

# 快速启动脚本
# Linux/Mac 版本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}========================================"
echo "  人情往来系统 - 部署选择"
echo "========================================${NC}"
echo ""

# 询问部署方式
echo -e "${YELLOW}请选择部署方式:${NC}"
echo "  1. Docker Hub 镜像部署 (推荐，快速)"
echo "  2. 本地构建部署 (需要构建镜像)"
echo ""

read -p "请输入选择 (1/2): " choice

if [ "$choice" = "1" ]; then
    # Docker Hub 部署
    echo -e "\n${GREEN}正在使用 Docker Hub 镜像部署...${NC}"
    
    # 检查 Docker 是否运行
    if ! docker info &> /dev/null; then
        echo -e "${RED}错误: Docker 未运行${NC}"
        echo "请启动 Docker 服务"
        exit 1
    fi
    
    # 拉取最新镜像
    echo -e "${YELLOW}拉取最新镜像...${NC}"
    docker pull your-dockerhub-username/renqing-wanglai:latest
    
    # 创建数据目录
    echo -e "${YELLOW}创建数据目录...${NC}"
    mkdir -p "$HOME/renqing-data"
    
    # 检查是否已有同名容器
    if docker ps -a | grep -q renqing-wanglai; then
        echo -e "${YELLOW}停止并移除现有容器...${NC}"
        docker stop renqing-wanglai 2>/dev/null || true
        docker rm renqing-wanglai 2>/dev/null || true
    fi
    
    # 运行容器
    echo -e "${YELLOW}启动容器...${NC}"
    docker run -d \
      --name renqing-wanglai \
      -p 3000:3000 \
      -v "$HOME/renqing-data:/app/data" \
      --restart unless-stopped \
      your-dockerhub-username/renqing-wanglai:latest
    
elif [ "$choice" = "2" ]; then
    # 本地构建部署
    echo -e "\n${GREEN}正在使用本地构建部署...${NC}"
    
    # 检查 Docker 是否运行
    if ! docker info &> /dev/null; then
        echo -e "${RED}错误: Docker 未运行${NC}"
        echo "请启动 Docker 服务"
        exit 1
    fi
    
    # 构建并启动容器
    echo -e "${YELLOW}构建 Docker 镜像...${NC}"
    docker-compose build
    
    echo -e "${YELLOW}启动容器...${NC}"
    docker-compose up -d
    
else
    echo -e "${RED}无效选择，退出部署${NC}"
    exit 1
fi

# 等待服务启动
echo -e "${YELLOW}等待服务启动...${NC}"
sleep 3

# 检查健康状态
echo -e "${YELLOW}检查服务状态...${NC}"
max_attempts=10
attempt=0
healthy=false

while [ $attempt -lt $max_attempts ] && [ "$healthy" = false ]; do
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health | grep -q "200"; then
        healthy=true
    else
        attempt=$((attempt + 1))
        sleep 2
    fi
done

if [ "$healthy" = true ]; then
    echo -e "\n${GREEN}========================================"
    echo "  人情往来系统已成功启动！"
    echo "========================================${NC}"
    echo ""
    echo -e "${CYAN}访问地址：${NC}"
    echo -e "  本地访问: ${YELLOW}http://localhost:3000${NC}"
    
    # 获取本机IP
    if command -v hostname &> /dev/null; then
        IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "无法获取")
        if [ "$IP" != "无法获取" ]; then
            echo -e "  局域网访问: ${YELLOW}http://$IP:3000${NC}"
        fi
    fi
    
    echo ""
    echo -e "${CYAN}数据存储: ${NC}"
    if [ "$choice" = "1" ]; then
        echo -e "  ${YELLOW}$HOME/renqing-data${NC}"
    else
        echo -e "  ${YELLOW}./data/${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}常用命令：${NC}"
    if [ "$choice" = "1" ]; then
        echo "  查看日志: docker logs -f renqing-wanglai"
        echo "  停止服务: docker stop renqing-wanglai"
        echo "  启动服务: docker start renqing-wanglai"
        echo "  重启服务: docker restart renqing-wanglai"
    else
        echo "  查看日志: docker-compose logs -f"
        echo "  停止服务: docker-compose down"
        echo "  重启服务: docker-compose restart"
    fi
    echo ""
    
    # 询问是否打开浏览器
    if command -v xdg-open &> /dev/null; then
        read -p "是否在浏览器中打开? (y/n): " open_browser
        if [ "$open_browser" = "y" ] || [ "$open_browser" = "Y" ]; then
            xdg-open "http://localhost:3000" 2>/dev/null || \
            open "http://localhost:3000" 2>/dev/null || \
            echo "请手动打开浏览器访问: http://localhost:3000"
        fi
    fi
else
    echo -e "\n${RED}服务启动失败，请查看日志：${NC}"
    if [ "$choice" = "1" ]; then
        echo "  docker logs renqing-wanglai"
    else
        echo "  docker-compose logs"
    fi
fi
