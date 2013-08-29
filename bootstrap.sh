#!/bin/bash

if [ ! -d "/srv/tilestache" ]; then
	mkdir /srv/tilestache
	cp -R ./files/tilestache/* /srv/tilestache
fi
