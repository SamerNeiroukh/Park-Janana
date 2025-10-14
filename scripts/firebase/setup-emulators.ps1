# 🔥 Firebase Emulator Quick Start Script

Write-Host "🔥 Firebase Emulator Quick Setup" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Function to get local IP address
function Get-LocalIP {
    $ip = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Wi-Fi*" | Where-Object {$_.IPAddress -like "192.168.*" -or $_.IPAddress -like "10.0.*"} | Select-Object -First 1).IPAddress
    if (-not $ip) {
        $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.*" -or $_.IPAddress -like "10.0.*"} | Select-Object -First 1).IPAddress
    }
    return $ip
}

# Get current IP
$currentIP = Get-LocalIP

if ($currentIP) {
    Write-Host "🌐 Detected IP Address: $currentIP" -ForegroundColor Green
    
    # Set environment variable for this session
    $env:FIREBASE_EMULATOR_HOST = $currentIP
    Write-Host "✅ Set FIREBASE_EMULATOR_HOST to: $currentIP" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "📋 Available Commands:" -ForegroundColor Yellow
    Write-Host "  1. Start emulators: firebase emulators:start" -ForegroundColor White
    Write-Host "  2. Run on Android:  flutter run -d android" -ForegroundColor White
    Write-Host "  3. Run on device:   flutter run -d <device-id>" -ForegroundColor White
    Write-Host ""
    Write-Host "🌐 Emulator UI will be available at: http://127.0.0.1:4000" -ForegroundColor Green
    Write-Host "📱 App will connect to emulators at: $currentIP" -ForegroundColor Green
    
} else {
    Write-Host "❌ Could not detect IP address. Using localhost (127.0.0.1)" -ForegroundColor Red
    $env:FIREBASE_EMULATOR_HOST = "127.0.0.1"
}

Write-Host ""
Write-Host "🚀 Ready to start development!" -ForegroundColor Cyan

# Ask if user wants to start emulators now
$response = Read-Host "Start Firebase emulators now? (y/n)"
if ($response -eq "y" -or $response -eq "Y") {
    Write-Host "🔥 Starting Firebase emulators..." -ForegroundColor Cyan
    firebase emulators:start
}
