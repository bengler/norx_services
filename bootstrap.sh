#!/bin/bash

GITHUB_ACCESS_TOKEN="a09e2e7b5488f777a79b82edd506e61ccdfcbe43"

echo  "\t * Setting up TileStache"
sudo cp ./etc/tilestache /etc/init.d
sudo chmod 755 /etc/init.d/tilestache
sudo /etc/init.d/tilestache start

echo  "\t * Setting up terrafab"
git clone "https://$GITHUB_ACCESS_TOKEN@github.com/bengler/terrafab"
cd terrafab
npm install
