#!/usr/bin/env bash

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

link() {
  local src="$DOTFILES_DIR/$1"
  local dest="$2"

  mkdir -p "$(dirname "$dest")"

  if [[ -e "$dest" && ! -L "$dest" ]]; then
    echo "  Backing up $dest → $dest.bak"
    mv "$dest" "$dest.bak"
  fi

  ln -sfn "$src" "$dest"
  echo "  Linked $dest"
}

inject_bashrc() {
  local bashrc="$HOME/.bashrc"
  local marker="# >>> dotfiles >>>"

  if ! grep -q "$marker" "$bashrc"; then
    cat >> "$bashrc" <<EOF

$marker
[ -f "\$HOME/.bash_aliases" ] && source "\$HOME/.bash_aliases"
# <<< dotfiles <<<
EOF
    echo "  Updated .bashrc"
  else
    echo "  .bashrc already configured, skipping"
  fi
}
