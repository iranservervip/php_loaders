#!/bin/bash

# Check for root access
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with root privileges (sudo)."
  exit 1
fi

# Log file setup (ASCII art only printed to terminal, not logged)
LOG_FILE="/var/log/php_loaders_install.log"
echo "=== ionCube/SourceGuardian Installation Started ===" | tee -a "$LOG_FILE"
echo "Execution Date: $(date)" | tee -a "$LOG_FILE"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color
YELLOW='\033[1;33m'

# Print ASCII art in green and red (only to terminal)
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

echo "=============================================================" | tee -a "$LOG_FILE"
echo "  PHP Loaders Installer Script (ionCube & SourceGuardian)" | tee -a "$LOG_FILE"
echo "  Created by: M.H.SAEIDI" | tee -a "$LOG_FILE"
echo "  Version: 2.0 | Date: $(date +%Y-%m-%d)" | tee -a "$LOG_FILE"
echo "=============================================================" | tee -a "$LOG_FILE"

# Detect OS
if [ -f /etc/os-release ]; then
  OS=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
else
  OS="unknown"
fi
echo "Detected OS: $OS" | tee -a "$LOG_FILE"

# Detect web server / control panel
WEB_SERVER="apache"  # default
CPANEL=""
if [ -d "/usr/local/lsws" ]; then
    WEB_SERVER="litespeed"
    echo "Web Server: LiteSpeed (or OpenLiteSpeed) detected" | tee -a "$LOG_FILE"
elif [ -d "/usr/local/cpanel" ]; then
    CPANEL="cpanel"
    echo "Control Panel: cPanel detected" | tee -a "$LOG_FILE"
elif [ -d "/usr/local/directadmin" ]; then
    CPANEL="directadmin"
    echo "Control Panel: DirectAdmin detected" | tee -a "$LOG_FILE"
else
    echo "No supported web server or control panel found! This script works only with cPanel, DirectAdmin, or LiteSpeed." | tee -a "$LOG_FILE"
    exit 1
fi

# Find active PHP versions
echo "Searching for active PHP versions..." | tee -a "$LOG_FILE"

if [ "$WEB_SERVER" == "litespeed" ]; then
  PHP_BINARIES=$(ls /usr/local/lsws/lsphp*/bin/php 2>/dev/null)
elif [ "$CPANEL" == "cpanel" ]; then
  PHP_BINARIES=$(ls /opt/cpanel/ea-php*/bin/php 2>/dev/null)
elif [ "$CPANEL" == "directadmin" ]; then
  PHP_BINARIES=$(ls /usr/local/php*/bin/php 2>/dev/null)
fi

INSTALLED_VERSIONS=""
for php in $PHP_BINARIES; do
  VER=$($php -v 2>/dev/null | grep -oP 'PHP \K[0-9]+\.[0-9]+' | head -1)
  if [ ! -z "$VER" ]; then
    INSTALLED_VERSIONS="$INSTALLED_VERSIONS $VER"
  fi
done

INSTALLED_VERSIONS=$(echo "$INSTALLED_VERSIONS" | tr ' ' '\n' | sort -u | tr '\n' ' ')

if [ -z "$INSTALLED_VERSIONS" ]; then
  echo "No active PHP versions found!" | tee -a "$LOG_FILE"
  exit 1
fi

echo "Active PHP versions: $INSTALLED_VERSIONS" | tee -a "$LOG_FILE"

# User choice with colors
echo "-----------------------------------------------------" | tee -a "$LOG_FILE"
echo -e "${YELLOW}What would you like to install?${NC}"
echo "1) ionCube Loader"
echo "2) SourceGuardian Loader"
echo -e "${YELLOW}Enter your choice (1 or 2): ${NC}"
read -p "" CHOICE
echo "User selected: $CHOICE" | tee -a "$LOG_FILE"

# Helper function to get PHP paths
get_php_paths() {
  local PHP_PATH=$1
  EXT_DIR=$($PHP_PATH -i 2>/dev/null | grep '^extension_dir' | awk '{print $3}' | tr -d "'")
  INI_FILE=$($PHP_PATH --ini 2>/dev/null | grep "Loaded Configuration File" | awk '{print $4}')
  SCAN_DIR=$($PHP_PATH --ini 2>/dev/null | grep "Scan for additional .ini files in" | awk -F': ' '{print $2}' | tr -d "'")
}

