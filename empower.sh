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
empower_PORT=35
if [ ! $WALLET ]; then
	echo "export WALLET=wallet" >> $HOME/.bash_profile
fi
echo "export empower_CHAIN_ID=altruistic-1" >> $HOME/.bash_profile
echo "export empower_PORT=${empower_PORT}" >> $HOME/.bash_profile
source $HOME/.bash_profile

echo '================================================='
echo -e "Your node name: \e[1m\e[32m$NODENAME\e[0m"
echo -e "Your wallet name: \e[1m\e[32m$WALLET\e[0m"
echo -e "Your chain name: \e[1m\e[32m$empower_CHAIN_ID\e[0m"
echo -e "Your port: \e[1m\e[32m$empower_PORT\e[0m"
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
cd $HOME && git clone https://github.com/empowerchain/empowerchain && \
cd empowerchain/chain && \
make install && \
empowerd version --long | head

# config
empowerd config chain-id $empower_CHAIN_ID
empowerd config keyring-backend test
empowerd config node tcp://localhost:${empower_PORT}657

# init
empowerd init $NODENAME --chain-id $empower_CHAIN_ID

# download genesis and addrbook
wget -qO $HOME/.empower/config/genesis.json "https://raw.githubusercontent.com/empowerchain/empowerchain/main/testnets/altruistic-1/genesis.json"

# set peers and seeds
SEEDS=""
PEERS="9de92b545638f6baaa7d6d5109a1f7148f093db3@65.108.77.106:26656,4fd5e497563b2e09cfe6f857fb35bdae76c12582@65.108.206.56:26656,fe32c17373fbaa36d9fd86bc1146bfa125bb4f58@5.9.147.185:26656,220fb60b083bc4d443ce2a7a5363f4813dd4aef4@116.202.236.115:26656,225ad85c594d03942a026b90f4dab43f90230ea0@88.99.3.158:26656,2a2932e780a681ddf980594f7eacf5a33081edaf@192.168.147.43:26656,333de3fc2eba7eead24e0c5f53d665662b2ba001@10.132.0.11:26656,4a38efbae54fd1357329bd583186a68ccd6d85f9@94.130.212.252:26656,52450b21f346a4cf76334374c9d8012b2867b842@167.172.246.201:26656,56d05d4ae0e1440ad7c68e52cc841c424d59badd@192.168.1.46:26656,6a675d4f66bfe049321c3861bcfd19bd09fefbde@195.3.223.204:26656,1069820cdd9f5332503166b60dc686703b2dccc5@138.201.141.76:26656,277ff448eec6ec7fa665f68bdb1c9cb1a52ff597@159.69.110.238:26656,3335c9458105cf65546db0fb51b66f751eeb4906@5.189.129.30:26656,bfb56f4cb8361c49a2ac107251f92c0ea5a1c251@192.168.1.177:26656,edc9aa0bbf1fcd7433fcc3650e3f50ab0becc0b5@65.21.170.3:26656,d582bcd8a8f0a20c551098571727726bc75bae74@213.239.217.52:26656,eb182533a12d75fbae1ec32ef1f8fc6b6dd06601@65.109.28.219:26656,b22f0708c6f393bf79acc0a6ca23643fe7d58391@65.21.91.50:26656,e8f6d75ab37bf4f08c018f306416df1e138fd21c@95.217.135.41:26656,ed83872f2781b2bdb282fc2fd790527bcb6ffe9f@192.168.3.17:26656"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.empower/config/config.toml

# set custom ports
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${empower_PORT}658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:${empower_PORT}657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${empower_PORT}060\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${empower_PORT}656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${empower_PORT}660\"%" $HOME/.empower/config/config.toml
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${empower_PORT}317\"%; s%^address = \":8080\"%address = \":${empower_PORT}080\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${empower_PORT}090\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${empower_PORT}091\"%" $HOME/.empower/config/app.toml

# config pruning
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="0"
pruning_interval="50"
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.empower/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.empower/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.empower/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.empower/config/app.toml

# set minimum gas price and timeout commit


# enable prometheus
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.empower/config/config.toml

# reset
empowerd tendermint unsafe-reset-all --home $HOME/.empower

echo -e "\e[1m\e[32m4. Starting service... \e[0m" && sleep 1
# create service
sudo tee /etc/systemd/system/empowerd.service > /dev/null <<EOF
[Unit]
Description=empower
After=network-online.target

[Service]
User=$USER
ExecStart=$(which empowerd) start --home $HOME/.empower
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# start service
sudo systemctl daemon-reload
sudo systemctl enable empowerd
sudo systemctl restart empowerd

echo '=============== SETUP FINISHED ==================='
echo -e 'To check logs: \e[1m\e[32mjournalctl -u empowerd -f -o cat\e[0m'
echo -e "To check sync status: \e[1m\e[32mcurl -s localhost:${empower_PORT}657/status | jq .result.sync_info\e[0m"
