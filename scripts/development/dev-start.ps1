# 🔥 Park Janana - Ultimate Dev Startup Script
# One script to rule them all - handles emulators, network config, device selection, and app launch

param(
    [string]$Device = "",
    [switch]$Web,
    [switch]$NoEmulators,
    [switch]$CleanBuild,
    [switch]$Help,
    [string]$ForceIP = ""
)

# Colors for output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Cyan = "Cyan"
$Blue = "Blue"
$Gray = "Gray"
$White = "White"

# Global variables for cleanup
$global:EmulatorProcess = $null
$global:ExportOnExit = $false

function Write-Header {
    param($Text)
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor $Cyan
    Write-Host " 🔥 $Text" -ForegroundColor $Cyan
    Write-Host "=" * 60 -ForegroundColor $Cyan
}

function Write-Success {
    param($Text)
    Write-Host "✅ $Text" -ForegroundColor $Green
}

function Write-Warning {
    param($Text)
    Write-Host "⚠️  $Text" -ForegroundColor $Yellow
}

function Write-Error {
    param($Text)
    Write-Host "❌ $Text" -ForegroundColor $Red
}

function Write-Info {
    param($Text)
    Write-Host "ℹ️  $Text" -ForegroundColor $Blue
}

# Function to handle cleanup on exit
function Stop-EmulatorAndExport {
    Write-Host ""
    Write-Header "Shutting Down Development Environment"
    
    # Stop any running emulator process
    if ($global:EmulatorProcess -and -not $global:EmulatorProcess.HasExited) {
        Write-Info "Stopping Firebase emulators..."
        try {
            # Try graceful shutdown first by sending Ctrl+C
            if (-not $global:EmulatorProcess.HasExited) {
                Write-Info "Sending shutdown signal to emulator process..."
                $global:EmulatorProcess.CloseMainWindow()
                Start-Sleep -Seconds 3
            }
            
            # Force kill if still running
            if (-not $global:EmulatorProcess.HasExited) {
                Write-Warning "Force stopping emulator process..."
                $global:EmulatorProcess.Kill()
            }
        } catch {
            Write-Warning "Failed to stop emulator process: $_"
        }
    }
    
    # Export emulator data if enabled and emulators were started
    if ($global:ExportOnExit) {
        Write-Info "Exporting emulator data before shutdown..."
        try {
            $exportResult = firebase emulators:export "./emulator-data" 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Emulator data exported to ./emulator-data"
            } else {
                Write-Warning "Export completed with warnings: $exportResult"
            }
        } catch {
            Write-Warning "Failed to export emulator data: $_"
        }
    }
    
    # Try to kill any remaining Firebase processes
    try {
        Write-Info "Cleaning up remaining Firebase processes..."
        
        # Look for Firebase-related processes
        $firebaseProcesses = @()
        
        # Java processes (Firebase emulators run on JVM)
        $javaProcesses = Get-Process -Name "java" -ErrorAction SilentlyContinue
        foreach ($proc in $javaProcesses) {
            try {
                $cmdLine = (Get-WmiObject Win32_Process -Filter "ProcessId = $($proc.Id)").CommandLine
                if ($cmdLine -and ($cmdLine -like "*firebase*" -or $cmdLine -like "*emulator*")) {
                    $firebaseProcesses += $proc
                }
            } catch {
                # Skip if can't get command line
            }
        }
        
        # Node.js processes (Firebase CLI)
        $nodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue
        foreach ($proc in $nodeProcesses) {
            try {
                $cmdLine = (Get-WmiObject Win32_Process -Filter "ProcessId = $($proc.Id)").CommandLine
                if ($cmdLine -and $cmdLine -like "*firebase*") {
                    $firebaseProcesses += $proc
                }
            } catch {
                # Skip if can't get command line
            }
        }
        
        if ($firebaseProcesses.Count -gt 0) {
            Write-Info "Found $($firebaseProcesses.Count) Firebase process(es) to terminate"
            $firebaseProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
        }
    } catch {
        # Ignore errors here - best effort cleanup
    }
    
    Write-Success "Cleanup completed. Goodbye! 👋"
}

