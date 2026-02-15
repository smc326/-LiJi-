# 快速启动脚本

# Windows PowerShell 版本
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  人情往来系统 - 部署选择" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 询问部署方式
Write-Host "请选择部署方式:" -ForegroundColor Yellow
Write-Host "  1. Docker Hub 镜像部署 (推荐，快速)" -ForegroundColor White
Write-Host "  2. 本地构建部署 (需要构建镜像)" -ForegroundColor White
Write-Host ""

$choice = Read-Host "请输入选择 (1/2)"

if ($choice -eq "1") {
    # Docker Hub 部署
    Write-Host "\n正在使用 Docker Hub 镜像部署..." -ForegroundColor Green
    
    # 检查 Docker 是否运行
    $dockerRunning = docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "错误: Docker 未运行，请先启动 Docker Desktop" -ForegroundColor Red
        exit 1
    }
    
    # 拉取最新镜像
    Write-Host "拉取最新镜像..." -ForegroundColor Yellow
    docker pull your-dockerhub-username/renqing-wanglai:latest
    
    # 创建数据目录
    Write-Host "创建数据目录..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path "$env:USERPROFILE\renqing-data" -Force | Out-Null
    
    # 检查是否已有同名容器
    $existingContainer = docker ps -a --filter "name=renqing-wanglai" --format "{{.Names}}"
    if ($existingContainer -eq "renqing-wanglai") {
        Write-Host "停止并移除现有容器..." -ForegroundColor Yellow
        docker stop renqing-wanglai 2>$null
        docker rm renqing-wanglai 2>$null
    }
    
    # 运行容器
    Write-Host "启动容器..." -ForegroundColor Yellow
    docker run -d `
      --name renqing-wanglai `
      -p 3000:3000 `
      -v "$env:USERPROFILE\renqing-data:/app/data" `
      --restart unless-stopped `
      your-dockerhub-username/renqing-wanglai:latest
    
} elseif ($choice -eq "2") {
    # 本地构建部署
    Write-Host "\n正在使用本地构建部署..." -ForegroundColor Green
    
    # 检查 Docker 是否运行
    $dockerRunning = docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "错误: Docker 未运行，请先启动 Docker Desktop" -ForegroundColor Red
        exit 1
    }
    
    # 构建并启动容器
    Write-Host "构建 Docker 镜像..." -ForegroundColor Yellow
    docker-compose build
    
    Write-Host "启动容器..." -ForegroundColor Yellow
    docker-compose up -d
} else {
    Write-Host "无效选择，退出部署" -ForegroundColor Red
    exit 1
}

# 等待服务启动
Write-Host "等待服务启动..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

# 检查健康状态
$maxAttempts = 10
$attempt = 0
$healthy = $false

while ($attempt -lt $maxAttempts -and -not $healthy) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000/health" -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            $healthy = $true
        }
    } catch {
        $attempt++
        Start-Sleep -Seconds 2
    }
}

if ($healthy) {
    Write-Host "`n" -NoNewline
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  人情往来系统已成功启动！" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "`n访问地址：" -ForegroundColor Cyan
    Write-Host "  本地访问: http://localhost:3000" -ForegroundColor White
    Write-Host "  局域网访问: http://" -NoNewline -ForegroundColor White
    Write-Host (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*" -and $_.IPAddress -notlike "169.254.*"} | Select-Object -First 1).IPAddress -NoNewline -ForegroundColor Yellow
    Write-Host ":3000" -ForegroundColor White
    Write-Host "`n数据存储: " -NoNewline -ForegroundColor Cyan
    if ($choice -eq "1") {
        Write-Host "$env:USERPROFILE\renqing-data" -ForegroundColor White
    } else {
        Write-Host ".\data\" -ForegroundColor White
    }
    Write-Host "`n常用命令：" -ForegroundColor Cyan
    if ($choice -eq "1") {
        Write-Host "  查看日志: docker logs -f renqing-wanglai" -ForegroundColor White
        Write-Host "  停止服务: docker stop renqing-wanglai" -ForegroundColor White
        Write-Host "  启动服务: docker start renqing-wanglai" -ForegroundColor White
        Write-Host "  重启服务: docker restart renqing-wanglai" -ForegroundColor White
    } else {
        Write-Host "  查看日志: docker-compose logs -f" -ForegroundColor White
        Write-Host "  停止服务: docker-compose down" -ForegroundColor White
        Write-Host "  重启服务: docker-compose restart" -ForegroundColor White
    }
    Write-Host "`n" -NoNewline
    
    # 询问是否打开浏览器
    $openBrowser = Read-Host "是否在浏览器中打开? (y/n)"
    if ($openBrowser -eq "y" -or $openBrowser -eq "Y") {
        Start-Process "http://localhost:3000"
    }
} else {
    Write-Host "`n服务启动失败，请查看日志：" -ForegroundColor Red
    if ($choice -eq "1") {
        Write-Host "  docker logs renqing-wanglai" -ForegroundColor Yellow
    } else {
        Write-Host "  docker-compose logs" -ForegroundColor Yellow
    }
}
