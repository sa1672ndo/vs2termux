#!/bin/bash
clear
(
check_dep(){
	if [ "$#" -ne 3 ]; then
		echo "invalid arguments"
		exit 1
	fi
	loader=$1
	version=$2
	name=$3
	url="https://api.modrinth.com/v2/project/"$name"/version?loaders=\[%22"$loader"%22\]&game_versions=\[%22"$version"%22\]"
	i=0
	while [ "$i" -le 4 ]
	do
		url="https://api.modrinth.com/v2/project/"$name"/version?loaders=\[%22"$loader"%22\]&game_versions=\[%22"$version"%22\]"
		command='jq -r ".[0].dependencies["$i"] | select(.dependency_type == \"required\") | .project_id"'
		id=$(curl -s "$url" | eval "$command")
		if [ -n "$id" ]; then
			install_mod "$1" "$2" "$id"
		fi
		i=$((i + 1)) 
	done
}
install_mod(){
if [ "$#" -ne 3 ]; then
        echo "invalid arguments"
        exit 1
fi
	loader=$1
	version=$2
	name=$3
	url="https://api.modrinth.com/v2/project/"$name"/version?loaders=\[%22"$loader"%22\]&game_versions=\[%22"$version"%22\]"
	dlink="$(curl -s "$url" | jq -r '.[0].files[0].url')"
	if [ ! -d "$HOME"/vs2server/instances/mods ]; then
		mkdir $HOME/vs2server/instances/mods
	fi
	cd $HOME/vs2server/instances/mods
	wget "$dlink"
	check_dep "$loader" "$version" "$name"
	
}
remove_mod(){
	name=$1
	if [ -n "$name" ]; then
		cd $HOME/vs2server/instances/mods
		if [ -e "$name" ]; then
			rm "$name"
			exit
		else
			echo "File '$name' does not exist."
			exit
		fi
	else
		while true; do
			clear
			cd $HOME/vs2server/instances/mods
			ls
			read -p "Enter the name of the file you want to delete (or type 'return' to return): " name
			if [ "$name" = "return" ]; then
				echo "Exiting script..."
				break
			elif [ -e "$name" ]; then
				echo "Are you sure that you want to delete "$name" ? [Y/n]"
				read -r dc
			    case "$(echo "$dc" | tr '[:upper:]' '[:lower:]')" in
				[yY])
					rm "$name"
					echo "File '$name' deleted."
				;;
				*)
					echo "Cancelled."
					exit 1
					;;
				esac
			else
				echo "File '$name' does not exist. Please try again."
				sleep 3
			fi
		done
	fi
}




if [ "$1" = "-i" ]; then
	if [ "$#" -eq 1 ]; then
		# mod installer cli
		while true; do
			loader=$(cat $HOME/vs2server/configs/loader.txt)
			version=$(cat $HOME/vs2server/configs/mcver.txt)
			read -p "Enter the name of the mod you want to install from modrinth (or type 'return' to return): " name
			if [ $name = "return" ]; then
				exit
			fi
			if [[ $name == *" "* ]]; then
				name="${name// /-}"
			fi
			url="https://api.modrinth.com/v2/project/"$name"/version"
			check="$(curl -s "$url" | jq '.[0]')"
			if [ -n "$check" ] && [ "$check" != "null" ]; then
				url="https://api.modrinth.com/v2/project/"$name"/version?loaders=\[%22"$loader"%22\]"
				check="$(curl -s "$url" | jq '.[0]')"
				if [ -n "$check" ] && [ "$check" != "null" ]; then
					url="https://api.modrinth.com/v2/project/"$name"/version?loaders=\[%22"$loader"%22\]&game_versions=\[%22"$version"%22\]"
					check="$(curl -s "$url" | jq '.[0]')"
					if [ -n "$check" ] && [ "$check" != "null" ]; then
						install_mod "$loader" "$version" "$name"
					else
						echo ""$name" does not support minecraft "$version""
					fi
				else
					echo ""$name" does not support loader "$loader""
				fi
			else
				echo "Mod "$name" was not found"
			fi
		done
	elif [ "$#" -eq 4 ]; then
		loader="$2"
		version="$3"
		name="$4"
		if [[ $name == *" "* ]]; then
			name="${name// /-}"
		fi
		url="https://api.modrinth.com/v2/project/"$name"/version"
		check="$(curl -s "$url" | jq '.[0]')"
		if [ -n "$check" ] && [ "$check" != "null" ]; then
			url="https://api.modrinth.com/v2/project/"$name"/version?loaders=\[%22"$loader"%22\]"
			check="$(curl -s "$url" | jq '.[0]')"
			if [ -n "$check" ] && [ "$check" != "null" ]; then
				url="https://api.modrinth.com/v2/project/"$name"/version?loaders=\[%22"$loader"%22\]&game_versions=\[%22"$version"%22\]"
				check="$(curl -s "$url" | jq '.[0]')"
				if [ -n "$check" ] && [ "$check" != "null" ]; then
					install_mod "$loader" "$version" "$name"
					exit
				else
					echo ""$name" does not support minecraft "$version""
				fi
			else
				echo ""$name" does not support loader "$loader""
			fi
		else
			echo "Mod "$name" was not found"
		fi
	else
		echo "Invalid arguments"
		echo "Usage: $0 -i <fabric/forge> <minecraft_version> <modname/modrinth_project-ID> (Installs a mod and it's depencencies from modrinth ONLY)"
		echo "Usage: $0 -i (Opens mod installation Command Line Interface)"
		echo "Example: $0 -i fabric 1.20.4 valkyrien-skies"
	fi
elif [ "$1" = "-d" ]; then
	if [ "$#" -eq 1 ]; then
		# mod remover Command Line Interface
		remove_mod
	elif [ "$#" -eq 2 ]; then
		# mod remover preset
		name="$2"
		remove_mod "$name"
	else
		echo "Invalid arguments"
		echo "Usage: $0 -d <filename>"
		echo "Usage: $0 -d"
		echo "Example: $0 -d sodium.."
		exit
	fi
else
	echo "Invalid arguments"
	echo "Usage: $0 -i <fabric/forge> <minecraft_version> <modname/modrinth_project-ID> (Installs a mod and it's depencencies from modrinth ONLY)"
	echo "Usage: $0 -i (Opens mod installation Command Line Interface)"
	echo "Usage: $0 -d <filename> (Deletes a mod in the mods folder)"
	echo "Usage: $0 -d (Opens mod deletion Command Line Interface)"
	echo "Example: $0 -i fabric 1.20.4 valkyrien-skies"
	echo "Example: $0 -d sodium.."
    exit
fi
) 2>&1 | tee "$HOME"/vs2server/logs/mod_manager.log