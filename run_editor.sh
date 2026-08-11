#!/bin/bash
cd "$(dirname "$0")"
luajit editor_main.lua "$@"
