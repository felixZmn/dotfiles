#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DOTFILES_DIR/lib/helpers.sh"

echo ""
echo "==> Git"
link git/.gitconfig           ~/.gitconfig
link git/.gitignore_global    ~/.gitignore_global

echo ""
echo "==> Git hooks"
link git/hooks               ~/.config/git/hooks

echo ""
echo "==> Vim"
link vim/.vimrc               ~/.vimrc

echo ""
echo "==> Bash scripts"
link bash/scripts            ~/.local/bin/dotscripts
link bash/aliases            ~/.bash_aliases

echo ""
echo "==> k9s"
link k9s/config.yaml ~/.config/k9s/config.yaml 
link k9s/skin.yaml ~/.config/k9s/skins/skin.yaml

inject_bashrc

echo "✅ Done! Restart your shell or run: source ~/.bashrc"