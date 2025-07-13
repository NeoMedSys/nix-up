#!/usr/bin/env bash
# Perseus Deployment Helper
# Makes it easy to deploy with custom configurations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
PERSEUS_USER=${PERSEUS_USER:-"algol"}
PERSEUS_BROWSERS=${PERSEUS_BROWSERS:-"brave"}
PERSEUS_DEV_TOOLS=${PERSEUS_DEV_TOOLS:-""}
PERSEUS_LAPTOP=${PERSEUS_LAPTOP:-"true"}
PERSEUS_GPU=${PERSEUS_GPU:-"true"}
GITHUB_REPO=""
TARGET_HOST=""
CONFIG_TYPE="perseus"

show_help() {
    echo -e "${BLUE}🌌 Perseus Deployment Helper${NC}"
    echo "=================================="
    echo ""
    echo "Usage: $0 [OPTIONS] <github-repo> <target-host>"
    echo ""
    echo -e "${YELLOW}Arguments:${NC}"
    echo "  github-repo    GitHub repository (e.g., yourusername/perseus)"
    echo "  target-host    Target host (e.g., root@192.168.1.100)"
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo "  -u, --user USER           Username (default: algol)"
    echo "  -b, --browsers BROWSERS   Comma-separated browsers (default: brave)"
    echo "  -d, --dev-tools TOOLS     Comma-separated dev tools (default: none)"
    echo "                            Options: python,go,rust,nextjs"
    echo "  -l, --laptop BOOL         Laptop optimizations true/false (default: true)"
    echo "  -g, --gpu BOOL            GPU support true/false (default: true)"
    echo "  -c, --config TYPE         Config type: perseus/perseus-desktop/perseus-server (default: perseus)"
    echo "  -t, --tag TAG             Git tag/version (default: latest)"
    echo "  -h, --help                Show this help"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  # Default deployment"
    echo "  $0 yourusername/perseus root@192.168.1.100"
    echo ""
    echo "  # Custom user with dev tools"
    echo "  $0 -u alice -d python,rust,nextjs yourusername/perseus root@192.168.1.100"
    echo ""
    echo "  # Full development setup"
    echo "  $0 -d python,go,rust,nextjs -b firefox,chromium yourusername/perseus root@192.168.1.100"
    echo ""
    echo "  # Server deployment (python and go only)"
    echo "  $0 -c perseus-server -d python,go yourusername/perseus root@192.168.1.100"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--user)
            PERSEUS_USER="$2"
            shift 2
            ;;
        -b|--browsers)
            PERSEUS_BROWSERS="$2"
            shift 2
            ;;
        -d|--dev-tools)
            PERSEUS_DEV_TOOLS="$2"
            shift 2
            ;;
        -l|--laptop)
            PERSEUS_LAPTOP="$2"
            shift 2
            ;;
        -g|--gpu)
            PERSEUS_GPU="$2"
            shift 2
            ;;
        -c|--config)
            CONFIG_TYPE="$2"
            shift 2
            ;;
        -t|--tag)
            GIT_TAG="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*|--*)
            echo -e "${RED}❌ Unknown option $1${NC}"
            exit 1
            ;;
        *)
            if [[ -z "$GITHUB_REPO" ]]; then
                GITHUB_REPO="$1"
            elif [[ -z "$TARGET_HOST" ]]; then
                TARGET_HOST="$1"
            else
                echo -e "${RED}❌ Too many positional arguments${NC}"
                exit 1
            fi
            shift
            ;;
    esac
done

# Check required arguments
if [[ -z "$GITHUB_REPO" ]] || [[ -z "$TARGET_HOST" ]]; then
    echo -e "${RED}❌ Missing required arguments${NC}"
    echo ""
    show_help
    exit 1
fi

# Build flake URL
if [[ -n "$GIT_TAG" ]]; then
    FLAKE_URL="github:${GITHUB_REPO}/${GIT_TAG}#${CONFIG_TYPE}"
else
    FLAKE_URL="github:${GITHUB_REPO}#${CONFIG_TYPE}"
fi

# Show configuration
echo -e "${BLUE}🌌 Perseus Deployment Configuration${NC}"
echo "====================================="
echo -e "${YELLOW}User:${NC}         $PERSEUS_USER"
echo -e "${YELLOW}Browsers:${NC}     $PERSEUS_BROWSERS"
echo -e "${YELLOW}Dev Tools:${NC}    $PERSEUS_DEV_TOOLS"
echo -e "${YELLOW}Laptop:${NC}       $PERSEUS_LAPTOP"
echo -e "${YELLOW}GPU:${NC}          $PERSEUS_GPU"
echo -e "${YELLOW}Config:${NC}       $CONFIG_TYPE"
echo -e "${YELLOW}Flake URL:${NC}    $FLAKE_URL"
echo -e "${YELLOW}Target:${NC}       $TARGET_HOST"
echo ""

# Confirm deployment
read -p "$(echo -e ${YELLOW}"🤔 Deploy with these settings? (y/N): "${NC})" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}🚫 Deployment cancelled${NC}"
    exit 0
fi

# Export environment variables
export PERSEUS_USER
export PERSEUS_BROWSERS  
export PERSEUS_DEV_TOOLS
export PERSEUS_LAPTOP
export PERSEUS_GPU

# Run nixos-anywhere
echo -e "${GREEN}🚀 Starting deployment...${NC}"
echo ""

if command -v nixos-anywhere >/dev/null 2>&1; then
    nixos-anywhere --flake "$FLAKE_URL" "$TARGET_HOST"
    echo ""
    echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
else
    echo -e "${RED}❌ nixos-anywhere not found. Please install it first:${NC}"
    echo "nix run github:nix-community/nixos-anywhere"
    exit 1
fi
