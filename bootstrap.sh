#!/bin/bash

if [ ! -f '.done_tilestache' ]; then
	echo  "Setting up Tilestache"
	cp ./etc/tilestache /etc/init.d
	chmod 755 /etc/init.d/tilestache
	/etc/init.d/tilestache start
	touch '.done_tilestache'
fi

if [ ! -f '.done_leaflet' ]; then
	echo  "Setting up Leaflet demo app"
  sudo -u norx mkdir leaflet
	sudo -u norx git clone git://github.com/bengler/norx_leaflet.git leaflet
	cd leaflet
  npm install
  chown norx *
	cd ..
	cp ./etc/leaflet /etc/init.d
	chmod 755 /etc/init.d/leaflet
	/etc/init.d/leaflet start
	touch '.done_leaflet'
fi

if [ ! -f '.done_elasticsearch' ]; then
	echo "Setting up Elastic Search postgres bindings and index"
	
  curl --silent -XDELETE 'localhost:9200/_river'
  curl --silent -XDELETE 'localhost:9200/places'
  
  curl --silent -X PUT localhost:9200/places

  curl --silent -XPUT localhost:9200/places/place/_mapping -d "{
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
  curl --silent -XPUT 'localhost:9200/_river/places_suggest_river/_meta' -d "{
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

  # curl -XGET localhost:9200/places/_suggest -d '{
  #     "place-suggest" : {
  #       "text" : "n",
  #       "completion" : {
  #         "field" : "suggest"
  #       }
  #     }
  # }'

	touch '.done_elasticsearch'
fi
