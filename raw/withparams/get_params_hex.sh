#!/bin/bash

DIR="/home/ubuntu/raw"

mkdir -p "${DIR}"/withparams

find "${DIR}" -type f -name "*.json" > "${DIR}"/filelist.txt
readarray -t files < "${DIR}"/filelist.txt
rm -f "${DIR}"/filelist.txt
num_files="${#files[@]}"

for i in $(seq 1 $num_files); do

	FILE="${files[$(($i-1))]}"
	FILENAME=$(basename "$FILE")

	tempjson="${DIR}"/temp.json
	rm -f "${tempjson}"
	cat "${DIR}"/$FILENAME | jq '[.data.categories[].scenes[] | {name: .sceneName, subname: .lightEffects[].scenceName, code: .lightEffects[].sceneCode, params_b64: .lightEffects[].scenceParam}]' > "${tempjson}"

	filewparams="${DIR}"/withparams/$FILENAME
	rm -f "${filewparams}"
	mv "${DIR}"/temp.json "${DIR}"/withparams/$FILENAME

	paramb64file="${DIR}"/withparams/${FILENAME//.json/_params_b64.json}
	rm -f "${paramb64file}"
	cat "${DIR}"/withparams/$FILENAME | jq '.[] | .params_b64' > "${paramb64file}"
	readarray -t params_b64 < "${paramb64file}"

	paramhexfile="${DIR}"/withparams/${FILENAME//.json/_params_hex.json}
	rm -f "${paramhexfile}"

	num_lines=$(wc -l < "${paramb64file}")

	for p in $(seq 1 $num_lines); do 

		b64=${params_b64[$((${p}-1))]}

		if [ $p == 1 ]; then
			echo "[" >> "${paramhexfile}"
		fi
		
		echo '{"params_hex": ' >> "${paramhexfile}"
		
		if [ ${b64} == "" ]; then
			hex=""
		else
			hex=$(echo ${b64//\"/} | base64 -d | od -t x1 -An -w20 | tr -d '\n' | tr -d ' ')
		fi
			echo -e '"'"${hex}"'"' >> "${paramhexfile}"
		
		if [ $p -lt $num_lines ]; then
			echo "}," >> "${paramhexfile}"
		else
			echo "}" >> "${paramhexfile}"
			echo "]" >> "${paramhexfile}"
		fi
		
	done

	# Merge

	filemerged="${DIR}"/withparams/${FILENAME//.json/_with_hex_param.json}
	rm -f "${filemerged}"
	jq -s 'transpose | map(add)' "${filewparams}" "${paramhexfile}" > "${filemerged}"

	# Combine "name" with "subname"
	merged=$(cat "${filemerged}")
	combined=${merged//'"'subname'"': '""',/}
	combined=${combined//'"', '"'subname'"': '"'/-}
	echo ${combined} > "${filemerged}"

	filepretty=${filemerged//_scenes_raw/}
	rm -f "${filepretty}"
	jq -s 'transpose | map(add)' "${filewparams}" "${paramhexfile}" > "${filemerged}"
	# Make Pretty
	jq . "${filemerged}" > "${filepretty}"

	# CLEANUP
	rm -f "${tempjson}"
	rm -f "${filewparams}"
	rm -f "${paramb64file}"
	rm -f "${paramhexfile}"
	rm -f "${filemerged}"

done
