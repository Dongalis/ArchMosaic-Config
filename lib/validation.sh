#!/usr/bin/env bash

# System validation for installer

[[ -n "${VALIDATION_SH_LOADED:-}" ]] && return
readonly VALIDATION_SH_LOADED=1

validation_check_arch() {
    if [[ ! -f /etc/arch-release ]]; then
        echo "Error: This installer is designed for Arch Linux."
        exit 1
    fi
    echo "Arch Linux detected."
}

validation_check_system() {
    validation_check_arch
}
