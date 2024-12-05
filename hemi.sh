#!/bin/bash

log() {
    local level=$1
    local message=$2
    echo "[$level] $message"
}

print_green() {
    echo -e "\e[32m$1\e[0m"
}

curl -s https://file.winsnip.xyz/file/uploads/Logo-winsip.sh | bash
sleep 5

log "INFO" "Hemi Miner...!!!"
sleep 2

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

log "INFO" "Installing required packages..."
if ! command_exists wget; then
    sudo apt-get update && sudo apt-get install -y wget
fi

if ! command_exists tar; then
    sudo apt-get install -y tar
fi

if ! command_exists jq; then
    sudo apt-get install -y jq
fi

log "INFO" "Downloading binaries..."
ARCH=$(uname -m)

case "$ARCH" in
    x86_64)
        log "INFO" "Detected x86_64 architecture. Downloading Hemi Network Binary..."
        wget https://github.com/hemilabs/heminetwork/releases/download/v0.7.0/heminetwork_v0.7.0_linux_amd64.tar.gz -O heminetwork.tar.gz
        ;;
    aarch64)
        log "INFO" "Detected arm64 architecture. Downloading Hemi Network Binary..."
        wget https://github.com/hemilabs/heminetwork/releases/download/v0.7.0/heminetwork_v0.7.0_linux_arm64.tar.gz -O heminetwork.tar.gz
        ;;
    *)
        log "ERROR" "Unsupported architecture: $ARCH. Exiting..."
        exit 1
        ;;
esac

if [ ! -f "heminetwork.tar.gz" ]; then
    log "ERROR" "Download failed. Exiting..."
    exit 1
fi

log "INFO" "Creating Hemi Miner directory..."
mkdir -p hemi-miner

log "INFO" "Extracting Hemi Network Binary..."
tar --strip-components=1 -xzvf heminetwork.tar.gz -C hemi-miner
if [ $? -ne 0 ]; then
    log "ERROR" "Extraction failed. Exiting..."
    exit 1
fi

log "INFO" "Cleaning up: removing the downloaded archive..."
rm -f heminetwork.tar.gz

cd hemi-miner || { log "ERROR" "Failed to navigate to hemi-miner directory. Exiting..."; exit 1; }

log "INFO" "User input required"
read -p "Enter your private key (PK): " PRIVATE_KEY
read -p "Enter fee amount (default 1250): " POPM_STATIC_FEE

if [ -z "$PRIVATE_KEY" ]; then
    log "ERROR" "Private key not provided. Exiting..."
    exit 1
fi

if [ -z "$POPM_STATIC_FEE" ]; then
    POPM_STATIC_FEE=1250
fi

SERVICE_FILE="/etc/systemd/system/heminetwork.service"
log "INFO" "Creating systemd service file..."
cat <<EOF | sudo tee $SERVICE_FILE
[Unit]
Description=Hemilabs Network Node
After=network.target

[Service]
User=$(whoami)
Group=$(id -g -n)
WorkingDirectory=$(pwd)
ExecStart=$(pwd)/popmd
Environment="POPM_BTC_PRIVKEY=$PRIVATE_KEY"
Environment="POPM_STATIC_FEE=$POPM_STATIC_FEE"
Environment="POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public"
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

log "INFO" "Reloading systemd and enabling the service..."
sudo systemctl daemon-reload
sudo systemctl enable heminetwork
sudo systemctl start heminetwork

log "INFO" "Checking the status of the service..."
sudo systemctl status heminetwork
