#!/bin/bash
# install.sh - Manual installation script
# License: GPL-3.0
set -e
INSTALL_DIR="/usr/lib/nadim"
BIN_DIR="/usr/bin"
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi
echo "Installing Nadim Dolphin Rescue..."
mkdir -p "$INSTALL_DIR"
cp -r * "$INSTALL_DIR/"
ln -sf "$INSTALL_DIR/nadim.sh" "$BIN_DIR/nadim"
ln -sf "$INSTALL_DIR/nadimdr.sh" "$BIN_DIR/nadimdr"
ln -sf "$INSTALL_DIR/nsh.sh" "$BIN_DIR/nsh"
echo "Installation complete."
echo "Run 'nadim help' to get started."
