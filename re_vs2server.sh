#Initialize variables
declare -A args=()
Android=""


### --- Argument Parsing Area --- ###

# Parse arguments and assign them variable
while (( $# )); do
	case "$1" in
 	('--mcver') args+=("$1" "$2"); shift 2;;
 	('--loaderver') args+=("$1" "$2"); shift 2;;
 	('--loader') args+=("$1" "$2"); shift 2;;
	('--glibc') if [ "$PREFIX" = '/data/data/com.termux/files/usr' ]; then args+=("$1" "true"); fi; shift 1;;
	(*) echo "Invalid argument found. Check your spelling"; break;;
	esac
done




###~~~~Debug Echoes~~~###
echo "###~~~~Debug Echoes~~~###"

echo "All args: ""${args[@]}"
echo "Minecraft Version: ""${args['--mcver']}"
echo "${args['--loader']}"" Mod Loader Version: ""${args['--loaderver']}"

echo "GLIBC: " "${args['--glibc']}"

echo "###~~~~Debug Echoes~~~###"
###~~~~Debug Echoes~~~###


# Parse Associative Array into regular vars to simplify scripts below



### --- Argument Parsing Area --- ###


# Check if given versions are valid


# Create folders
mkdir $HOME/mcserver
mkdir $HOME/mcserver/runtimes
mkdir $HOME/mcserver/"${args['--mcver']}"_"${args['--loader']}"_"${args['--loader']}"


# Install Temurin

## Install glibc but only if on termux.

