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
        local file=("$SCRIPT_DIR/profiles/${profile}/packages.txt")

        if [[ ! -f "$file" ]]; then
            echo "Warning: File not found: $file"
            continue
        fi

        while IFS= read -r pkg || [[ -n "$pkg" ]]; do
            [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
            packages+=("$pkg")
        done < "$file"
    done
    
    for pkg in "${packages[@]}"; do
        if pacman -Si "$pkg" &>/dev/null; then
            pacmian_list+=("$pkg")
        else
            if $AUR_HELPER -Ss "^$pkg$" &>/dev/null; then
                aur_list+=("$pkg")
            else
                echo "Warning: Package '$pkg' not found in pacman or AUR, skipping."
            fi
        fi
    done
    
    if [[ ${#pacman_list[@]} -eq 0 ]]; then
        sudo pacman -Suy --needed "${pacman_list[@]}"
    else
        echo "no packages for pacman"
    fi

    if [[ ${#aur_list[@]} -eq 0 ]]; then
        $AUR_HELPER -Suy --needed "${aur_lust[@]}"
    else
        echo "no packages for $AUR_HELPER"
    fi
}

flatpak_install_bulk() {
    local profiles=("$@")
    local flatpak_list=()

    for profile in "${profiles[@]}"; do
        local file=("$SCRIPT_DIR/profiles/${profile}/packages.txt")

        if [[ ! -f "$file" ]]; then
            echo "Warning: File not found: $file"
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
        echo "no packages for flatpak"
    else
        flatpak install ${flatpak_list[@]}
    fi
}
