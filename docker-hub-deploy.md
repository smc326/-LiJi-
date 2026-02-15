# 通过 Docker Hub 部署人情往来系统

## 方案一：直接拉取镜像部署（推荐）

### 1. 准备工作

确保已安装 Docker：
```bash
docker --version
```

### 2. 创建数据目录

```bash
# Linux/Mac
mkdir -p ~/renqing-data

# Windows PowerShell
New-Item -ItemType Directory -Path "$env:USERPROFILE\renqing-data" -Force
```

### 3. 拉取并运行镜像

```bash
# 拉取最新版本镜像
docker pull your-dockerhub-username/renqing-wanglai:latest

# 运行容器
docker run -d \
  --name renqing-wanglai \
  -p 3000:3000 \
  -v ~/renqing-data:/app/data \
  --restart unless-stopped \
  your-dockerhub-username/renqing-wanglai:latest
```

**Windows PowerShell:**
```powershell
docker run -d `
  --name renqing-wanglai `
  -p 3000:3000 `
  -v "$env:USERPROFILE\renqing-data:/app/data" `
  --restart unless-stopped `
  your-dockerhub-username/renqing-wanglai:latest
```

### 4. 访问应用

浏览器打开：`http://localhost:3000`

默认密码：`admin`

### 5. 查看日志

```bash
docker logs -f renqing-wanglai
```

### 6. 停止和删除容器

```bash
# 停止容器
docker stop renqing-wanglai

# 删除容器
docker rm renqing-wanglai

# 重新启动
docker start renqing-wanglai
```

---

## 方案二：使用 Docker Compose 部署

### 1. 创建 docker-compose.yml 文件

创建一个新目录并在其中创建 `docker-compose.yml`：

```yaml
version: '3.8'

services:
  renqing-app:
    image: your-dockerhub-username/renqing-wanglai:latest
    container_name: renqing-wanglai
    ports:
      - "3000:3000"
    volumes:
      - ./data:/app/data
    environment:
      - NODE_ENV=production
      - PORT=3000
      - DATA_DIR=/app/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

### 2. 启动服务

```bash
# 创建数据目录
mkdir -p data

# 拉取镜像并启动
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

---

## 方案三：一键部署脚本

### Linux/Mac 一键部署脚本

创建 `deploy.sh`：

```bash
#!/bin/bash

echo "======================================"
echo "  人情往来系统 - Docker Hub 部署"
echo "======================================"

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo "错误: Docker 未安装，请先安装 Docker"
    exit 1
fi

# 设置变量
IMAGE_NAME="your-dockerhub-username/renqing-wanglai:latest"
CONTAINER_NAME="renqing-wanglai"
DATA_DIR="$HOME/renqing-data"
PORT=3000

# 创建数据目录
echo "创建数据目录: $DATA_DIR"
mkdir -p "$DATA_DIR"

# 停止并删除旧容器
echo "检查并清理旧容器..."
docker stop $CONTAINER_NAME 2>/dev/null || true
docker rm $CONTAINER_NAME 2>/dev/null || true

# 拉取最新镜像
echo "拉取最新镜像..."
docker pull $IMAGE_NAME

# 运行新容器
echo "启动容器..."
docker run -d \
  --name $CONTAINER_NAME \
  -p $PORT:3000 \
  -v "$DATA_DIR:/app/data" \
  --restart unless-stopped \
  $IMAGE_NAME

# 等待容器启动
echo "等待服务启动..."
sleep 5

# 检查容器状态
if docker ps | grep -q $CONTAINER_NAME; then
    echo ""
    echo "======================================"
    echo "  部署成功！"
    echo "======================================"
    echo ""
    echo "访问地址: http://localhost:$PORT"
    echo "数据目录: $DATA_DIR"
    echo "默认密码: admin"
    echo ""
    echo "常用命令:"
    echo "  查看日志: docker logs -f $CONTAINER_NAME"
    echo "  停止服务: docker stop $CONTAINER_NAME"
    echo "  启动服务: docker start $CONTAINER_NAME"
    echo "  重启服务: docker restart $CONTAINER_NAME"
    echo ""
else
    echo ""
    echo "部署失败，请查看日志："
    echo "  docker logs $CONTAINER_NAME"
fi
```

