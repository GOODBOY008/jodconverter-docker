#!/bin/bash

# JODConverter Docker Images - Test Script
# This script tests the built images to ensure they work correctly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
REGISTRY="local"
VERSION="latest"
TEST_PORT_GUI=8080
TEST_PORT_REST=8081
TIMEOUT=60

echo -e "${BLUE}=== JODConverter Docker Images Test Suite ===${NC}"
echo -e "Registry: ${YELLOW}${REGISTRY}${NC}"
echo -e "Version: ${YELLOW}${VERSION}${NC}"
echo ""

# Function to wait for service to be ready
wait_for_service() {
    local url=$1
    local name=$2
    local timeout=$3
    
    echo -e "${BLUE}Waiting for ${name} to be ready...${NC}"
    
    for i in $(seq 1 $timeout); do
        if curl -f -s "$url" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ ${name} is ready!${NC}"
            return 0
        fi
        echo -n "."
        sleep 1
    done
    
    echo -e "${RED}✗ ${name} failed to start within ${timeout} seconds${NC}"
    return 1
}

# Function to test image
test_image() {
    local image_name=$1
    local container_name=$2
    local port=$3
    local service_name=$4
    
    echo -e "${BLUE}Testing ${service_name} (${image_name})...${NC}"
    
    # Stop any existing container
    docker stop "$container_name" 2>/dev/null || true
    docker rm "$container_name" 2>/dev/null || true
    
    # Start the container
    echo -e "${YELLOW}Starting container ${container_name}...${NC}"
    docker run -d --name "$container_name" -p "$port:8080" --memory 512m "$image_name"
    
    # Wait for service to be ready
    if wait_for_service "http://localhost:$port" "$service_name" $TIMEOUT; then
        echo -e "${GREEN}✓ ${service_name} test passed${NC}"
        
        # Additional health checks
        echo -e "${BLUE}Running additional health checks...${NC}"
        
        # Check if service responds to health endpoint (if available)
        if curl -f -s "http://localhost:$port/actuator/health" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Health endpoint is accessible${NC}"
        else
            echo -e "${YELLOW}⚠ Health endpoint not available (this is normal for some versions)${NC}"
        fi
        
        # Test basic HTML response
        if curl -s "http://localhost:$port" | grep -i "jodconverter\|convert\|upload" > /dev/null; then
            echo -e "${GREEN}✓ Service contains expected content${NC}"
        else
            echo -e "${YELLOW}⚠ Service response doesn't contain expected keywords${NC}"
        fi
        
        # Stop the container
        docker stop "$container_name"
        docker rm "$container_name"
        
        return 0
    else
        echo -e "${RED}✗ ${service_name} test failed${NC}"
        
        # Show logs for debugging
        echo -e "${RED}Container logs:${NC}"
        docker logs "$container_name" | tail -20
        
        # Cleanup
        docker stop "$container_name" 2>/dev/null || true
        docker rm "$container_name" 2>/dev/null || true
        
        return 1
    fi
}

# Check if images exist
echo -e "${BLUE}Checking if images exist...${NC}"

GUI_IMAGE="${REGISTRY}/jodconverter-examples:gui"
REST_IMAGE="${REGISTRY}/jodconverter-examples:rest"

if ! docker image inspect "$GUI_IMAGE" >/dev/null 2>&1; then
    echo -e "${RED}✗ GUI image ${GUI_IMAGE} not found${NC}"
    echo -e "${YELLOW}Please build the images first: make build${NC}"
    exit 1
fi

if ! docker image inspect "$REST_IMAGE" >/dev/null 2>&1; then
    echo -e "${RED}✗ REST image ${REST_IMAGE} not found${NC}"
    echo -e "${YELLOW}Please build the images first: make build${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All required images found${NC}"
echo ""

# Test GUI image
echo -e "${BLUE}=== Testing GUI Image ===${NC}"
if test_image "$GUI_IMAGE" "test-jodconverter-gui" $TEST_PORT_GUI "JODConverter GUI"; then
    GUI_TEST_PASSED=true
else
    GUI_TEST_PASSED=false
fi
echo ""

# Test REST image
echo -e "${BLUE}=== Testing REST Image ===${NC}"
if test_image "$REST_IMAGE" "test-jodconverter-rest" $TEST_PORT_REST "JODConverter REST"; then
    REST_TEST_PASSED=true
else
    REST_TEST_PASSED=false
fi
echo ""

# Summary
echo -e "${BLUE}=== Test Summary ===${NC}"
if [ "$GUI_TEST_PASSED" = true ]; then
    echo -e "${GREEN}✓ GUI image test: PASSED${NC}"
else
    echo -e "${RED}✗ GUI image test: FAILED${NC}"
fi

if [ "$REST_TEST_PASSED" = true ]; then
    echo -e "${GREEN}✓ REST image test: PASSED${NC}"
else
    echo -e "${RED}✗ REST image test: FAILED${NC}"
fi

echo ""

if [ "$GUI_TEST_PASSED" = true ] && [ "$REST_TEST_PASSED" = true ]; then
    echo -e "${GREEN}🎉 All tests passed! Images are working correctly.${NC}"
    echo ""
    echo -e "${BLUE}Quick start commands:${NC}"
    echo -e "  ${YELLOW}docker run --rm -p 8080:8080 ${GUI_IMAGE}${NC}  # GUI version"
    echo -e "  ${YELLOW}docker run --rm -p 8080:8080 ${REST_IMAGE}${NC} # REST version"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Please check the logs above.${NC}"
    exit 1
fi
