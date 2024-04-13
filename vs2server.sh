#!/bin/bash
clear
(
SHELL=/data/data/com.termux/files/usr/bin/bash
echo "This script should only be run in termux"
read -n1 -r -p "Press any key to continue..."

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
echo "Installing needed termux packages"
pkg update -y
pkg upgrade -y
pkg install glibc-repo -y
pkg install glibc-runner patchelf-glibc coreutils-glibc tar coreutils patchelf openjdk-17 jq -y
if [ ! -d "$HOME"/vs2server ]; then
	mkdir "$HOME"/vs2server
fi
if [ ! -d "$HOME"/vs2server/configs ]; then
	mkdir "$HOME"/vs2server/configs
fi
if [ ! -d "$HOME"/vs2server/scripts ]; then
	mkdir "$HOME"/vs2server/script
fi
if [ ! -d "$HOME"/vs2server/logs ]; then
	mkdir "$HOME"/vs2server/logs
fi
clear
while true; do
	echo "select a task:"
	echo "server_installer; runtime_installer; export/import_world"
	echo "mod_manager; config_editor; export_logs; exit; unistall"
	read -r dc
	case "$dc" in
	"server_installer")
		#installer done, now make unistaller and add it to this script.
		#too tired to implement multi instance support, just overwrite the existing instances with a new one.
		read -p "Enter the loader name: " loader
		read -p "Enter the minecraft version: " mcver
		read -p "Enter the loader version: " loader_ver
		bash server_installer.sh "$loader" "$mcver" "$loader_ver"
		;;
	"runtime_installer")
		#installer done, now make unistaller and add it to this script
		#too tired to implement multi runtime support, just overwrite the existing runtime with a new one.
		read -p "Enter the java version: " java
		read -p "Enter the package type <jdk/jre>): " package
        bash runtime_installer.sh $java $package
		;;
	"world_manager")
		#copy world folder to storage or copy world folder from storage and overwrite the current one
		echo "not implemented"
		;;
	"mod_manager")
		echo "select a task"
		read -p "install; uninstall " task
		if [ "$task" = "install" ]; then
			bash mod_manager.sh -i
		elif [ "$task" = "uninstall" ]; then
			bash mod_manager.sh -d
		fi
		;;
	"config_editor")
		#add file explorer and allow user to nano selected file if it exists.
		echo "not implemented"
		;;
	"export_logs")
		if [ ! -d "$HOME"/storage ]; then
			termux-setup-storage
		fi
		cd "$HOME"/vs2server
        tar -cJf logs.tar.xz logs
        mv logs.tar.xz "$HOME"/storage/downloads
		echo "All of the logs have been copied to your downloads folder"
		;;
	"unistall")
		echo "Are you sure that you want to unistall vs2termux and all of it's files? [Y/n]"
		read -r dc
		case "$(echo "$dc" | tr '[:upper:]' '[:lower:]')" in
		[yY])
			rm -rf ~/vs2server
			rm vs2server.sh
			exit
			;;
	"exit")
		exit
		;;
		*)
			;;
		esac
		;;
	*)
		echo "Unreconized task: $dc"
		;;
	esac
done

) 2>&1 | tee "$HOME"/vs2server/logs/vs2server.log