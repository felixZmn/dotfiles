#!/usr/bin/env sh
# =============================================================================
# kuse.sh - Manage multiple kubeconfig files safely
#
# INSTALL:
#   1. create configs directory and add kubeconfig files:
#      mkdir -p ~/.kube/configs
#   2. add this script to your shell config (e.g. ~/.bashrc or ~/.zshrc)
#
# CONFIGURE (optional):
#   export KUBE_CONFIGS_DIR="/custom/path"   # default: ~/.kube/configs
#
# USAGE:
#   kuse                  list configs (default)
#   kuse <name>           activate a config
#   kuse -l, --list       list all configs
#   kuse -c, --current    show active config + context
#   kuse -r, --reset      switch back to ~/.kube/config
#   kuse -h, --help       show this help
# =============================================================================

# -- Resolve config dir -------------------------------------------------------

_kube_resolve_dir() {
    if [ -n "$KUBE_CONFIGS_DIR" ]; then
        _KUBE_CONFIGS_DIR="$KUBE_CONFIGS_DIR"
    else
        _KUBE_CONFIGS_DIR="$HOME/.kube/configs"
    fi
}

_kube_resolve_dir

# -- Colours ------------------------------------------------------------------
# Disabled automatically when stdout is not a tty (e.g. piped).

_kube_setup_colors() {
    if [ -t 1 ]; then
        _KC_RED='\033[0;31m'
        _KC_GREEN='\033[0;32m'
        _KC_YELLOW='\033[0;33m'
        _KC_BLUE='\033[0;34m'
        _KC_CYAN='\033[0;36m'
        _KC_WHITE='\033[0;37m'
        _KC_RESET='\033[0m'
    else
        _KC_RED='' _KC_GREEN='' _KC_YELLOW='' _KC_BLUE=''
        _KC_CYAN='' _KC_WHITE='' _KC_RESET=''
    fi
}

_kube_setup_colors

# -- Low-level print helpers --------------------------------------------------

_kube_print() {
    # _kube_print <color> <message>  — prints with trailing newline
    printf "%b%s%b\n" "$1" "$2" "$_KC_RESET"
}

_kube_print_inline() {
    # _kube_print_inline <color> <message>  — no trailing newline
    printf "%b%s%b" "$1" "$2" "$_KC_RESET"
}

_kube_header() {
    _kube_print "$_KC_WHITE" "$1"
    _kube_print "$_KC_BLUE"  "--------------------------------------------"
}

# -- Shared helpers -----------------------------------------------------------

_kube_test_dir() {
    if [ ! -d "$_KUBE_CONFIGS_DIR" ]; then
        _kube_print "$_KC_RED"  "✗ Config dir not found: $_KUBE_CONFIGS_DIR"
        _kube_print "$_KC_CYAN" "  mkdir -p '$_KUBE_CONFIGS_DIR'"
        return 1
    fi
}

_kube_find_config() {
    # Sets _KUBE_FOUND_PATH on success, clears it on failure.
    _KUBE_FOUND_PATH=""
    _base="$_KUBE_CONFIGS_DIR/$1"
    for _candidate in "$_base" "$_base.yaml" "$_base.yml"; do
        if [ -f "$_candidate" ]; then
            _KUBE_FOUND_PATH="$_candidate"
            return 0
        fi
    done
    return 1
}

_kube_current_context() {
    # Sets _KUBE_CTX
    _KUBE_CTX=$(kubectl config current-context 2>/dev/null)
    : "${_KUBE_CTX:=(none)}"
}

_kube_all_contexts() {
    # Sets _KUBE_ALL_CTX as a comma-separated string
    _raw=$(kubectl config get-contexts -o name 2>/dev/null)
    if [ -z "$_raw" ]; then
        _KUBE_ALL_CTX="(none)"
        return
    fi
    _KUBE_ALL_CTX=$(printf "%s" "$_raw" | tr '\n' ',' | sed 's/,$//; s/,/, /g')
}

# -- Subcommand implementations -----------------------------------------------

_kuse_switch() {
    _kube_test_dir || return 1

    if ! _kube_find_config "$1"; then
        _kube_print "$_KC_RED"  "✗ Not found: '$1'"
        _kube_print "$_KC_CYAN" "  Run 'kuse --list' to see available configs."
        return 1
    fi

    export KUBECONFIG="$_KUBE_FOUND_PATH"

    _kube_current_context
    _kube_all_contexts

    _kube_print_inline "$_KC_GREEN" "✓ Active: "
    _kube_print        "$_KC_WHITE" "$(basename "$_KUBE_FOUND_PATH")"
    _kube_print        "$_KC_CYAN"  "  Context : $_KUBE_CTX"
    _kube_print        "$_KC_CYAN"  "  All ctx : $_KUBE_ALL_CTX"
}

