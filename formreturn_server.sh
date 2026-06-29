#!/bin/bash
# Arranca el componente servidor de FormReturn (lo invoca el Manager).
# Réplica de installer/linux/formreturn_server.sh del repo, con el fix de
# renderizado XWayland.
FRM_HOME=.
COMMAND_PATH=`echo ${0} | sed -e "s/\(.*\)\/.*$/\1/g"`
cd ${COMMAND_PATH}

if [ -z $JAVA_HOME ]; then
  JAVA_COMMAND=`which java`
  if [ "$?" = "1" ]; then
    echo "No executable java found. Please set JAVA_HOME variable";
    exit 1;
  fi
else
  JAVA_COMMAND=$JAVA_HOME/bin/java
fi

exec $JAVA_COMMAND -Dsun.java2d.xrender=false \
  -cp "$FRM_HOME/lib/formreturn.jar:$FRM_HOME/lib/*" \
  -Xmx512m com.ebstrada.formreturn.server.ServerGUI
