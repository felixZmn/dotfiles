#!/bin/bash

# detect-env.sh - Detect system environment (OS, shell, package manager)
# Usage: source detect-env.sh
# Provides: $OS_TYPE, $SHELL_TYPE, $PKG_MANAGER

export OS_TYPE=""
export SHELL_TYPE=""
export PKG_MANAGER=""

# ============================================================================
# Detect Operating System
# ============================================================================
detect_os_type() {
    case "$(uname -s)" in
        Linux*)
            if grep -qi ubuntu /etc/os-release 2>/dev/null; then
                echo "ubuntu"
            elif grep -qi debian /etc/os-release 2>/dev/null; then
                echo "debian"
            elif grep -qi fedora /etc/os-release 2>/dev/null; then
                echo "fedora"
            elif grep -qi arch /etc/os-release 2>/dev/null; then
                echo "arch"
            else
                echo "linux"
            fi
            ;;
        Darwin*)
            echo "macos"
            ;;
        MSYS*|MINGW*|CYGWIN*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# ============================================================================
# Detect Shell
# ============================================================================
detect_shell_type() {
    case "$SHELL" in
        *zsh)
            echo "zsh"
            ;;
        *bash)
            echo "bash"
            ;;
        *fish)
            echo "fish"
            ;;
        *ksh)
            echo "ksh"
            ;;
        *)
            echo "sh"
            ;;
    esac
}

# ============================================================================
# Detect Package Manager
# ============================================================================
detect_package_manager() {
    if command -v apt &> /dev/null; then
        echo "apt"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v brew &> /dev/null; then
        echo "brew"
    elif command -v yum &> /dev/null; then
        echo "yum"
    else
        echo "unknown"
    fi
}

# ============================================================================
# Export variables
# ============================================================================
export OS_TYPE=$(detect_os_type)
export SHELL_TYPE=$(detect_shell_type)
export PKG_MANAGER=$(detect_package_manager)
