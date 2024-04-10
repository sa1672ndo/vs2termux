JAVA_HOME=$HOME/vs2server/runtimes/jdk*
SHELL=/data/data/com.termux/files/usr/bin/bash
grun -s $JAVA_HOME/bin/java -Djava.library.path=$JAVA_HOME/lib -Xmx2G -jar $HOME/vs2server/jar
