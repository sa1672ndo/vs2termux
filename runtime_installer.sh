#!/bin/bash
clear
(
if [ "$#" -ne 2 ]; then
        echo "Usage: $0 <java_version> <jre/jdk>"
        echo "Example: $0 17 jre"
        exit 1
fi
if [ "$2" != "jre" ] && [ "$2" != "jdk" ]; then
    echo "Invalid argument: $2. The second argument must be 'jre' or 'jdk'"
    exit 1
fi
iferror() {
    if [ "$?" -ne 0 ]; then
        echo "Something went wrong, log saved to ~/.cache/vs2server.log"
        exit 1
    fi
}
java=$1
releases=$(curl -s https://api.adoptium.net/v3/info/available_releases | jq -r '.available_releases[]')
iferror
found=false
for a in $releases; do
    if [ "$a" -eq "$java" ]; then
        found=true
        break
    fi
done
if [ "$found" = false ]; then
    echo "Java "$java" version does not exist. Heres a list of available java releases:"
    echo "$releases"
	exit
	sleep 3
fi 
if [ -d "$HOME"/vs2server/runtimes ]; then
	echo "Another runtime already exists. Proceeding will cause it to be overwritten with new one. Continue? [Y/n]"
	read -r dc
       case "$(echo "$dc" | tr '[:upper:]' '[:lower:]')" in
	[yY])
        echo "Deleting runtimes folder"
		rm -rf "$HOME"/vs2server/runtimes
        	;;
        *)
        	echo "Cancelled."
        	exit 1
        	;;
        esac
fi
mkdir "$HOME"/vs2server/runtimes
install_temurin_jdk() {
     version=$1
     package=$2
    arch=$(uname -m)
	os=$(uname | tr '[:upper:]' '[:lower:]')
     echo "Downloading Temurin $package $version for $os $arch"
    wget -P "$HOME"/vs2server/runtimes/ https://api.adoptium.net/v3/binary/latest/$version/ga/$os/$arch/$package/hotspot/normal/eclipse
    iferror
     echo "Extracting..."
     tar -xzf $HOME/vs2server/runtimes/eclipse -C "$HOME"/vs2server/runtimes/
    rm $HOME/vs2server/runtimes/eclipse
}
install_temurin_jdk "$1" "$2"
cd "$HOME"/vs2server/runtimes/jdk-"$1"*-"$2"/lib || exit
iferror
grun -c -f ../bin/java
iferror
) 2>&1 | tee "$HOME"/vs2server/logs/runtime_installer.log