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

sudo systemctl stop terpd

cd || return
rm -rf terp-core
git clone https://github.com/terpnetwork/terp-core.git
cd terp-core || return
git checkout v0.1.2
make install
terpd version # v0.1.2

terpd config chain-id athena-2
terpd tendermint unsafe-reset-all --home $HOME/.terp

curl -s https://raw.githubusercontent.com/terpnetwork/test-net/master/athena-2/genesis.json > $HOME/.terp/config/genesis.json
sha256sum $HOME/.terp/config/genesis.json # b2acc7ba63b05f5653578b05fc5322920635b35a19691dbafd41ef6374b1bc9a

seeds=""
peers="15f5bc75be9746fd1f712ca046502cae8a0f6ce7@terp-testnet.nodejumper.io:26656,7e5c0b9384a1b9636f1c670d5dc91ba4721ab1ca@23.88.53.28:36656,14ca69edabb36c51504f1a760292f8e6b9190bd7@65.21.138.123:28656,c989593c89b511318aa6a0c0d361a7a7f4271f28@65.108.124.172:26656,08a0f07da691a2d18d26e35eaa22ec784d1440cd@194.163.164.52:56656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.terp/config/config.toml

sudo systemctl restart terpd


sudo apt update
sudo apt install lz4 -y

sudo systemctl stop terpd

cp $HOME/.terp/data/priv_validator_state.json $HOME/.terp/priv_validator_state.json.backup
terpd tendermint unsafe-reset-all --home $HOME/.terp --keep-addr-book

rm -rf $HOME/.terp/data 
rm -rf $HOME/.terp/wasm

SNAP_NAME=$(curl -s https://snapshots2-testnet.nodejumper.io/terpnetwork-testnet/ | egrep -o ">athena-2.*\.tar.lz4" | tr -d ">")
curl https://snapshots2-testnet.nodejumper.io/terpnetwork-testnet/${SNAP_NAME} | lz4 -dc - | tar -xf - -C $HOME/.terp

mv $HOME/.terp/priv_validator_state.json.backup $HOME/.terp/data/priv_validator_state.json

sudo systemctl restart terpd
sudo journalctl -u terpd -f --no-hostname -o cat

