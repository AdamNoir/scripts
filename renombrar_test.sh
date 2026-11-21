#!/usr/bin/bash
#
# renombrar.sh - Renombra los archivos de una carpeta con un patrón + número.
#
# Ejemplo:  ./renombrar.sh -p vacaciones -c 2 ~/Fotos
#           IMG_8841.jpg  ->  vacaciones_001.jpg
#           IMG_8842.jpg  ->  vacaciones_002.jpg

set -euo pipefail

# ---------- Utilidades ----------
error() {
    echo "Error: $1" >&2
    echo "Usa -h para ver la ayuda." >&2
    exit 1
}

uso() {
    cat <<EOF
Uso: $(basename "$0") -p PATRON [opciones] [RUTA]

Renombra los archivos de RUTA (o de la carpeta actual si no se indica)
usando PATRON y numerándolos desde 001.

Opciones:
  -p PATRON   Patrón base del nombre (obligatorio).
  -c CEROS    Ceros de relleno antes del número (default: 2 -> 001).
              Con 0 -> 1, 2, 3...   Con 3 -> 0001, 0002...
  -o ORDEN    Posición del número: "despues" (default) o "antes" del patrón.
                despues -> patron_001.ext
                antes   -> 001_patron.ext
  -s SEP      Separador entre patrón y número (default: "_"). Puede ser "".
  -t          Modo simulación: muestra los cambios sin renombrar nada.
  -h          Muestra esta ayuda.

Notas:
  - Solo se renombran archivos regulares; se ignoran subcarpetas y
    archivos ocultos (los que empiezan con punto).
  - Se conserva la extensión original de cada archivo.
  - Se ordenan de forma natural (archivo2 va antes que archivo10).
EOF
}

# ---------- Valores por defecto ----------
patron=""
ceros=2
orden="despues"
sep="_"
simular=0

# ---------- Lectura de opciones ----------
while getopts ":p:c:o:s:th" opt; do
    case "$opt" in
        p) patron=$OPTARG ;;
        c) ceros=$OPTARG ;;
        o) orden=$OPTARG ;;
        s) sep=$OPTARG ;;
        t) simular=1 ;;
        h) uso; exit 0 ;;
        :) error "La opción -$OPTARG requiere un valor." ;;
        \?) error "Opción inválida: -$OPTARG" ;;
    esac
done
shift $((OPTIND - 1))

# ---------- Validación de argumentos ----------
[[ -n "$patron" ]] || error "Falta el patrón (-p)."
[[ "$patron" != */* && "$sep" != */* ]] || error "El patrón y el separador no pueden contener '/'."
[[ "$ceros" =~ ^[0-9]+$ ]] || error "-c debe ser un número entero >= 0."
[[ "$orden" == "antes" || "$orden" == "despues" ]] || error "-o debe ser 'antes' o 'despues'."
(( $# <= 1 )) || error "Solo se acepta una ruta."

# ---------- Validación de la ruta (solo carpetas) ----------
ruta="${1:-.}"

[[ -e "$ruta" ]] || error "La ruta '$ruta' no existe."
[[ -d "$ruta" ]] || error "'$ruta' no es una carpeta."
[[ -r "$ruta" && -x "$ruta" ]] || error "No tienes permiso de lectura en '$ruta'."
[[ -w "$ruta" ]] || error "No tienes permiso de escritura en '$ruta'."

ruta="$(cd -- "$ruta" && pwd)"   # ruta absoluta y limpia

# ---------- Detección de carpeta vacía ----------
if [[ -z "$(find "$ruta" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
    echo "La carpeta '$ruta' está vacía. No hay nada que renombrar."
    exit 0
fi

# ---------- Lista de archivos (regulares, no ocultos, orden natural) ----------
mapfile -d '' archivos < <(
    find "$ruta" -maxdepth 1 -type f -not -name '.*' -print0 | sort -zV
)

if (( ${#archivos[@]} == 0 )); then
    echo "La carpeta '$ruta' no contiene archivos para renombrar (solo subcarpetas u ocultos)."
    exit 0
fi

# ---------- Cálculo de los nuevos nombres ----------
ancho=$((ceros + 1))
declare -A origenes=()
nuevos=()
bases=()

for ruta_archivo in "${archivos[@]}"; do
    origenes["$(basename "$ruta_archivo")"]=1
done

i=0
for ruta_archivo in "${archivos[@]}"; do
    i=$((i + 1))
    base="$(basename "$ruta_archivo")"

    ext=""
    [[ "$base" == *.* ]] && ext=".${base##*.}"

    printf -v num "%0*d" "$ancho" "$i"

    if [[ "$orden" == "despues" ]]; then
        nuevo="${patron}${sep}${num}${ext}"
    else
        nuevo="${num}${sep}${patron}${ext}"
    fi

    # Evita pisar un archivo existente que no forma parte de la lista
    if [[ -e "$ruta/$nuevo" && -z "${origenes[$nuevo]:-}" ]]; then
        error "'$nuevo' ya existe y no es parte de los archivos a renombrar. No se hizo ningún cambio."
    fi

    bases+=("$base")
    nuevos+=("$nuevo")
done

# ---------- Modo simulación ----------
if (( simular )); then
    echo "Simulación en: $ruta"
    for idx in "${!bases[@]}"; do
        printf '  %s  ->  %s\n' "${bases[$idx]}" "${nuevos[$idx]}"
    done
    echo "Total: ${#bases[@]} archivo(s). No se renombró nada."
    exit 0
fi

# ---------- Renombrado en dos fases (evita choques entre nombres) ----------
temporales=()
for idx in "${!bases[@]}"; do
    tmp=".renombrar_tmp_$$_${idx}"
    mv -- "$ruta/${bases[$idx]}" "$ruta/$tmp"
    temporales+=("$tmp")
done

for idx in "${!temporales[@]}"; do
    mv -- "$ruta/${temporales[$idx]}" "$ruta/${nuevos[$idx]}"
    printf '  %s  ->  %s\n' "${bases[$idx]}" "${nuevos[$idx]}"
done

echo "Listo: ${#nuevos[@]} archivo(s) renombrado(s) en $ruta"
