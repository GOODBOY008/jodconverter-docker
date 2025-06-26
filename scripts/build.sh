#!/bin/bash

# JODConverter Docker Images - Unified Build Script
# This script builds both runtime and examples images with proper dependencies

set -e

# Default values
REGISTRY="local"
RUNTIME_VERSION="latest"
JAVA_VERSION="21"
PUSH=false
BUILD_RUNTIME=true
BUILD_EXAMPLES=true

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Help function
show_help() {
    cat << EOF
JODConverter Docker Images Build Script

Usage: $0 [OPTIONS]

OPTIONS:
    -r, --registry REGISTRY     Docker registry prefix (default: local)
    -v, --version VERSION       Runtime image version tag (default: latest)
    -j, --java-version VERSION  Java version to use (default: 21)
    -p, --push                  Push images to registry after build
    --runtime-only              Build only runtime images
    --examples-only             Build only examples images
    -h, --help                  Show this help message

EXAMPLES:
    # Build all images locally
    $0

    # Build and push to registry
    $0 --registry ghcr.io/myorg --push

    # Build specific Java version
    $0 --java-version 17

    # Build only runtime images
    $0 --runtime-only

    # Build only examples images (requires runtime to exist)
    $0 --examples-only

NOTES:
    - Runtime images are built first as they are dependencies for examples
    - Both JRE and JDK variants of runtime are built
    - Examples include both GUI and REST variants
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--registry)
            REGISTRY="$2"
            shift 2
            ;;
        -v|--version)
            RUNTIME_VERSION="$2"
            shift 2
            ;;
        -j|--java-version)
            JAVA_VERSION="$2"
            shift 2
            ;;
        -p|--push)
            PUSH=true
            shift
            ;;
        --runtime-only)
            BUILD_EXAMPLES=false
            shift
            ;;
        --examples-only)
            BUILD_RUNTIME=false
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Print configuration
echo -e "${BLUE}=== JODConverter Docker Build Configuration ===${NC}"
echo -e "Registry: ${YELLOW}${REGISTRY}${NC}"
echo -e "Runtime Version: ${YELLOW}${RUNTIME_VERSION}${NC}"
echo -e "Java Version: ${YELLOW}${JAVA_VERSION}${NC}"
echo -e "Push to Registry: ${YELLOW}${PUSH}${NC}"
echo -e "Build Runtime: ${YELLOW}${BUILD_RUNTIME}${NC}"
echo -e "Build Examples: ${YELLOW}${BUILD_EXAMPLES}${NC}"
echo ""

# Function to build and optionally push image
build_and_push() {
    local image_name=$1
    local dockerfile_path=$2
    local build_args=$3
    local target=$4
    
    echo -e "${BLUE}Building ${image_name}...${NC}"
    
    if [ -n "$target" ]; then
        docker build --target "$target" $build_args -t "$image_name" -f "$dockerfile_path" .
    else
        docker build $build_args -t "$image_name" -f "$dockerfile_path" .
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Successfully built ${image_name}${NC}"
        
        if [ "$PUSH" = true ]; then
            echo -e "${BLUE}Pushing ${image_name}...${NC}"
            docker push "$image_name"
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ Successfully pushed ${image_name}${NC}"
            else
                echo -e "${RED}✗ Failed to push ${image_name}${NC}"
                return 1
            fi
        fi
    else
        echo -e "${RED}✗ Failed to build ${image_name}${NC}"
        return 1
    fi
}

