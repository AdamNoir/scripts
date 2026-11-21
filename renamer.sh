#!/bin/bash


VERDE="\e[32m"; AMARILLO="\e[33m"; ROJO="\e[31m"; RESET="\e[0m"
info()  { echo -e "${VERDE}[+]${RESET} $*"; }
aviso() { echo -e "${AMARILLO}[!]${RESET} $*"; }
error() { echo -e "${ROJO}[x]${RESET} $*" >&2; }


read -p "INGRESA UN PATH: " user_path

# -e comprueba si existe en el sistema
if [ ! -e $user_path ]; then
	error "RUTA NO EXISTE"
	exit 1
fi


# -d comprueba que si sea un directorio
if [ ! -d $user_path ]; then
	error "NO ES UN DIRECTORIO"
	exit 1
fi

contador=1
for file in $(ls $user_path) ; do
		info $file
		extension=${file##*.}
		new_name="jenna_${contador}.${extension}"
		mv "$file" "${new_name}"
		aviso $new_name
		((contador++))
done

echo $user_path
