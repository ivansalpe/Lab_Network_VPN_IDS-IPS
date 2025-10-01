#!/bin/bash
IF=ens33
sudo apt install -y ethtool
sudo ethtool -K $IF gro off gso off tso off
sudo ip link set dev $IF promisc on
echo "Offloads disabled and promisc enabled on $IF"
