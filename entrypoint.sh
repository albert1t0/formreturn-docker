#!/usr/bin/env bash
# Arranca FormReturn Manager dentro del contenedor.
# Corre como root -> user.home=/root -> la app usa /root/.formreturn,
# que run.sh mapea a $HOME/.formreturn del host.
set -euo pipefail

FR_HOME="${FR_HOME:-/opt/formreturn}"
JAVA_MEM="${JAVA_MEM:-1024}"

# cd al directorio de la app (como hace el formreturn.sh original).
cd "${FR_HOME}"

# headless=false explícito: aunque exponemos DISPLAY, algunas JVM lo heredan mal.
# -Dsun.java2d.xrender=false: bajo XWayland la aceleración XRender renderiza
# ventanas en blanco; forzar la pipeline de software lo resuelve.
exec java \
    -Djava.awt.headless=false \
    -Dsun.java2d.xrender=false \
    -Xmx${JAVA_MEM}m \
    -jar "${FR_HOME}/lib/formreturn.jar" \
    "$@"
