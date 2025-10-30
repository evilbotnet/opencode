#!/bin/bash
# Helper script to run OpenCode with split-screen in Docker

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
IMAGE_NAME="opencode-split-screen:latest"
PROJECT_DIR="${PROJECT_DIR:-$(pwd)}"
DATA_DIR="${DATA_DIR:-$HOME/.opencode}"
DOCKERFILE="${DOCKERFILE:-Dockerfile}"

# Functions
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] [COMMAND]

OpenCode Split-Screen Docker Helper

COMMANDS:
    build       Build the Docker image
    run         Run OpenCode TUI (default)
    shell       Open a shell in the container
    clean       Remove the Docker image and volumes
    logs        Show container logs

OPTIONS:
    -p, --project DIR    Project directory to mount (default: current directory)
    -d, --data DIR       OpenCode data directory (default: ~/.opencode)
    -i, --image NAME     Docker image name (default: opencode-split-screen:latest)
    -f, --file FILE      Dockerfile to use (default: Dockerfile)
    -h, --help           Show this help message

ENVIRONMENT VARIABLES:
    ANTHROPIC_API_KEY    Your Anthropic API key
    OPENAI_API_KEY       Your OpenAI API key
    PROJECT_DIR          Project directory to mount
    DATA_DIR             OpenCode data directory

EXAMPLES:
    # Build the image
    $0 build

    # Run with default settings
    $0 run

    # Run with specific project directory
    $0 -p /path/to/project run

    # Open a shell for debugging
    $0 shell

EOF
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
}

build_image() {
    print_info "Building Docker image: $IMAGE_NAME"
    print_info "Using Dockerfile: $DOCKERFILE"
    docker build -f "$DOCKERFILE" -t "$IMAGE_NAME" .
    print_info "Build complete!"
}

run_container() {
    print_info "Starting OpenCode split-screen TUI..."
    print_info "Project directory: $PROJECT_DIR"
    print_info "Data directory: $DATA_DIR"
    print_info ""
    print_info "Use Ctrl+W to switch between terminal and OpenCode panes"
    print_info "Press Ctrl+C twice to exit"
    print_info ""

    # Check if .env file exists
    ENV_FILE=""
    if [ -f .env ]; then
        ENV_FILE="--env-file .env"
        print_info "Loading environment from .env file"
    fi

    # Run the container
    # Mount project directory to /project to avoid overwriting the built app
    docker run -it --rm \
        $ENV_FILE \
        -v "$DATA_DIR:/root/.opencode" \
        -v "$PROJECT_DIR:/project" \
        -w /project \
        --hostname opencode \
        "$IMAGE_NAME" \
        "$@"
}

run_shell() {
    print_info "Opening shell in OpenCode container..."
    docker run -it --rm \
        -v "$DATA_DIR:/root/.opencode" \
        -v "$PROJECT_DIR:/project" \
        -w /project \
        --entrypoint /bin/bash \
        "$IMAGE_NAME"
}

clean_docker() {
    print_warn "This will remove the Docker image and associated volumes."
    read -p "Are you sure? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Removing Docker image: $IMAGE_NAME"
        docker rmi "$IMAGE_NAME" 2>/dev/null || print_warn "Image not found"

        print_info "Removing Docker volumes..."
        docker volume ls -q | grep opencode | xargs docker volume rm 2>/dev/null || print_warn "No volumes found"

        print_info "Cleanup complete!"
    else
        print_info "Cleanup cancelled"
    fi
}

show_logs() {
    docker logs -f $(docker ps -q --filter ancestor="$IMAGE_NAME") 2>/dev/null || \
        print_error "No running container found"
}

# Parse arguments
COMMAND=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--project)
            PROJECT_DIR="$2"
            shift 2
            ;;
        -d|--data)
            DATA_DIR="$2"
            shift 2
            ;;
        -i|--image)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -f|--file)
            DOCKERFILE="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        build|run|shell|clean|logs)
            COMMAND="$1"
            shift
            break
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Default command
if [ -z "$COMMAND" ]; then
    COMMAND="run"
fi

# Check Docker is installed
check_docker

# Execute command
case $COMMAND in
    build)
        build_image
        ;;
    run)
        run_container "$@"
        ;;
    shell)
        run_shell
        ;;
    clean)
        clean_docker
        ;;
    logs)
        show_logs
        ;;
    *)
        print_error "Unknown command: $COMMAND"
        show_usage
        exit 1
        ;;
esac
