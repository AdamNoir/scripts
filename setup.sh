#!/bin/bash

set -euo pipefail

GREEN="\e[32m"; YELLOW="\e[33m"; RED="\e[31m"; RESET="\e[0m"
info()  { echo -e "${GREEN}[+]${RESET} $*"; }
notice() { echo -e "${YELLOW}[!]${RESET} $*"; }
error() { echo -e "${RED}[x]${RESET} $*" >&2; }

detect_os() {
    if [[ -r /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        case "${ID:-}" in
            arch|cachyos|endeavouros|manjaro) echo "arch" ;;
            debian|ubuntu|pop|linuxmint)      echo "debian" ;;
            *)
                if [[ "${ID_LIKE:-}" == *"debian"* ]]; then
                    echo "debian"
                elif [[ "${ID_LIKE:-}" == *"arch"* ]]; then
                    echo "arch"
                else
                    echo "unknown"
                fi
                ;;
        esac
    else
        echo "unknown"
    fi
}


update_system(){
        info "UPDATING SYSTEM..."

        case $os in
        "Debian")
	        sudo apt update && sudo apt upgrade
                ;;
        "Arch")
                sudo pacman -Syu
                ;;
        esac
	info "SYSTEM UPDATED!" 
}


update_system() {
    local os="$1"
    info "Updating system..."
    case "$os" in
        debian)
            sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
            ;;
        arch)
            sudo pacman -Syu --noconfirm
            ;;
    esac
    info "System updated!"
}


install_debian() {
    info "Installing Debian packages..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${PACKAGE_LIST[@]}"
}



keep_sudo_alive() {
    sudo -v
    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" || exit
    done 2>/dev/null &
}





local os
os="$(detect_os)"

package_list=( $(cat apps.txt) )
echo "Los paquets a instalar son: $package_list[@]"

if ((${#PACKAGE_LIST[@]} == 0)); then
        notice "No packages found in $PKG_FILE. Nothing to install."
        exit 0
    fi

info "Packages to install (${#PACKAGE_LIST[@]}): ${PACKAGE_LIST[*]}"
keep_sudo_alive
update_system "$os"

if [ $os = "Arch" ]; then
        install_arch package_list
elif [ $os = "debian" ]; then
        #install_debian package_list
        echo "debian lionux o yea baby"
else
        error "ERROR"
        exit 1
fi




info "=== DONE! ==="
