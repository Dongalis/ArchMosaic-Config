#!/usr/bin/env bash

# Running commands during installation

[[ -n "${COMMANDS_SH_LOADED:-}" ]] && return
readonly COMMANDS_SH_LOADED=1

execute_commands() {
    local files=("$@")

    for file in "${files[@]}"; do
        if [[ ! -f "$file" ]]; then
            echo "File not found: $file"
            continue
        fi

        echo "===== Executing: $file ====="
        bash "$file"

        # Stop immediately if a script fails
        if [[ $? -ne 0 ]]; then
            echo "Error while executing $file"
            return 1
        fi
    done    
}

commands_run_pre_install() {
    local profiles=("$@")
    local command_files=()

    for profile in "${profiles[@]}"; do
        command_files+=("$SCRIPT_DIR/profiles/${profile}/pre-install.sh")
    done
    
    execute_commands "${command_files[@]}"
}

commands_run_post_install() {
    local profiles=("$@")
    local command_files=()

    for profile in "${profiles[@]}"; do
        command_files+=("$SCRIPT_DIR/profiles/${profile}/post-install.sh")
    done
    
    execute_commands "${command_files[@]}"
}
