#!/bin/bash

if [ "$#" -ne 3 ]; then
        echo "Usage: $0 <fabric/forge> <minecraft_version> <loader_version>"
        echo "Example: $0 fabric 1.20.4 0.15.9"
        exit 1
fi


rm "$HOME"/.cache/vs2server.log
iferror() {
    if [ "$?" -ne 0 ]; then
        echo "Something went wrong, log saved to ~/.cache/vs2server.log"
        exit 1
    fi
}

install_temurin_jdk() {
 	version=$1
 	arch=aarch64
 	echo "Downloading Temurin JDK $version for $arch..."
	wget -P "$HOME"/vs2server/runtimes/ https://api.adoptium.net/v3/binary/latest/$version/ga/linux/aarch64/jre/hotspot/normal/eclipse
	iferror
 	echo "Extracting..."
 	tar -xzf $HOME/vs2server/runtimes/* -C "$HOME"/vs2server/runtimes/
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
		rm -rf "$HOME"/vs2server
		mkdir "$HOME"/vs2server
        	;;
        *)
        	echo "Cancelled."
        	exit 1
        	;;
        esac
fi

case $1 in
fabric )
        wget -P "$HOME"/vs2server/ https://meta.fabricmc.net/v2/versions/loader/"$2"/"$3"/1.0.0/server/jar
	iferror
        jarfile=fabric-server-mc."$2"-loader."$3"-launcher.1.0.0
        ;;
forge )
        wget -P "$HOME"/vs2server/ https://maven.minecraftforge.net/net/minecraftforge/forge/"$2"-"$3"/forge-"$2"-"$3"-installer.jar
	iferror
        jarfile=forge-"$2"-"$3"-installer
        ;;
* )
        echo "Invalid Mod Loader, use fabric or forge"
esac

echo "Installing needed termux packages"
pkg update
pkg upgrade -y
pkg install glibc-repo -y
pkg install glibc-runner patchelf-glibc coreutils-glibc tar coreutils patchelf bc openjdk-17 -y
mkdir "$HOME"/vs2server/runtimes
#this shit is broken, so i disabled it. 

#if (( "$(echo '$2 > 1.20' | bc -l)" )); then
#	install_temurin_jdk 21
#else
    install_temurin_jdk 17
#fi 
cd "$HOME"/vs2server/runtimes/jdk*/lib || exit
iferror
grun -c -f ../bin/java
iferror
cd "$HOME"/vs2server/ 

case $1 in
fabric )
	grun -s JAVA_HOME=$HOME/vs2server/runtimes/jdk* $HOME/vs2server/runtimes/jdk*/bin/java -Djava.library.path=$HOME/vs2server/runtimes/jdk* -jar $HOME/vs2server/jar nogui
	echo "eula=true" > $HOME/vs2server/eula.txt
	grun -s JAVA_HOME=$HOME/vs2server/runtimes/jdk* $HOME/vs2server/runtimes/jdk*/bin/java -Djava.library.path=$HOME/vs2server/runtimes/jdk* -jar -Xmx2G $HOME/vs2server/jar nogui
        ;;
forge )
    	java -jar $HOME/vs2server/forge-"$2"-"$3"-installer.jar --installServer
	echo "# Xmx and Xms set the maximum and minimum RAM usage, respectively.
# They can take any number, followed by an M or a G.
# M means Megabyte, G means Gigabyte.
# For example, to set the maximum to 3GB: -Xmx3G
# To set the minimum to 2.5GB: -Xms2500M

# A good default for a modded server is 4GB.
# Uncomment the next line to set it.
-Xmx2G -Djava.library.path=$HOME/vs2server/runtimes/jdk*" > $HOME/vs2server/user_jvm_args.txt
	echo "#!/usr/bin/env sh
# Forge requires a configured set of both JVM and program argume#!/usr/bin/env sh
# Forge requires a configured set of both JVM and program arguments.
# Add custom JVM arguments to the user_jvm_args.txt
# Add custom program arguments {such as nogui} to this file in the next line before the "$@" or
#  pass them to this script directly 
grun -s JAVA_HOME=$HOME/vs2server/runtimes/jdk* $HOME/vs2server/runtimes/jdk*/bin/java @user_jvm_args.txt @libraries/net/minecraftforge/forge/1.20.1-47.2.23/unix_args.txt nogui"$@"" > run.sh
    ;;
esac

) 2>&1 | tee -a ~/.cache/vs2server.log
