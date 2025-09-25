# MCP Todo Connector Start Script (Windows PowerShell)
# This script starts the MCP Todo Connector server with proper configuration

param(
    [switch]$Dev,
    [switch]$Watch,
    [switch]$Daemon,
    [string]$Port,
    [string]$LogLevel,
    [switch]$Help
)

# Set error action preference
$ErrorActionPreference = "Stop"

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

function Write-Header {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Cyan
}

# Show help information
if ($Help) {
    Write-Host "Usage: .\scripts\start.ps1 [OPTIONS]" -ForegroundColor White
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  -Dev               Run in development mode" -ForegroundColor White
    Write-Host "  -Watch             Enable file watching (development mode)" -ForegroundColor White
    Write-Host "  -Daemon            Run as background service" -ForegroundColor White
    Write-Host "  -Port <number>     Override port number" -ForegroundColor White
    Write-Host "  -LogLevel <level>  Set log level (debug, info, warn, error)" -ForegroundColor White
    Write-Host "  -Help              Show this help message" -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\scripts\start.ps1                    # Start in production mode" -ForegroundColor Gray
    Write-Host "  .\scripts\start.ps1 -Dev               # Start in development mode" -ForegroundColor Gray
    Write-Host "  .\scripts\start.ps1 -Dev -Watch        # Start in development mode with file watching" -ForegroundColor Gray
    Write-Host "  .\scripts\start.ps1 -Daemon            # Start as background service" -ForegroundColor Gray
    exit 0
}

# Determine mode
$Mode = if ($Dev) { "development" } else { "production" }

# Check prerequisites
function Test-Prerequisites {
    Write-Status "Checking prerequisites..."
    
    # Check if Node.js is installed
    try {
        $null = node --version
    }
    catch {
        Write-Error "Node.js is not installed. Please run setup.ps1 first."
        exit 1
    }
    
    # Check if package.json exists
    if (-not (Test-Path "package.json")) {
        Write-Error "package.json not found. Please run setup.ps1 first."
        exit 1
    }
    
    # Check if node_modules exists
    if (-not (Test-Path "node_modules")) {
        Write-Error "Dependencies not installed. Please run setup.ps1 first."
        exit 1
    }
    
    Write-Success "Prerequisites check passed"
}

# Load environment variables
function Set-Environment {
    Write-Status "Loading environment configuration..."
    
    # Load .env file if it exists
    if (Test-Path ".env") {
        Get-Content ".env" | ForEach-Object {
            if ($_ -match "^([^#][^=]+)=(.*)$") {
                $name = $matches[1].Trim()
                $value = $matches[2].Trim()
                [Environment]::SetEnvironmentVariable($name, $value, "Process")
            }
        }
        Write-Success "Environment variables loaded from .env"
    } else {
        Write-Warning ".env file not found, using default configuration"
    }
    
    # Override with command line arguments
    if ($Port) {
        [Environment]::SetEnvironmentVariable("PORT", $Port, "Process")
        Write-Status "Port overridden to: $Port"
    }
    
    if ($LogLevel) {
        [Environment]::SetEnvironmentVariable("LOG_LEVEL", $LogLevel, "Process")
        Write-Status "Log level overridden to: $LogLevel"
    }
    
    # Set mode-specific environment variables
    if ($Mode -eq "development") {
        [Environment]::SetEnvironmentVariable("NODE_ENV", "development", "Process")
        if (-not $env:DEBUG) {
            [Environment]::SetEnvironmentVariable("DEBUG", "mcp:*", "Process")
        }
        Write-Status "Running in development mode"
    } else {
        [Environment]::SetEnvironmentVariable("NODE_ENV", "production", "Process")
        Write-Status "Running in production mode"
    }
}

# Create necessary directories and files
function Initialize-Runtime {
    Write-Status "Preparing runtime environment..."
    
    # Create directories if they don't exist
    if (-not (Test-Path "data")) {
        New-Item -ItemType Directory -Path "data" -Force | Out-Null
    }
    if (-not (Test-Path "logs")) {
        New-Item -ItemType Directory -Path "logs" -Force | Out-Null
    }
    
    # Create initial todos.json if it doesn't exist
    if (-not (Test-Path "data\todos.json")) {
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
        Write-Success "Created initial todos.json"
    }
    
    Write-Success "Runtime environment prepared"
}

