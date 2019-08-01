#!/bin/bash

sudo nspawn init "$1/$2/$3"
sleep 30s
sudo machinectl start "$1-$2-$3"
sleep 30s
sudo machinectl login "$1-$2-$3"
sudo machinectl stop "$1-$2-$3"
sleep 30s
sudo machinectl remove "$1-$2-$3"
sudo machinectl clean
