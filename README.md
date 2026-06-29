# FormReturn 1.7.5 en contenedor (Docker)

Reconocimiento óptico de marcas (OMR) corriendo en **OpenJDK 8** dentro de un
contenedor, sin tocar el OpenJDK 25 del sistema.

La imagen descarga el instalador oficial precompilado y extrae únicamente `lib/`
(la app + sus ~60 dependencias). No compila nada, así no depende de
`maven.formreturn.com`.

## Archivos

| Archivo        | Descripción                                                              |
|----------------|--------------------------------------------------------------------------|
| `Dockerfile`   | `eclipse-temurin:8-jdk` + libs X11 + extracción de `lib/` + usuario uid 1000 |
| `entrypoint.sh`| Arranca `java -jar lib/formreturn.jar`                                   |
| `run.sh`       | Wrapper del host: `xhost`/`DISPLAY`/volúmenes                            |

## Construir

```bash
docker build -t formreturn:1.7.5 .
# Si tu uid no es 1000:
docker build --build-arg APP_UID=$(id -u) --build-arg APP_GID=$(id -g) -t formreturn:1.7.5 .
```

## Ejecutar (GUI sobre XWayland)

```bash
./run.sh
```

Los datos (BD Derby, formularios, capturas) persisten en `~/.formreturn`
(como una instalación nativa) y son propiedad de tu usuario (no de root).

## Memoria

Por defecto `-Xmx1024m`. Para formularios/imágenes grandes:

```bash
JAVA_MEM=2048 ./run.sh
```

## Notas

- **SELinux (openSUSE)**: tu sistema tiene SELinux `enforcing` y Docker con
  `selinux-enabled`. `run.sh` usa `--security-opt label=disable` para que el
  contenedor pueda leer `/tmp/.X11-unix`. NO se usa `:z`/`:Z` en ese socket
  porque reetiquetaría el X del host y rompería tu sesión.
- **GUI**: vía X11 forwarding contra XWayland (`DISPLAY=:1`). `run.sh` ejecuta
  `xhost +SI:localuser:$(whoami)`. Revocar al cerrar: `xhost -SI:localuser:$(whoami)`.
- **Usuario/ownership**: el contenedor corre como `formreturn` con tu mismo UID
  (1000), así los archivos en `~/.formreturn` son tuyos. Revisa `id -u` si no es 1000.
- **Escáner**: FormReturn soporta SANE (`swingsane`). Para usarlo desde el
  contenedor haría falta `libsane` y mapear el dispositivo. No incluido por
  defecto; se puede escanear fuera e importar las imágenes.
- **Datos**: `run.sh` monta `$HOME/.formreturn` → `/home/formreturn/.formreturn`.