# Register cleanup function to run on script exit
Register-EngineEvent PowerShell.Exiting -Action { Stop-EmulatorAndExport }

# Handle Ctrl+C gracefully
$null = Register-ObjectEvent -InputObject ([Console]) -EventName "CancelKeyPress" -Action {
    $Event.SourceEventArgs.Cancel = $true
    Stop-EmulatorAndExport
    exit 0
}

function Show-Help {
    Write-Header "Park Janana Development Script Help"
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor $Yellow
    Write-Host "  .\dev-start.ps1 [OPTIONS]" -ForegroundColor $White
    Write-Host ""
    Write-Host "OPTIONS:" -ForegroundColor $Yellow
    Write-Host "  -Device <id>      Specify device ID to run on" -ForegroundColor $White
    Write-Host "  -Web              Run on web browser instead of mobile" -ForegroundColor $White
    Write-Host "  -NoEmulators      Skip Firebase emulator startup" -ForegroundColor $White
    Write-Host "  -CleanBuild       Clean build before running" -ForegroundColor $White
    Write-Host "  -ForceIP <ip>     Force specific IP for emulators" -ForegroundColor $White
    Write-Host "  -Help             Show this help message" -ForegroundColor $White
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor $Yellow
    Write-Host "  .\dev-start.ps1                    # Auto-detect everything" -ForegroundColor $White
    Write-Host "  .\dev-start.ps1 -Web               # Run on web" -ForegroundColor $White
    Write-Host "  .\dev-start.ps1 -Device android    # Run on Android" -ForegroundColor $White
    Write-Host "  .\dev-start.ps1 -CleanBuild        # Clean build first" -ForegroundColor $White
    Write-Host "  .\dev-start.ps1 -ForceIP 10.0.0.5  # Use specific IP" -ForegroundColor $White
    Write-Host ""
    Write-Host "ENVIRONMENT CONFIGURATION:" -ForegroundColor $Yellow
    Write-Host "  Edit .env file to configure default behavior:" -ForegroundColor $White
    Write-Host "  - DEFAULT_DEVICE_TYPE: android/web/chrome" -ForegroundColor $White
    Write-Host "  - AUTO_START_EMULATORS: true/false" -ForegroundColor $White
    Write-Host "  - AUTO_CLEAN_BUILD: true/false" -ForegroundColor $White
    Write-Host "  - VERBOSE_LOGGING: true/false" -ForegroundColor $White
    Write-Host "  - IMPORT_EMULATOR_DATA: true/false" -ForegroundColor $White
    Write-Host "  - EXPORT_EMULATOR_DATA: true/false" -ForegroundColor $White
    Write-Host ""
    exit
}

if ($Help) {
    Show-Help
}

Write-Header "Park Janana Development Environment"
Write-Info "Initializing development environment..."

# Load .env file
$envFile = ".\.env"
$env_vars = @{}
if (Test-Path $envFile) {
    Write-Success "Loading configuration from .env file"
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^([^#][^=]+)=(.*)$') {
            $env_vars[$matches[1].Trim()] = $matches[2].Trim()
        }
    }
} else {
    Write-Warning ".env file not found, using defaults"
}

# Helper function to get env var with default
function Get-EnvVar {
    param($Key, $Default = "")
    if ($env_vars.ContainsKey($Key) -and $env_vars[$Key] -ne "") {
        return $env_vars[$Key]
    }
    return $Default
}

