#!/bin/bash


while true
do
	curl -XPOST 'http://'$IP':8456/broadcast-miner-update'
	sleep 1800
done
