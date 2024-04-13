#!/bin/bash
clear
(
if [ "$#" -ne 3 ]; then
        echo "Usage: $0 <fabric/forge> <minecraft_version> <loader_version>"
        echo "Example: $0 fabric 1.20.4 0.15.9"
        exit 1
fi

mkdir "$HOME"/vs2server/instances
iferror() {
    if [ "$?" -ne 0 ]; then
        echo "Something went wrong, log saved to ~/.cache/vs2server.log"
        exit 1
    fi
}
# ------------------------------------------------------------------------- #
#if [ "$(free --giga | awk '/Mem:/ {print $2}')" -le 5 ]; then
#        echo "Your phone stinks, it might die if you continue with $(free --giga | awk '/Mem:/ {print $2}')GB of useable RAM. Continue? [Y/n]"
#        read -r dc
#        case "$(echo "$dc" | tr '[:upper:]' '[:lower:]')" in
#        [yY])
#            echo "Okay sure but don't blame me if sonething went wrong"
#            ;;
#        *)
#            echo "Your phone thanks you in your infinite wisdom"
#            exit 1
#            ;;
#        esac
#fi
# ------------------------------------------------------------------------- #
if [ -d "$HOME"/vs2server/instances ]; then
	echo "Another instance already exists. Proceeding will delete the instance, all worlds, configs, and mods. Continue? [Y/n]"
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
echo Installing Minecraft "$2" "$1"-"$3" in "$4"
cd "$HOME"/vs2server/instances/
case $1 in
fabric )
        wget https://meta.fabricmc.net/v2/versions/loader/"$2"/"$3"/1.0.0/server/jar
	iferror
        jarfile=fabric-server-mc."$2"-loader."$3"-launcher.1.0.0
        ;;
forge )
        wget https://maven.minecraftforge.net/net/minecraftforge/forge/"$2"-"$3"/forge-"$2"-"$3"-installer.jar
	iferror
        jarfile=forge-"$2"-"$3"-installer
        ;;
* )
        echo "Invalid Mod Loader, use fabric or forge"
esac

#echo "Installing needed termux packages"
#pkg update
#pkg upgrade -y
#pkg install glibc-repo -y
#pkg install glibc-runner patchelf-glibc coreutils-glibc tar coreutils patchelf openjdk-17 jq -y

case $1 in
fabric )
	grun -s JAVA_HOME=$HOME/vs2server/runtimes/jdk* $HOME/vs2server/runtimes/jdk*/bin/java -Djava.library.path=$HOME/vs2server/runtimes/jdk* -jar $HOME/vs2server/instances/jar nogui
	echo "eula=true" > $HOME/vs2server/instances/eula.txt
    ;;
forge )
    java -jar $HOME/vs2server/instances/forge-"$2"-"$3"-installer.jar --installServer
	echo "eula=true" > $HOME/vs2server/instances/eula.txt
	
    ;;
esac
echo "$1" > $HOME/vs2server/configs/loader.txt
echo "$2" > $HOME/vs2server/configs/mcver.txt
) 2>&1 | tee "$HOME"/vs2server/logs/server_installer.log
