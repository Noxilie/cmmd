#!/bin/bash

modpack="enigmatica2expert"
version=${1}
modpack_url="https://minecraft.curseforge.com/projects/${modpack}/files"

if [ -z ${version+x} ]; then
	version='data-name';
fi

function get_mod {
	cd mods
	mod_url="https://minecraft.curseforge.com/projects/${1}/files/${2}/download"
	echo "Downloading ${mod_url}..."
	wget -q --show-progress --trust-server-names "${mod_url}"
	if [ $? -ne 0 ]; then
		echo >&2 -e "\033[31;1mDownload error!!!\033[0m"
	fi
	cd ..
}

command -v wget >/dev/null 2>&1 || { echo >&2 -e "I require \033[31;1mwget\033[0m but it's not installed.  Aborting."; exit 1; }
command -v 7z >/dev/null 2>&1 || { echo >&2 -e "I require \033[31;1m7z\033[0m but it's not installed.  Aborting."; exit 1; }
command -v curl >/dev/null 2>&1 || { echo >&2 -e "I require \033[31;1mcurl\033[0m but it's not installed.  Aborting."; exit 1; }
command -v awk >/dev/null 2>&1 || { echo >&2 -e "I require \033[31;1mawk\033[0m but it's not installed.  Aborting."; exit 1; }

rm -rf mods_bkp config_bkp
mv -f mods mods_bkp
mv -f config config_bkp
mkdir mods config

echo "Getting page - ${modpack_url}..."
download_block=$(curl "${modpack_url}" 2>&1 |\
		grep "overflow-tip twitch-link" -A 50 | grep "twitch-link\|data-name"|grep "${version}" -B 1|head -n 2)
download_version=$(echo "${download_block}"|grep "data-name"|awk -F'"' '{print $4}')
download_path=$(echo "${download_block}" |head -n 1|awk -F'"' '{print $4}')
echo "Downloading curse modpack..."
wget -q --show-progress https://minecraft.curseforge.com/${download_path}/download -O modpack.zip

#-------------get all needed mods from modpack
printf "Examining the manifest of the modpack... "
7z e -y modpack.zip manifest.json 1>/dev/null
printf "done\n"

echo "Downloading mods..."
grep "projectID\|fileID" manifest.json|tail -n +2|sed -r 's/.+ ([0-9]+).+/\1/g'| awk 'NR%2{printf "%s ",$0;next;}1'|while read line; do get_mod $line; done

forge_ver=$(grep "forge-" manifest.json|awk -F'"' '{print $4}')
rm manifest.json

#-------------unpack overrides
printf "Unpacking overrides... "
7z x -y modpack.zip overrides 1>/dev/null
for obj in $(ls overrides); do
	if [ "${obj}" != 'config' ] && [ "${obj}" != 'mods' ]; then 
		rm -rf "${obj}"
	fi
	cp -rlf "overrides/${obj}" .
done;
rm -r overrides
printf "done\n"
rm modpack.zip

printf "\n\nSuccessfully updated to \"${download_version}\"\n"
printf "Modpack forge version: ${forge_ver}\n"
