@echo off
powershell -Command "Start-Process powershell -Verb RunAs -ArgumentList '-Command Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value \"`n127.0.0.1`tapi.importflow.local\"'"
