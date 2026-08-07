Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "Starting ImportFlow ERP (Backend & Frontend)" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

# Start Backend in new process
Start-Process powershell -ArgumentList "-NoExit", "-Command", "python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload"

Start-Sleep -Seconds 2

# Start Frontend in new process
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd frontend; flutter run -d web-server --web-port 3000 --web-hostname 0.0.0.0"

Write-Host "Backend running at:  http://localhost:8000" -ForegroundColor Green
Write-Host "Frontend running at: http://localhost:3000" -ForegroundColor Green