install_ioncube() {
  local PHP_VER=$1
  local PHP_PATH=$2
  get_php_paths "$PHP_PATH"

  if [ -z "$EXT_DIR" ] || [ -z "$INI_FILE" ]; then
    echo "Error: Could not find extension_dir or php.ini for PHP $PHP_VER!" | tee -a "$LOG_FILE"
    return 1
  fi

  echo "Installing ionCube Loader for PHP $PHP_VER in $EXT_DIR" | tee -a "$LOG_FILE"

  cd /tmp || exit 1
  rm -f ioncube_loaders_lin_* >/dev/null 2>&1

  ARCH=$(uname -m)
  if [ "$ARCH" == "x86_64" ]; then
    ARCH="x86-64"
  elif [ "$ARCH" == "aarch64" ]; then
    ARCH="aarch64"
  else
    echo "Unsupported architecture: $ARCH" | tee -a "$LOG_FILE"
    return 1
  fi

  wget -q --no-check-certificate "https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_${ARCH}.tar.gz"
  if [ $? -ne 0 ]; then
    echo "Download of ionCube failed!" | tee -a "$LOG_FILE"
    return 1
  fi

  tar -xzf ioncube_loaders_lin_${ARCH}.tar.gz
  LOADER="ioncube/ioncube_loader_lin_${PHP_VER}.so"

  if [ ! -f "$LOADER" ]; then
    echo "ionCube loader for PHP $PHP_VER not found!" | tee -a "$LOG_FILE"
    rm -rf ioncube* >/dev/null 2>&1
    return 1
  fi

  cp "$LOADER" "$EXT_DIR/"
  chown root:root "$EXT_DIR/ioncube_loader_lin_${PHP_VER}.so"
  chmod 755 "$EXT_DIR/ioncube_loader_lin_${PHP_VER}.so"

  if [ ! -z "$SCAN_DIR" ]; then
    EXT_INI="$SCAN_DIR/98-ioncube.ini"
    echo "zend_extension=$EXT_DIR/ioncube_loader_lin_${PHP_VER}.so" > "$EXT_INI"
    echo "Added ionCube to: $EXT_INI" | tee -a "$LOG_FILE"
  else
    if ! grep -q "ioncube_loader_lin_${PHP_VER}.so" "$INI_FILE"; then
      echo "zend_extension=$EXT_DIR/ioncube_loader_lin_${PHP_VER}.so" >> "$INI_FILE"
      echo "Added ionCube to: $INI_FILE" | tee -a "$LOG_FILE"
    else
      echo "ionCube already present in $INI_FILE" | tee -a "$LOG_FILE"
    fi
  fi

  rm -rf ioncube* ioncube_loaders_lin_* >/dev/null 2>&1
  echo "ionCube successfully installed for PHP $PHP_VER" | tee -a "$LOG_FILE"
}

install_sourceguardian() {
  local PHP_VER=$1
  local PHP_PATH=$2
  get_php_paths "$PHP_PATH"

  if [ -z "$EXT_DIR" ] || [ -z "$INI_FILE" ]; then
    echo "Error: Could not find extension_dir or php.ini for PHP $PHP_VER!" | tee -a "$LOG_FILE"
    return 1
  fi

  echo "Installing SourceGuardian Loader for PHP $PHP_VER in $EXT_DIR" | tee -a "$LOG_FILE"

  cd /tmp || exit 1
  rm -f loaders.linux-* sg_loaders.tar.gz >/dev/null 2>&1

  ARCH=$(uname -m)
  if [ "$ARCH" == "x86_64" ]; then
    wget -q "https://www.sourceguardian.com/loaders/download/loaders.linux-x86_64.tar.gz" -O sg_loaders.tar.gz
  elif [ "$ARCH" == "aarch64" ]; then
    wget -q "https://www.sourceguardian.com/loaders/download/loaders.linux-aarch64.tar.gz" -O sg_loaders.tar.gz
  else
    echo "Unsupported architecture: $ARCH" | tee -a "$LOG_FILE"
    return 1
  fi

  if [ $? -ne 0 ]; then
    echo "Download of SourceGuardian failed!" | tee -a "$LOG_FILE"
    return 1
  fi

  tar -xzf sg_loaders.tar.gz
  LOADER="ixed.${PHP_VER}.lin"

  if [ ! -f "$LOADER" ]; then
    echo "SourceGuardian loader for PHP $PHP_VER not found!" | tee -a "$LOG_FILE"
    rm -f ixed.* sg_loaders.tar.gz >/dev/null 2>&1
    return 1
  fi

  cp "$LOADER" "$EXT_DIR/"
  chown root:root "$EXT_DIR/$LOADER"
  chmod 755 "$EXT_DIR/$LOADER"

  if [ ! -z "$SCAN_DIR" ]; then
    EXT_INI="$SCAN_DIR/99-sourceguardian.ini"
    echo "extension=$EXT_DIR/$LOADER" > "$EXT_INI"
    echo "Added SourceGuardian to: $EXT_INI" | tee -a "$LOG_FILE"
  else
    if ! grep -q "ixed.${PHP_VER}.lin" "$INI_FILE"; then
      echo "extension=$EXT_DIR/$LOADER" >> "$INI_FILE"
      echo "Added SourceGuardian to: $INI_FILE" | tee -a "$LOG_FILE"
    else
      echo "SourceGuardian already present in $INI_FILE" | tee -a "$LOG_FILE"
    fi
  fi

  rm -f ixed.* sg_loaders.tar.gz >/dev/null 2>&1
  echo "SourceGuardian successfully installed for PHP $PHP_VER" | tee -a "$LOG_FILE"
}

