# 将镜像推送到 Docker Hub 指南

## 准备工作

### 1. 注册 Docker Hub 账号

访问 https://hub.docker.com/ 注册账号

### 2. 登录 Docker Hub

```bash
docker login
# 输入用户名和密码
```

---

## 方法一：本地构建并推送

### 1. 构建镜像

```bash
# 进入项目目录
cd "人情往来"

# 构建镜像（替换 your-username 为你的 Docker Hub 用户名）
docker build -t your-username/renqing-wanglai:latest .

# 同时打标签版本号
docker build -t your-username/renqing-wanglai:v1.0.0 .
```

### 2. 测试镜像

```bash
# 运行测试
docker run -d \
  --name test-renqing \
  -p 3000:3000 \
  -v ./data:/app/data \
  your-username/renqing-wanglai:latest

# 访问 http://localhost:3000 测试

# 停止并删除测试容器
docker stop test-renqing
docker rm test-renqing
```

### 3. 推送到 Docker Hub

```bash
# 推送 latest 版本
docker push your-username/renqing-wanglai:latest

# 推送特定版本
docker push your-username/renqing-wanglai:v1.0.0
```

---

## 方法二：使用自动化脚本

创建 `push.sh` (Linux/Mac):

```bash
#!/bin/bash

# 配置
DOCKER_USERNAME="your-username"
IMAGE_NAME="renqing-wanglai"
VERSION="1.0.0"

echo "======================================"
echo "  推送镜像到 Docker Hub"
echo "======================================"

# 检查是否已登录
if ! docker info | grep -q "Username: $DOCKER_USERNAME"; then
    echo "请先登录 Docker Hub:"
    docker login
fi

# 构建镜像
echo "构建镜像..."
docker build -t $DOCKER_USERNAME/$IMAGE_NAME:latest .
docker build -t $DOCKER_USERNAME/$IMAGE_NAME:v$VERSION .

# 推送镜像
echo "推送镜像到 Docker Hub..."
docker push $DOCKER_USERNAME/$IMAGE_NAME:latest
docker push $DOCKER_USERNAME/$IMAGE_NAME:v$VERSION

echo ""
echo "======================================"
echo "  推送成功！"
echo "======================================"
echo ""
echo "镜像地址:"
echo "  $DOCKER_USERNAME/$IMAGE_NAME:latest"
echo "  $DOCKER_USERNAME/$IMAGE_NAME:v$VERSION"
echo ""
echo "拉取命令:"
echo "  docker pull $DOCKER_USERNAME/$IMAGE_NAME:latest"
```

创建 `push.ps1` (Windows):

```powershell
# 配置
$DOCKER_USERNAME = "your-username"
$IMAGE_NAME = "renqing-wanglai"
$VERSION = "1.0.0"

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  推送镜像到 Docker Hub" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# 检查是否已登录
try {
    $info = docker info 2>&1 | Select-String "Username"
    if (!$info) {
        Write-Host "请先登录 Docker Hub:" -ForegroundColor Yellow
        docker login
    }
} catch {
    Write-Host "请先登录 Docker Hub:" -ForegroundColor Yellow
    docker login
}

# 构建镜像
Write-Host "构建镜像..." -ForegroundColor Yellow
docker build -t "${DOCKER_USERNAME}/${IMAGE_NAME}:latest" .
docker build -t "${DOCKER_USERNAME}/${IMAGE_NAME}:v${VERSION}" .

# 推送镜像
Write-Host "推送镜像到 Docker Hub..." -ForegroundColor Yellow
docker push "${DOCKER_USERNAME}/${IMAGE_NAME}:latest"
docker push "${DOCKER_USERNAME}/${IMAGE_NAME}:v${VERSION}"

Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "  推送成功！" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""
Write-Host "镜像地址:" -ForegroundColor Cyan
Write-Host "  ${DOCKER_USERNAME}/${IMAGE_NAME}:latest" -ForegroundColor White
Write-Host "  ${DOCKER_USERNAME}/${IMAGE_NAME}:v${VERSION}" -ForegroundColor White
Write-Host ""
Write-Host "拉取命令:" -ForegroundColor Cyan
Write-Host "  docker pull ${DOCKER_USERNAME}/${IMAGE_NAME}:latest" -ForegroundColor White
```

**使用方法:**
```bash
# Linux/Mac
chmod +x push.sh
./push.sh

# Windows
.\push.ps1
```

---

## 方法三：使用 GitHub Actions 自动构建推送

创建 `.github/workflows/docker-publish.yml`:

```yaml
name: Docker Build and Push

on:
  push:
    branches: [ main ]
    tags:
      - 'v*'
  pull_request:
    branches: [ main ]

env:
  REGISTRY: docker.io
  IMAGE_NAME: your-username/renqing-wanglai

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Log into Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v4
        with:
          images: ${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=raw,value=latest,enable={{is_default_branch}}

      - name: Build and push Docker image
        uses: docker/build-push-action@v4
        with:
          context: .
          push: ${{ github.event_name != 'pull_request' }}
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

**配置步骤:**
1. 在 GitHub 仓库设置中添加 Secrets:
   - `DOCKER_USERNAME`: Docker Hub 用户名
   - `DOCKER_PASSWORD`: Docker Hub 密码或访问令牌

2. 提交代码到 main 分支或打标签触发自动构建

---

## 镜像标签策略

### 推荐的标签方案

```bash
# latest - 最新稳定版本
docker tag your-username/renqing-wanglai:v1.0.0 your-username/renqing-wanglai:latest

