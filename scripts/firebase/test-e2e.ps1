# 🧪 E2E Firebase Test Runner
# Run this script to execute end-to-end tests with Firebase emulators

param(
    [switch]$StartEmulators,
    [switch]$StopEmulators,
    [switch]$Help
)

function Show-Help {
    Write-Host ""
    Write-Host "🧪 E2E Firebase Test Runner" -ForegroundColor Cyan
    Write-Host "═══════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "  .\scripts\test-e2e.ps1 [OPTIONS]" -ForegroundColor White
    Write-Host ""
    Write-Host "OPTIONS:" -ForegroundColor Yellow
    Write-Host "  -StartEmulators   Start Firebase emulators before tests" -ForegroundColor White
    Write-Host "  -StopEmulators    Stop Firebase emulators after tests" -ForegroundColor White
    Write-Host "  -Help             Show this help message" -ForegroundColor White
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "  .\scripts\test-e2e.ps1                    # Run tests (emulators must be running)" -ForegroundColor White
    Write-Host "  .\scripts\test-e2e.ps1 -StartEmulators    # Start emulators and run tests" -ForegroundColor White
    Write-Host ""
    Write-Host "PREREQUISITES:" -ForegroundColor Yellow
    Write-Host "  1. Firebase CLI installed" -ForegroundColor White
    Write-Host "  2. Flutter SDK installed" -ForegroundColor White
    Write-Host "  3. Project dependencies installed (flutter pub get)" -ForegroundColor White
    Write-Host ""
    exit
}

if ($Help) {
    Show-Help
}

Write-Host ""
Write-Host "🧪 E2E Firebase Test Runner" -ForegroundColor Cyan
Write-Host "═══════════════════════════" -ForegroundColor Cyan

$emulatorJob = $null
$testExitCode = 0

try {
    # Start emulators if requested
    if ($StartEmulators) {
        Write-Host ""
        Write-Host "🔥 Starting Firebase emulators..." -ForegroundColor Yellow
        
        # Check if emulators are already running
        try {
            $null = Invoke-WebRequest -Uri "http://127.0.0.1:9099" -TimeoutSec 2 -ErrorAction SilentlyContinue
            Write-Host "✅ Firebase emulators are already running" -ForegroundColor Green
        } catch {
            Write-Host "🚀 Starting Firebase emulators in background..." -ForegroundColor Blue
            $emulatorJob = Start-Job -ScriptBlock {
                Set-Location $using:PWD
                firebase emulators:start --import=./emulator-data --export-on-exit=./emulator-data
            }
            
            # Wait for emulators to start
            Write-Host "⏳ Waiting for emulators to initialize..." -ForegroundColor Blue
            $timeout = 30
            for ($i = 1; $i -le $timeout; $i++) {
                Start-Sleep -Seconds 1
                try {
                    $null = Invoke-WebRequest -Uri "http://127.0.0.1:9099" -TimeoutSec 2 -ErrorAction SilentlyContinue
                    Write-Host "✅ Firebase emulators started successfully!" -ForegroundColor Green
                    Write-Host "   Auth: http://127.0.0.1:9099" -ForegroundColor Gray
                    Write-Host "   Firestore: http://127.0.0.1:8081" -ForegroundColor Gray
                    Write-Host "   Storage: http://127.0.0.1:9199" -ForegroundColor Gray
                    Write-Host "   UI: http://127.0.0.1:4000" -ForegroundColor Gray
                    break
                } catch {
                    Write-Host "." -NoNewline -ForegroundColor Gray
                }
                
                if ($i -eq $timeout) {
                    Write-Host ""
                    Write-Host "❌ Emulators failed to start within ${timeout}s" -ForegroundColor Red
                    if ($emulatorJob) {
                        Write-Host "Emulator logs:" -ForegroundColor Yellow
                        Receive-Job $emulatorJob
                    }
                    exit 1
                }
            }
        }
    } else {
        # Check if emulators are running
        Write-Host ""
        Write-Host "🔍 Checking if Firebase emulators are running..." -ForegroundColor Blue
        try {
            $null = Invoke-WebRequest -Uri "http://127.0.0.1:9099" -TimeoutSec 2 -ErrorAction SilentlyContinue
            Write-Host "✅ Firebase emulators are running" -ForegroundColor Green
        } catch {
            Write-Host "❌ Firebase emulators are not running!" -ForegroundColor Red
            Write-Host ""
            Write-Host "To start emulators:" -ForegroundColor Yellow
            Write-Host "  1. Run: .\scripts\test-e2e.ps1 -StartEmulators" -ForegroundColor White
            Write-Host "  2. Or manually: firebase emulators:start" -ForegroundColor White
            Write-Host "  3. Or use VS Code task: Ctrl+Shift+P → Tasks → 🔥 Start Firebase Emulators" -ForegroundColor White
            exit 1
        }
    }

    # Run the E2E integration tests
    Write-Host ""
    Write-Host "🧪 Running E2E Firebase integration tests..." -ForegroundColor Yellow
    Write-Host "🔧 Setting FIREBASE_EMULATOR_HOST=127.0.0.1 for tests..." -ForegroundColor Blue
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    
    # Set environment variable for emulator host and run integration tests
    $env:FIREBASE_EMULATOR_HOST = "127.0.0.1"
    $testOutput = flutter test integration_test/e2e_firebase_test.dart --dart-define=FIREBASE_EMULATOR_HOST=127.0.0.1 2>&1
    $testExitCode = $LASTEXITCODE
    
    # Display the test output
    Write-Host $testOutput
    
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    
    if ($testExitCode -eq 0) {
        Write-Host "🎉 All E2E tests passed!" -ForegroundColor Green
    } else {
        Write-Host "❌ Some E2E tests failed (exit code: $testExitCode)" -ForegroundColor Red
    }

} catch {
    Write-Host "❌ Error running E2E tests: $_" -ForegroundColor Red
    $testExitCode = 1
} finally {
    # Stop emulators if we started them
    if ($StopEmulators -and $emulatorJob) {
        Write-Host ""
        Write-Host "🛑 Stopping Firebase emulators..." -ForegroundColor Yellow
        try {
            Stop-Job $emulatorJob -ErrorAction SilentlyContinue
            Remove-Job $emulatorJob -Force -ErrorAction SilentlyContinue
            Write-Host "✅ Firebase emulators stopped" -ForegroundColor Green
        } catch {
            Write-Host "⚠️  Warning: Could not cleanly stop emulators: $_" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
if ($testExitCode -eq 0) {
    Write-Host "✅ E2E test run completed successfully!" -ForegroundColor Green
} else {
    Write-Host "❌ E2E test run completed with errors!" -ForegroundColor Red
}

exit $testExitCode
