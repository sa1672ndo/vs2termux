#!/bin/bash
clear

SHELL=/data/data/com.termux/files/usr/bin/bash
echo "This script should only be run in termux"
read -n1 -r -p "Press any key to continue..."

if [ "$#" -ne 3 ]; then
        echo "Usage: $0 <fabric/forge> <minecraft_version> <loader_version>"
        echo "Example: $0 fabric 1.20.4 0.15.9"
        exit 1
fi

#check if mc ver is not below 1.16.5
version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }
if version_gt "1.16.5" "$2"; then
    echo "Warning: This script was designed to run minecraft 1.16.5>."
	echo "Older versions of minecraft WONT RUN because they only support java 16 or older, NOT java 21 which is automatically installed."
	echo "If you want to host old minecraft server on ur phone, use any other script or set it up manually urself."
	exit
fi
url="https://api.modrinth.com/v2/project/valkyrien-skies/version?loaders=\[%22"$loader"%22\]&game_versions=\[%22"$version"%22\]"
check="$(curl -s "$url" | jq '.[0]')"
if [ -n "$check" ] && [ "$check" != "null" ]; then
	mods=true
else
	echo "Warning: This script was designed to run a minecraft server with valkyrien skies 2 installed, which isn't available for minecraft "$version"."
	exit
fi
iferror() {
    if [ "$?" -ne 0 ]; then
        echo "Something went wrong, log saved to ~/.cache/vs2server.log"
        exit 1
    fi
}

install_temurin_jdk() {
     version=$1
     #package=$2
    arch=$(uname -m)
	os=$(uname | tr '[:upper:]' '[:lower:]')
     echo "Downloading Temurin $package $version for $os $arch"
    wget -P "$HOME"/vs2server/runtimes/ https://api.adoptium.net/v3/binary/latest/$version/ga/$os/$arch/jre/hotspot/normal/eclipse
    iferror
     echo "Extracting..."
     tar -xzf $HOME/vs2server/runtimes/eclipse -C "$HOME"/vs2server/runtimes/
    rm $HOME/vs2server/runtimes/eclipse
}

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
# ------------------------------------------------------------------------- #
pkg install procps coreutils -y
if [ "$(free --giga | awk '/Mem:/ {print $2}')" -le 5 ]; then
        echo "Your phone stinks, it might die if you continue with $(free --giga | awk '/Mem:/ {print $2}')GB of useable RAM. Continue? [Y/n]"
        read -r dc
        case "$(echo "$dc" | tr '[:upper:]' '[:lower:]')" in
        [yY])
            echo "Okay sure but don't blame me if sonething went wrong"
            ;;
        *)
            echo "Your phone thanks you in your infinite wisdom"
            exit 1
            ;;
        esac
fi
# ------------------------------------------------------------------------- #

(
echo Installing Minecraft "$2" "$1"-"$3"

if [ -d "$HOME"/vs2server ]; then
	echo "It seems you already ran this script before. Proceeding will delete all worlds, configs, and mods. Continue? [Y/n]"
	read -r dc
        case "$(echo "$dc" | tr '[:upper:]' '[:lower:]')" in
 	[yY])
        echo "Deleting vs2server folder"
		rm -rf "$HOME"/vs2server/instances
        	;;
        *)
        	echo "Cancelled."
        	exit 1
        	;;
        esac
fi
mkdir "$HOME"/vs2server/instances
case $1 in
fabric )
        wget -P "$HOME"/vs2server/instances https://meta.fabricmc.net/v2/versions/loader/"$2"/"$3"/1.0.0/server/jar
	iferror
        jarfile=fabric-server-mc."$2"-loader."$3"-launcher.1.0.0
        ;;
forge )
        wget -P "$HOME"/vs2server/instances https://maven.minecraftforge.net/net/minecraftforge/forge/"$2"-"$3"/forge-"$2"-"$3"-installer.jar
	iferror
        jarfile=forge-"$2"-"$3"-installer
        ;;
* )
        echo "Invalid Mod Loader, use fabric or forge"
esac

echo "Installing needed termux packages"
pkg update -y
pkg upgrade -y
pkg install glibc-repo -y
pkg install glibc-runner patchelf-glibc coreutils-glibc tar coreutils patchelf openjdk-17 -y
mkdir "$HOME"/vs2server/runtimes

if [ -d "$HOME"/vs2server/runtimes ]; then
	echo "Another runtime already exists. Do you want to overwrite it with a new one?. [Y/n]"
	read -r dc
       case "$(echo "$dc" | tr '[:upper:]' '[:lower:]')" in
	[yY])
        echo "Deleting runtimes folder"
		rm -rf "$HOME"/vs2server/runtimes/jdk*
		install_temurin_jdk 21
        	;;
        *)
        	echo "Cancelled."
        	;;
        esac
elif [ ! -d "$HOME"/vs2server/runtimes ]; then
	mkdir "$HOME"/vs2server/runtimes/
	install_temurin_jdk 21
fi
cd "$HOME"/vs2server/runtimes/jdk*/lib || exit
iferror
grun -c -f ../bin/java
iferror
cd "$HOME"/vs2server/instances

case $1 in
fabric )
	echo "eula=true" > $HOME/vs2server/instances/eula.txt
	grun -s JAVA_HOME=$HOME/vs2server/runtimes/jdk* $HOME/vs2server/runtimes/jdk*/bin/java -Djava.library.path=$HOME/vs2server/runtimes/jdk* -jar $HOME/vs2server/jar nogui
	wget https://raw.githubusercontent.com/sa1672ndo/vs2termux/main/start.sh
	sh start.sh
        ;;
forge )
    java -jar $HOME/vs2server/instance/forge-"$2"-"$3"-installer.jar --installServer
	rm user_jvm_args.txt
	rm run.sh
	wget https://raw.githubusercontent.com/sa1672ndo/vs2termux/main/user_jvm_args.txt
	wget https://raw.githubusercontent.com/sa1672ndo/vs2termux/main/run.sh
	echo "eula=true" > $HOME/vs2server/instances/eula.txt
	sh run.sh
    ;;
esac
read -p "Do you want to install Valkyrian Skies and Eureka? [Y/n]" dc
case "$(echo "$dc" | tr '[:upper:]' '[:lower:]')" in
[yY])
	install_mod "$1" "$2" "eureka"
	;;
*)
	exit
	;;
esac

) 2>&1 | tee ~/.cache/vs2server.log
