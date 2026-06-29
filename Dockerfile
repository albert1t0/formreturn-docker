# FormReturn 1.7.5 — contenedor con OpenJDK 8
# La app se extrae del instalador oficial precompilado (no requiere compilar).
FROM eclipse-temurin:8-jdk

# Fuentes + librerías X11 nativas para AWT/Swing (libawt_xawt.so necesita libXext,
# libXrender, etc., que la imagen base eclipse-temurin NO incluye).
RUN apt-get update && apt-get install -y --no-install-recommends \
        fonts-dejavu \
        fonts-liberation \
        fontconfig \
        libfreetype6 \
        libxext6 \
        libxrender1 \
        libxi6 \
        libxtst6 \
        libx11-6 \
        unzip \
        curl \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# La imagen base eclipse-temurin:8-jdk ya trae el usuario 'ubuntu' con uid/gid
# 1000 (igual que el host). Lo reusamos para que los archivos en ~/.formreturn
# sean del usuario, no de root.
ARG APP_USER=ubuntu

ENV FR_HOME=/opt/formreturn
WORKDIR ${FR_HOME}

# Descarga el instalador oficial y extrae ÚNICAMENTE lib/ (la app + sus 60 deps).
# El instalador es interactivo, pero lib/formreturn.jar y sus Class-Path ya están
# todos embebidos, así que se omite el paso de instalación.
ARG FORMRETURN_VERSION=1.7.5
RUN curl -fsSL -o /tmp/installer.jar \
        "https://github.com/rquast/formreturn/releases/download/v${FORMRETURN_VERSION}/formreturn_setup_${FORMRETURN_VERSION}.jar" \
    && mkdir -p ${FR_HOME}/lib \
    && unzip -j -o /tmp/installer.jar 'lib/*' -d ${FR_HOME}/lib/ \
    && chmod -R a+rX ${FR_HOME} \
    && rm -f /tmp/installer.jar

COPY entrypoint.sh /entrypoint.sh
RUN chmod a+rx /entrypoint.sh

# Script del servidor: el Manager lo lanza vía ProcessBuilder. Sin él, las
# ventanas que dependen del servidor quedan en blanco.
COPY formreturn_server.sh ${FR_HOME}/formreturn_server.sh
RUN chmod a+rx ${FR_HOME}/formreturn_server.sh

# A partir de aquí la app corre como usuario no-root (uid = el del host).
USER ${APP_USER}
ENV HOME=/home/${APP_USER}
# Ruta DENTRO del contenedor donde la app guarda sus datos (BD Derby, formularios,
# capturas). Java la deriva de HOME, así que es ${HOME}/.formreturn. run.sh la lee
# de la imagen para montar aquí tu carpeta del host -> el Dockerfile es la fuente
# de verdad. Configurable con --build-arg FR_DATA_DIR=...
ARG FR_DATA_DIR=/home/${APP_USER}/.formreturn
ENV FR_DATA_DIR=${FR_DATA_DIR}
# Swing en blanco bajo XWayland: Java pide un visual ARGB de 32-bit que XWayland
# no pinta. Forzar visuals RGB (24-bit) lo resuelve. Aplica a Manager y Server.
ENV XLIB_SKIP_ARGB_VISUALS=1
WORKDIR ${FR_HOME}

ENTRYPOINT ["/entrypoint.sh"]
