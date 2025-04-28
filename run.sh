#!/usr/bin/env sh
# Forge requires a configured set of both JVM and program argume#!/usr/bin/env sh
# Forge requires a configured set of both JVM and program arguments.
# Add custom JVM arguments to the user_jvm_args.txt
# Add custom program arguments {such as nogui} to this file in the next line before the "$@" or
#  pass them to this script directly 
grun -s JAVA_HOME=$HOME/vs2server/runtimes/jdk* $HOME/vs2server/runtimes/jdk*/bin/java @user_jvm_args.txt @libraries/net/minecraftforge/forge/1.20.1-47.2.23/unix_args.txt nogui"$@"