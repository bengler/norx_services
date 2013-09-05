#!/bin/bash

GITHUB_ACCESS_TOKEN="a09e2e7b5488f777a79b82edd506e61ccdfcbe43"

if [ ! -f '/home/kartverk/kartverk_vm_services/.tilestache_done' ]; then
	echo  "Setting up Tilestache"
	sudo cp ./etc/tilestache /etc/init.d
	sudo chmod 755 /etc/init.d/tilestache
	sudo /etc/init.d/tilestache start
	touch '/home/kartverk/kartverk_vm_services/.tilestache_done'
fi

if [ ! -f '/home/kartverk/kartverk_vm_services/.terrafab_done' ]; then
	echo  "Setting up TerraFab"
	git clone "https://$GITHUB_ACCESS_TOKEN@github.com/bengler/terrafab"
	cd terrafab
	npm install
	cd ..
	sudo cp ./etc/terrafab /etc/init.d
	sudo chmod 755 /etc/init.d/terrafab
	sudo /etc/init.d/tilestache start
	touch '/home/kartverk/kartverk_vm_services/.terrafab_done'
fi

cd terrafab
npm install
git pull
cd ..
