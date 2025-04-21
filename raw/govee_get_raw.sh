#!/bin/bash

MODELS=("H6022" "H6051" "H6061" "H6062" "H6065" "H6072" "H6076" "H6078" "H6079" "H608C" "H6092" "H6167" "H7042" "H7055" "H7066" "H706C" "H7075" "H70BC" "H70CB")

for MODEL in "${MODELS[@]}"; do

	# Set filename with date

	FILENAME=${MODEL}_`date +%F`_scenes_raw.json

	# Pull the scene data from Govee. The publicly available (no-key-required) API works. Write to data to $FILENAME

	curl "https://app2.govee.com/appsku/v1/light-effect-libraries?sku=${MODEL}" -H 'AppVersion: 9999999' -s > ${FILENAME}

	############
	# Make raw data "pretty" =

	rm -f pretty_temp.json
	jq . <${FILENAME} >pretty_temp.json
	mv pretty_temp.json ${FILENAME}

done
