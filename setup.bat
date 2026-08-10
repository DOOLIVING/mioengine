@echo off
setlocal enabledelayedexpansion

echo ============================================
echo   MioEngine - Windows Setup
echo ============================================
echo.

set DEPS=%~dp0deps
set T=%~dp0_temp_setup

if not exist "%DEPS%" mkdir "%DEPS%"
if not exist "%T%" mkdir "%T%"

powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12"

where gcc >nul 2>&1
if %errorlevel% equ 0 (
    set CC=gcc
    echo [OK] gcc found
) else (
    where cl >nul 2>&1
    if %errorlevel% equ 0 (
        set CC=cl
        echo [OK] MSVC cl found
    ) else (
        echo [ERROR] No compiler found. Install MinGW or Visual Studio Build Tools.
        goto :done
    )
)

where luajit >nul 2>&1
if %errorlevel% neq 0 (
    echo [GET] LuaJIT...
    powershell -Command "Invoke-WebRequest -Uri 'https://luajit.org/download/LuaJIT-2.1.0-beta3-win64.zip' -OutFile '%T%\luajit.zip'"
    powershell -Command "Expand-Archive -Path '%T%\luajit.zip' -DestinationPath '%T%\luajit' -Force"
    for /r "%T%\luajit" %%f in (luajit.exe) do copy "%%f" "%DEPS%\luajit.exe" >nul
    if exist "%DEPS%\luajit.exe" (echo [OK] LuaJIT) else (echo [FAIL] LuaJIT)
) else (
    echo [OK] luajit already installed
)

if not exist "%DEPS%\glfw3.dll" (
    echo [GET] GLFW 3.4...
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/glfw/glfw/releases/download/3.4/glfw-3.4.bin.WIN64.zip' -OutFile '%T%\glfw.zip'"
    powershell -Command "Expand-Archive -Path '%T%\glfw.zip' -DestinationPath '%T%\glfw' -Force"
    for %%v in (bin-vc2022 bin-vc2019 bin-vc2017 bin-mingw) do (
        if exist "%T%\glfw\glfw-3.4.bin.WIN64\%%v\glfw3.dll" (
            copy "%T%\glfw\glfw-3.4.bin.WIN64\%%v\glfw3.dll" "%DEPS%\glfw3.dll" >nul
            goto :glfw_ok
        )
    )
    echo [FAIL] GLFW
    goto :glfw_done
    :glfw_ok
    echo [OK] glfw3.dll
) else (
    echo [OK] glfw3.dll already exists
)
:glfw_done

if not exist "%DEPS%\assimp.dll" (
    echo [GET] Assimp 5.4.3...
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/assimp/assimp/releases/download/v5.4.3/assimp-5.4.3-win32.zip' -OutFile '%T%\assimp.zip'"
    powershell -Command "Expand-Archive -Path '%T%\assimp.zip' -DestinationPath '%T%\assimp' -Force"
    for /r "%T%\assimp" %%f in (assimp.dll libassimp.dll) do (
        if exist "%%f" (
            copy "%%f" "%DEPS%\assimp.dll" >nul
            goto :assimp_ok
        )
    )
    echo [FAIL] Assimp
    goto :assimp_done
    :assimp_ok
    echo [OK] assimp.dll
) else (
    echo [OK] assimp.dll already exists
)
:assimp_done

if not exist "%DEPS%\OpenAL32.dll" (
    echo [GET] OpenAL Soft...
    powershell -Command "Invoke-WebRequest -Uri 'https://openal-soft.org/openal-binaries/openal-soft-1.23.1-bin.zip' -OutFile '%T%\openal.zip'"
    powershell -Command "Expand-Archive -Path '%T%\openal.zip' -DestinationPath '%T%\openal' -Force"
    for /r "%T%\openal" %%f in (OpenAL32.dll) do (
        copy "%%f" "%DEPS%\OpenAL32.dll" >nul
        goto :openal_ok
    )
    echo [FAIL] OpenAL
    goto :openal_done
    :openal_ok
    echo [OK] OpenAL32.dll
) else (
    echo [OK] OpenAL32.dll already exists
)
:openal_done

echo.
if "%CC%"=="gcc" (
    echo [BUILD] stb_image.dll
    gcc -shared -o "%DEPS%\stb_image.dll" "%DEPS%\stb_image_impl.c" -I"%DEPS%" -lm
    echo [BUILD] stb_truetype.dll
    gcc -shared -o "%DEPS%\stb_truetype.dll" "%DEPS%\stb_truetype_impl.c" -I"%DEPS%" -lm
) else (
    echo [BUILD] stb_image.dll (MSVC)
    cl /LD "%DEPS%\stb_image_impl.c" /I"%DEPS%" /Fe:"%DEPS%\stb_image.dll" >nul 2>&1
    echo [BUILD] stb_truetype.dll (MSVC)
    cl /LD "%DEPS%\stb_truetype_impl.c" /I"%DEPS%" /Fe:"%DEPS%\stb_truetype.dll" >nul 2>&1
)

if exist "%DEPS%\stb_image.dll" echo [OK] stb_image.dll
if exist "%DEPS%\stb_truetype.dll" echo [OK] stb_truetype.dll

echo.
echo Copying DLLs to project root...
for %%f in ("%DEPS%\*.dll") do copy "%%f" "%~dp0" >nul 2>&1

echo.
echo Cleaning up...
rmdir /s /q "%T%" 2>nul

echo.
echo ============================================
echo   Done! Deps:
echo ============================================
dir /b "%DEPS%\*.dll" 2>nul
echo.
echo Run:  luajit main.lua
echo.

:done
endlocal
pause
