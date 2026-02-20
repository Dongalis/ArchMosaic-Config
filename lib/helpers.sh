#!/usr/bin/env bash

# AUR helper management for installer

[[ -n "${HELPERS_SH_LOADED:-}" ]] && return
readonly HELPERS_SH_LOADED=1

helpers_detect_aur_helper() {
    if [[ -n "${AUR_HELPER:-}" ]]; then
        if command -v "$AUR_HELPER" &>/dev/null; then
            return 0
        else
            echo "Configured AUR helper '$AUR_HELPER' not found in PATH."
            exit 1
        fi
    fi
    
    if command -v paru &>/dev/null; then
        echo "Detected AUR helper: paru"
        AUR_HELPER="paru"
        return 0
    fi

    if command -v yay &>/dev/null; then
        echo "Detected AUR helper: yay"
        AUR_HELPER="yay"
        return 0
    fi

    echo "No AUR helper detected."

    if [[ "${AUTO_MODE:-false}" == true ]]; then
        echo "Auto mode enabled and no AUR helper installed."
        echo "Please install yay or paru manually."
        exit 1
    fi

    while true; do
        echo ""
        echo "Select AUR helper to use:"
        echo "  1) paru"
        echo "  2) yay"
        read -rp "Enter choice [1-2]: " choice

        case "$choice" in
            1)
                AUR_HELPER="paru"
                break
                ;;
            2)
                AUR_HELPER="yay"
                break
                ;;
            *)
                echo "Invalid selection. Please choose 1 or 2."
                ;;
        esac
    done
}

helpers_install_chaotic_aur() {
    if pacman -Sl chaotic-aur &>/dev/null; then
        echo "CHaotic Aur already configured"
        return 0
    fi
    
    sudo pacman-key --init 
    sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign-key 3056513887B78AEB
    sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
    sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
    echo -e "\r\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf >/dev/null
    sudo pacman -Syu
}

helpers_install_aur_helper() {
    if command -v "$AUR_HELPER" &>/dev/null; then
        echo "Aur helper already installed"
        return 0
    fi
    
    if pacman -Sl chaotic-aur &>/dev/null; then
        echo "installiong aur helper usig chaotic AUR"
        sudo pacman -Syu --needed "$AUR_HELPER"
        return 0
    fi

    sudo pacman -Syu --needed git
    git clone "https://aur.archlinux.org/${AUR_HELPER}.git" "$HOME/${AUR_HELPER}"
    cd "$HOME/${AUR_HELPER}"
    makepkg -si
    cd "$HOME"
    rm -rf "$HOME/${AUR_HELPER}"
}

helpers_install_flatpak() {
    if command -v flatpak &>/dev/null; then
        echo "flatpak already installed"
        return 0
    fi
    sudo pacman -Syu --needed flatpak
}

helpers_packaging_setup() {
    helpers_install_chaotic_aur
    helpers_install_aur_helper
    helpers_install_flatpak
}
