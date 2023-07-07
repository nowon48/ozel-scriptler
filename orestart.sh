while true
do
pkill geth
pkill beacon-chain
pkill validator

echo "${Wait10Seconds}"
sleep 10
"/root/testnet-auto-install-v3/opside-chain/start-geth.sh"
"/root/testnet-auto-install-v3/opside-chain/start-beaconChain.sh"
"/root/testnet-auto-install-v3/opside-chain/start-validator.sh"
sleep 3600
done
