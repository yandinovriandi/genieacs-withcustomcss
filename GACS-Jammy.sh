#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to display spinner
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf "${CYAN} [%c]  ${NC}" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Function to run command with progress
run_command() {
    local cmd="$1"
    local msg="$2"
    printf "${YELLOW}%-50s${NC}" "$msg..."
    eval "$cmd" > /dev/null 2>&1 &
    spinner $!
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Done${NC}"
    else
        echo -e "${RED}Failed${NC}"
        exit 1
    fi
}

# Print banner
print_banner() {
	echo -e "${BLUE}${BOLD}"
	echo "   ____    _    ____ ____     ____            _       _   "
	echo "  / ___|  / \  / ___/ ___|   / ___|  ___ _ __(_)_ __ | |_ "
	echo " | |  _  / _ \| |   \___ \   \___ \ / __| '__| | '_ \| __|"
	echo " | |_| |/ ___ \ |___ ___) |   ___) | (__| |  | | |_) | |_ "
	echo "  \____/_/   \_\____|____/   |____/ \___|_|  |_| .__/ \__|"
	echo "                                               |_|        "
	echo ""
	echo "                  --- Ubuntu 22.04 ---"
	echo "                  --- By Mostech ---"
	echo "           (With Custom UI & Mobile Support)"
	echo -e "${NC}"
}

# Check for root access
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
fi

# Check Ubuntu version
if [ "$(lsb_release -cs)" != "jammy" ]; then
    echo -e "${RED}This script only supports Ubuntu 22.04 (Jammy)${NC}"
    exit 1
fi

# Print banner
print_banner

# Main installation process
total_steps=32
current_step=0

echo -e "\n${MAGENTA}${BOLD}Starting GenieACS Installation Process${NC}\n"

run_command "apt-get update -y" "Updating system ($(( ++current_step ))/$total_steps)"

run_command "sed -i 's/#\$nrconf{restart} = '"'"'i'"'"';/\$nrconf{restart} = '"'"'a'"'"';/g' /etc/needrestart/needrestart.conf" "Configuring needrestart ($(( ++current_step ))/$total_steps)"

# Install prerequisites
run_command "apt-get install -y curl wget gnupg2 ca-certificates lsb-release ubuntu-keyring" "Installing prerequisites ($(( ++current_step ))/$total_steps)"

# Install Node.js 20.x LTS
run_command "curl -fsSL https://deb.nodesource.com/setup_20.x | bash -" "Adding NodeJS 20.x repository ($(( ++current_step ))/$total_steps)"

run_command "apt-get install -y nodejs" "Installing NodeJS 20.x ($(( ++current_step ))/$total_steps)"

run_command "npm install -g npm@latest" "Updating NPM to latest ($(( ++current_step ))/$total_steps)"

# Install MongoDB 7.0 (latest stable)
run_command "curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg" "Adding MongoDB 7.0 GPG key ($(( ++current_step ))/$total_steps)"

run_command "echo 'deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse' | tee /etc/apt/sources.list.d/mongodb-org-7.0.list" "Adding MongoDB 7.0 repository ($(( ++current_step ))/$total_steps)"

run_command "apt-get update -y" "Updating package list ($(( ++current_step ))/$total_steps)"

run_command "apt-get install -y mongodb-org" "Installing MongoDB 7.0 ($(( ++current_step ))/$total_steps)"

run_command "apt-get upgrade -y" "Upgrading system ($(( ++current_step ))/$total_steps)"

run_command "systemctl start mongod" "Starting MongoDB service ($(( ++current_step ))/$total_steps)"

run_command "systemctl enable mongod" "Enabling MongoDB service ($(( ++current_step ))/$total_steps)"

run_command "npm install -g genieacs@1.2.13" "Installing GenieACS 1.2.13 ($(( ++current_step ))/$total_steps)"

run_command "useradd --system --no-create-home --user-group genieacs 2>/dev/null || true" "Creating GenieACS user ($(( ++current_step ))/$total_steps)"

run_command "mkdir -p /opt/genieacs/ext && chown genieacs:genieacs /opt/genieacs/ext" "Creating GenieACS directories ($(( ++current_step ))/$total_steps)"