# Configuration from .env file
$PROJECT_NAME = Get-EnvVar "PROJECT_NAME" "Park Janana"
$AUTO_START_EMULATORS = (Get-EnvVar "AUTO_START_EMULATORS" "true") -eq "true"
$AUTO_CLEAN_BUILD = (Get-EnvVar "AUTO_CLEAN_BUILD" "false") -eq "true"
$VERBOSE_LOGGING = (Get-EnvVar "VERBOSE_LOGGING" "true") -eq "true"
$AUTO_UPDATE_NETWORK_CONFIG = (Get-EnvVar "AUTO_UPDATE_NETWORK_CONFIG" "true") -eq "true"
$DEFAULT_DEVICE_TYPE = Get-EnvVar "DEFAULT_DEVICE_TYPE" "android"
$IMPORT_EMULATOR_DATA = (Get-EnvVar "IMPORT_EMULATOR_DATA" "true") -eq "true"
$EXPORT_EMULATOR_DATA = (Get-EnvVar "EXPORT_EMULATOR_DATA" "true") -eq "true"
$EMULATOR_STARTUP_TIMEOUT = [int](Get-EnvVar "EMULATOR_STARTUP_TIMEOUT" "30")

# Firebase emulator port configuration
$FIREBASE_AUTH_PORT = Get-EnvVar "FIREBASE_AUTH_PORT" "9099"
$FIREBASE_FIRESTORE_PORT = Get-EnvVar "FIREBASE_FIRESTORE_PORT" "8081"
$FIREBASE_STORAGE_PORT = Get-EnvVar "FIREBASE_STORAGE_PORT" "9199"
$FIREBASE_FUNCTIONS_PORT = Get-EnvVar "FIREBASE_FUNCTIONS_PORT" "5001"
$FIREBASE_UI_PORT = Get-EnvVar "FIREBASE_UI_PORT" "4000"

# Override with command line parameters
if ($CleanBuild) { $AUTO_CLEAN_BUILD = $true }
if ($NoEmulators) { $AUTO_START_EMULATORS = $false }
if ($Web) { $DEFAULT_DEVICE_TYPE = "web" }

Write-Info "Project: $PROJECT_NAME"
Write-Info "Auto-start emulators: $AUTO_START_EMULATORS"
Write-Info "Clean build: $AUTO_CLEAN_BUILD"
Write-Info "Default device: $DEFAULT_DEVICE_TYPE"
Write-Info "Import emulator data: $IMPORT_EMULATOR_DATA"
Write-Info "Verbose logging: $VERBOSE_LOGGING"

# Function to get local IP
function Get-LocalIP {
    Write-Info "Detecting local IP address..."
    
    if ($ForceIP -ne "") {
        Write-Success "Using forced IP: $ForceIP"
        return $ForceIP
    }
    
    # Check environment variable first
    $envIP = Get-EnvVar "FIREBASE_EMULATOR_HOST"
    if ($envIP -ne "") {
        Write-Success "Using IP from .env: $envIP"
        return $envIP
    }
    
    # Auto-detect IP
    try {
        $ip = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Wi-Fi*" | Where-Object {$_.IPAddress -like "192.168.*" -or $_.IPAddress -like "10.0.*"} | Select-Object -First 1).IPAddress
        if (-not $ip) {
            $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.*" -or $_.IPAddress -like "10.0.*"} | Select-Object -First 1).IPAddress
        }
        if ($ip) {
            Write-Success "Auto-detected IP: $ip"
            return $ip
        }
    } catch {
        Write-Warning "Auto-detection failed: $_"
    }
    
    # Try fallback IPs
    $fallbacks = (Get-EnvVar "FALLBACK_IPS" "10.0.0.9,192.168.1.2,192.168.0.2").Split(",")
    foreach ($fallback in $fallbacks) {
        $fallback = $fallback.Trim()
        if ($fallback -ne "") {
            Write-Warning "Trying fallback IP: $fallback"
            return $fallback
        }
    }
    
    # Final fallback
    Write-Error "Could not detect IP, using localhost"
    return "127.0.0.1"
}

