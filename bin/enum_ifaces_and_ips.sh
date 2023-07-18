#!/bin/bash

# Enumerate interfaces
readarray -t ifaces < <(ip -j -br l | jq -r '.[]|select(.ifname != "lo")|.ifname')

# populate addresses
for i in ${ifaces[@]}; do
	ip -j a s dev $i | jq -r '{(.[]|.ifname): [.[].addr_info[]|select(.scope == "global").local]}'
done | jq -s '.'
