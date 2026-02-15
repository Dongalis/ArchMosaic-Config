#!/usr/bin/env bash

# Profile handling and dependency resolution

PROFILES_DIR="$SCRIPT_DIR/profiles"

RESOLVED_PROFILES=()
SEEN_PROFILES=()
STACK_PROFILES=()

_profile_array_contains() {
    local value="$1"
    shift
    for item in "$@"; do
        [[ "$item" == "$value" ]] && return 0
    done
    return 1
}

_profile_resolve_single() {
    local profile="$1"
    local profile_path="$PROFILES_DIR/$profile"
    
    if [[ -z "$profile" ]]; then
        return 0
    fi

    if [[ ! -d "$profile_path" ]]; then
        echo "Profile '$profile' does not exist."
        exit 1
    fi

    if _profile_array_contains "$profile" "${STACK_PROFILES[@]}"; then
        echo "Circular dependency detected involving profile '$profile'."
        exit 1
    fi

    if _profile_array_contains "$profile" "${SEEN_PROFILES[@]}"; then
        return 0
    fi

    STACK_PROFILES+=("$profile")

    local DEPENDS=()
    if [[ -f "$profile_path/profile.conf" ]]; then
        source "$profile_path/profile.conf"
    fi

    for dep in "${DEPENDS[@]:-}"; do
        _profile_resolve_single "$dep"
    done

    STACK_PROFILES=("${STACK_PROFILES[@]/$profile}")

    SEEN_PROFILES+=("$profile")
    RESOLVED_PROFILES+=("$profile")
}

# Public function
profile_resolve_dependencies() {

    if [[ "$#" -eq 0 ]]; then
        echo "No profiles specified."
        exit 1
    fi

    RESOLVED_PROFILES=()
    SEEN_PROFILES=()
    STACK_PROFILES=()

    for profile in "$@"; do
        _profile_resolve_single "$profile"
    done

    PROFILES=("${RESOLVED_PROFILES[@]}")

    echo "Resolved profile order:"
    for p in "${PROFILES[@]}"; do
        echo "  - $p"
    done
}
