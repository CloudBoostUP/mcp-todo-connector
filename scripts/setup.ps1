# MCP Todo Connector Setup Script (Windows PowerShell)
# This script sets up the development environment for the MCP Todo Connector

param(
    [switch]$Force,
    [switch]$Verbose
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Enable verbose output if requested
if ($Verbose) {
    $VerbosePreference = "Continue"
}

Write-Host "🚀 Setting up MCP Todo Connector..." -ForegroundColor Cyan

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check if Node.js is installed
function Test-NodeJS {
    Write-Status "Checking Node.js installation..."
    
    try {
        $nodeVersion = node --version
        if (-not $nodeVersion) {
            throw "Node.js not found"
        }
        
        # Extract version number (remove 'v' prefix)
        $versionNumber = $nodeVersion.Substring(1)
        $requiredVersion = [version]"18.0.0"
        $currentVersion = [version]$versionNumber
        
        if ($currentVersion -lt $requiredVersion) {
            Write-Error "Node.js version $versionNumber is too old. Please install version 18.0.0 or higher."
            Write-Status "Visit: https://nodejs.org/en/download/"
            exit 1
        }
        
        Write-Success "Node.js version $versionNumber is compatible"
    }
    catch {
        Write-Error "Node.js is not installed. Please install Node.js 18.0.0 or higher."
        Write-Status "Visit: https://nodejs.org/en/download/"
        exit 1
    }
}

# Check if npm is installed
function Test-NPM {
    Write-Status "Checking npm installation..."
    
    try {
        $npmVersion = npm --version
        if (-not $npmVersion) {
            throw "npm not found"
        }
        
        Write-Success "npm version $npmVersion is available"
    }
    catch {
        Write-Error "npm is not installed. Please install npm."
        exit 1
    }
}

# Install dependencies
function Install-Dependencies {
    Write-Status "Installing dependencies..."
    
    try {
        if (Test-Path "package-lock.json") {
            npm ci
        } else {
            npm install
        }
        
        Write-Success "Dependencies installed successfully"
    }
    catch {
        Write-Error "Failed to install dependencies: $_"
        exit 1
    }
}

# Create necessary directories
function New-ProjectDirectories {
    Write-Status "Creating necessary directories..."
    
    $directories = @("data", "logs", "src\storage", "src\utils", "tests")
    
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Verbose "Created directory: $dir"
        }
    }
    
    Write-Success "Directories created"
}

# Setup environment file
function Set-Environment {
    Write-Status "Setting up environment configuration..."
    
    if (-not (Test-Path ".env") -or $Force) {
        if (Test-Path ".env.example") {
            Copy-Item ".env.example" ".env"
            Write-Success "Environment file created from template"
            Write-Warning "Please edit .env file with your specific configuration"
        } else {
            Write-Warning ".env.example not found, skipping environment setup"
        }
    } else {
        Write-Warning ".env file already exists, skipping (use -Force to overwrite)"
    }
}

# Create initial todo data file
function New-InitialData {
    Write-Status "Creating initial data structure..."
    
    if (-not (Test-Path "data\todos.json") -or $Force) {
        $currentDate = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        
        $initialData = @{
            todos = @()
            categories = @("personal", "work", "shopping", "health")
            tags = @("urgent", "important", "quick", "meeting", "review")
            metadata = @{
                version = "1.0.0"
                created = $currentDate
                lastModified = $currentDate
            }
        } | ConvertTo-Json -Depth 10
        
        $initialData | Out-File -FilePath "data\todos.json" -Encoding UTF8
        Write-Success "Initial data file created"
    } else {
        Write-Warning "Data file already exists, skipping (use -Force to overwrite)"
    }
}

# Create main server files if they don't exist
function New-ServerFiles {
    Write-Status "Creating main server files..."
    
    # Create index.js if it doesn't exist
    if (-not (Test-Path "index.js") -or $Force) {
        $indexContent = @"
#!/usr/bin/env node

/**
 * MCP Todo Connector Server
 * Entry point for the Model Context Protocol todo management server
 */

require('dotenv').config();
const { TodoServer } = require('./src/server');

async function main() {
    const server = new TodoServer();
    
    try {
        await server.start();
        console.log('MCP Todo Connector server started successfully');
    } catch (error) {
        console.error('Failed to start server:', error);
        process.exit(1);
    }
}

// Handle graceful shutdown
process.on('SIGINT', () => {
    console.log('Received SIGINT, shutting down gracefully...');
    process.exit(0);
});

process.on('SIGTERM', () => {
    console.log('Received SIGTERM, shutting down gracefully...');
    process.exit(0);
});

if (require.main === module) {
    main();
}
"@
        
        $indexContent | Out-File -FilePath "index.js" -Encoding UTF8
        Write-Success "Created index.js"
    }
}

# Verify installation
function Test-Installation {
    Write-Status "Verifying installation..."
    
    # Check if main dependencies are available
    try {
        $mcpSdk = npm list @modelcontextprotocol/sdk 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "MCP SDK dependency verified"
        } else {
            Write-Warning "MCP SDK dependency not found in node_modules"
        }
    }
    catch {
        Write-Warning "Could not verify MCP SDK dependency"
    }
    
    # Check if required files exist
    $requiredFiles = @("package.json", ".env", "data\todos.json")
    foreach ($file in $requiredFiles) {
        if (Test-Path $file) {
            Write-Success "Required file $file exists"
        } else {
            Write-Warning "Required file $file is missing"
        }
    }
}

# Main setup process
function Start-Setup {
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host "  MCP Todo Connector Setup Script" -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host ""
    
    Test-NodeJS
    Test-NPM
    Install-Dependencies
    New-ProjectDirectories
    Set-Environment
    New-InitialData
    New-ServerFiles
    Test-Installation
    
    Write-Host ""
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Success "Setup completed successfully! 🎉"
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Status "Next steps:"
    Write-Host "  1. Edit .env file with your configuration" -ForegroundColor White
    Write-Host "  2. Run '.\scripts\start.ps1' to start the server" -ForegroundColor White
    Write-Host "  3. Check the README.md for usage instructions" -ForegroundColor White
    Write-Host ""
    Write-Status "For authentication setup, see: scripts\auth-note.md"
}

# Run main setup
try {
    Start-Setup
}
catch {
    Write-Error "Setup failed: $_"
    exit 1
}