# Start the server
function Start-Server {
    Write-Status "Starting MCP Todo Connector server..."
    
    # Determine which command to use
    $startCommand = ""
    $logFile = "logs\server.log"
    
    if ($Mode -eq "development" -and $Watch) {
        $startCommand = "npm run dev"
        Write-Status "Starting with file watching enabled"
    } elseif ($Mode -eq "development") {
        $startCommand = "node index.js"
        Write-Status "Starting in development mode"
    } else {
        $startCommand = "npm start"
        Write-Status "Starting in production mode"
    }
    
    # Ensure logs directory exists
    if (-not (Test-Path "logs")) {
        New-Item -ItemType Directory -Path "logs" -Force | Out-Null
    }
    
    if ($Daemon) {
        Write-Status "Starting as background service..."
        Write-Status "Logs will be written to: $logFile"
        
        # Start as background job
        $job = Start-Job -ScriptBlock {
            param($command, $logPath)
            
            # Change to the correct directory
            Set-Location $using:PWD
            
            # Start the process and redirect output
            $process = Start-Process -FilePath "powershell" -ArgumentList "-Command", $command -NoNewWindow -PassThru -RedirectStandardOutput $logPath -RedirectStandardError $logPath
            
            # Return process info
            return @{
                ProcessId = $process.Id
                StartTime = $process.StartTime
            }
        } -ArgumentList $startCommand, (Resolve-Path $logFile)
        
        # Wait for job to start
        Start-Sleep -Seconds 2
        
        $result = Receive-Job -Job $job -Wait
        
        if ($result -and $result.ProcessId) {
            # Save PID for later management
            $result.ProcessId | Out-File -FilePath "logs\server.pid" -Encoding UTF8
            
            Write-Success "Server started successfully as background service (PID: $($result.ProcessId))"
            Write-Status "To stop the server: Stop-Process -Id $($result.ProcessId)"
            Write-Status "To view logs: Get-Content $logFile -Wait"
        } else {
            Write-Error "Failed to start server as background service"
            exit 1
        }
    } else {
        Write-Status "Starting in foreground mode..."
        Write-Status "Press Ctrl+C to stop the server"
        
        # Start in foreground
        try {
            Invoke-Expression $startCommand
        }
        catch {
            Write-Error "Failed to start server: $_"
            exit 1
        }
    }
}

# Display server information
function Show-ServerInfo {
    $port = if ($Port) { $Port } else { $env:PORT }
    if (-not $port) { $port = "3000" }
    
    $host = if ($env:HOST) { $env:HOST } else { "localhost" }
    $logLevel = if ($LogLevel) { $LogLevel } else { if ($env:LOG_LEVEL) { $env:LOG_LEVEL } else { "info" } }
    $dataPath = if ($env:TODO_STORAGE_PATH) { $env:TODO_STORAGE_PATH } else { ".\data\todos.json" }
    
    Write-Host ""
    Write-Header "======================================"
    Write-Header "  MCP Todo Connector Server"
    Write-Header "======================================"
    Write-Host ""
    Write-Status "Server Configuration:"
    Write-Host "  • Mode: $Mode" -ForegroundColor White
    Write-Host "  • Host: $host" -ForegroundColor White
    Write-Host "  • Port: $port" -ForegroundColor White
    Write-Host "  • Log Level: $logLevel" -ForegroundColor White
    Write-Host "  • Data Path: $dataPath" -ForegroundColor White
    Write-Host ""
    
    if (-not $Daemon) {
        Write-Status "Server will start momentarily..."
        Write-Host ""
    }
}

# Handle cleanup on exit
function Stop-ServerGracefully {
    Write-Host ""
    Write-Status "Shutting down server..."
    
    # Kill any background jobs
    Get-Job | Stop-Job -PassThru | Remove-Job
    
    # If there's a PID file, try to stop that process too
    if (Test-Path "logs\server.pid") {
        try {
            $pid = Get-Content "logs\server.pid" -Raw
            if ($pid) {
                Stop-Process -Id $pid.Trim() -Force -ErrorAction SilentlyContinue
                Remove-Item "logs\server.pid" -Force -ErrorAction SilentlyContinue
            }
        }
        catch {
            # Ignore errors when cleaning up
        }
    }
    
    Write-Success "Server stopped"
}

# Set up signal handlers
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    Stop-ServerGracefully
}

# Main execution
function Start-Main {
    try {
        Show-ServerInfo
        Test-Prerequisites
        Set-Environment
        Initialize-Runtime
        Start-Server
    }
    catch {
        Write-Error "Failed to start server: $_"
        exit 1
    }
}

# Run main function
Start-Main