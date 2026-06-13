@echo off
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "%~dp0forz_retrieve.ps1"
pause
