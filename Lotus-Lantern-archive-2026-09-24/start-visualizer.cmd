@echo off
title Lotus Lantern - Audio Visualizer
color 0B

echo ============================================
echo    LOTUS LANTERN - AUDIO VISUALIZER
echo ============================================
echo.
echo   Captures PC audio and syncs with LED strip
echo   Press Ctrl+C to stop
echo.
echo ============================================
echo.

cd /d "%~dp0"

python visualizer.py

pause
