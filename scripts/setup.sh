#!/bin/bash

# MCP Todo Connector Setup Script (Linux/macOS)
# This script sets up the development environment for the MCP Todo Connector

set -e  # Exit on any error

echo "🚀 Setting up MCP Todo Connector..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Check if Node.js is installed
check_node() {
    print_status "Checking Node.js installation..."
    
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed. Please install Node.js 18.0.0 or higher."
        print_status "Visit: https://nodejs.org/en/download/"
        exit 1
    fi
    
    NODE_VERSION=$(node --version | cut -d'v' -f2)
    REQUIRED_VERSION="18.0.0"
    
    if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$NODE_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
        print_error "Node.js version $NODE_VERSION is too old. Please install version 18.0.0 or higher."
        exit 1
    fi
    
    print_success "Node.js version $NODE_VERSION is compatible"
}

# Check if npm is installed
check_npm() {
    print_status "Checking npm installation..."
    
    if ! command -v npm &> /dev/null; then
        print_error "npm is not installed. Please install npm."
        exit 1
    fi
    
    NPM_VERSION=$(npm --version)
    print_success "npm version $NPM_VERSION is available"
}

# Install dependencies
install_dependencies() {
    print_status "Installing dependencies..."
    
    if [ -f "package-lock.json" ]; then
        npm ci
    else
        npm install
    fi
    
    print_success "Dependencies installed successfully"
}

# Create necessary directories
create_directories() {
    print_status "Creating necessary directories..."
    
    mkdir -p data
    mkdir -p logs
    mkdir -p src/storage
    mkdir -p src/utils
    mkdir -p tests
    
    print_success "Directories created"
}

# Setup environment file
setup_environment() {
    print_status "Setting up environment configuration..."
    
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            cp .env.example .env
            print_success "Environment file created from template"
            print_warning "Please edit .env file with your specific configuration"
        else
            print_warning ".env.example not found, skipping environment setup"
        fi
    else
        print_warning ".env file already exists, skipping"
    fi
}

# Create initial todo data file
create_initial_data() {
    print_status "Creating initial data structure..."
    
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
        print_success "Initial data file created"
    else
        print_warning "Data file already exists, skipping"
    fi
}

# Set executable permissions for scripts
set_permissions() {
    print_status "Setting executable permissions for scripts..."
    
    chmod +x scripts/start.sh
    chmod +x scripts/setup.sh
    
    print_success "Script permissions set"
}

# Verify installation
verify_installation() {
    print_status "Verifying installation..."
    
    # Check if main dependencies are available
    if npm list @modelcontextprotocol/sdk &> /dev/null; then
        print_success "MCP SDK dependency verified"
    else
        print_warning "MCP SDK dependency not found in node_modules"
    fi
    
    # Check if required files exist
    local required_files=("package.json" ".env" "data/todos.json")
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            print_success "Required file $file exists"
        else
            print_warning "Required file $file is missing"
        fi
    done
}

# Main setup process
main() {
    echo "======================================"
    echo "  MCP Todo Connector Setup Script"
    echo "======================================"
    echo
    
    check_node
    check_npm
    install_dependencies
    create_directories
    setup_environment
    create_initial_data
    set_permissions
    verify_installation
    
    echo
    echo "======================================"
    print_success "Setup completed successfully! 🎉"
    echo "======================================"
    echo
    print_status "Next steps:"
    echo "  1. Edit .env file with your configuration"
    echo "  2. Run './scripts/start.sh' to start the server"
    echo "  3. Check the README.md for usage instructions"
    echo
    print_status "For authentication setup, see: scripts/auth-note.md"
}

# Run main function
main "$@"