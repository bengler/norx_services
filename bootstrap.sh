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

if [ ! -f '/home/kartverk/kartverk_vm_services/.elasticsearch_done' ]; then
	echo "Setting up elastic search postgres bindings"
	# IN CASE YOU WANT TO DELETE: curl -XDELETE 'localhost:9200/_river' && curl -XDELETE 'localhost:9200/stedsnavn'
	curl -XPUT 'localhost:9200/_river/adm_areas_kommuner_river/_meta' -d '{
	    "type" : "jdbc",
	    "jdbc" : {
	        "driver" : "org.postgresql.Driver",
	        "url" : "jdbc:postgresql://localhost:5432/kartverk",
	        "user" : "kartverk",
	        "password" : "bengler",
	        "sql" : "select navn as name, st_asgeojson(st_centroid(wkb_geometry)) as point, objtype from adm_areas_kommuner"

	    },
	      "index" : {
	          "index" : "stedsnavn",
	          "type" : "jdbc"
	      }
	}'

	touch '/home/kartverk/kartverk_vm_services/.elasticsearch_done'
fi

# Update and restart services
git pull
cd terrafab
npm install
git pull
cd ..

sudo cp ./etc/tilestache /etc/init.d
sudo chmod 755 /etc/init.d/tilestache
sudo cp ./etc/terrafab /etc/init.d
sudo chmod 755 /etc/init.d/terrafab

sudo /etc/init.d/tilestache restart
sudo /etc/init.d/terrafab restart
