@echo off
cd /d "%~dp0"

echo Building stb_image shared library...
gcc -shared -o stb_image.dll stb_image_impl.c -I. -lm
if errorlevel 1 (
    echo Trying cl.exe...
    cl /LD stb_image_impl.c /I. /Fe:stb_image.dll /link /EXPORT:*
)
if exist stb_image.dll echo Done: deps\stb_image.dll

echo Building stb_truetype shared library...
gcc -shared -o stb_truetype.dll stb_truetype_impl.c -I. -lm
if errorlevel 1 (
    echo Trying cl.exe...
    cl /LD stb_truetype_impl.c /I. /Fe:stb_truetype.dll /link /EXPORT:*
)
if exist stb_truetype.dll echo Done: deps\stb_truetype.dll

echo.
echo Build complete!
echo Copy .dll files to deps\ if they are not already there.
