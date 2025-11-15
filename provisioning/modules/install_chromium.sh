#!/usr/bin/env bash
set -euo pipefail

echo "=== Installing Snap Chromium + ChromeDriver ==="
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y wget curl unzip snapd

# Install Snap Chromium
sudo snap install chromium

# Create Google Chrome compatibility symlinks
sudo ln -sf /usr/bin/chromium-browser /usr/bin/google-chrome
sudo ln -sf /usr/bin/chromium-browser /usr/bin/google-chrome-stable

# Verify installation
CHROMIUM_BIN="/usr/bin/chromium-browser"
CHROMEDRIVER_BIN="/snap/bin/chromium.chromedriver"

if ! command -v "$CHROMIUM_BIN" &> /dev/null; then
  echo "Chromium binary not found at $CHROMIUM_BIN"
  exit 1
fi

if ! command -v "$CHROMEDRIVER_BIN" &> /dev/null; then
  echo "Chromedriver binary not found at $CHROMEDRIVER_BIN"
  exit 1
fi

echo "Chromium version: $($CHROMIUM_BIN --version)"
echo "ChromeDriver version: $($CHROMEDRIVER_BIN --version)"

echo "=== Snap Chromium module complete ==="
