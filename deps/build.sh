#!/bin/bash
set -e
cd "$(dirname "$0")"

OS=$(uname -s)
case "$OS" in
    Darwin) EXT="dylib"; PREFIX="lib"; CC_FLAGS="-shared -framework CoreServices";;
    Linux)  EXT="so";    PREFIX="lib"; CC_FLAGS="-shared -lm";;
    MINGW*|MSYS*|CYGWIN*) EXT="dll"; PREFIX=""; CC_FLAGS="-shared -lm";;
    *) echo "Unknown OS: $OS"; exit 1;;
esac

echo "Building stb_image shared library..."
cc -shared -o ${PREFIX}stb_image.${EXT} stb_image_impl.c -I. $CC_FLAGS
echo "Done: deps/${PREFIX}stb_image.${EXT}"

echo "Building stb_truetype shared library..."
cc -shared -o ${PREFIX}stb_truetype.${EXT} stb_truetype_impl.c -I. $CC_FLAGS
echo "Done: deps/${PREFIX}stb_truetype.${EXT}"

echo ""
echo "Build complete!"
