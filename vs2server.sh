#!/bin/bash
if [ "$#" -ne 3 ]; then
        echo "Usage: $0 <fabric/forge> <minecraft_version> <loader_version>"
        echo "Example: $0 fabric 1.20.4 0.15.9"
        exit 1
fi
SHELL=/data/data/com.termux/files/usr/bin/bash
echo "This script should only be run in termux"
read -n1 -r -p "Press any key to continue..."
clear
#check if mc ver is not below 1.16.5
version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }
if version_gt "1.16.5" "$2"; then
    echo "Warning: This script was designed to run minecraft 1.16.5>."
	echo "Older versions of minecraft WONT RUN because they only support java 16 or older, NOT java 21 which is automatically installed."
	echo "If you want to host old minecraft server on ur phone, use any other script or set it up manually urself."
	exit
fi
pkg install jq -y
loader="$1"
version="$2"
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
start_script_fabric() {
JAVA_HOME=$HOME/vs2server/runtimes/jdk*
echo "JAVA_HOME=$HOME/vs2server/runtimes/jdk*
SHELL=/data/data/com.termux/files/usr/bin/bash
grun -s $JAVA_HOME/bin/java -Djava.library.path=$JAVA_HOME/lib -Xmx2G -jar $HOME/vs2server/instances/jar" > start.sh
}
start_script_forge(){
JAVA_HOME=$HOME/vs2server/runtimes/jdk*
echo "#!/usr/bin/env sh
# Forge requires a configured set of both JVM and program argume#!/usr/bin/env sh
# Forge requires a configured set of both JVM and program arguments.
# Add custom JVM arguments to the user_jvm_args.txt
# Add custom program arguments {such as nogui} to this file in the next line before the "$@" or
#  pass them to this script directly 
grun -s JAVA_HOME=$HOME/vs2server/runtimes/jdk* $HOME/vs2server/runtimes/jdk*/bin/java @user_jvm_args.txt @libraries/net/minecraftforge/forge/1.20.1-47.2.23/unix_args.txt nogui"$@"" > start.sh
echo "# Xmx and Xms set the maximum and minimum RAM usage, respectively.
# They can take any number, followed by an M or a G.
# M means Megabyte, G means Gigabyte.
# For example, to set the maximum to 3GB: -Xmx3G
# To set the minimum to 2.5GB: -Xms2500M

# A good default for a modded server is 4GB.
# Uncomment the next line to set it.
-Xmx2G -Djava.library.path=$HOME/vs2server/runtimes/jdk*" > user_jvm_args.txt
}
remove_mod(){
cat << 'EOF' > mod_remover.sh
#!/bin/bash

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
            echo "Are you sure that you want to delete '$name'? [Y/n]"
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
EOF
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
	fname="$(curl -s "$url" | jq -r '.[0].files[0].filename')"
	if [ ! -d "$HOME"/vs2server/instances/mods ]; then
		mkdir $HOME/vs2server/instances/mods
	fi
	if [ -f "$HOME"/vs2server/instances/mods/"$fname" ]; then
        echo "Mod $fname already downloaded"
    else
        wget -P "$HOME"/vs2server/instances/mods "$dlink"
    fi
	check_dep "$loader" "$version" "$name"
}
# ------------------------------------------------------------------------- #
echo "Installing needed termux packages"
pkg update -y
pkg upgrade -y
pkg install glibc-repo -y
pkg install glibc-runner patchelf-glibc coreutils-glibc tar coreutils patchelf procps -y

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

if [ "$1" = "forge" ]; then
	if command -v java >/dev/null 2>&1; then
		echo "java is already installed"
	else
		pkg install openjdk-17
	fi
fi

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

install=true
if [ -d "$HOME"/vs2server/instances ]; then
	echo "Another instance already exists. Proceeding will overwrite it which will delete all worlds, configs, and mods. Continue? [Y/n] "
	read -r dc
    case "$(echo "$dc" | tr '[:upper:]' '[:lower:]')" in
	[yY])
		echo "Deleting vs2server folder"
		rm -rf "$HOME"/vs2server/instances
        	;;
        *)
        echo "Cancelled."
		install=false
        ;;
    esac
elif [ ! -d "$HOME"/vs2server/instances ]; then
	mkdir "$HOME"/vs2server/instances
