#!/usr/bin/env bash
# Lanza el contenedor de FormReturn conectándose a tu pantalla X (XWayland).
# Los datos se guardan en ~/.formreturn (igual que una instalación nativa) y,
# al correr con tu UID, los archivos son tuyos (no de root).
set -euo pipefail

IMG="formreturn:1.7.5"
FR_DIR="${HOME}/.formreturn"
APP_HOME="/home/ubuntu"

mkdir -p "${FR_DIR}"

# El contenedor corre con tu uid (usuario formreturn) -> SO_PEERCRED ve a tu
# usuario del host. Autoriza a $(whoami). Revocable con:
#   xhost -SI:localuser:$(whoami)
if command -v xhost >/dev/null 2>&1; then
    xhost +SI:localuser:"$(whoami)" >/dev/null 2>&1 || xhost +local:root >/dev/null 2>&1 || true
fi

docker run --rm -it \
    --security-opt label=disable \
    --ipc=host \
    -e "DISPLAY=${DISPLAY:-:1}" \
    -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
    -v "${FR_DIR}:${APP_HOME}/.formreturn" \
    -e "JAVA_MEM=${JAVA_MEM:-1024}" \
    --name formreturn \
    "${IMG}" "$@"
