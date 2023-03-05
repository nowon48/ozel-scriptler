while true
do
	sudo systemctl restart nibid
	sudo journalctl -u nibid -f --no-hostname -o cat	
	sleep 3600
done