fi
if [ "$install" = "true" ]; then
	case $1 in
	fabric )
        wget -P "$HOME"/vs2server/instances https://meta.fabricmc.net/v2/versions/loader/"$2"/"$3"/1.0.0/server/jar
		iferror
		jarfile=fabric-server-mc."$2"-loader."$3"-launcher.1.0.0
		grun -s JAVA_HOME=$HOME/vs2server/runtimes/jdk* $HOME/vs2server/runtimes/jdk*/bin/java -Djava.library.path=$HOME/vs2server/runtimes/jdk* -jar $HOME/vs2server/instances/jar nogui
		start_script_fabric
		echo "eula=true" > $HOME/vs2server/instances/eula.txt
		;;
	forge )
        wget -P "$HOME"/vs2server/instances https://maven.minecraftforge.net/net/minecraftforge/forge/"$2"-"$3"/forge-"$2"-"$3"-installer.jar
		iferror
        jarfile=forge-"$2"-"$3"-installer
		java -jar $HOME/vs2server/instances/forge-"$2"-"$3"-installer.jar --installServer
		rm run.sh
		start_script_forge
		echo "eula=true" > $HOME/vs2server/instances/eula.txt
		;;
	* )
        echo "Invalid Mod Loader, use fabric or forge"
		;;
	esac
fi

cd "$HOME"/vs2server/instances

read -p "Do you want to install Valkyrian Skies, Clockwork and Eureka? [Y/n] " dc
case "$(echo "$dc" | tr '[:upper:]' '[:lower:]')" in
[yY])
	install_mod "$1" "$2" "eureka"
	install_mod "$1" "$2" "create-clockwork"
	;;
esac
cd "$HOME"/vs2server/instances/
pwd=$(pwd)
echo "server files are located in "$pwd""
cd ~/
if [ ! -f "start.sh" ]; then
	read -p "Do you want to make a start script in your home directory? [Y/n] " dc
	case "$(echo "$dc" | tr '[:upper:]' '[:lower:]')" in
	[yY])
		echo "cd "$HOME"/vs2server/instances/ 
sh start.sh" > start.sh
		echo "To run the server, run 'sh start.sh'"
		;;
	*)
		echo "To run the server, go to "$pwd" and run 'sh start.sh'"
	esac
fi
if [ ! -f "~/import_mods.sh" ]; then
	echo "cp -r storage/shared/vs2termux/mods "$HOME"/vs2server/instances/" > import_mods.sh
fi
if [ ! -f "~/mod_remover.sh" ]; then
	remove_mod
fi
if [ ! -d "$HOME"/storage/shared ]; then
	termux-setup-storage
fi
if [ ! -d "$HOME"/storage/shared/vs2termux ]; then
	mkdir "$HOME"/storage/shared/vs2termux
fi
if [ ! -d "$HOME"/storage/shared/vs2termux/mods ]; then
	mkdir "$HOME"/storage/shared/vs2termux/mods
fi
if [ -d "$HOME"/storage/shared/vs2termux/exported_mods ]; then
	rm -rf "$HOME"/storage/shared/vs2termux/exported_mods
fi
if [ ! -d "$HOME"/storage/shared/vs2termux/exported_mods ]; then
	mkdir "$HOME"/storage/shared/vs2termux/exported_mods
	cp -R "$HOME"/vs2server/instances/mods "$HOME"/storage/shared/vs2termux/exported_mods/ 
fi
cd ~/storage/shared/vs2termux
if [ ! -f "~/storage/shared/vs2termux/copy_mod_to_server.txt" ]; then
	echo "Folder for importing mods from the internal storage to the server. 
Add mods to the 'mods' folder and run 'sh import_mods.sh' in termux to copy it to the server." > copy_mod_to_server.txt
fi
if [ ! -f "~/storage/shared/vs2termux/run_server.txt" ]; then
	echo "To run the server, run 'sh start.sh' if u made the script in the home folder.
Run 'cd ~/vs2server/instances/ && sh start.sh' if u did not made the script in the home folder.
To join the server, enter 'localhost' if ur trying to join the server from the same device as ur hosting it.
If you want someone else to join from outside of ur local network, u will need to 'port foward' the server.
Theres shit ton of guides on how to do that online. " > run_server.txt
fi
if [ ! -f "~/storage/shared/vs2termux/mod_remover.txt" ]; then
	echo "Run 'sh mod_remover.sh' to open mod removing Command Line Interface" > mod_remover.txt
fi
if [ ! -f "~/storage/shared/vs2termux/exported_mods.txt" ]; then
	echo "'exported_mods' folder contains the mods that the server has downloaded automatically.
U need to copy them to ur clients mods folder so u could join the server" > exported_mods.txt
fi
echo "Check 'internal storage/vs2termux/' folder for some information that u might find useful."

) 2>&1 | tee "$HOME"/.cache/vs2server.log
