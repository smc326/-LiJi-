# 人情往来系统 - Docker Hub 一键部署脚本
# 适用于 Windows PowerShell

# 配置变量
$IMAGE_NAME = "your-dockerhub-username/renqing-wanglai"
$CONTAINER_NAME = "renqing-wanglai"
$DATA_DIR = "$env:USERPROFILE\renqing-data"
$PORT = 3000

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  人情往来系统 - Docker Hub 部署" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# 检查 Docker 是否运行
try {
    docker info | Out-Null
    Write-Host "✓ Docker 检查通过" -ForegroundColor Green
} catch {
    Write-Host "错误: Docker 未运行" -ForegroundColor Red
    Write-Host "请先启动 Docker Desktop" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# 询问配置
$userDataDir = Read-Host "请输入数据存储目录 (默认: $DATA_DIR)"
if ($userDataDir) { $DATA_DIR = $userDataDir }

$userPort = Read-Host "请输入访问端口 (默认: $PORT)"
if ($userPort) { $PORT = $userPort }

$dockerUser = Read-Host "请输入 Docker Hub 用户名 (默认: your-dockerhub-username)"
if ($dockerUser) {
    $IMAGE_NAME = "$dockerUser/renqing-wanglai"
} else {
    $dockerUser = "your-dockerhub-username"
}

Write-Host ""
Write-Host "配置信息:" -ForegroundColor Yellow
Write-Host "  镜像名称: $IMAGE_NAME`:latest"
Write-Host "  容器名称: $CONTAINER_NAME"
Write-Host "  数据目录: $DATA_DIR"
Write-Host "  访问端口: $PORT"
Write-Host ""

$confirm = Read-Host "确认部署? (y/n)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "部署已取消" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "开始部署..." -ForegroundColor Yellow
Write-Host ""

# 创建数据目录
Write-Host "[1/5] 创建数据目录..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $DATA_DIR -Force | Out-Null
Write-Host "✓ 数据目录创建成功: $DATA_DIR" -ForegroundColor Green
Write-Host ""

# 停止并删除旧容器
Write-Host "[2/5] 清理旧容器..." -ForegroundColor Cyan
$existing = docker ps -a --filter "name=$CONTAINER_NAME" --format "{{.Names}}"
if ($existing -eq $CONTAINER_NAME) {
    docker stop $CONTAINER_NAME 2>$null | Out-Null
    docker rm $CONTAINER_NAME 2>$null | Out-Null
    Write-Host "✓ 旧容器已清理" -ForegroundColor Green
} else {
    Write-Host "✓ 无需清理" -ForegroundColor Green
}
Write-Host ""

# 拉取最新镜像
Write-Host "[3/5] 拉取最新镜像..." -ForegroundColor Cyan
try {
    docker pull "$IMAGE_NAME`:latest" | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ 镜像拉取成功" -ForegroundColor Green
    } else {
        throw "镜像拉取失败"
    }
} catch {
    Write-Host "✗ 镜像拉取失败" -ForegroundColor Red
    Write-Host "请检查:" -ForegroundColor Yellow
    Write-Host "  1. Docker Hub 用户名是否正确"
    Write-Host "  2. 镜像是否存在"
    Write-Host "  3. 网络连接是否正常"
    exit 1
}
Write-Host ""

# 运行容器
Write-Host "[4/5] 启动容器..." -ForegroundColor Cyan
docker run -d `
  --name $CONTAINER_NAME `
  -p "${PORT}:3000" `
  -v "${DATA_DIR}:/app/data" `
  -e NODE_ENV=production `
  -e PORT=3000 `
  -e DATA_DIR=/app/data `
  --restart unless-stopped `
  "$IMAGE_NAME`:latest"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ 容器启动成功" -ForegroundColor Green
} else {
    Write-Host "✗ 容器启动失败" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 等待服务启动
Write-Host "[5/5] 等待服务启动..." -ForegroundColor Cyan
Start-Sleep -Seconds 5

# 检查容器状态
$running = docker ps --filter "name=$CONTAINER_NAME" --format "{{.Names}}"
if ($running -eq $CONTAINER_NAME) {
    Write-Host "✓ 服务运行正常" -ForegroundColor Green
    Write-Host ""
    Write-Host "======================================" -ForegroundColor Green
    Write-Host "  部署成功！" -ForegroundColor Green
    Write-Host "======================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "访问信息:" -ForegroundColor Cyan
    Write-Host "  本地访问: " -NoNewline -ForegroundColor White
    Write-Host "http://localhost:$PORT" -ForegroundColor Yellow
    
    # 获取本机IP
    try {
        $IP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.*" -or $_.IPAddress -like "10.*"} | Select-Object -First 1).IPAddress
        if ($IP) {
            Write-Host "  局域网访问: " -NoNewline -ForegroundColor White
            Write-Host "http://$IP`:$PORT" -ForegroundColor Yellow
        }
    } catch {}
    
    Write-Host "  默认密码: " -NoNewline -ForegroundColor White
    Write-Host "admin" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "数据目录:" -ForegroundColor Cyan
    Write-Host "  $DATA_DIR"
    Write-Host ""
    Write-Host "常用命令:" -ForegroundColor Cyan
    Write-Host "  查看日志: docker logs -f $CONTAINER_NAME"
    Write-Host "  停止服务: docker stop $CONTAINER_NAME"
    Write-Host "  启动服务: docker start $CONTAINER_NAME"
    Write-Host "  重启服务: docker restart $CONTAINER_NAME"
    Write-Host "  删除容器: docker rm -f $CONTAINER_NAME"
    Write-Host ""
    
    # 询问是否打开浏览器
    $openBrowser = Read-Host "是否在浏览器中打开? (y/n)"
    if ($openBrowser -eq "y" -or $openBrowser -eq "Y") {
        Start-Process "http://localhost:$PORT"
    }
} else {
    Write-Host "✗ 服务启动失败" -ForegroundColor Red
    Write-Host ""
    Write-Host "请查看日志：" -ForegroundColor Yellow
    Write-Host "  docker logs $CONTAINER_NAME"
    exit 1
}