# Function to update network security config
function Update-NetworkSecurityConfig {
    param($IP, $DeviceID)
    
    if (-not $AUTO_UPDATE_NETWORK_CONFIG) {
        Write-Info "Network config auto-update disabled"
        return
    }
    
    $configPath = "android\app\src\main\res\xml\network_security_config.xml"
    
    if (-not (Test-Path $configPath)) {
        Write-Warning "Network security config not found, creating one..."
        $configDir = Split-Path $configPath -Parent
        if (-not (Test-Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
    }
    
    Write-Info "Updating network security config for IP: $IP and Device: $DeviceID"
    
    $domains = @()
    # Device-specific domain logic
    if ($DeviceID -eq "chrome" -or $DeviceID -eq "web") {
        # Web: only localhost
        $domains += "127.0.0.1"
        $domains += "localhost"
    } elseif ($DeviceID -like "emulator*" -or $DeviceID -eq "android" -or $DeviceID -eq "10.0.2.2") {
        # Android emulator: emulator IPs and localhost
        $domains += "10.0.2.2"
        $domains += "127.0.0.1"
        $domains += "localhost"
    } else {
        # Physical device: detected host IP, plus localhost/emulator IPs for safety
        $domains += $IP
        $domains += "10.0.2.2"
        $domains += "127.0.0.1"
        $domains += "localhost"
    }
    # Deduplicate
    $domains = $domains | Select-Object -Unique
    $domainXml = $domains | ForEach-Object { '        <domain includeSubdomains="true">' + $_ + '</domain>' } | Out-String
    
    $configContent = @"
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <!-- 🔥 Auto-generated by dev-start.ps1 -->
    <debug-overrides>
        <trust-anchors>
            <certificates src="system"/>
            <certificates src="user"/>
        </trust-anchors>
    </debug-overrides>
    
    <domain-config cleartextTrafficPermitted="true">
$domainXml    </domain-config>
    
    <base-config cleartextTrafficPermitted="true">
        <trust-anchors>
            <certificates src="system"/>
            <certificates src="user"/>
        </trust-anchors>
    </base-config>
</network-security-config>
"@
    
    try {
        $configContent | Out-File -FilePath $configPath -Encoding UTF8
        Write-Success "Network security config updated"
    } catch {
        Write-Error "Failed to update network security config: $_"
    }
}

# Function to start Firebase emulators
function Start-FirebaseEmulators {
    param($IP)
    
    if (-not $AUTO_START_EMULATORS) {
        Write-Info "Emulator auto-start disabled"
        return $true
    }
    
    Write-Info "Checking if Firebase emulators are already running..."
    
    # Check if emulators are already running
    try {
        $null = Invoke-WebRequest -Uri "http://127.0.0.1:$FIREBASE_AUTH_PORT" -TimeoutSec 2 -ErrorAction SilentlyContinue
        Write-Success "Firebase emulators are already running!"
        return $true
    } catch {
        Write-Info "Starting Firebase emulators..."
    }
    
    # Set environment variable for this session
    $env:FIREBASE_EMULATOR_HOST = $IP
    
    # Start emulators in a new visible PowerShell window
    Write-Info "Starting Firebase emulators in a new window..."
    $emulatorArgs = @("emulators:start")
    
    # Add import data option if enabled
    if ($IMPORT_EMULATOR_DATA -and (Test-Path "./emulator-data")) {
        Write-Info "Importing existing emulator data..."
        $emulatorArgs += "--import=./emulator-data"
    }
    
    # Add export on exit option if enabled
    if ($EXPORT_EMULATOR_DATA) {
        Write-Info "Enabling export on exit..."
        $emulatorArgs += "--export-on-exit=./emulator-data"
    }
    
    # Build the command to run in the new window
    $currentDir = Get-Location
    $emulatorCommand = "firebase " + ($emulatorArgs -join " ")
    $windowTitle = "Firebase Emulators - $PROJECT_NAME"
    
    # Start emulators in a new PowerShell window
    $processArgs = @(
        "-NoExit",
        "-Command",
        "Set-Location '$currentDir'; `$Host.UI.RawUI.WindowTitle = '$windowTitle'; Write-Host '🔥 Starting Firebase Emulators...' -ForegroundColor Cyan; $emulatorCommand"
    )
    
    $global:EmulatorProcess = Start-Process -FilePath "powershell.exe" -ArgumentList $processArgs -PassThru
    
    if ($global:EmulatorProcess) {
        Write-Success "Firebase emulators started in new window (PID: $($global:EmulatorProcess.Id))"
        Write-Info "Window title: '$windowTitle'"
    } else {
        Write-Error "Failed to start emulator process"
        return $false
    }
    
    # Wait for emulators to start
    Write-Info "Waiting for emulators to start (timeout: ${EMULATOR_STARTUP_TIMEOUT}s)..."
    
    for ($i = 1; $i -le $EMULATOR_STARTUP_TIMEOUT; $i++) {
        Start-Sleep -Seconds 1
        try {
            $null = Invoke-WebRequest -Uri "http://127.0.0.1:$FIREBASE_AUTH_PORT" -TimeoutSec 2 -ErrorAction SilentlyContinue
            Write-Success "Firebase emulators started successfully!"
            Write-Success "Emulator UI available at: http://127.0.0.1:$FIREBASE_UI_PORT"
            Write-Info "Auth emulator: http://127.0.0.1:$FIREBASE_AUTH_PORT"
            Write-Info "Firestore emulator: http://127.0.0.1:$FIREBASE_FIRESTORE_PORT"
            Write-Info "Storage emulator: http://127.0.0.1:$FIREBASE_STORAGE_PORT"
            Write-Info "Functions emulator: http://127.0.0.1:$FIREBASE_FUNCTIONS_PORT"
            return $true
        } catch {
            if ($VERBOSE_LOGGING) {
                Write-Host "." -NoNewline
            }
        }
    }
    
    Write-Error "Emulators failed to start within timeout"
    Write-Info "Check the Firebase emulator window for error details"
    Write-Info "Process ID: $($global:EmulatorProcess.Id)"
    return $false
}

# Function to get available devices
function Get-FlutterDevices {
    Write-Info "Scanning for available devices..."
    
    try {
        $devicesOutput = flutter devices 2>$null
        $devices = @()
        
        # Parse flutter devices output - each device starts with 2 spaces and has bullet points
        # Format: "  Name (type) • ID • platform • description..."
        # Handle both • and ΓÇó (encoding variants)
        $deviceLines = $devicesOutput | Where-Object { $_ -match '^\s{2}[^\s].*(•|ΓÇó).*(•|ΓÇó).*(•|ΓÇó)' }
        
        foreach ($line in $deviceLines) {
            # Clean up the line and replace bullet points with delimiter
            $cleanLine = $line.Trim() -replace '\s+', ' '
            $cleanLine = $cleanLine -replace '(•|ΓÇó)', '|'
            $parts = $cleanLine -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
            
            if ($parts.Count -ge 3) {
                $nameAndType = $parts[0].Trim()
                $id = $parts[1].Trim()
                $platform = $parts[2].Trim()
                $description = if ($parts.Count -gt 3) { ($parts[3..$($parts.Count-1)] -join ' ').Trim() } else { "" }
                
                # Extract just the name from "Name (type)" format
                if ($nameAndType -match '^(.+?)\s*\([^)]+\)$') {
                    $name = $matches[1].Trim()
                } else {
                    $name = $nameAndType
                }
                
                # Skip empty or invalid entries
                if ($name -ne "" -and $id -ne "" -and $name -notmatch "Found \d+ connected") {
                    $devices += @{
                        Name = $name
                        ID = $id
                        Platform = $platform
                        Description = $description
                        FullName = $nameAndType
                    }
                    
                    if ($VERBOSE_LOGGING) {
                        Write-Host "  Found device: $nameAndType -> $id" -ForegroundColor $White
                    }
                }
            }
        }
        
        return $devices
    } catch {
        Write-Error "Failed to get Flutter devices: $_"
        return @()
    }
}

# Function to select device
function Select-Device {
    # Always enumerate, even if -Device or -Web is passed, so the user confirms.
    $devices = Get-FlutterDevices

    # Add web target based on default device type or -Web flag
    if ($Web -or $DEFAULT_DEVICE_TYPE -eq "web" -or $DEFAULT_DEVICE_TYPE -eq "chrome") {
        $devices += @{
            Name        = "Chrome (web)"
            ID          = "chrome"
            Platform    = "web"
            Description = "Flutter web via Chrome"
            FullName    = "Chrome (web)"
        }
    }

    if ($devices.Count -eq 0) {
        Write-Error "No Flutter devices found!"
        Write-Info "Make sure you have:"
        Write-Info "  - Android device connected (USB debugging enabled)"
        Write-Info "  - Android emulator running"
        Write-Info "  - Use -Web to add a Chrome (web) option"
        exit 1
    }

    Write-Info "Available devices:"
    for ($i = 0; $i -lt $devices.Count; $i++) {
        $d = $devices[$i]
        Write-Host "  [$i] $($d.FullName) -> $($d.ID)" -ForegroundColor $White
        if ($d.Description) {
            Write-Host "      $($d.Description)" -ForegroundColor $Gray
        }
    }

    # Find suggested device based on command line parameter or .env default
    $suggestedIndex = $null
    $suggestedSource = ""
    
    # First priority: command line -Device parameter
    if ($Device -ne "") {
        $suggestedIndex = ($devices | ForEach-Object { $_ } |
            Where-Object { $_.ID -eq $Device -or $_.Name -eq $Device } |
            ForEach-Object { [array]::IndexOf($devices, $_) } |
            Select-Object -First 1)

        if ($null -ne $suggestedIndex) {
            $suggestedSource = "command line"
        } else {
            Write-Warning "The -Device '$Device' was not found in the current list."
        }
    }
    
    # Second priority: DEFAULT_DEVICE_TYPE from .env
    if ($null -eq $suggestedIndex -and $DEFAULT_DEVICE_TYPE -ne "") {
        $suggestedIndex = ($devices | ForEach-Object { $_ } |
            Where-Object { 
                $_.Platform -eq $DEFAULT_DEVICE_TYPE -or 
                $_.ID -eq $DEFAULT_DEVICE_TYPE -or 
                ($DEFAULT_DEVICE_TYPE -eq "android" -and $_.Platform -eq "android-x64") -or
                ($DEFAULT_DEVICE_TYPE -eq "web" -and $_.ID -eq "chrome")
            } |
            ForEach-Object { [array]::IndexOf($devices, $_) } |
            Select-Object -First 1)
            
        if ($null -ne $suggestedIndex) {
            $suggestedSource = ".env DEFAULT_DEVICE_TYPE"
        }
    }

    if ($null -ne $suggestedIndex) {
        Write-Info "Suggested device from $suggestedSource`: $($devices[$suggestedIndex].FullName) -> $($devices[$suggestedIndex].ID)"
    }

    # Prompt until the user explicitly selects.
    while ($true) {
        $range = "0-$($devices.Count-1)"
        if ($null -ne $suggestedIndex) {
            $prompt = "Select device [$range] (Enter for $suggestedIndex, 'r' to rescan, 'q' to quit)"
        } else {
            $prompt = "Select device [$range] ('r' to rescan, 'q' to quit)"
        }

        $selection = Read-Host $prompt

        switch -Regex ($selection) {
            '^[Qq]$' {
                Write-Error "Aborted by user."
                exit 1
            }
            '^[Rr]$' {
                Write-Info "Rescanning devices..."
                $devices = Get-FlutterDevices
                if ($Web -and -not ($devices | Where-Object { $_.ID -eq 'chrome' })) {
                    $devices += @{
                        Name        = "Chrome (web)"
                        ID          = "chrome"
                        Platform    = "web"
                        Description = "Flutter web via Chrome"
                        FullName    = "Chrome (web)"
                    }
                }

                if ($devices.Count -eq 0) {
                    Write-Error "Still no devices found."
                    continue
                }

                Write-Info "Available devices:"
                for ($i = 0; $i -lt $devices.Count; $i++) {
                    $d = $devices[$i]
                    Write-Host "  [$i] $($d.FullName) -> $($d.ID)" -ForegroundColor $White
                    if ($d.Description) {
                        Write-Host "      $($d.Description)" -ForegroundColor $Gray
                    }
                }
                continue
            }
            '^$' {
                if ($null -ne $suggestedIndex) {
                    $chosen = $devices[$suggestedIndex]
                    Write-Success "Selected: $($chosen.FullName) -> $($chosen.ID)"
                    return $chosen.ID
                } else {
                    Write-Warning "Please enter a number, 'r' to rescan, or 'q' to quit."
                    continue
                }
            }
            '^\d+$' {
                $index = [int]$selection
                if ($index -ge 0 -and $index -lt $devices.Count) {
                    $chosen = $devices[$index]
                    Write-Success "Selected: $($chosen.FullName) -> $($chosen.ID)"
                    return $chosen.ID
                } else {
                    Write-Warning "Invalid selection. Choose between $range."
                    continue
                }
            }
            default {
                Write-Warning "Unrecognized input. Enter a number, 'r' to rescan, or 'q' to quit."
            }
        }
    }
}


# Function to run Flutter app
function Start-FlutterApp {
    param($DeviceID, $IP)
    
    Write-Info "Preparing to run Flutter app..."
    
    # Clean build if requested
    if ($AUTO_CLEAN_BUILD) {
        Write-Info "Cleaning Flutter build..."
        flutter clean
        Write-Info "Getting dependencies..."
        flutter pub get
    }
    
    Write-Info "Starting Flutter app on device: $DeviceID"
    Write-Info "Using emulator host: $IP"
    
    $flutterArgs = @("run", "-d", $DeviceID, "--dart-define=FIREBASE_EMULATOR_HOST=$IP")
    
    if ($VERBOSE_LOGGING) {
        $flutterArgs += "--verbose"
    }
    
    # Run Flutter app
    Write-Success "Launching $PROJECT_NAME..."
    Write-Info "Command: flutter $($flutterArgs -join ' ')"
    
    try {
        & flutter @flutterArgs
    } catch {
        Write-Error "Failed to start Flutter app: $_"
        exit 1
    }
}

# Function to update .env file
function Update-EnvFile {
    param($HostIP)
    $envFile = ".env"
    $lines = @()
    $found = $false
    if (Test-Path $envFile) {
        $lines = Get-Content $envFile
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '^FIREBASE_EMULATOR_HOST=') {
                $lines[$i] = "FIREBASE_EMULATOR_HOST=$HostIP"
                $found = $true
            }
        }
    }
    if (-not $found) {
        $lines += "FIREBASE_EMULATOR_HOST=$HostIP"
    }
    $lines | Set-Content $envFile -Encoding UTF8
    Write-Success ".env updated: FIREBASE_EMULATOR_HOST=$HostIP"
}

