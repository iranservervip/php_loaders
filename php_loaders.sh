#!/bin/bash

# PHP Loaders Installer Script (ionCube & SourceGuardian)
# Author: M.H.SAEIDI
# Version: 2.3 | Date: December 2025
# Optimized: Single download for loaders

# Check for root access
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with root privileges (sudo)."
  exit 1
fi

# Log file setup
LOG_FILE="/var/log/php_loaders_install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== ionCube/SourceGuardian Installation Started ==="
echo "Execution Date: $(date)"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ASCII Art
echo -e "${GREEN}"
cat << 'EOF'
###################################################################
# ██████╗  ██████╗ ██╗    ██╗███████╗██████╗ ██████╗ ██╗   ██╗    #
# ██╔══██╗██╔═══██╗██║    ██║██╔════╝██╔══██╗██╔══██╗╚██╗ ██╔╝    #
# ██████╔╝██║   ██║██║ █╗ ██║█████╗  ██████╔╝██████╔╝ ╚████╔╝     #
# ██╔═══╝ ██║   ██║██║███╗██║██╔══╝  ██╔══██╗██╔══██╗  ╚██╔╝      #
# ██║     ╚██████╔╝╚███╔███╔╝███████╗██║  ██║██████╔╝   ██║       #
# ╚═╝      ╚═════╝  ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚═════╝    ╚═╝       #
#                                                                 #
EOF
echo -e "${RED}"
cat << 'EOF'
# ███╗   ███╗   ██╗  ██╗   ███████╗ █████╗ ███████╗██╗██████╗ ██╗ #
# ████╗ ████║   ██║  ██║   ██╔════╝██╔══██╗██╔════╝██║██╔══██╗██║ #
# ██╔████╔██║   ███████║   ███████╗███████║█████╗  ██║██║  ██║██║ #
# ██║╚██╔╝██║   ██╔══██║   ╚════██║██╔══██║██╔══╝  ██║██║  ██║██║ #
# ██║ ╚═╝ ██║██╗██║  ██║██╗███████║██║  ██║███████╗██║██████╔╝██║ #
# ╚═╝     ╚═╝╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚═╝  ╚═╝╚══════╝╚═╝╚═════╝ ╚═╝ #
###################################################################
EOF
echo -e "${NC}"

echo "============================================================="
echo "  PHP Loaders Installer Script (ionCube & SourceGuardian)"
echo "  Created by: ${RED}M.H.SAEIDI${NC}"
echo "  Version: 2.3 | Date: $(date +%Y-%m-%d)"
echo "============================================================="

# Detect OS and environment
if [ -f /etc/os-release ]; then
  OS=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
else
  OS="unknown"
fi
echo "Detected OS: $OS"

WEB_SERVER="apache"
if [ -d "/usr/local/lsws" ]; then
    WEB_SERVER="litespeed"
    echo "Web Server: LiteSpeed detected"
elif [ -d "/usr/local/cpanel" ]; then
    WEB_SERVER="cpanel"
    echo "Control Panel: cPanel detected"
elif [ -d "/usr/local/directadmin" ]; then
    WEB_SERVER="directadmin"
    echo "Control Panel: DirectAdmin detected"
else
    echo "No supported environment found!"
    exit 1
fi

# Find PHP versions
echo "Searching for active PHP versions..."
PHP_BINARIES=$(ls /usr/local/lsws/lsphp*/bin/{php,lsphp} /usr/local/php*/bin/php /opt/cpanel/ea-php*/bin/php /usr/bin/php* 2>/dev/null | grep -E '/php[0-9]' | sort -u)

echo "Found PHP binaries: $PHP_BINARIES"

INSTALLED_VERSIONS=""
for php_bin in $PHP_BINARIES; do
    [ -x "$php_bin" ] || continue
    VER=$("$php_bin" -v 2>/dev/null | grep -oP 'PHP \K[0-9]+\.[0-9]+' | head -1)
    [ -n "$VER" ] && INSTALLED_VERSIONS="$INSTALLED_VERSIONS $VER"
done

INSTALLED_VERSIONS=$(echo "$INSTALLED_VERSIONS" | tr ' ' '\n' | sort -u | tr '\n' ' ')

if [ -z "$INSTALLED_VERSIONS" ]; then
    echo "ERROR: No PHP versions found!"
    exit 1
fi

echo "Active PHP versions: $INSTALLED_VERSIONS"

# User selection
echo "-----------------------------------------------------"
echo -e "${YELLOW}What would you like to install?${NC}"
echo "1) ionCube Loader"
echo "2) SourceGuardian Loader"
echo -e "${YELLOW}Enter your choice (1 or 2): ${NC}"
read -p "" CHOICE
echo "User selected: $CHOICE"

[[ ! "$CHOICE" =~ ^[1-2]$ ]] && { echo "Invalid choice!"; exit 1; }

# Temporary directory for loaders
TMP_DIR="/tmp/php_loaders_$$"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

# Robust download function
download_file() {
  local url=$1
  local output=$2
  echo "Downloading $output..."

  if command -v wget >/dev/null; then
    wget -q --no-check-certificate --tries=3 --timeout=30 "$url" -O "$output" && return 0
  fi
  if command -v curl >/dev/null; then
    curl -L -k --retry 3 --connect-timeout 30 "$url" -o "$output" && return 0
  fi
  echo "Download failed for $url"
  return 1
}