# Create genieacs.env file
cat << EOF > /opt/genieacs/genieacs.env
GENIEACS_CWMP_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-cwmp-access.log
GENIEACS_NBI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-nbi-access.log
GENIEACS_FS_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-fs-access.log
GENIEACS_UI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-ui-access.log
GENIEACS_DEBUG_FILE=/var/log/genieacs/genieacs-debug.yaml
NODE_OPTIONS=--enable-source-maps
GENIEACS_EXT_DIR=/opt/genieacs/ext
EOF
echo -e "${YELLOW}Creating genieacs.env file ($(( ++current_step ))/$total_steps)${NC}... ${GREEN}Done${NC}"

run_command "node -e \"console.log('GENIEACS_UI_JWT_SECRET=' + require('crypto').randomBytes(128).toString('hex'))\" >> /opt/genieacs/genieacs.env" "Generating JWT secret ($(( ++current_step ))/$total_steps)"

run_command "chown genieacs:genieacs /opt/genieacs/genieacs.env && chmod 600 /opt/genieacs/genieacs.env" "Setting genieacs.env permissions ($(( ++current_step ))/$total_steps)"

run_command "mkdir -p /var/log/genieacs && chown genieacs:genieacs /var/log/genieacs" "Creating log directory ($(( ++current_step ))/$total_steps)"

# Create systemd service files
for service in cwmp nbi fs ui; do
    cat << EOF > /etc/systemd/system/genieacs-$service.service
[Unit]
Description=GenieACS $service
After=network.target

[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/local/bin/genieacs-$service
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOF
    echo -e "${YELLOW}Creating genieacs-$service service file ($(( ++current_step ))/$total_steps)${NC}... ${GREEN}Done${NC}"
done

# Create logrotate configuration
cat << EOF > /etc/logrotate.d/genieacs
/var/log/genieacs/*.log /var/log/genieacs/*.yaml {
    daily
    rotate 30
    compress
    delaycompress
    dateext
}
EOF
echo -e "${YELLOW}Creating logrotate configuration ($(( ++current_step ))/$total_steps)${NC}... ${GREEN}Done${NC}"

# Reload systemd
run_command "systemctl daemon-reload" "Reloading systemd ($(( ++current_step ))/$total_steps)"

# Enable and start services
for service in cwmp nbi fs ui; do
    run_command "systemctl enable genieacs-$service && systemctl start genieacs-$service" "Enabling and starting genieacs-$service ($(( ++current_step ))/$total_steps)"
done

# Wait for services to start
sleep 3

# ========================================
# CUSTOM UI CUSTOMIZATION
# ========================================

echo -e "\n${MAGENTA}${BOLD}Installing Custom UI Theme${NC}\n"

# Create custom UI directory
run_command "mkdir -p /opt/genieacs/custom-ui" "Creating custom UI directory ($(( ++current_step ))/$total_steps)"

# Create custom CSS file
cat << 'EOFCSS' > /opt/genieacs/custom-ui/custom-theme.css
/* ============================================
   GenieACS Custom Theme v2 - Eye-Friendly
   Modern Professional Design for RT/RW Net
   ============================================ */

/* Header - Modern Blue Gradient */
#header {
  background: linear-gradient(135deg, #0891b2 0%, #0e7490 100%) !important;
  box-shadow: 0 2px 12px rgba(0,0,0,0.1) !important;
}

#header .logo {
  color: white !important;
  padding: 0.75rem 1.5rem !important;
}

#header .logo img {
  filter: brightness(0) invert(1) !important;
}

#header .logo .version {
  color: rgba(255,255,255,0.7) !important;
  font-size: 0.7rem !important;
}

#header .user-menu {
  color: white !important;
  padding: 0.75rem 1.5rem !important;
}

#header .user-menu button {
  background: rgba(255,255,255,0.2) !important;
  color: white !important;
  border: 1px solid rgba(255,255,255,0.3) !important;
  padding: 0.5rem 1.25rem !important;
  border-radius: 0.5rem !important;
  font-weight: 500 !important;
  transition: all 0.2s !important;
}

#header .user-menu button:hover {
  background: rgba(255,255,255,0.3) !important;
}

/* Top Navigation - Clean White Tabs */
#header > nav {
  background: #f8fafc !important;
  border: none !important;
  padding: 0 !important;
  box-shadow: inset 0 -1px 0 #e2e8f0 !important;
}

#header > nav ul {
  display: flex !important;
  padding: 0 1.5rem !important;
  gap: 0.5rem !important;
  margin: 0 !important;
  list-style: none !important;
}

#header > nav ul li {
  margin: 0 !important;
}

#header > nav ul li a {
  display: block !important;
  padding: 1rem 1.75rem !important;
  color: #64748b !important;
  background: transparent !important;
  text-decoration: none !important;
  font-weight: 500 !important;
  border-radius: 0.5rem 0.5rem 0 0 !important;
  transition: all 0.2s !important;
  border: none !important;
  margin-top: 0.5rem !important;
}

