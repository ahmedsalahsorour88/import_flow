#!/bin/bash

echo "===================================================="
echo "Starting ImportFlow ERP (Backend & Frontend)"
echo "===================================================="

# Start FastAPI Backend in background
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload &
BACKEND_PID=$!
echo "Backend started with PID $BACKEND_PID at http://localhost:8000"

# Wait 2 seconds
sleep 2

# Start Flutter Web Frontend
cd frontend
flutter run -d web-server --web-port 3000 --web-hostname 0.0.0.0 &
FRONTEND_PID=$!
echo "Frontend started with PID $FRONTEND_PID at http://localhost:3000"

echo ""
echo "Both services are running!"
echo "Backend:  http://localhost:8000"
echo "Frontend: http://localhost:3000"

wait
