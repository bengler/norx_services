#!/bin/bash

# Update and restart services
git pull
cd leaflet
sudo -u norx npm --silent install
git pull
cd ..

cp ./etc/tilestache /etc/init.d
chmod 755 /etc/init.d/tilestache
cp ./etc/leaflet /etc/init.d
chmod 755 /etc/init.d/leaflet

/etc/init.d/tilestache restart
/etc/init.d/leaflet restart