# Build runtime images
if [ "$BUILD_RUNTIME" = true ]; then
    echo -e "${BLUE}=== Building Runtime Images ===${NC}"
    
    # Build JRE runtime
    build_and_push \
        "${REGISTRY}/jodconverter-runtime:jre-${RUNTIME_VERSION}" \
        "runtime/Dockerfile" \
        "--build-arg JAVA_VERSION=${JAVA_VERSION}" \
        "jre"
    
    # Build JDK runtime  
    build_and_push \
        "${REGISTRY}/jodconverter-runtime:jdk-${RUNTIME_VERSION}" \
        "runtime/Dockerfile" \
        "--build-arg JAVA_VERSION=${JAVA_VERSION}" \
        "jdk"
    
    # Tag without jre prefix for compatibility
    docker tag "${REGISTRY}/jodconverter-runtime:jre-${RUNTIME_VERSION}" "${REGISTRY}/jodconverter-runtime:${RUNTIME_VERSION}"
    
    if [ "$PUSH" = true ]; then
        docker push "${REGISTRY}/jodconverter-runtime:${RUNTIME_VERSION}"
    fi
    
    echo -e "${GREEN}✓ Runtime images completed${NC}"
    echo ""
fi

# Build examples images
if [ "$BUILD_EXAMPLES" = true ]; then
    echo -e "${BLUE}=== Building Examples Images ===${NC}"
    
    # Build GUI example
    build_and_push \
        "${REGISTRY}/jodconverter-examples:gui-${RUNTIME_VERSION}" \
        "examples/Dockerfile" \
        "--build-arg BASE_REGISTRY=${REGISTRY} --build-arg BASE_VERSION=jre-${RUNTIME_VERSION}" \
        "gui"
    
    # Build REST example
    build_and_push \
        "${REGISTRY}/jodconverter-examples:rest-${RUNTIME_VERSION}" \
        "examples/Dockerfile" \
        "--build-arg BASE_REGISTRY=${REGISTRY} --build-arg BASE_VERSION=jre-${RUNTIME_VERSION}" \
        "rest"
    
    # Tag without version suffix for compatibility
    docker tag "${REGISTRY}/jodconverter-examples:gui-${RUNTIME_VERSION}" "${REGISTRY}/jodconverter-examples:gui"
    docker tag "${REGISTRY}/jodconverter-examples:rest-${RUNTIME_VERSION}" "${REGISTRY}/jodconverter-examples:rest"
    
    if [ "$PUSH" = true ]; then
        docker push "${REGISTRY}/jodconverter-examples:gui"
        docker push "${REGISTRY}/jodconverter-examples:rest"
    fi
    
    echo -e "${GREEN}✓ Examples images completed${NC}"
    echo ""
fi

echo -e "${GREEN}=== Build Summary ===${NC}"
echo -e "${GREEN}All requested images have been built successfully!${NC}"
echo ""
echo -e "${BLUE}Available images:${NC}"
if [ "$BUILD_RUNTIME" = true ]; then
    echo -e "  • ${YELLOW}${REGISTRY}/jodconverter-runtime:${RUNTIME_VERSION}${NC} (JRE)"
    echo -e "  • ${YELLOW}${REGISTRY}/jodconverter-runtime:jre-${RUNTIME_VERSION}${NC}"
    echo -e "  • ${YELLOW}${REGISTRY}/jodconverter-runtime:jdk-${RUNTIME_VERSION}${NC}"
fi
if [ "$BUILD_EXAMPLES" = true ]; then
    echo -e "  • ${YELLOW}${REGISTRY}/jodconverter-examples:gui${NC}"
    echo -e "  • ${YELLOW}${REGISTRY}/jodconverter-examples:rest${NC}"
    echo -e "  • ${YELLOW}${REGISTRY}/jodconverter-examples:gui-${RUNTIME_VERSION}${NC}"
    echo -e "  • ${YELLOW}${REGISTRY}/jodconverter-examples:rest-${RUNTIME_VERSION}${NC}"
fi
echo ""
echo -e "${BLUE}Quick start commands:${NC}"
echo -e "  # Run GUI example:"
echo -e "  ${YELLOW}docker run --rm -p 8080:8080 ${REGISTRY}/jodconverter-examples:gui${NC}"
echo -e ""
echo -e "  # Run REST example:"
echo -e "  ${YELLOW}docker run --rm -p 8080:8080 ${REGISTRY}/jodconverter-examples:rest${NC}"
