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
	# IN CASE YOU WANT TO DELETE: curl -XDELETE 'localhost:9200/_river' && curl -XDELETE 'localhost:9200/places'

  curl -X PUT localhost:9200/places

  curl -XPUT localhost:9200/places/place/_mapping -d "{
    \"place\":{
      \"properties\":{
        \"name\" : { \"type\" : \"string\" },
        \"point\" : { \"type\" : \"string\", \"index\" : \"not_analyzed\"},
        \"kind\" : { \"type\" : \"integer\" },
        \"parent_name\" : { \"type\" : \"string\"},
        \"suggest\" : {
          \"type\" :     \"completion\",
          \"index_analyzer\" : \"simple\",
          \"search_analyzer\" : \"simple\",
          \"payloads\" : true
        }
      }
    }
  }"


  SQL="SELECT 'places' as _index, ssr.enh_snavn as \\\"place.name\\\", ssr.ogc_fid as _id, split_part(substring(ST_AsText(ssr.wkb_geometry), '\\\(([^\\\)]+)\\\)'), ' ', 1) as \\\"place.point.lng\\\", split_part(substring(ST_AsText(ssr.wkb_geometry), '\\\(([^\\\)]+)\\\)'), ' ', 2) as \\\"place.point.lat\\\", ssr.enh_navntype as \\\"place.kind\\\", adm_areas_kommuner.navn as \\\"place.parent_name\\\", ssr.enh_snavn || ' ' || adm_areas_kommuner.navn as \\\"suggest.input\\\", ssr.enh_snavn || ' (' || adm_areas_kommuner.navn || ')' as \\\"suggest.output\\\", split_part(substring(ST_AsText(ssr.wkb_geometry), '\\\(([^\\\)]+)\\\)'), ' ', 1) as \\\"suggest.payload.lng\\\", split_part(substring(ST_AsText(ssr.wkb_geometry), '\\\(([^\\\)]+)\\\)'), ' ', 2) as \\\"suggest.payload.lat\\\", ssr.enh_navntype, CASE WHEN ssr.enh_navntype IN(181,182,268,269,270,266) THEN 20 WHEN ssr.enh_navntype IN(101, 104, 108) THEN 10 ELSE 1 END as \\\"suggest.weight\\\" FROM ssr left join adm_areas_kommuner on ST_Within(ssr.wkb_geometry, adm_areas_kommuner.wkb_geometry)"
  curl -XPUT 'localhost:9200/_river/places_suggest_river/_meta' -d "{
      \"type\" : \"jdbc\",
      \"jdbc\" : {
          \"driver\" : \"org.postgresql.Driver\",
          \"url\" : \"jdbc:postgresql://localhost:5432/kartverk\",
          \"user\" : \"kartverk\",
          \"password\" : \"bengler\",
          \"sql\" : \"$SQL\"

      },
      \"index\" : {
          \"index\" : \"places\",
          \"type\" : \"place\"
      }
  }"

  # Test the index:
  # curl -XGET localhost:9200/places/_suggest -d '{
  #     "place-suggest" : {
  #       "text" : "n",
  #       "completion" : {
  #         "field" : "suggest"
  #       }
  #     }
  # }'

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
