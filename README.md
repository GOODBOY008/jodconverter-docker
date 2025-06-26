# JODConverter Docker Images - 统一仓库

[![Docker Build](https://github.com/your-org/jodconverter-docker/actions/workflows/docker.yml/badge.svg)](https://github.com/your-org/jodconverter-docker/actions/workflows/docker.yml)

这是一个将 [jodconverter-runtime](https://github.com/jodconverter/docker-image-jodconverter-runtime) 和 [jodconverter-examples](https://github.com/jodconverter/docker-image-jodconverter-examples) 合并的统一 Docker 构建仓库。

## 项目结构

```text
├── runtime/                    # Runtime 镜像 (基础镜像)
│   └── Dockerfile             # 包含 LibreOffice + Java 运行时环境
├── examples/                   # Examples 镜像 (应用镜像)
│   ├── Dockerfile             # 基于 runtime 镜像构建的示例应用
│   └── bin/
│       └── docker-entrypoint.sh
├── scripts/
│   └── build.sh              # 统一构建脚本
├── Makefile                   # 便捷的构建命令
└── README.md                  # 项目文档
```

## 镜像依赖关系

```text
runtime (JRE/JDK) 
    ↓
examples (GUI/REST)
```

- **runtime**: 提供 LibreOffice + OpenJDK 的基础运行环境
- **examples**: 基于 runtime 构建的 JODConverter 示例应用

## 快速开始

### 构建所有镜像

```bash
# 使用 Makefile (推荐)
make build

# 或使用构建脚本
./scripts/build.sh
```

### 运行示例

#### GUI 版本 (Web界面)

```bash
make start-gui
# 或
docker run --rm -p 8080:8080 --memory 512m local/jodconverter-examples:gui
```

访问 [http://localhost:8080](http://localhost:8080) 查看 Web UI

#### REST 版本 (仅API)

```bash
make start-rest
# 或  
docker run --rm -p 8080:8080 --memory 512m local/jodconverter-examples:rest
```

## 构建选项

### 基础构建

```bash
# 构建所有镜像
make build

# 只构建 runtime 镜像
make build-runtime

# 只构建 examples 镜像
make build-examples
```

### 自定义配置

```bash
# 指定注册表和版本
make build REGISTRY=ghcr.io/myorg VERSION=1.0.0

# 指定 Java 版本
make build JAVA_VERSION=17

# 构建并推送到注册表
make push REGISTRY=ghcr.io/myorg
```

### 使用构建脚本

```bash
# 查看所有选项
./scripts/build.sh --help

# 构建特定版本
./scripts/build.sh --registry ghcr.io/myorg --version 1.0.0 --java-version 17

# 只构建 runtime
./scripts/build.sh --runtime-only

# 构建并推送
./scripts/build.sh --registry ghcr.io/myorg --push
```

## 生成的镜像

构建完成后，你将获得以下镜像：

### Runtime 镜像

- `local/jodconverter-runtime:latest` (JRE 版本)
- `local/jodconverter-runtime:jre-latest`
- `local/jodconverter-runtime:jdk-latest`

### Examples 镜像

- `local/jodconverter-examples:gui`
- `local/jodconverter-examples:rest`

## 高级用法

### 应用配置

你可以通过挂载配置文件来自定义应用设置：

```bash
docker run --rm -p 8080:8080 \
  -v $(pwd)/application.properties:/etc/app/application.properties \
  local/jodconverter-examples:gui
```

示例 `application.properties`:

```properties
# LibreOffice 实例数量
jodconverter.local.port-numbers=2002,2003
# 临时文件夹
jodconverter.local.working-dir=/tmp
# 上传文件大小限制
spring.servlet.multipart.max-file-size=5MB
spring.servlet.multipart.max-request-size=5MB
# 服务端口
server.port=8090
```

### 环境变量

支持的环境变量：

- `JAVA_OPTS`: JVM 参数
- `SPRING_PROFILES_ACTIVE`: Spring 配置文件

### 内存限制

建议为容器设置内存限制：

```bash
docker run --memory 512m --rm -p 8080:8080 local/jodconverter-examples:gui
```

## 开发

### 本地开发构建

```bash
# 开发构建（不推送）
make build

# 清理镜像
make clean

# 查看已构建的镜像
make list
```

### CI/CD 构建

```bash
# 生产构建并推送
make push REGISTRY=ghcr.io/myorg VERSION=$(git describe --tags)
```

## 故障排除

### 常见问题

1. **构建失败**: 确保 Docker 有足够的内存和磁盘空间
2. **Runtime 镜像不存在**: 先构建 runtime 镜像再构建 examples
3. **端口冲突**: 确保 8080 端口没有被占用

### 查看日志

```bash
# 查看容器日志
docker logs jodconverter-gui

# 实时查看日志
docker logs -f jodconverter-rest
```

### 调试模式

```bash
# 进入容器调试
docker run --rm -it --entrypoint /bin/bash local/jodconverter-examples:gui
```

## 贡献

欢迎提交问题和改进建议！

### 开发流程

1. Fork 此仓库
2. 创建功能分支
3. 提交更改
4. 创建 Pull Request

## 许可证

MIT License - 参见 [LICENSE](LICENSE) 文件

## 致谢

- [JODConverter](https://github.com/jodconverter/jodconverter) - 核心转换库
- [LibreOffice](https://www.libreoffice.org/) - 提供文档转换能力
- 原始项目维护者 [EugenMayer](https://github.com/EugenMayer) 和 [jodconverter](https://github.com/jodconverter) 团队

## 相关项目

- [原始 Runtime 项目](https://github.com/jodconverter/docker-image-jodconverter-runtime)
- [原始 Examples 项目](https://github.com/jodconverter/docker-image-jodconverter-examples)
- [JODConverter 主项目](https://github.com/jodconverter/jodconverter)
- [生产级转换服务](https://github.com/EugenMayer/officeconverter)
