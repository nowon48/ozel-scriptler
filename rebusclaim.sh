#!/bin/bash


while true
do
	rebusd tx distribution withdraw-rewards $REBUS_VALOPER_ADDRESS --from=$WALLET --commission --chain-id=$REBUS_CHAIN_ID -y
	sleep 10
	amount=$(rebusd query bank balances $REBUS_WALLET_ADDRESS | grep -oP -m1 '(?<=")[^"]*')
	rebusd tx staking delegate $REBUS_VALOPER_ADDRESS "${amount}arebus" --from=$WALLET --chain-id=$REBUS_CHAIN_ID --gas=auto -y
	sleep 120
done


