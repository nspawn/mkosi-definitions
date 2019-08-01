#!/bin/bash

sudo nspawn init "$1/$2/$3"
sudo machinectl start "$1-$2-$3"
sleep 10
sudo machinectl login "$1-$2-$3"
sudo machinectl stop "$1-$2-$3"
sudo machinectl remove "$1-$2-$3"
sudo machinectl clean
