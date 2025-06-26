# 快速开始指南

## 🚀 快速启动

### 1. 构建所有镜像
```bash
make build
```

### 2. 启动服务

#### GUI 版本 (Web界面)
```bash
make start-gui
```

然后访问 [http://localhost:8080](http://localhost:8080)

#### REST API 版本
```bash
make start-rest
```

然后访问 [http://localhost:8080](http://localhost:8080) 查看 API

## 🧪 测试

运行自动化测试：
```bash
./scripts/test.sh
```

## 🔧 开发

### VS Code 任务
按 `Cmd+Shift+P` (macOS) 或 `Ctrl+Shift+P` (Windows/Linux)，然后选择 `Tasks: Run Task`：

- **Build All Images** - 构建所有镜像
- **Build Runtime Only** - 只构建runtime镜像
- **Build Examples Only** - 只构建examples镜像
- **Start GUI Example** - 启动GUI示例
- **Start REST Example** - 启动REST示例
- **Stop All Containers** - 停止所有容器
- **Clean Images** - 清理所有镜像
- **List Images** - 列出所有镜像

### Docker Compose
```bash
# 启动GUI服务
docker-compose up -d jodconverter-gui

# 启动REST服务
docker-compose --profile rest up -d jodconverter-rest

# 停止所有服务
docker-compose down
```

## 📝 常用命令

```bash
# 查看帮助
make help
./scripts/build.sh --help

# 构建特定版本
make build VERSION=1.0.0

# 推送到注册表
make push REGISTRY=ghcr.io/myorg

# 清理
make clean

# 查看镜像
make list
```

## 🐛 故障排除

如果遇到问题：

1. 检查 Docker 是否运行
2. 确保端口 8080 没有被占用
3. 查看容器日志：`docker logs <container-name>`
4. 运行测试脚本：`./scripts/test.sh`

## 📚 更多信息

详细文档请查看 [README.md](README.md)