**使用方法：**
```bash
chmod +x deploy.sh
./deploy.sh
```

### Windows PowerShell 一键部署脚本

创建 `deploy.ps1`：

```powershell
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  人情往来系统 - Docker Hub 部署" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# 检查 Docker 是否运行
try {
    docker info | Out-Null
} catch {
    Write-Host "错误: Docker 未运行，请先启动 Docker Desktop" -ForegroundColor Red
    exit 1
}

# 设置变量
$IMAGE_NAME = "your-dockerhub-username/renqing-wanglai:latest"
$CONTAINER_NAME = "renqing-wanglai"
$DATA_DIR = "$env:USERPROFILE\renqing-data"
$PORT = 3000

# 创建数据目录
Write-Host "创建数据目录: $DATA_DIR" -ForegroundColor Yellow
New-Item -ItemType Directory -Path $DATA_DIR -Force | Out-Null

# 停止并删除旧容器
Write-Host "检查并清理旧容器..." -ForegroundColor Yellow
docker stop $CONTAINER_NAME 2>$null
docker rm $CONTAINER_NAME 2>$null

# 拉取最新镜像
Write-Host "拉取最新镜像..." -ForegroundColor Yellow
docker pull $IMAGE_NAME

# 运行新容器
Write-Host "启动容器..." -ForegroundColor Yellow
docker run -d `
  --name $CONTAINER_NAME `
  -p "${PORT}:3000" `
  -v "${DATA_DIR}:/app/data" `
  --restart unless-stopped `
  $IMAGE_NAME

# 等待容器启动
Write-Host "等待服务启动..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# 检查容器状态
$running = docker ps --filter "name=$CONTAINER_NAME" --format "{{.Names}}"
if ($running -eq $CONTAINER_NAME) {
    Write-Host ""
    Write-Host "======================================" -ForegroundColor Green
    Write-Host "  部署成功！" -ForegroundColor Green
    Write-Host "======================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "访问地址: http://localhost:$PORT" -ForegroundColor White
    Write-Host "数据目录: $DATA_DIR" -ForegroundColor White
    Write-Host "默认密码: admin" -ForegroundColor White
    Write-Host ""
    Write-Host "常用命令:" -ForegroundColor Cyan
    Write-Host "  查看日志: docker logs -f $CONTAINER_NAME" -ForegroundColor White
    Write-Host "  停止服务: docker stop $CONTAINER_NAME" -ForegroundColor White
    Write-Host "  启动服务: docker start $CONTAINER_NAME" -ForegroundColor White
    Write-Host "  重启服务: docker restart $CONTAINER_NAME" -ForegroundColor White
    Write-Host ""
    
    $openBrowser = Read-Host "是否在浏览器中打开? (y/n)"
    if ($openBrowser -eq "y" -or $openBrowser -eq "Y") {
        Start-Process "http://localhost:$PORT"
    }
} else {
    Write-Host ""
    Write-Host "部署失败，请查看日志：" -ForegroundColor Red
    Write-Host "  docker logs $CONTAINER_NAME" -ForegroundColor Yellow
}
```

**使用方法：**
```powershell
.\deploy.ps1
```

---

## 镜像版本说明

### 可用的镜像标签

- `latest` - 最新稳定版本
- `v1.0.0` - 特定版本
- `dev` - 开发版本

### 拉取特定版本

```bash
# 拉取最新版本
docker pull your-dockerhub-username/renqing-wanglai:latest

# 拉取特定版本
docker pull your-dockerhub-username/renqing-wanglai:v1.0.0
```

---

## 配置选项

### 环境变量

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `PORT` | 3000 | 应用端口 |
| `DATA_DIR` | /app/data | 数据存储目录 |
| `NODE_ENV` | production | 运行环境 |

### 端口映射

修改主机端口：
```bash
docker run -d \
  --name renqing-wanglai \
  -p 8080:3000 \    # 使用 8080 端口访问
  -v ~/renqing-data:/app/data \
  your-dockerhub-username/renqing-wanglai:latest