# 版本号 - 特定版本
docker tag your-username/renqing-wanglai:v1.0.0 your-username/renqing-wanglai:1.0
docker tag your-username/renqing-wanglai:v1.0.0 your-username/renqing-wanglai:1

# dev - 开发版本
docker tag your-username/renqing-wanglai:dev your-username/renqing-wanglai:dev

# 推送所有标签
docker push --all-tags your-username/renqing-wanglai
```

---

## 优化镜像大小

### 1. 使用 .dockerignore

创建 `.dockerignore`:
```
node_modules
npm-debug.log
.git
.gitignore
README.md
DEPLOYMENT.md
docker-compose.yml
data/
*.md
.DS_Store
```

### 2. 多阶段构建

已在 Dockerfile 中实现，使用 Alpine 基础镜像。

### 3. 查看镜像大小

```bash
docker images | grep renqing-wanglai
```

---

## 创建 Docker Hub 仓库描述

登录 Docker Hub 后，在仓库页面添加以下描述:

### Short Description
```
人情往来记录系统 - 管理随礼还礼的智能工具
```

### Full Description
```markdown
# 人情往来记录系统

一个用于记录和管理人情往来、随礼还礼的智能 Web 应用。

## 功能特点

- 📝 记录收礼/送礼明细
- 📖 礼薄管理（办事收礼登记）
- 👥 亲友录（智能联想输入）
- 📊 统计分析（年度/事由统计）
- 🔐 密码保护（数据安全）
- 💾 数据持久化存储
- 📱 响应式设计（支持移动端）

## 快速开始

### 运行容器

\`\`\`bash
docker run -d \
  --name renqing-wanglai \
  -p 3000:3000 \
  -v ~/renqing-data:/app/data \
  --restart unless-stopped \
  your-username/renqing-wanglai:latest
\`\`\`

### 访问应用

浏览器访问: http://localhost:3000

默认密码: `admin`

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| PORT | 3000 | 应用端口 |
| DATA_DIR | /app/data | 数据目录 |
| NODE_ENV | production | 运行环境 |

## 数据持久化

数据存储在挂载的 `/app/data` 目录:
- `records.json` - 人情往来记录
- `giftbooks.json` - 礼薄数据

## 文档

- [GitHub 仓库](https://github.com/your-username/renqing-wanglai)
- [部署文档](https://github.com/your-username/renqing-wanglai/blob/main/DEPLOYMENT.md)
- [使用指南](https://github.com/your-username/renqing-wanglai/blob/main/README.md)

## 技术栈

- 前端: HTML5, CSS3, JavaScript
- 后端: Node.js + Express
- 存储: JSON 文件
- 容器: Docker

## 许可证

MIT License

## 支持

如有问题，请提交 [Issue](https://github.com/your-username/renqing-wanglai/issues)
\`\`\`

---

## 查看镜像信息

```bash
# 查看镜像详情
docker inspect your-username/renqing-wanglai:latest

# 查看镜像层
docker history your-username/renqing-wanglai:latest
```

---

## 删除旧版本镜像

```bash
# 删除本地镜像
docker rmi your-username/renqing-wanglai:v0.9.0

# 在 Docker Hub 网页端删除旧标签
# 登录 Docker Hub -> 进入仓库 -> Tags -> 删除
```

---

## 常见问题

### 1. 推送失败

```bash
# 重新登录
docker logout
docker login

# 检查镜像名称格式
docker images | grep renqing
```

### 2. 镜像过大

```bash
# 压缩镜像
docker image save your-username/renqing-wanglai:latest | gzip > renqing.tar.gz

# 查看镜像各层大小
docker history your-username/renqing-wanglai:latest --no-trunc
```

### 3. 更新镜像

```bash
# 重新构建
docker build --no-cache -t your-username/renqing-wanglai:latest .

# 推送更新
docker push your-username/renqing-wanglai:latest
```

---

## 镜像维护

### 定期更新基础镜像

```bash
# 拉取最新基础镜像
docker pull node:18-alpine

# 重新构建
docker build -t your-username/renqing-wanglai:latest .

# 推送更新
docker push your-username/renqing-wanglai:latest
```

### 安全扫描

```bash
# 使用 Docker Scout 扫描
docker scout cves your-username/renqing-wanglai:latest

# 使用 Trivy 扫描
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image your-username/renqing-wanglai:latest
```

---

**注意事项:**
1. 确保 Dockerfile 在项目根目录
2. 替换所有 `your-username` 为实际的 Docker Hub 用户名
3. 推送前务必测试镜像
4. 生产环境建议使用固定版本号
5. 定期更新基础镜像和依赖