# Apply to all PHP versions
for VER in $INSTALLED_VERSIONS; do
  if [ "$WEB_SERVER" == "litespeed" ]; then
    BINARY_PATH="/usr/local/lsws/lsphp${VER//./}/bin/php"
  elif [ "$CPANEL" == "cpanel" ]; then
    BINARY_PATH="/opt/cpanel/ea-php${VER//./}/bin/php"
  elif [ "$CPANEL" == "directadmin" ]; then
    BINARY_PATH="/usr/local/php${VER//./}/bin/php"
  fi

  if [ -f "$BINARY_PATH" ]; then
    case $CHOICE in
      1) install_ioncube "$VER" "$BINARY_PATH" ;;
      2) install_sourceguardian "$VER" "$BINARY_PATH" ;;
      *) echo "Invalid choice!" | tee -a "$LOG_FILE"; exit 1 ;;
    esac
  else
    echo "PHP binary path not found for $VER: $BINARY_PATH" | tee -a "$LOG_FILE"
  fi
done

# Restart services
echo "Restarting services to apply changes..." | tee -a "$LOG_FILE"
if [ "$WEB_SERVER" == "litespeed" ]; then
  /usr/local/lsws/bin/lswsctrl restart >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "LiteSpeed gracefully restarted successfully." | tee -a "$LOG_FILE"
  else
    echo "LiteSpeed restart failed. Trying alternative command..." | tee -a "$LOG_FILE"
    service lsws restart >/dev/null 2>&1 || echo "Service restart failed. Please restart LiteSpeed manually." | tee -a "$LOG_FILE"
  fi
  /usr/local/lsws/bin/lswsctrl restart-lsphp >/dev/null 2>&1 || echo "LSPHP processes restarted." | tee -a "$LOG_FILE"
elif [ "$CPANEL" == "cpanel" ]; then
  /scripts/restartsrv_httpd >/dev/null 2>&1
  /scripts/restartsrv_apache_php_fpm >/dev/null 2>&1
  /scripts/restartsrv_cpanel_php_fpm >/dev/null 2>&1
elif [ "$CPANEL" == "directadmin" ]; then
  systemctl restart httpd apache2 nginx >/dev/null 2>&1
  /usr/local/directadmin/directadmin restart >/dev/null 2>&1
  for ver in $INSTALLED_VERSIONS; do
    systemctl restart "php-fpm${ver//./}" >/dev/null 2>&1
  done
fi

# Final summary
echo "-----------------------------------------------------" | tee -a "$LOG_FILE"
echo "=== Installation Completed Successfully ===" | tee -a "$LOG_FILE"
echo "Log file created at: $LOG_FILE" | tee -a "$LOG_FILE"
echo "To verify installation:" | tee -a "$LOG_FILE"
echo "  1. Run: php -m | grep -i ioncube  (for ionCube) or grep -i sourceguardian" | tee -a "$LOG_FILE"
echo "  2. Check if 'ioncube_loader' or 'ixed' appears in the output." | tee -a "$LOG_FILE"
echo "  3. For each PHP version, run: php -i | grep zend_extension or extension" | tee -a "$LOG_FILE"
echo "     Look for the added line (e.g., zend_extension=...ioncube_loader... or extension=...ixed...)" | tee -a "$LOG_FILE"
echo "  4. Check the log file for details on which files were modified." | tee -a "$LOG_FILE"
echo "If any issues occur, review the log file or contact support." | tee -a "$LOG_FILE"