#header > nav ul li a:hover {
  background: white !important;
  color: #0891b2 !important;
  box-shadow: 0 -2px 8px rgba(0,0,0,0.05) !important;
}

/* Active Tab - Vibrant Orange */
#header > nav ul li.active a {
  background: linear-gradient(135deg, #f97316 0%, #ea580c 100%) !important;
  color: white !important;
  font-weight: 600 !important;
  box-shadow: 0 4px 12px rgba(249,115,22,0.3) !important;
  border: none !important;
}

/* Sidebar - Clean Blue Gradient */
#side-menu {
  background: linear-gradient(180deg, #0e7490 0%, #155e75 100%) !important;
  padding: 1rem 0.75rem !important;
  box-shadow: 2px 0 12px rgba(0,0,0,0.08) !important;
}

#side-menu ul {
  list-style: none !important;
  padding: 0 !important;
  margin: 0 !important;
}

#side-menu ul li {
  margin: 0.5rem 0 !important;
}

#side-menu ul li a {
  display: block !important;
  padding: 0.875rem 1.25rem !important;
  color: rgba(255,255,255,0.9) !important;
  background: transparent !important;
  text-decoration: none !important;
  border-radius: 0.5rem !important;
  transition: all 0.2s !important;
  font-weight: 500 !important;
}

#side-menu ul li a:hover {
  background: rgba(255,255,255,0.15) !important;
  color: white !important;
  transform: translateX(4px) !important;
}

#side-menu ul li.active a {
  background: rgba(255,255,255,0.2) !important;
  color: white !important;
  font-weight: 600 !important;
  box-shadow: 0 2px 8px rgba(0,0,0,0.15) !important;
}

/* Content Background */
#content-wrapper {
  background: #f1f5f9 !important;
}

#content {
  padding: 2rem !important;
  background: transparent !important;
}

#content h1 {
  color: #0f172a !important;
  font-weight: 700 !important;
  font-size: 1.875rem !important;
  margin-bottom: 1.5rem !important;
}

/* Filter Section */
.filter {
  background: white !important;
  padding: 1.25rem 1.5rem !important;
  border-radius: 0.75rem !important;
  margin-bottom: 1.5rem !important;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05) !important;
  border: 1px solid #e2e8f0 !important;
}

.filter b {
  color: #334155 !important;
  font-weight: 600 !important;
  margin-right: 1rem !important;
}

.filter input[type="text"] {
  border: 2px solid #e2e8f0 !important;
  padding: 0.625rem 1rem !important;
  border-radius: 0.5rem !important;
  width: 350px !important;
  background: #f8fafc !important;
  transition: all 0.2s !important;
  color: #1e293b !important;
}

.filter input[type="text"]:focus {
  outline: none !important;
  border-color: #0891b2 !important;
  background: white !important;
  box-shadow: 0 0 0 3px rgba(8,145,178,0.1) !important;
}

/* Table Styling */
table.table {
  background: white !important;
  border-radius: 0.75rem !important;
  overflow: hidden !important;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05) !important;
  border: 1px solid #e2e8f0 !important;
  width: 100% !important;
  border-collapse: separate !important;
}

