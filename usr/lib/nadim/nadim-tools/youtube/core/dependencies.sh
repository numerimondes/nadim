#!/bin/bash

# Detect platform
OS=$(uname -s)
case "$OS" in
    Linux*)
        if command -v apt >/dev/null 2>&1; then
            sudo apt update && sudo apt install -y jq sed python3-pip
            pip3 install yt-dlp
        else
            echo "Unsupported Linux package manager. Install yt-dlp, jq, sed manually."
            exit 1
        fi
        ;;
    Darwin*)
        if command -v brew >/dev/null 2>&1; then
            brew install yt-dlp jq
        else
            echo "Homebrew not found. Install it from https://brew.sh, then run: brew install yt-dlp jq"
            exit 1
        fi
        ;;
    MINGW*|MSYS*|CYGWIN*)
        if command -v pip >/dev/null 2>&1; then
            pip install yt-dlp
            # Download jq binary for Windows
            curl -L -o jq.exe https://github.com/stedolan/jq/releases/download/jq-1.6/jq-win64.exe
            mv jq.exe /usr/bin/jq
            # sed is typically included in Git Bash
        else
            echo "pip not found. Install Python and pip, then run: pip install yt-dlp"
            exit 1
        fi
        ;;
    *)
        echo "Unsupported platform. Install yt-dlp, jq, sed manually."
        exit 1
        ;;
esac

# Verify installations
for cmd in yt-dlp jq sed; do
    if ! command -v $cmd >/dev/null 2>&1; then
        echo "Failed to install $cmd."
        exit 1
    fi
done
echo "Dependencies installed successfully."