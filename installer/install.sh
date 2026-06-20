#!/bin/bash

# install.sh - Cross-platform installer for Felix's dotfiles
# Usage: ./scripts/install.sh [OPTIONS]
# Options:
#   --ask-secrets    Prompt for git email and SSH key path
#   --force          Overwrite existing configs without backup
#   --bash           Force bash (default: auto-detect)

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${HOME}/.dotfiles-backup-$(date +%s)"
FORCE=false
ASK_SECRETS=false
SHELL_CHOICE=""

# ============================================================================
# Colors for output
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# Helper functions
# ============================================================================
log_info() {
    echo -e "${BLUE}ℹ${NC} $*"
}

log_success() {
    echo -e "${GREEN}✓${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*" >&2
}

backup_existing() {
    local target=$1
    if [[ -e "$target" ]]; then
        if [[ "$FORCE" == "true" ]]; then
            log_warn "Removing existing $target (force mode)"
            rm -rf "$target"
        else
            mkdir -p "$BACKUP_DIR"
            log_info "Backing up $target to $BACKUP_DIR/"
            cp -r "$target" "$BACKUP_DIR/$(basename "$target")"
        fi
    fi
}

symlink_file() {
    local src=$1
    local dst=$2

    backup_existing "$dst"
    mkdir -p "$(dirname "$dst")"
    ln -sf "$src" "$dst"
    log_success "Linked $dst -> $src"
}

# Append a dotfiles bootstrap snippet to the user's shell config without
# overwriting it. The snippet is sentinel-guarded, so re-running the
# installer is safe (idempotent). The user's existing aliases, PATH
# additions, distro defaults, etc. are preserved verbatim.
install_shell_bootstrap() {
    local dst=$1          # e.g. $HOME/.bashrc
    local snippet=$2      # e.g. $DOTFILES_DIR/shells/bash/.bashrc_dotfiles_snippet
    local sentinel="# >>> dotfiles bootstrap >>>"

    if [[ ! -f "$snippet" ]]; then
        log_error "Bootstrap snippet not found: $snippet"
        return 1
    fi

    mkdir -p "$(dirname "$dst")"
    touch "$dst"

    if grep -Fq "$sentinel" "$dst"; then
        log_info "Bootstrap already present in $dst (skipping)"
        return 0
    fi

    # Substitute __DOTFILES_DIR__ with the absolute dotfiles path so the
    # snippet works regardless of where the user cloned the repo.
    local rendered
    rendered=$(sed "s|__DOTFILES_DIR__|$DOTFILES_DIR|g" "$snippet")

    {
        echo ""
        echo "$rendered"
    } >> "$dst"

    log_success "Appended dotfiles bootstrap to $dst"
}
# ============================================================================
# Detect environment
# ============================================================================
detect_os() {
    case "$(uname -s)" in
        Linux*)  echo "Linux" ;;
        Darwin*) echo "macOS" ;;
        MSYS*|MINGW*|CYGWIN*) echo "Windows" ;;
        *) echo "Unknown" ;;
    esac
}

detect_shell() {
    if [[ "$SHELL_CHOICE" != "" ]]; then
        echo "$SHELL_CHOICE"
        return
    fi
    
    if [[ "$SHELL" == *"zsh"* ]]; then
        echo "zsh"
    elif [[ "$SHELL" == *"bash"* ]]; then
        echo "bash"
    else
        echo "bash" # default
    fi
}

# ============================================================================
# Parse arguments
# ============================================================================
while [[ $# -gt 0 ]]; do
    case $1 in
        --ask-secrets)
            ASK_SECRETS=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --zsh)
            SHELL_CHOICE="zsh"
            shift
            ;;
        --bash)
            SHELL_CHOICE="bash"
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# ============================================================================
# Main installation
# ============================================================================
main() {
    log_info "Starting dotfiles installation..."
    
    local os
    local shell
    os=$(detect_os)
    shell=$(detect_shell)
    
    log_info "Detected OS: $os"
    log_info "Detected shell: $shell"
    
    # Git configuration
    log_info "Installing git configuration..."
    symlink_file "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
    
    # Shell configuration
    log_info "Installing shell configuration..."
    case "$shell" in
        bash)
            install_shell_bootstrap "$HOME/.bashrc" \
                "$DOTFILES_DIR/shells/bash/.bashrc_dotfiles_snippet" || exit 1
            ;;
    esac
    
    # Vim configuration
    log_info "Installing vim configuration..."
    symlink_file "$DOTFILES_DIR/vim/.vimrc" "$HOME/.vimrc"
    
    # Git hooks
    log_info "Configuring git hooks..."
    git config --global core.hooksPath "$DOTFILES_DIR/git/hooks"
    log_success "Git hooks configured via core.hooksPath"
    
    # k9s configuration (if k9s is installed)
    if command -v k9s &> /dev/null; then
        log_info "Installing k9s skin..."
        mkdir -p "$HOME/.config/k9s/skins"
        symlink_file "$DOTFILES_DIR/tools/k9s/skin.yaml" "$HOME/.config/k9s/skins/catppuccin-custom.yaml"
    else
        log_warn "k9s not found, skipping k9s configuration"
    fi
    
    # Interactive prompt for secrets (optional)
    if [[ "$ASK_SECRETS" == "true" ]]; then
        log_info "Configuring git user settings..."
        
        read -p "Git user email (current: $(git config user.email || 'not set')): " -r email
        if [[ -n "$email" ]]; then
            git config --global user.email "$email"
            log_success "Git email set to: $email"
        fi
        
        read -p "SSH signing key path (current: $(git config user.signingKey || 'not set')): " -r signingKey
        if [[ -n "$signingKey" ]]; then
            git config --global user.signingKey "$signingKey"
            log_success "SSH signing key set to: $signingKey"
        fi
    fi
    
    echo
    log_success "Installation complete!"
    echo
    log_info "Summary:"
    echo "  - Git config: $HOME/.gitconfig"
    echo "  - Shell config: $HOME/.$([ "$shell" = "zsh" ] && echo "zshrc" || echo "bashrc") (bootstrap appended)"
    echo "  - Vim config: $HOME/.vimrc"
    echo "  - Git hooks: $DOTFILES_DIR/git/hooks"
    
    if [[ -d "$BACKUP_DIR" ]]; then
        echo "  - Backups: $BACKUP_DIR"
    fi
    
    echo
    log_info "Next steps:"
    echo "  1. Restart your shell or run: source \$HOME/.$([ "$shell" = "zsh" ] && echo "zshrc" || echo "bashrc")"
    echo "  2. Test git status in a repo: git status"
    echo "  3. (Optional) Configure git email: git config --global user.email 'your.email@example.com'"
    echo
    log_info "To uninstall the dotfiles layer, delete the block between"
    echo "  '# >>> dotfiles bootstrap >>>' and '# <<< dotfiles bootstrap <<<'"
    echo "  in your shell config."
}

main
