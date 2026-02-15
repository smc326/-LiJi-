# 人情往来系统 - 完整部署方案

## 📦 项目结构

```
人情往来/
├── server.js              # Node.js 后端服务器
├── package.json           # Node.js 依赖配置
├── Dockerfile            # Docker 镜像构建文件
├── docker-compose.yml    # Docker Compose 配置
├── .gitignore           # Git 忽略文件
├── start.ps1            # Windows 快速启动脚本
├── README.md            # 项目说明文档
├── DEPLOYMENT.md        # 本部署文档
├── public/              # 前端文件目录
│   └── index.html       # 前端页面
└── data/                # 数据持久化目录
    ├── records.json     # 人情往来记录
    └── giftbooks.json   # 礼薄数据
```

## 🚀 快速部署（推荐）

### 方案一：Docker Hub 镜像部署（最快）

#### Windows 用户

1. **确保 Docker Desktop 已安装并运行**

2. **下载并运行部署脚本**
   ```powershell
   # 下载部署脚本
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/your-repo/renqing-wanglai/main/deploy-from-hub.ps1" -OutFile "deploy-from-hub.ps1"
   
   # 运行部署脚本
   .\deploy-from-hub.ps1
   ```

3. **访问应用**
   - 本地访问：http://localhost:3000
   - 局域网访问：http://你的IP:3000

#### Linux/Mac 用户

```bash
# 1. 下载部署脚本
wget https://raw.githubusercontent.com/your-repo/renqing-wanglai/main/deploy-from-hub.sh
chmod +x deploy-from-hub.sh

# 2. 运行部署脚本
./deploy-from-hub.sh

# 3. 访问应用
# 浏览器打开 http://localhost:3000
```

### 方案二：本地构建部署

## 📋 详细部署步骤

### 方案一：Docker Hub 镜像部署

#### 1. 环境准备

**必需软件：**
- Docker（版本 20.10+）

**安装 Docker：**
- Windows: 下载 [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop)
- Linux: 
  ```bash
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker $USER
  ```
- Mac: 下载 [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop)

#### 2. 拉取镜像

```bash
# 拉取最新镜像
docker pull your-dockerhub-username/renqing-wanglai:latest
```

#### 3. 创建数据目录

```bash
# Linux/Mac
mkdir -p ~/renqing-data

# Windows PowerShell
New-Item -ItemType Directory -Path "$env:USERPROFILE\renqing-data" -Force
```

#### 4. 运行容器

```bash
# Linux/Mac
docker run -d \
  --name renqing-wanglai \
  -p 3000:3000 \
  -v ~/renqing-data:/app/data \
  --restart unless-stopped \
  your-dockerhub-username/renqing-wanglai:latest

# Windows PowerShell
docker run -d `
  --name renqing-wanglai `
  -p 3000:3000 `
  -v "$env:USERPROFILE\renqing-data:/app/data" `
  --restart unless-stopped `
  your-dockerhub-username/renqing-wanglai:latest
```

#### 5. 验证部署

```bash
# 检查容器状态
docker ps | grep renqing-wanglai

# 检查健康状态
curl http://localhost:3000/health

# 应该返回: {"status":"ok"}
```

### 方案二：本地构建部署

### 2. 文件准备

确保项目目录包含以下文件：
- ✅ server.js
- ✅ package.json
- ✅ Dockerfile
- ✅ docker-compose.yml
- ✅ public/index.html

### 3. 构建镜像

```bash
# 进入项目目录
cd 人情往来

# 构建 Docker 镜像
docker-compose build
```

### 4. 启动服务

```bash
# 后台启动
docker-compose up -d

# 查看日志
docker-compose logs -f

# 查看运行状态
docker-compose ps
```

### 5. 验证部署

```bash
# 检查健康状态
curl http://localhost:3000/health

# 应该返回: {"status":"ok"}
```

## 🔧 配置选项

### 端口配置

编辑 `docker-compose.yml`：

```yaml
ports:
  - "8080:3000"  # 将左侧改为你想要的端口
```

### 数据目录配置

编辑 `docker-compose.yml`：

```yaml
volumes:
  - /your/custom/path:/app/data  # 自定义数据存储路径
```

### 环境变量

编辑 `docker-compose.yml`：

```yaml
environment:
  - PORT=3000           # 应用端口
  - DATA_DIR=/app/data  # 数据目录
  - NODE_ENV=production # 运行模式