```

### 数据目录

数据存储在挂载的卷中：
- `records.json` - 人情往来记录
- `giftbooks.json` - 礼薄数据

---

## 升级镜像

```bash
# 1. 停止当前容器
docker stop renqing-wanglai

# 2. 删除容器（数据保留在挂载卷中）
docker rm renqing-wanglai

# 3. 拉取最新镜像
docker pull your-dockerhub-username/renqing-wanglai:latest

# 4. 重新运行容器
docker run -d \
  --name renqing-wanglai \
  -p 3000:3000 \
  -v ~/renqing-data:/app/data \
  --restart unless-stopped \
  your-dockerhub-username/renqing-wanglai:latest
```

---

## 数据备份和恢复

### 备份数据

```bash
# Linux/Mac
tar -czf renqing-backup-$(date +%Y%m%d).tar.gz ~/renqing-data

# Windows PowerShell
Compress-Archive -Path "$env:USERPROFILE\renqing-data" -DestinationPath "renqing-backup-$(Get-Date -Format 'yyyyMMdd').zip"
```

### 恢复数据

```bash
# 1. 停止容器
docker stop renqing-wanglai

# 2. 恢复数据
# Linux/Mac
tar -xzf renqing-backup-20231207.tar.gz -C ~

# Windows PowerShell
Expand-Archive -Path "renqing-backup-20231207.zip" -DestinationPath "$env:USERPROFILE\" -Force

# 3. 重启容器
docker start renqing-wanglai
```

---

## 多实例部署

运行多个实例（不同端口）：

```bash
# 实例 1 (端口 3000)
docker run -d \
  --name renqing-instance-1 \
  -p 3000:3000 \
  -v ~/renqing-data-1:/app/data \
  your-dockerhub-username/renqing-wanglai:latest

# 实例 2 (端口 3001)
docker run -d \
  --name renqing-instance-2 \
  -p 3001:3000 \
  -v ~/renqing-data-2:/app/data \
  your-dockerhub-username/renqing-wanglai:latest
```

---

## 故障排查

### 查看容器日志

```bash
docker logs renqing-wanglai
docker logs -f renqing-wanglai  # 实时查看
```

### 进入容器调试

```bash
docker exec -it renqing-wanglai sh
```

### 检查容器状态

```bash
docker ps -a | grep renqing
docker inspect renqing-wanglai
```

### 端口被占用

```bash
# 查看端口占用
netstat -ano | findstr :3000  # Windows
lsof -i :3000                 # Linux/Mac

# 使用其他端口
docker run -d \
  --name renqing-wanglai \
  -p 8080:3000 \
  -v ~/renqing-data:/app/data \
  your-dockerhub-username/renqing-wanglai:latest
```

---

## 安全建议

1. **修改默认密码**
   - 首次登录后立即修改密码

2. **限制访问**
   ```bash
   # 只监听本地
   docker run -d \
     --name renqing-wanglai \
     -p 127.0.0.1:3000:3000 \
     -v ~/renqing-data:/app/data \
     your-dockerhub-username/renqing-wanglai:latest
   ```

3. **定期备份数据**
   - 设置自动备份任务

4. **使用特定版本**
   - 生产环境使用固定版本号，避免使用 `latest`

---

## 卸载

```bash
# 停止并删除容器
docker stop renqing-wanglai
docker rm renqing-wanglai

# 删除镜像
docker rmi your-dockerhub-username/renqing-wanglai:latest

# 删除数据（可选）
rm -rf ~/renqing-data
```

---

## 技术支持

- **镜像地址**: https://hub.docker.com/r/your-dockerhub-username/renqing-wanglai
- **问题反馈**: GitHub Issues
- **文档**: README.md

---

**注意**: 
1. 请将 `your-dockerhub-username` 替换为实际的 Docker Hub 用户名
2. 确保数据目录有足够的磁盘空间
3. 生产环境建议使用反向代理（如 Nginx）配置 HTTPS