table.table thead {
  background: linear-gradient(135deg, #0891b2 0%, #0e7490 100%) !important;
}

table.table thead th {
  color: white !important;
  font-weight: 600 !important;
  text-transform: uppercase !important;
  font-size: 0.75rem !important;
  letter-spacing: 0.05em !important;
  padding: 1rem !important;
  border: none !important;
  text-align: left !important;
}

table.table thead th button {
  background: transparent !important;
  border: none !important;
  color: white !important;
  cursor: pointer !important;
  padding: 0 0.5rem !important;
  opacity: 0.8 !important;
}

table.table thead th button:hover {
  opacity: 1 !important;
}

table.table tbody tr {
  border-bottom: 1px solid #f1f5f9 !important;
  transition: all 0.2s !important;
}

table.table tbody tr:hover {
  background: #f0f9ff !important;
}

table.table tbody td {
  padding: 1rem !important;
  color: #334155 !important;
  border: none !important;
}

table.table tbody td a {
  color: #0891b2 !important;
  text-decoration: none !important;
  font-weight: 500 !important;
  transition: color 0.2s !important;
}

table.table tbody td a:hover {
  color: #0e7490 !important;
  text-decoration: underline !important;
}

table.table tbody td.table-row-links a {
  padding: 0.375rem 0.875rem !important;
  background: #f1f5f9 !important;
  border-radius: 0.375rem !important;
  color: #475569 !important;
  font-size: 0.875rem !important;
  display: inline-block !important;
  margin: 0 0.25rem !important;
  transition: all 0.2s !important;
}

table.table tbody td.table-row-links a:hover {
  background: #0891b2 !important;
  color: white !important;
  text-decoration: none !important;
}

table.table tfoot {
  background: #f8fafc !important;
  border-top: 1px solid #e2e8f0 !important;
}

table.table tfoot td {
  padding: 1rem !important;
  color: #64748b !important;
}

table.table tfoot button {
  background: #e2e8f0 !important;
  color: #475569 !important;
  border: none !important;
  padding: 0.5rem 1rem !important;
  border-radius: 0.375rem !important;
  margin: 0 0.5rem !important;
  cursor: pointer !important;
  transition: all 0.2s !important;
  font-weight: 500 !important;
}

table.table tfoot button:hover:not(:disabled) {
  background: #cbd5e1 !important;
  color: #1e293b !important;
}

table.table tfoot button:disabled {
  opacity: 0.5 !important;
  cursor: not-allowed !important;
}

table.table tfoot a.download-csv {
  background: linear-gradient(135deg, #10b981 0%, #059669 100%) !important;
  color: white !important;
  padding: 0.5rem 1.25rem !important;
  border-radius: 0.375rem !important;
  text-decoration: none !important;
  display: inline-block !important;
  margin: 0 0.5rem !important;
  font-weight: 500 !important;
  transition: all 0.2s !important;
}

table.table tfoot a.download-csv:hover {
  box-shadow: 0 4px 12px rgba(16,185,129,0.3) !important;
  transform: translateY(-1px) !important;
}

/* Action Buttons */
.actions-bar {
  margin-top: 1.5rem !important;
  display: flex !important;
  gap: 0.75rem !important;
}

.actions-bar button {
  background: linear-gradient(135deg, #0891b2 0%, #0e7490 100%) !important;
  color: white !important;
  border: none !important;
  padding: 0.75rem 1.5rem !important;
  border-radius: 0.5rem !important;
  font-weight: 600 !important;
  cursor: pointer !important;
  transition: all 0.2s !important;
  box-shadow: 0 2px 8px rgba(8,145,178,0.3) !important;
}

.actions-bar button:hover:not(:disabled) {
  background: linear-gradient(135deg, #0e7490 0%, #155e75 100%) !important;
  box-shadow: 0 4px 12px rgba(8,145,178,0.4) !important;
  transform: translateY(-2px) !important;
}

.actions-bar button:disabled {
  opacity: 0.5 !important;
  cursor: not-allowed !important;
  transform: none !important;
}

/* Checkboxes */
input[type="checkbox"] {
  width: 1.125rem !important;
  height: 1.125rem !important;
  cursor: pointer !important;
  accent-color: #0891b2 !important;
}

/* Scrollbar */
::-webkit-scrollbar {
  width: 10px !important;
  height: 10px !important;
}

::-webkit-scrollbar-track {
  background: #f1f5f9 !important;
}

::-webkit-scrollbar-thumb {
  background: #94a3b8 !important;
  border-radius: 10px !important;
}

::-webkit-scrollbar-thumb:hover {
  background: #64748b !important;
}

/* ============================================
   MOBILE RESPONSIVE
   ============================================ */

@media (max-width: 767px) {

  #header .logo {
    padding: 0.75rem 1rem 0.75rem 4rem !important;
    font-size: 0.875rem !important;
  }

  #header .logo img {
    width: 28px !important;
    height: 28px !important;
  }

  #header .logo .version {
    display: none !important;
  }

  #header .user-menu {
    padding: 0.75rem 1rem !important;
    font-size: 0.75rem !important;
  }

  #header .user-menu button {
    padding: 0.375rem 0.75rem !important;
    font-size: 0.7rem !important;
  }

  #header > nav {
    overflow-x: auto !important;
    -webkit-overflow-scrolling: touch !important;
    scrollbar-width: none !important;
  }

  #header > nav::-webkit-scrollbar {
    display: none !important;
  }

  #header > nav ul {
    padding: 0.5rem 1rem !important;
    gap: 0.375rem !important;
    flex-wrap: nowrap !important;
  }

  #header > nav ul li {
    flex-shrink: 0 !important;
  }

  #header > nav ul li a {
    padding: 0.625rem 1rem !important;
    font-size: 0.8rem !important;
    white-space: nowrap !important;
  }

  #side-menu {
    position: fixed !important;
    left: -100% !important;
    top: 0 !important;
    bottom: 0 !important;
    width: 75% !important;
    max-width: 280px !important;
    z-index: 1000 !important;
    transition: left 0.3s ease !important;
    overflow-y: auto !important;
    padding: 4rem 1rem 1rem !important;
  }

  body.sidebar-open #side-menu {
    left: 0 !important;
  }

  body.sidebar-open::after {
    content: "" !important;
    position: fixed !important;
    top: 0 !important;
    left: 0 !important;
    right: 0 !important;
    bottom: 0 !important;
    background: rgba(0,0,0,0.5) !important;
    z-index: 999 !important;
  }

  #content-wrapper {
    margin-left: 0 !important;
  }

  #content {
    padding: 1rem !important;
  }

  #content h1 {
    font-size: 1.375rem !important;
    margin-bottom: 1rem !important;
  }

  .filter {
    padding: 1rem !important;
  }

  .filter b {
    display: block !important;
    margin-bottom: 0.5rem !important;
  }

  .filter input[type="text"] {
    width: 100% !important;
    font-size: 0.875rem !important;
  }

  table.table {
    font-size: 0.75rem !important;
    display: block !important;
    overflow-x: auto !important;
    -webkit-overflow-scrolling: touch !important;
  }

  table.table thead th {
    padding: 0.75rem 0.5rem !important;
    font-size: 0.65rem !important;
  }

  table.table tbody td {
    padding: 0.75rem 0.5rem !important;
  }

  .actions-bar {
    flex-direction: column !important;
  }

  .actions-bar button {
    width: 100% !important;
  }
}

