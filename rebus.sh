#!/bin/bash

echo -e "\033[0;35m"
echo " :::    ::: ::::::::::: ::::    :::  ::::::::  :::::::::  :::::::::: ::::::::  ";
echo " :+:   :+:      :+:     :+:+:   :+: :+:    :+: :+:    :+: :+:       :+:    :+: ";
echo " +:+  +:+       +:+     :+:+:+  +:+ +:+    +:+ +:+    +:+ +:+       +:+        ";
echo " +#++:++        +#+     +#+ +:+ +#+ +#+    +:+ +#+    +:+ +#++:++#  +#++:++#++ ";
echo " +#+  +#+       +#+     +#+  +#+#+# +#+    +#+ +#+    +#+ +#+              +#+ ";
echo " #+#   #+#  #+# #+#     #+#   #+#+# #+#    #+# #+#    #+# #+#       #+#    #+# ";
echo " ###    ###  #####      ###    ####  ########  #########  ########## ########  ";
echo -e "\e[0m"


sleep 2

# set vars
if [ ! $NODENAME ]; then
	read -p "Enter node name: " NODENAME
	echo 'export NODENAME='$NODENAME >> $HOME/.bash_profile
fi
REBUS_PORT=21
if [ ! $WALLET ]; then
	echo "export WALLET=wallet" >> $HOME/.bash_profile
fi
echo "export REBUS_CHAIN_ID=reb_3333-1" >> $HOME/.bash_profile
echo "export REBUS_PORT=${REBUS_PORT}" >> $HOME/.bash_profile
source $HOME/.bash_profile

echo '================================================='
echo -e "Your node name: \e[1m\e[32m$NODENAME\e[0m"
echo -e "Your wallet name: \e[1m\e[32m$WALLET\e[0m"
echo -e "Your chain name: \e[1m\e[32m$REBUS_CHAIN_ID\e[0m"
echo -e "Your port: \e[1m\e[32m$REBUS_PORT\e[0m"
echo '================================================='
sleep 2

echo -e "\e[1m\e[32m1. Updating packages... \e[0m" && sleep 1
# update
sudo apt update && sudo apt upgrade -y

echo -e "\e[1m\e[32m2. Installing dependencies... \e[0m" && sleep 1
# packages
sudo apt install curl build-essential git wget jq make gcc tmux chrony -y

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
git clone https://github.com/rebuschain/rebus.core.git 
cd rebus.core && git checkout v0.0.4
make install

# config
rebusd config chain-id $REBUS_CHAIN_ID
rebusd config keyring-backend test
rebusd config node tcp://localhost:${REBUS_PORT}657

# init
rebusd init $NODENAME --chain-id $REBUS_CHAIN_ID

# download genesis and addrbook
wget -qO $HOME/.rebusd/config/genesis.json "https://raw.githubusercontent.com/rebuschain/rebus.testnet/master/rebus_3333-1/genesis.json"

# set peers and seeds
SEEDS="a6d710cd9baac9e95a55525d548850c91f140cd9@3.211.101.169:26656,c296ee829f137cfe020ff293b6fc7d7c3f5eeead@54.157.52.47:26656"
PEERS="1ae3fe91ec7aba98eba3aa472453a92aa0a38c04@116.202.169.22:28656,289b378944a9983dc7f6ed6b09ba4a30d8290ee1@148.251.53.155:28656,f2cf370ecff71c0e95b0970f3b2821ea11b66a40@195.201.165.123:20106,1f40e130d2c21a32b0d678eabddc45ec3d6964a2@138.201.127.91:26674,82fc54cd4f7cbb44ee5e9d0565d40b5b29475974@88.198.242.163:46656,bdb21276daf5cc3672ddf5597c68c61dc44ec8e5@212.154.90.211:21656,bcf1b8d1896031da70f5bd1d634d10591d066b1c@5.161.128.219:28656,8abcf4cbdfa413f310e792f31aa54e82e9e09a0c@38.242.131.51:26656,eb47d2414351c010c8f747701f184cf3f8a30181@79.143.179.196:16656,f084e8960bb714c3446796cb4738e78bc5c3f04b@65.109.18.179:31656,34dde0a9cac6aeecc3e6570b59a0d297ab64f5bd@65.108.126.46:31656,d5c87b9a13a3d5be1456e9d982c1fc0fe71d8723@38.242.156.72:26656,d4ac8ea1bc083d6348997fda833ffcf5b150bd92@38.242.156.132:26656,d1a72df36686394e99ff0fff006d58f042692699@161.97.136.177:21656,c2368a4db640aa26fb8d5bc9d0f331758d42ca86@141.95.65.26:28656,9f601f082beb325abf3b6b08cdf27374c8a29469@38.242.206.198:56656,64f998cfa053619f1c755fdb6b7e431ae7c0c7b3@95.217.89.23:30530"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.rebusd/config/config.toml

# set custom ports
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${REBUS_PORT}658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:${REBUS_PORT}657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${REBUS_PORT}060\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${REBUS_PORT}656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${REBUS_PORT}660\"%" $HOME/.rebusd/config/config.toml
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${REBUS_PORT}317\"%; s%^address = \":8080\"%address = \":${REBUS_PORT}080\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${REBUS_PORT}090\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${REBUS_PORT}091\"%; s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:${REBUS_PORT}545\"%; s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:${REBUS_PORT}546\"%" $HOME/.rebusd/config/app.toml

# config pruning
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="0"
pruning_interval="50"
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.rebusd/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.rebusd/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.rebusd/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.rebusd/config/app.toml

# set minimum gas price and timeout commit
sed -i -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0arebus\"/" $HOME/.rebusd/config/app.toml

# set commit timeout
timeout_commit="2s"
sed -i.bak -e "s/^timeout_commit *=.*/timeout_commit = \"$timeout_commit\"/" $HOME/.rebusd/config/config.toml

# enable prometheus
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.rebusd/config/config.toml

# reset
rebusd tendermint unsafe-reset-all --home $HOME/.rebusd

echo -e "\e[1m\e[32m4. Starting service... \e[0m" && sleep 1
# create service
sudo tee /etc/systemd/system/rebusd.service > /dev/null <<EOF
[Unit]
Description=rebus
After=network-online.target

[Service]
User=$USER
ExecStart=$(which rebusd) start --home $HOME/.rebusd
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# start service
sudo systemctl daemon-reload
sudo systemctl enable rebusd
sudo systemctl restart rebusd

echo '=============== SETUP FINISHED ==================='
echo -e 'To check logs: \e[1m\e[32mjournalctl -u rebusd -f -o cat\e[0m'
echo -e "To check sync status: \e[1m\e[32mcurl -s localhost:${REBUS_PORT}657/status | jq .result.sync_info\e[0m"
