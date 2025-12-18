# PHP Loaders Installer (ionCube & SourceGuardian)

[![GitHub](https://img.shields.io/badge/GitHub-Repository-blue?logo=github)](https://github.com/iranservervip/php_loaders)  
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A simple yet powerful Bash script to automatically install the latest versions of **ionCube Loader** and **SourceGuardian** on all active PHP versions on your server.

**Fully supports:**
- cPanel (EasyApache)
- DirectAdmin
- LiteSpeed Web Server (Standalone or combined with cPanel/DirectAdmin)
- Ubuntu, CentOS, AlmaLinux, and other Linux distributions

## Features
- Automatically detects the control panel / web server
- Identifies all active PHP versions (even multiple versions at once)
- Downloads the latest loaders directly from official sites (ioncube.com & sourceguardian.com)
- Installs extensions in the correct `extension_dir`
- Adds to `php.ini` or `conf.d` files (optimized for DirectAdmin/LiteSpeed)
- Graceful restart of services (zero downtime)
- Full logging to `/var/log/php_loaders_install.log`
- Colorful and attractive terminal interface with ASCII art
- Compatible with x86_64 and aarch64 architectures

## Requirements
- Root access (sudo)
- Internet connection
- Installed PHP versions (via cPanel, DirectAdmin, or LiteSpeed)

## Installation & Usage
1. Download the script:
   ```bash
   wget https://raw.githubusercontent.com/iranservervip/php_loaders/main/php_loaders.sh -O install_php_loaders.sh
   ```

2. Make it executable:
   ```bash
   chmod +x install_php_loaders.sh
   ```

3. Run the script:
   ```bash
   sudo ./install_php_loaders.sh
   ```

4. Follow the on-screen prompts:
   ```
   What would you like to install?
   1) ionCube Loader
   2) SourceGuardian Loader
   Enter your choice (1 or 2):
   ```

## Sample Output
```
=== PHP Loaders Installer Script ===
Created by: M.H.SAEIDI
Detected OS: ubuntu
Web Server: LiteSpeed detected
Active PHP versions: 8.1 8.2 8.3
Searching for active PHP versions...
...
Installation Completed Successfully
Log file: /var/log/php_loaders_install.log
```

## Verification
After installation, check if the loaders are active:

```bash
# For ionCube
php -m | grep -i ioncube

# For SourceGuardian
php -m | grep -i sourceguardian  # or 'ixed'

# Detailed info (look for zend_extension or extension line)
php -i | grep -i ioncube
php -i | grep -i sourceguardian
```

The log file (`/var/log/php_loaders_install.log`) contains full details of files copied and configurations updated.

## How It Works
1. Detects OS, control panel, and web server.
2. Finds all active PHP binaries and versions.
3. Downloads and installs the appropriate `.so` file.
4. Adds the extension to the correct `.ini` file.
5. Restarts services gracefully.

## Security Notes
- Downloads only from official sources.
- Files are owned by root:root with 755 permissions.
- No unnecessary changes to system files.

## License
MIT License – Free to use, modify, and distribute.

## Author
**M.H.SAEIDI**  
Email: [info@sepiol.ir]  
GitHub: [https://github.com/im-ecorp]

## Contributing
Pull requests are welcome! If you find a bug or want to add features (e.g., support for more panels), feel free to open an issue or PR.

Happy coding! 🚀