/* ============================================ */
EOFCSS
echo -e "${YELLOW}Creating custom CSS theme ($(( ++current_step ))/$total_steps)${NC}... ${GREEN}Done${NC}"

# Create mobile menu JavaScript
cat << 'EOFJS' > /usr/local/lib/node_modules/genieacs/public/mobile-menu.js
(function() {
  'use strict';

  function initMobileMenu() {
    if (window.innerWidth > 767) return;
    if (document.getElementById('mobile-hamburger')) return;

    const sidebar = document.getElementById('side-menu');
    if (!sidebar) {
      setTimeout(initMobileMenu, 500);
      return;
    }

    const h = document.createElement('button');
    h.id = 'mobile-hamburger';
    h.innerHTML = '☰';
    h.setAttribute('aria-label', 'Toggle menu');
    h.style.cssText = 'position:fixed;left:1rem;top:1rem;z-index:1001;font-size:1.75rem;color:white;cursor:pointer;width:44px;height:44px;display:flex;align-items:center;justify-content:center;background:rgba(8,145,178,0.95);border:none;border-radius:0.5rem;box-shadow:0 2px 8px rgba(0,0,0,0.2);transition:all 0.2s;';

    document.body.appendChild(h);

    h.onclick = function(e) {
      e.stopPropagation();
      document.body.classList.toggle('sidebar-open');
      this.innerHTML = document.body.classList.contains('sidebar-open') ? '✕' : '☰';
    };

    document.addEventListener('click', function(e) {
      if (document.body.classList.contains('sidebar-open') &&
          !sidebar.contains(e.target) &&
          e.target.id !== 'mobile-hamburger') {
        document.body.classList.remove('sidebar-open');
        h.innerHTML = '☰';
      }
    });

    sidebar.addEventListener('click', function(e) {
      if (e.target.tagName === 'A') {
        setTimeout(function() {
          document.body.classList.remove('sidebar-open');
          h.innerHTML = '☰';
        }, 300);
      }
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initMobileMenu);
  } else {
    initMobileMenu();
  }

  setTimeout(initMobileMenu, 1000);
  setTimeout(initMobileMenu, 2000);
})();
EOFJS
echo -e "${YELLOW}Creating mobile menu script ($(( ++current_step ))/$total_steps)${NC}... ${GREEN}Done${NC}"

# Create CSS injection script
cat << 'EOFSCRIPT' > /opt/genieacs/inject-custom-css.sh
#!/bin/bash
set -e

GENIEACS_CSS="/usr/local/lib/node_modules/genieacs/public/app-LU66VFYW.css"
CUSTOM_CSS="/opt/genieacs/custom-ui/custom-theme.css"
BACKUP_CSS="/opt/genieacs/custom-ui/app-LU66VFYW.css.original"
MARKER="/* === CUSTOM THEME INJECTED === */"

if [ ! -f "$GENIEACS_CSS" ]; then
    echo "Error: GenieACS CSS not found"
    exit 1
fi

if [ ! -f "$CUSTOM_CSS" ]; then
    echo "Error: Custom CSS not found"
    exit 1
fi

if [ ! -f "$BACKUP_CSS" ]; then
    cp "$GENIEACS_CSS" "$BACKUP_CSS"
fi

if grep -q "$MARKER" "$GENIEACS_CSS"; then
    cp "$BACKUP_CSS" "$GENIEACS_CSS"
fi

echo "" >> "$GENIEACS_CSS"
echo "$MARKER" >> "$GENIEACS_CSS"
cat "$CUSTOM_CSS" >> "$GENIEACS_CSS"

if systemctl is-active --quiet genieacs-ui; then
    systemctl restart genieacs-ui
fi

echo "Custom CSS injected successfully"
EOFSCRIPT

run_command "chmod +x /opt/genieacs/inject-custom-css.sh" "Making CSS injector executable ($(( ++current_step ))/$total_steps)"

# Wait for GenieACS UI to be fully started
sleep 2

# Inject custom CSS
run_command "/opt/genieacs/inject-custom-css.sh" "Injecting custom CSS theme ($(( ++current_step ))/$total_steps)"

# Create update script for future use
cat << 'EOFUPDATE' > /opt/genieacs/update-custom-ui.sh
#!/bin/bash
echo "Updating GenieACS Custom UI..."
/opt/genieacs/inject-custom-css.sh
echo "Done! Clear browser cache to see changes."
EOFUPDATE

run_command "chmod +x /opt/genieacs/update-custom-ui.sh" "Creating UI update script ($(( ++current_step ))/$total_steps)"

# ========================================
# FINAL CHECKS
# ========================================

# Check services status
echo -e "\n${MAGENTA}${BOLD}Checking services status:${NC}"
all_running=true
for service in mongod genieacs-cwmp genieacs-nbi genieacs-fs genieacs-ui; do
    status=$(systemctl is-active $service)
    if [ "$status" = "active" ]; then
        echo -e "${GREEN}✔ $service is running${NC}"
    else
        echo -e "${RED}✘ $service is not running${NC}"
        all_running=false
    fi
done

# Display versions
echo -e "\n${MAGENTA}${BOLD}Installed versions:${NC}"
echo -e "${CYAN}Node.js:${NC} $(node --version)"
echo -e "${CYAN}NPM:${NC} $(npm --version)"
echo -e "${CYAN}MongoDB:${NC} $(mongod --version | head -n1 | awk '{print $3}')"
echo -e "${CYAN}GenieACS:${NC} 1.2.13"

# Display access information
echo -e "\n${MAGENTA}${BOLD}Access Information:${NC}"
SERVER_IP=$(hostname -I | awk '{print $1}')
echo -e "${CYAN}GenieACS UI:${NC} http://$SERVER_IP:3000"
echo -e "${CYAN}CWMP:${NC} http://$SERVER_IP:7547"
echo -e "${CYAN}NBI API:${NC} http://$SERVER_IP:7557"
echo -e "${CYAN}FS:${NC} http://$SERVER_IP:7567"

echo -e "\n${MAGENTA}${BOLD}Custom UI Features:${NC}"
echo -e "${GREEN}✔ Modern responsive design${NC}"
echo -e "${GREEN}✔ Mobile-friendly hamburger menu${NC}"
echo -e "${GREEN}✔ Eye-friendly color scheme${NC}"
echo -e "${GREEN}✔ Professional gradient styling${NC}"

echo -e "\n${YELLOW}${BOLD}Important Notes:${NC}"
echo -e "${YELLOW}• Clear browser cache (Ctrl+Shift+Delete) to see custom UI${NC}"
echo -e "${YELLOW}• To update custom UI: /opt/genieacs/update-custom-ui.sh${NC}"
echo -e "${YELLOW}• Custom CSS location: /opt/genieacs/custom-ui/custom-theme.css${NC}"

if [ "$all_running" = true ]; then
    echo -e "\n${GREEN}${BOLD}✓ Installation completed successfully!${NC}"
else
    echo -e "\n${YELLOW}${BOLD}⚠ Installation completed with warnings. Check logs for details.${NC}"
    echo -e "${YELLOW}Run: journalctl -u genieacs-ui -n 50${NC}"
fi