_kuse_list() {
    _kube_test_dir || return 1

    _kube_header "Kubeconfig files"
    _kube_print "$_KC_CYAN" "  Dir: $_KUBE_CONFIGS_DIR"
    printf "\n"

    _file_count=0
    for _f in "$_KUBE_CONFIGS_DIR"/*; do
        [ -f "$_f" ] && _file_count=$(( _file_count + 1 ))
    done

    if [ "$_file_count" -eq 0 ]; then
        _kube_print "$_KC_YELLOW" "  No configs found."
        _kube_print "$_KC_CYAN"   "  Copy kubeconfig files to: $_KUBE_CONFIGS_DIR"
        return 0
    fi

    for _f in "$_KUBE_CONFIGS_DIR"/*; do
        [ -f "$_f" ] || continue
        _fname=$(basename "$_f")
        if [ "$_f" = "$KUBECONFIG" ]; then
            _kube_print_inline "$_KC_GREEN"  "  ▶  "
            _kube_print_inline "$_KC_WHITE"  "$_fname"
            _kube_print        "$_KC_YELLOW" "  ← active"
        else
            _kube_print_inline "$_KC_BLUE" "  ◦  "
            printf "%s\n" "$_fname"
        fi
    done
}

_kuse_current() {
    _kube_header "Active kubeconfig"

    _kc_file="${KUBECONFIG:-$HOME/.kube/config}"
    _kube_print "$_KC_CYAN" "  File   : $_kc_file"

    _ctx=$(kubectl config current-context 2>/dev/null)
    if [ -z "$_ctx" ]; then
        _kube_print "$_KC_RED" "  Context: (unavailable)"
        return 0
    fi

    _kube_print "$_KC_CYAN" "  Context: $_ctx"
    printf "\n"
    _kube_header "All contexts in this file"
    kubectl config get-contexts 2>/dev/null
}

_kuse_reset() {
    _default="$HOME/.kube/config"
    export KUBECONFIG="$_default"

    _kube_print "$_KC_YELLOW" "↩  Reset to: $_default"

    if [ ! -f "$_default" ]; then
        _kube_print "$_KC_YELLOW" "  ⚠  File does not exist"
        return 0
    fi

    _ctx=$(kubectl config current-context 2>/dev/null)
    [ -n "$_ctx" ] && _kube_print "$_KC_CYAN" "  Context: $_ctx"
}

_kuse_help() {
    _kube_header "kuse — kubernetes config switcher"

    # Columns: flag | description
    _entries="\
<name>              |activate a kubeconfig
-l, --list          |list all configs (default)
-c, --current       |show active config + context
-r, --reset         |switch back to ~/.kube/config
-h, --help          |show this help"

    printf "%s\n" "$_entries" | while IFS='|' read -r _cmd _desc; do
        _kube_print_inline "$_KC_CYAN" "  $_cmd"
        printf "%s\n" "$_desc"
    done

    printf "\n"
    _kube_print      "$_KC_BLUE" "  Config dir : $_KUBE_CONFIGS_DIR"
    _kube_print_inline "$_KC_BLUE" "  Override   : "
    printf "%s\n"    'export KUBE_CONFIGS_DIR="/your/path"'
}

# -- Main entry point ---------------------------------------------------------

kuse() {
    case "$1" in
        "")           _kuse_list
                      printf "\n"
                      _kube_print "$_KC_CYAN" "Tip: kuse <name> to switch  |  kuse --help for all options"
                      ;;
        -l|--list)    _kuse_list    ;;
        -c|--current) _kuse_current ;;
        -r|--reset)   _kuse_reset   ;;
        -h|--help)    _kuse_help    ;;
        -*)           _kube_print "$_KC_RED"  "✗ Unknown option: '$1'"
                      _kube_print "$_KC_CYAN" "  Run 'kuse --help' for usage."
                      return 1
                      ;;
        *)            _kuse_switch "$1" ;;
    esac
}

# -- Tab completion -----------------------------------------------------------

_KUSE_FLAGS="--list --current --reset --help -l -c -r -h"

# bash
if [ -n "$BASH_VERSION" ]; then
    _kuse_completions_bash() {
        local _cur="${COMP_WORDS[COMP_CWORD]}"
        local _candidates="$_KUSE_FLAGS"

        for _f in "$_KUBE_CONFIGS_DIR"/*; do
            [ -f "$_f" ] && _candidates="$_candidates $(basename "$_f")"
        done

        # shellcheck disable=SC2207
        COMPREPLY=( $(compgen -W "$_candidates" -- "$_cur") )
    }
    complete -F _kuse_completions_bash kuse
fi

# zsh
if [ -n "$ZSH_VERSION" ]; then
    _kuse_completions_zsh() {
        local -a _candidates
        local _f

        _candidates=( ${=_KUSE_FLAGS} )   # split the flag string into array elements

        for _f in "$_KUBE_CONFIGS_DIR"/*; do
            [ -f "$_f" ] && _candidates+=( "$(basename "$_f")" )
        done

        compadd -a _candidates
    }
    compdef _kuse_completions_zsh kuse
fi
