#!/usr/bin/env bash

# Installation of packages

[[ -n "${PACKAGES_SH_LOADED:-}" ]] && return
readonly PACKAGES_SH_LOADED=1

packages_install_bulk() {
    local profiles=("$@")
    local packages=()
    local pacman_list=()
    local aur_list=()

    for profile in "${profiles[@]}"; do
        local file="$SCRIPT_DIR/profiles/${profile}/packages.txt"

        if [[ ! -f "$file" ]]; then
            continue
        fi

        while IFS= read -r pkg || [[ -n "$pkg" ]]; do
            [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
            packages+=("$pkg")
        done < "$file"
    done
    
    for pkg in "${packages[@]}"; do
        if pacman -Si "$pkg" &>/dev/null; then
            pacman_list+=("$pkg")

        elif pacman -Sg "$pkg" &>/dev/null; then
            while read -r package; do
                pacman_list+=("$package")
            done < <(pacman -Sg "$pkg" | awk '{print $2}')

        else
            if $AUR_HELPER -Si "$pkg" &>/dev/null; then
                aur_list+=("$pkg")
            else
                echo "Warning: Package '$pkg' not found in pacman or AUR, skipping."
            fi
        fi
    done
    
    if [[ ${#pacman_list[@]} -ne 0 ]]; then
        echo "Installing packages with pacman: ${pacman_list[@]}"
        if ! sudo pacman -Suy --needed "${pacman_list[@]}"; then
            echo "Error: Failed to install pacman packages"
            exit 1
        fi
    else
        echo "No packages for pacman"
    fi

    if [[ ${#aur_list[@]} -ne 0 ]]; then
        echo "Installing packages with $AUR_HELPER: ${aur_list[@]}"
        if ! $AUR_HELPER -Suy --needed "${aur_list[@]}"; then
            echo "Error: Failed to install AUR packages"
            exit 1
        fi
    else
        echo "No packages for $AUR_HELPER"
    fi
}

flatpak_install_bulk() {
    local profiles=("$@")
    local flatpak_list=()

    for profile in "${profiles[@]}"; do
        local file="$SCRIPT_DIR/profiles/${profile}/flatpaks.txt"

        if [[ ! -f "$file" ]]; then
            continue
        fi

        while IFS= read -r pkg || [[ -n "$pkg" ]]; do
            [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
            if flatpak remote-info flathub "$pkg" &>/dev/null; then
                flatpak_list+=("$pkg")
            fi
        done < "$file"
    done
    
    if [[ ${#flatpak_list[@]} -eq 0 ]]; then
        echo "No packages for flatpak"
    else
        echo "Installing flatpaks: ${flatpak_list[@]}"
        if ! flatpak install -y ${flatpak_list[@]}; then
            echo "Error: Failed to install flatpak packages"
            exit 1
        fi
    fi
}
