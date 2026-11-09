#!/bin/sh
set -eu

if ! command -v zsh >/dev/null 2>&1; then
  echo "claude-account-switch requires Zsh." >&2
  exit 1
fi

source_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
install_dir="${XDG_DATA_HOME:-$HOME/.local/share}/claude-account-switch"
zshrc="${ZDOTDIR:-$HOME}/.zshrc"
source_line='source "${XDG_DATA_HOME:-$HOME/.local/share}/claude-account-switch/claude-account-switch.zsh"'

mkdir -p "$install_dir" "$(dirname -- "$zshrc")"
if [ "$source_dir/claude-account-switch.zsh" != "$install_dir/claude-account-switch.zsh" ]; then
  cp "$source_dir/claude-account-switch.zsh" "$install_dir/claude-account-switch.zsh"
fi
chmod 644 "$install_dir/claude-account-switch.zsh"
touch "$zshrc"

if ! grep -Fqx "$source_line" "$zshrc"; then
  printf '\n# claude-account-switch\n%s\n' "$source_line" >> "$zshrc"
fi

echo "Installed claude-account-switch."
echo "Restart Zsh or run: source \"$zshrc\""
