#!/usr/bin/env bash

# Deploying configuration files

[[ -n "${FILES_SH_LOADED:-}" ]] && return
readonly FILES_SH_LOADED=1

declare -Ag meta_root=()
declare -Ag meta_home=()

check_manifest_conflicts() {
    local type="$1" # "root" or "home"
    local -n meta_ref="$2"
    local has_conflict=0

    for profile in "${profiles[@]}"; do
        local manifest="$SCRIPT_DIR/profiles/${profile}/${type}.manifest"

        [[ -f "$manifest" ]] || continue

        while IFS=' ' read -r path mode user group; do
            [[ -z "$path" || "$path" =~ ^# ]] && continue

            if [[ "$type" == "home" ]]; then
                path="${path#/}"
            fi

            if [[ -n "${meta_ref[$path]:-}" ]]; then
                echo "[ERROR] Duplicate ${type} file detected:"
                echo "  Path: $path"
                echo "  Profiles: ${seen_ref[$path]} and $profile"
                exit 1
            else
                echo "$path"
                meta_ref["$path"]="$profile $mode $user $group"
            fi
        done < "$manifest"
    done
}

verify_files_against_metadata() {
    local type="$1"       # root or home
    local -n meta_ref="$2"  # meta_root or meta_home
    local missing=0

    # Loop over all profiles
    for profile_dir in "$SCRIPT_DIR/profiles/"*/; do
        # Extract profile name from path
        local profile="${profile_dir##*/}"
        profile="${profile%/}"  # remove trailing slash

        local base_dir="$profile_dir/$type"
        [[ -d "$base_dir" ]] || continue

        # Find all regular files
        while IFS=' ' read -r -d '' file; do
            # Path relative to base_dir
            local rel_path="${file#$base_dir/}"

            # Normalize key for manifest lookup
            local key
            if [[ "$type" == "home" ]]; then
                key="$rel_path"
            else
                key="/$rel_path"
            fi
            echo "$key"
            # Check if the file is in the manifest metadata
            if [[ -z "${meta_ref[$key]:-}" ]]; then
                echo "[ERROR] File exists but missing from manifest:"
                echo "  Profile: $profile"
                echo "  Path: $key"
                missing=1
            fi
        done < <(find "$base_dir" -type f -print0)
    done

    return $missing
}

verify_metadata_files_exist() {
    local type="$1"         # root or home
    local -n meta_ref="$2"  # meta_root or meta_home
    local missing=0

    for path in "${!meta_ref[@]}"; do
        # Extract profile name and metadata
        # Stored as: "profile mode user group"
        IFS=' ' read -r profile mode user group <<< "${meta_ref[$path]}"

        # Determine the expected file location
        local base_dir="$SCRIPT_DIR/profiles/$profile/$type"
        local file_path
        if [[ "$type" == "home" ]]; then
            file_path="$base_dir/$path"
        else
            # For root, remove leading slash from manifest path
            file_path="$base_dir/${path#/}"
        fi

        if [[ ! -f "$file_path" ]]; then
            echo "[ERROR] Metadata entry has no corresponding file:"
            echo "  Profile: $profile"
            echo "  Path: $path"
            missing=1
        fi
    done

    return $missing
}

deploy_root_files() {
    local -n meta_ref="$1"   # meta_root

    for path in "${!meta_ref[@]}"; do
        # Extract profile, mode, user, group
        IFS=' ' read -r profile mode user group <<< "${meta_ref[$path]}"

        # Source file in repo
        local src_file="$SCRIPT_DIR/profiles/$profile/root/${path#/}"
        # Destination on system
        local dest_file="$path"

        # Ensure parent directory exists
        sudo mkdir -p "$(dirname "$dest_file")"

        # Copy file (overwrite)
        sudo cp "$src_file" "$dest_file"

        # Apply permissions
        sudo chmod "$mode" "$dest_file"

        # Apply ownership if user and group exist
        if id "$user" &>/dev/null && getent group "$group" &>/dev/null; then
            sudo chown "$user:$group" "$dest_file"
        else
            echo "[WARN] Skipping chown for $dest_file (user/group missing: $user:$group)"
        fi
    done
}

deploy_home_files() {
    local -n meta_ref="$1"    # meta_home
    local target_user="$2"
    local target_home="/home/$target_user"

    if ! id "$target_user" &>/dev/null; then
        echo "[ERROR] Target user $target_user does not exist. Skipping home deployment."
        return 1
    fi

    for path in "${!meta_ref[@]}"; do
        # Extract profile, mode, user, group
        IFS=' ' read -r profile mode user group <<< "${meta_ref[$path]}"

        # Replace {USER} placeholders
        path="${path//\{USER\}/$target_user}"
        user="${user//\{USER\}/$target_user}"
        group="${group//\{USER\}/$target_user}"

        # Source file in repo
        local src_file="$SCRIPT_DIR/profiles/$profile/home/$path"
        # Destination file
        local dest_file="$target_home/$path"

        # Ensure parent directory exists
        mkdir -p "$(dirname "$dest_file")"

        # Copy file
        cp "$src_file" "$dest_file"

        # Apply permissions
        chmod "$mode" "$dest_file"

        # Apply ownership if user/group exist
        if id "$user" &>/dev/null && getent group "$group" &>/dev/null; then
            chown "$user:$group" "$dest_file"
        else
            echo "[WARN] Skipping chown for $dest_file (user/group missing: $user:$group)"
        fi
    done
}

files_deploy() {
    local profiles=("$@")

    echo "Checking root manifest conflicts..."
    check_manifest_conflicts root meta_root || {
        echo "Root manifest conflicts detected. Aborting."
        exit 1
    }

    echo "Checking home manifest conflicts..."
    check_manifest_conflicts home meta_home || {
        echo "Home manifest conflicts detected. Aborting."
        exit 1
    }
    
    verify_files_against_metadata root meta_root || exit 1
    verify_files_against_metadata home meta_home || exit 1
    
    verify_metadata_files_exist root meta_root || exit 1
    verify_metadata_files_exist home meta_home || exit 1

    deploy_root_files meta_root
    TARGET_USER="$USER"
    deploy_home_files meta_home "$TARGET_USER"
}