# Main execution flow
try {
    # Step 1: Get IP address
    Write-Header "Step 1: Network Configuration"
    $hostIP = Get-LocalIP
    
    # Step 2: Device selection
    Write-Header "Step 2: Device Selection"
    $selectedDevice = Select-Device
    
    # Step 3: Update Android network config (pass device ID)
    Write-Header "Step 3: Android Configuration"
    Update-NetworkSecurityConfig -IP $hostIP -DeviceID $selectedDevice
    
   
    
    # Step 4: Start Firebase emulators
    Write-Header "Step 5: Firebase Emulators"
    $emulatorsStarted = Start-FirebaseEmulators -IP $hostIP
    
    # Set export flag if emulators started and export is enabled
    if ($emulatorsStarted -and $EXPORT_EMULATOR_DATA -and $AUTO_START_EMULATORS) {
        $global:ExportOnExit = $true
    }
    
    if (-not $emulatorsStarted -and $AUTO_START_EMULATORS) {
        Write-Error "Failed to start emulators. Continue anyway? (y/n)"
        $continue = Read-Host
        if ($continue -ne "y" -and $continue -ne "Y") {
            exit 1
        }
    }

    # Step 5: Launch app
    Write-Header "Step 6: Launch Application"
    Start-FlutterApp -DeviceID $selectedDevice -IP $hostIP
    
    Write-Header "Development Session Complete"
    
    # Normal exit - cleanup will be handled by the registered event
    Write-Success "Thanks for using the $PROJECT_NAME dev script! 🚀"
    
} catch {
    Write-Error "Script failed: $_"
    Write-Info "Run with -Help for usage information"
    exit 1
}
