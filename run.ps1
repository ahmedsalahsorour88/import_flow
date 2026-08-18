Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "Starting ImportFlow ERP (Backend & Frontend)" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

# Free port 8000 and 3000 if already in use
Get-NetTCPConnection -LocalPort 8000, 3000 -ErrorAction SilentlyContinue | ForEach-Object {
    $procId = $_.OwningProcess
    if ($procId -gt 0) {
        Write-Host "Freeing occupied port $($_.LocalPort) (PID: $procId)..." -ForegroundColor Yellow
        Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
    }
}

Start-Sleep -Seconds 1

# Start Backend in new process
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PSScriptRoot'; python -m uvicorn main:app --host 0.0.0.0 --port 8000"

Start-Sleep -Seconds 2

# Start Frontend in new process
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PSScriptRoot/frontend'; flutter run -d web-server --web-port 3000 --web-hostname 0.0.0.0"

Write-Host "Backend running at:  http://localhost:8000" -ForegroundColor Green
Write-Host "Frontend running at: http://localhost:3000" -ForegroundColor Green
