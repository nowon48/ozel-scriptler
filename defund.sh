#!/bin/bash

echo -e "\033[0;35m"
echo " DDDDDDDDDDDDD                         ZZZZZZZZZZZZZZZZZZZ                   ";
echo " D::::::::::::DDD                      Z:::::::::::::::::Z                   ";
echo " D:::::::::::::::DD                    Z:::::::::::::::::Z                   ";
echo " DDD:::::DDDDD:::::D                   Z:::ZZZZZZZZ:::::Z                    ";
echo "   D:::::D    D:::::D    ooooooooooo   ZZZZZ     Z:::::Z  zzzzzzzzzzzzzzzzz  ";
echo "   D:::::D     D:::::D oo:::::::::::oo         Z:::::Z    z:::::::::::::::z  ";
echo "   D:::::D     D:::::Do:::::::::::::::o       Z:::::Z     z::::::::::::::z   ";
echo "   D:::::D     D:::::Do:::::ooooo:::::o      Z:::::Z      zzzzzzzz::::::z    ";
echo "   D:::::D     D:::::Do::::o     o::::o     Z:::::Z             z::::::z     ";
echo "   D:::::D     D:::::Do::::o     o::::o    Z:::::Z             z::::::z      ";
echo "   D:::::D     D:::::Do::::o     o::::o   Z:::::Z             z::::::z       ";
echo "   D:::::D    D:::::D o::::o     o::::oZZZ:::::Z     ZZZZZ   z::::::z        ";
echo " DDD:::::DDDDD:::::D  o:::::ooooo:::::oZ::::::ZZZZZZZZ:::Z  z::::::zzzzzzzz  ";
echo " D:::::::::::::::DD   o:::::::::::::::oZ:::::::::::::::::Z z::::::::::::::z  ";
echo " D::::::::::::DDD      oo:::::::::::oo Z:::::::::::::::::Zz:::::::::::::::z  ";
echo " DDDDDDDDDDDDD           ooooooooooo   ZZZZZZZZZZZZZZZZZZZzzzzzzzzzzzzzzzzz  ";
echo -e "\e[0m"


sleep 2

# set vars
if [ ! $NODENAME ]; then
	read -p "Enter node name: " NODENAME
	echo 'export NODENAME='$NODENAME >> $HOME/.bash_profile
fi
echo "export WALLET=wallet" >> $HOME/.bash_profile
echo "export CHAIN_ID=defund-private-2" >> $HOME/.bash_profile
source $HOME/.bash_profile

echo '================================================='
echo 'Your node name: ' $NODENAME
echo 'Your wallet name: ' $WALLET
echo 'Your chain name: ' $CHAIN_ID
echo '================================================='
sleep 2

echo -e "\e[1m\e[32m1. Updating packages... \e[0m" && sleep 1
# update
sudo apt update && sudo apt upgrade -y

echo -e "\e[1m\e[32m2. Installing dependencies... \e[0m" && sleep 1
# packages
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential bsdmainutils git make ncdu gcc git jq chrony liblz4-tool -y

# install go
if ! [ -x "$(command -v go)" ]; then
  ver="1.18.2"
  cd $HOME
  wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
  rm "go$ver.linux-amd64.tar.gz"
  echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile
  source ~/.bash_profile
fi

echo -e "\e[1m\e[32m3. Downloading and building binaries... \e[0m" && sleep 1
# download binary
cd $HOME
git clone https://github.com/defund-labs/defund
cd defund
git checkout v0.1.0
make install

# config
defundd config chain-id $CHAIN_ID
defundd config keyring-backend file

# init
defundd init $NODENAME --chain-id $CHAIN_ID

# download addrbook and genesis
wget -O ~/.defund/config/genesis.json https://raw.githubusercontent.com/defund-labs/testnet/main/defund-private-2/genesis.json

# set minimum gas price
sed -i.bak -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.0025ufetf\"/" ~/.defund/config/app.toml

# set peers and seeds
export SEEDS=85279852bd306c385402185e0125dffeed36bf22@38.146.3.194:26656
sed -i.bak -e "s/^seeds *=.*/seeds = \"$SEEDS\"/" ~/.defund/config/config.toml

# enable prometheus
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.defund/config/config.toml

# add external (if dont use sentry), port is default
# external_address=$(wget -qO- eth0.me)
# sed -i -e "s/^external_address = \"\"/external_address = \"$external_address:26656\"/" $HOME/.defund/config/config.toml

# config pruning
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="0"
pruning_interval="10"

sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.defund/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.defund/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.defund/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.defund/config/app.toml

# disable indexing
sed -i.bak -e "s/indexer *=.*/indexer = \"null\"/g" $HOME/.defund/config/config.toml
sed -i "s/index-events=.*/index-events=[\"tx.hash\",\"tx.height\",\"block.height\"]/g" $HOME/.defund/config/app.toml

# reset
defundd tendermint unsafe-reset-all

echo -e "\e[1m\e[32m4. Starting service... \e[0m" && sleep 1
# create service
tee $HOME/defundd.service > /dev/null <<EOF
[Unit]
Description=defundd
After=network.target
[Service]
Type=simple
User=$USER
ExecStart=$(which defundd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

sudo mv $HOME/defundd.service /etc/systemd/system/

# start service
sudo systemctl daemon-reload
sudo systemctl enable defundd
sudo systemctl restart defundd

echo '=============== SETUP FINISHED ==================='
echo -e 'To check logs: \e[1m\e[32mjournalctl -u defundd -f -o cat\e[0m'
echo -e 'To check sync status: \e[1m\e[32mcurl -s localhost:26657/status | jq .result.sync_info\e[0m'
