<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# JODConverter Docker Images Project Instructions

This is a unified Docker repository that combines both jodconverter-runtime and jodconverter-examples into a single codebase with proper dependency management.

## Project Structure
- `runtime/`: Contains the base runtime image with LibreOffice and Java
- `examples/`: Contains the application images that depend on the runtime image
- `scripts/`: Build automation scripts
- `Makefile`: Convenient build commands

## Key Technologies
- Docker multi-stage builds
- LibreOffice headless mode
- JODConverter (Java-based document converter)
- Spring Boot (for the example applications)
- OpenJDK/Eclipse Temurin

## Build Dependencies
The images have a clear dependency chain:
- runtime (JRE/JDK) → examples (GUI/REST)
- Always build runtime images before examples images

## Coding Guidelines
- Use multi-stage Dockerfiles for efficiency
- Maintain consistent naming conventions for images
- Include proper error handling in shell scripts
- Use environment variables for configuration
- Follow Docker best practices for layer caching
- Ensure proper file permissions and security

## Common Tasks
- Building images: Use `make build` or `./scripts/build.sh`
- Running examples: Use `make start-gui` or `make start-rest`
- Cleaning up: Use `make clean`
- Custom builds: Use build script parameters for registries and versions
