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

echo "Hemi Miner...!!!"
sleep 2

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo "Installing required packages..."
if ! command_exists wget; then
    sudo apt-get update
    sudo apt-get install -y wget
fi

if ! command_exists tar; then
    sudo apt-get install -y tar
fi

if ! command_exists jq; then
    sudo apt-get install -y jq
fi

echo "Downloading binaries..."
wget -q https://github.com/hemilabs/heminetwork/releases/download/v0.4.3/heminetwork_v0.4.3_linux_amd64.tar.gz

echo "Extracting binaries..."
tar -xvf heminetwork_v0.4.3_linux_amd64.tar.gz
rm heminetwork_v0.4.3_linux_amd64.tar.gz
cd heminetwork_v0.4.3_linux_amd64



echo "Extracting private key..."
PRIVATE_KEY=$(jq -r '.private_key' $HOME/popm-address.json)

if [ -z "$PRIVATE_KEY" ]; then
    echo "Private key not found in popm-address.json"
    exit 1
fi

SERVICE_FILE="/etc/systemd/system/heminetwork.service"
echo "Creating systemd service file..."
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
Environment="POPM_STATIC_FEE=50"
Environment="POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public"
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

echo "Reloading systemd and enabling the service..."
sudo systemctl daemon-reload
sudo systemctl enable heminetwork
sudo systemctl start heminetwork

echo "Checking the status of the service..."
sudo systemctl status heminetwork
