while true
do
	terpd tx distribution withdraw-rewards $TERP_VALOPER_ADDRESS --from=$WALLET --commission --chain-id=$TERP_CHAIN_ID -y
	sleep 10
	amount=$(terpd query bank balances $TERP_WALLET_ADDRESS | grep -oP -m1 '(?<=")[^"]*')
	terpd tx staking delegate $TERP_VALOPER_ADDRESS "${amount}uterpx" --from=$WALLET --chain-id=$TERP_CHAIN_ID --gas-prices 0.1uterpx --gas-adjustment 1.5 --gas=auto -y	
	sleep 3600
done
