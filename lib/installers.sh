#!/usr/bin/env bash

# AUR helper management for installer

installers_detect_aur_helper() {
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
                helper="paru"
                break
                ;;
            2)
                helper="yay"
                break
                ;;
            *)
                echo "Invalid selection. Please choose 1 or 2."
                ;;
        esac
    done
}