```

## 💾 数据管理

### 数据位置

数据存储在 `./data` 目录：
- `records.json` - 人情往来记录
- `giftbooks.json` - 礼薄数据

### 备份数据

```bash
# 方式1：复制整个 data 目录
cp -r ./data ./backup_$(date +%Y%m%d_%H%M%S)

# 方式2：使用 tar 压缩
tar -czf backup_$(date +%Y%m%d_%H%M%S).tar.gz ./data

# Windows PowerShell
Compress-Archive -Path .\data -DestinationPath "backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"
```

### 恢复数据

```bash
# 停止服务
docker-compose down

# 恢复数据
cp -r ./backup_20231207_150000/data/* ./data/

# 重启服务
docker-compose up -d
```

### 数据迁移

从 localStorage 迁移到服务器：

1. 打开浏览器开发者工具（F12）
2. 进入 Console 标签
3. 执行以下代码：

```javascript
// 导出 localStorage 数据
console.log('Records:', localStorage.getItem('renqing-records'));
console.log('GiftBooks:', localStorage.getItem('renqing-giftbooks'));

// 复制输出的内容
// 将内容保存到 data/records.json 和 data/giftbooks.json
```

## 🌐 外网访问

### 使用 Nginx 反向代理

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### 使用内网穿透（frp）

```ini
[renqing]
type = http
local_port = 3000
custom_domains = renqing.yourdomain.com
```

### 云服务器部署

1. **购买云服务器**（阿里云、腾讯云等）
2. **安装 Docker**
3. **上传项目文件**
4. **配置安全组**（开放 3000 端口）
5. **启动服务**

```bash
# 克隆项目（或上传文件）
git clone your-repo-url

# 构建启动
docker-compose up -d

# 配置防火墙
sudo ufw allow 3000
```

## 📊 监控和维护

### 查看日志

```bash
# 实时查看日志
docker-compose logs -f

# 查看最近100行
docker-compose logs --tail=100

# 查看特定服务日志
docker-compose logs renqing-app
```

### 性能监控

```bash
# 查看容器资源使用
docker stats renqing-wanglai

# 查看容器详情
docker inspect renqing-wanglai
```

### 自动重启

已在 `docker-compose.yml` 中配置：
```yaml
restart: unless-stopped
```

## 🔒 安全建议

1. **修改默认端口**
   ```yaml
   ports:
     - "8888:3000"  # 使用非标准端口
   ```

2. **配置防火墙**
   ```bash
   # 只允许特定IP访问
   sudo ufw allow from 192.168.1.0/24 to any port 3000
   ```

3. **使用 HTTPS**（配合 Nginx + Let's Encrypt）

4. **定期备份数据**（设置 cron 任务）
   ```bash
   # 每天凌晨2点备份
   0 2 * * * /path/to/backup.sh
   ```

5. **限制容器资源**
   ```yaml
   deploy:
     resources:
       limits:
         cpus: '0.5'
         memory: 512M
   ```

## 🐛 故障排查

### 容器无法启动

```bash
# 查看详细日志
docker-compose logs

# 检查端口占用
netstat -ano | findstr :3000  # Windows
lsof -i :3000                 # Linux/Mac

# 重新构建
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### 数据未持久化

```bash
# 检查数据目录权限
ls -la ./data

# 修改权限
chmod -R 755 ./data

# 检查挂载点
docker inspect renqing-wanglai | grep Mounts -A 20
```

### 无法访问

1. 检查 Docker 是否运行
2. 检查防火墙设置
3. 检查端口映射
4. 查看容器日志

## 📝 更新应用

```bash
# 1. 停止当前服务
docker-compose down

# 2. 备份数据
cp -r ./data ./data_backup

# 3. 更新代码
git pull  # 或手动更新文件

# 4. 重新构建
docker-compose build

# 5. 启动新版本
docker-compose up -d

# 6. 验证
curl http://localhost:3000/health
```

## 💡 性能优化

### 1. 使用 Docker 卷而不是绑定挂载

```yaml
volumes:
  - renqing-data:/app/data

volumes:
  renqing-data:
```

### 2. 启用 Node.js 生产模式

已在 Dockerfile 中配置：
```dockerfile
ENV NODE_ENV=production
```

### 3. 使用多阶段构建（可选）

```dockerfile
# 构建阶段
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# 运行阶段
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
CMD ["npm", "start"]
```

## 📞 技术支持

遇到问题？
1. 查看本文档的故障排查章节
2. 检查 Docker 和 Docker Compose 日志
3. 确保所有依赖已正确安装

---

**祝您部署顺利！** 🎉