# Pre-download loaders (only once)
if [ "$CHOICE" = "1" ]; then
  echo "Preparing ionCube Loader (single download)..."
  ARCH=$(uname -m)
  [ "$ARCH" = "x86_64" ] && ARCH="x86-64"
  download_file "https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_${ARCH}.tar.gz" "ioncube.tar.gz" || { echo "ionCube download failed"; exit 1; }
  tar -xzf ioncube.tar.gz || { echo "Failed to extract ionCube"; exit 1; }
  LOADER_DIR="ioncube"
elif [ "$CHOICE" = "2" ]; then
  echo "Preparing SourceGuardian Loader (single download)..."
  ARCH=$(uname -m)
  if [ "$ARCH" = "x86_64" ]; then
    URL="https://www.sourceguardian.com/loaders/download/loaders.linux-x86_64.tar.gz"
  elif [ "$ARCH" = "aarch64" ]; then
    URL="https://www.sourceguardian.com/loaders/download/loaders.linux-aarch64.tar.gz"
  else
    echo "Unsupported architecture: $ARCH"
    exit 1
  fi
  download_file "$URL" "sg_loaders.tar.gz" || { echo "SourceGuardian download failed"; exit 1; }
  tar -xzf sg_loaders.tar.gz || { echo "Failed to extract SourceGuardian"; exit 1; }
  LOADER_DIR="."
fi

# Helper: get PHP paths
get_php_paths() {
  local PHP_PATH=$1
  EXT_DIR=$("$PHP_PATH" -i 2>/dev/null | grep '^extension_dir' | awk '{print $3}' | tr -d "'")
  INI_FILE=$("$PHP_PATH" --ini 2>/dev/null | grep "Loaded Configuration File" | awk '{print $4}')
  SCAN_DIR=$("$PHP_PATH" --ini 2>/dev/null | grep "Scan for additional .ini files in" | awk -F': ' '{print $2}' | tr -d "'")
}

# Install loop
for VER in $INSTALLED_VERSIONS; do
  BINARY_PATH=$(ls /usr/local/lsws/lsphp${VER//./}/bin/{php,lsphp} /usr/local/php${VER//./}/bin/php 2>/dev/null | head -1)
  [ -z "$BINARY_PATH" ] && BINARY_PATH=$(ls /opt/cpanel/ea-php${VER//./}/bin/php 2>/dev/null | head -1)

  if [ -n "$BINARY_PATH" ] && [ -x "$BINARY_PATH" ]; then
    echo "Processing PHP $VER → $BINARY_PATH"
    get_php_paths "$BINARY_PATH"

    if [ -z "$EXT_DIR" ]; then
      echo "Warning: Could not determine extension_dir for PHP $VER"
      continue
    fi

    if [ "$CHOICE" = "1" ]; then
      LOADER_FILE="ioncube_loader_lin_${VER}.so"
      SOURCE_PATH="$LOADER_DIR/$LOADER_FILE"
      if [ -f "$SOURCE_PATH" ]; then
        cp "$SOURCE_PATH" "$EXT_DIR/"
        chown root:root "$EXT_DIR/$LOADER_FILE"
        chmod 755 "$EXT_DIR/$LOADER_FILE"
        if [ -n "$SCAN_DIR" ]; then
          echo "zend_extension=$EXT_DIR/$LOADER_FILE" > "$SCAN_DIR/98-ioncube.ini"
          echo "Added ionCube → $SCAN_DIR/98-ioncube.ini"
        else
          grep -q "$LOADER_FILE" "$INI_FILE" || echo "zend_extension=$EXT_DIR/$LOADER_FILE" >> "$INI_FILE"
          echo "Added ionCube → $INI_FILE"
        fi
        echo "ionCube installed for PHP $VER"
      else
        echo "Warning: ionCube loader for PHP $VER not available in package"
      fi

    else  # SourceGuardian
      LOADER_FILE="ixed.${VER}.lin"
      SOURCE_PATH="$LOADER_DIR/$LOADER_FILE"
      if [ -f "$SOURCE_PATH" ]; then
        cp "$SOURCE_PATH" "$EXT_DIR/"
        chown root:root "$EXT_DIR/$LOADER_FILE"
        chmod 755 "$EXT_DIR/$LOADER_FILE"
        if [ -n "$SCAN_DIR" ]; then
          echo "extension=$EXT_DIR/$LOADER_FILE" > "$SCAN_DIR/99-sourceguardian.ini"
          echo "Added SourceGuardian → $SCAN_DIR/99-sourceguardian.ini"
        else
          grep -q "$LOADER_FILE" "$INI_FILE" || echo "extension=$EXT_DIR/$LOADER_FILE" >> "$INI_FILE"
          echo "Added SourceGuardian → $INI_FILE"
        fi
        echo "SourceGuardian installed for PHP $VER"
      else
        echo "Warning: SourceGuardian loader for PHP $VER not available in package"
      fi
    fi
  else
    echo "Warning: Binary not found for PHP $VER"
  fi
done

# Cleanup
cd /
rm -rf "$TMP_DIR"

# Restart services
echo "Restarting services..."
if [ "$WEB_SERVER" = "litespeed" ]; then
  /usr/local/lsws/bin/lswsctrl restart >/dev/null 2>&1 && echo "LiteSpeed restarted"
  /usr/local/lsws/bin/lswsctrl restart-lsphp >/dev/null 2>&1 && echo "LSPHP restarted"
fi

# Final
echo "-----------------------------------------------------"
echo "=== Installation Completed Successfully ==="
echo "Log: $LOG_FILE"
echo "Verify with:"
echo "  /usr/local/php74/bin/php -m | grep ixed   # SourceGuardian on 7.4"
echo "  php -m | grep -i sourceguardian"
echo "Thank you for using M.H.SAEIDI's script! 🚀"
