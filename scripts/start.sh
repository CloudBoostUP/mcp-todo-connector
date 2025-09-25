#!/bin/bash

# MCP Todo Connector Start Script (Linux/macOS)
# This script starts the MCP Todo Connector server with proper configuration

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${CYAN}$1${NC}"
}

# Default values
MODE="production"
PORT=""
LOG_LEVEL=""
DAEMON=false
WATCH=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dev)
            MODE="development"
            shift
            ;;
        -w|--watch)
            WATCH=true
            shift
            ;;
        --daemon)
            DAEMON=true
            shift
            ;;
        -p|--port)
            PORT="$2"
            shift 2
            ;;
        -l|--log-level)
            LOG_LEVEL="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -d, --dev          Run in development mode"
            echo "  -w, --watch        Enable file watching (development mode)"
            echo "  --daemon           Run as daemon (background process)"
            echo "  -p, --port PORT    Override port number"
            echo "  -l, --log-level    Set log level (debug, info, warn, error)"
            echo "  -h, --help         Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                 # Start in production mode"
            echo "  $0 --dev           # Start in development mode"
            echo "  $0 --dev --watch   # Start in development mode with file watching"
            echo "  $0 --daemon        # Start as background daemon"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Node.js is installed
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed. Please run setup.sh first."
        exit 1
    fi
    
    # Check if package.json exists
    if [ ! -f "package.json" ]; then
        print_error "package.json not found. Please run setup.sh first."
        exit 1
    fi
    
    # Check if node_modules exists
    if [ ! -d "node_modules" ]; then
        print_error "Dependencies not installed. Please run setup.sh first."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Load environment variables
load_environment() {
    print_status "Loading environment configuration..."
    
    if [ -f ".env" ]; then
        # Export variables from .env file
        set -a
        source .env
        set +a
        print_success "Environment variables loaded from .env"
    else
        print_warning ".env file not found, using default configuration"
    fi
    
    # Override with command line arguments
    if [ -n "$PORT" ]; then
        export PORT="$PORT"
        print_status "Port overridden to: $PORT"
    fi
    
    if [ -n "$LOG_LEVEL" ]; then
        export LOG_LEVEL="$LOG_LEVEL"
        print_status "Log level overridden to: $LOG_LEVEL"
    fi
    
    # Set mode-specific environment variables
    if [ "$MODE" = "development" ]; then
        export NODE_ENV="development"
        export DEBUG="${DEBUG:-mcp:*}"
        print_status "Running in development mode"
    else
        export NODE_ENV="production"
        print_status "Running in production mode"
    fi
}

# Create necessary directories and files
prepare_runtime() {
    print_status "Preparing runtime environment..."
    
    # Create data directory if it doesn't exist
    mkdir -p data
    mkdir -p logs
    
    # Create initial todos.json if it doesn't exist
    if [ ! -f "data/todos.json" ]; then
        cat > data/todos.json << 'EOF'
{
  "todos": [],
  "categories": ["personal", "work", "shopping", "health"],
  "tags": ["urgent", "important", "quick", "meeting", "review"],
  "metadata": {
    "version": "1.0.0",
    "created": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "lastModified": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  }
}
EOF
        print_success "Created initial todos.json"
    fi
    
    print_success "Runtime environment prepared"
}

# Start the server
start_server() {
    print_status "Starting MCP Todo Connector server..."
    
    # Determine which command to use
    local start_command=""
    local log_file="logs/server.log"
    
    if [ "$MODE" = "development" ] && [ "$WATCH" = true ]; then
        start_command="npm run dev"
        print_status "Starting with file watching enabled"
    elif [ "$MODE" = "development" ]; then
        start_command="node index.js"
        print_status "Starting in development mode"
    else
        start_command="npm start"
        print_status "Starting in production mode"
    fi
    
    # Create log file
    mkdir -p logs
    touch "$log_file"
    
    if [ "$DAEMON" = true ]; then
        print_status "Starting as daemon process..."
        print_status "Logs will be written to: $log_file"
        
        # Start as daemon
        nohup $start_command > "$log_file" 2>&1 &
        local pid=$!
        
        # Save PID for later management
        echo $pid > logs/server.pid
        
        # Wait a moment to check if process started successfully
        sleep 2
        
        if kill -0 $pid 2>/dev/null; then
            print_success "Server started successfully as daemon (PID: $pid)"
            print_status "To stop the server: kill $pid"
            print_status "To view logs: tail -f $log_file"
        else
            print_error "Failed to start server as daemon"
            exit 1
        fi
    else
        print_status "Starting in foreground mode..."
        print_status "Press Ctrl+C to stop the server"
        
        # Start in foreground
        exec $start_command
    fi
}

# Display server information
show_server_info() {
    local port="${PORT:-3000}"
    local host="${HOST:-localhost}"
    
    echo ""
    print_header "======================================"
    print_header "  MCP Todo Connector Server"
    print_header "======================================"
    echo ""
    print_status "Server Configuration:"
    echo "  • Mode: $MODE"
    echo "  • Host: $host"
    echo "  • Port: $port"
    echo "  • Log Level: ${LOG_LEVEL:-info}"
    echo "  • Data Path: ${TODO_STORAGE_PATH:-./data/todos.json}"
    echo ""
    
    if [ "$DAEMON" = false ]; then
        print_status "Server will start momentarily..."
        echo ""
    fi
}

# Handle cleanup on exit
cleanup() {
    echo ""
    print_status "Shutting down server..."
    
    # Kill any child processes
    jobs -p | xargs -r kill
    
    print_success "Server stopped"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Main execution
main() {
    show_server_info
    check_prerequisites
    load_environment
    prepare_runtime
    start_server
}

# Run main function
main "$@"