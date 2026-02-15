#!/usr/bin/env bash

# Main installer handler

set -euo pipefail
IFS=$'\n\t'

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
CONFIG_FILE="$SCRIPT_DIR/installer.conf"
AUTO_MODE=false
INTERACTIVE_MODE=false
PROFILES=()

# Placeholder variable for AUR helper
AUR_HELPER=""

# Load Libraries
#source "$SCRIPT_DIR/lib/utils.sh"
#source "$SCRIPT_DIR/lib/commands.sh"
source "$SCRIPT_DIR/lib/validation.sh"
source "$SCRIPT_DIR/lib/profile.sh"
#source "$SCRIPT_DIR/lib/packages.sh"
source "$SCRIPT_DIR/lib/installers.sh"
#source "$SCRIPT_DIR/lib/files.sh"

# Functions
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        echo "Loaded configuration from $CONFIG_FILE"
    else
        echo "No local config found, proceeding with defaults."
    fi
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --auto)
                AUTO_MODE=true
                shift
                ;;
            --interactive)
                INTERACTIVE_MODE=true
                shift
                ;;
            -*)
                echo "Unknown option: $1"
                exit 1
                ;;
            *)
                PROFILES+=("$1")
                shift
                ;;
        esac
    done
}

validate_system() {
    validation_check_system
}

detect_aur_helper() {
    installers_detect_aur_helper
    echo "Using AUR helper: $AUR_HELPER"
}

resolve_profiles() {
    profile_resolve_dependencies "${PROFILES[@]}"
}

run_pre_install() {
    commands_run_pre_install "${PROFILES[@]}"
}

setup_core_packages() {
    core_packaging_setup
}

install_packages() {
    packages_install_bulk "${PROFILES[@]}"
}

install_flatpaks() {
    flatpak_install_bulk "${PROFILES[@]}"
}

deploy_files() {
    files_deploy "${PROFILES[@]}"
}

run_post_install() {
    commands_run_post_install "${PROFILES[@]}"
}

cleanup() {
    echo cleanup
}

# ------------------------------------------------------------------------------
#  Main Execution Pipeline
# ------------------------------------------------------------------------------
main() {
    load_config
    parse_args "$@"

    validate_system
    detect_aur_helper
    resolve_profiles
    setup_core_packages
    run_pre_install
    install_packages
    install_flatpaks
    deploy_files
    run_post_install
    cleanup

    echo "Installation completed successfully!"
}

# ------------------------------------------------------------------------------
#  Execute main
# ------------------------------------------------------------------------------
main "$@"
