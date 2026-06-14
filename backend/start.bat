@echo off
echo ========================================
echo AI Companion Backend Startup Script
echo ========================================
echo.

cd /d "%~dp0"

echo Current directory: %CD%
echo.

if exist "pom.xml" (
    echo Found pom.xml, starting Maven...
    echo.
    
    REM 尝试使用 mvn 命令
    where mvn >nul 2>&1
    if %errorlevel% equ 0 (
        echo Using Maven from PATH
        mvn spring-boot:run
    ) else (
        echo Maven not found in PATH
        echo.
        echo Please set MAVEN_HOME environment variable or add Maven to PATH
        echo.
        echo Alternative: Open this project in IntelliJ IDEA and run from there
        pause
    )
) else (
    echo ERROR: pom.xml not found!
    echo Please run this script from the backend directory
    pause
)
