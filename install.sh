#!/bin/sh
set -eu

if ! command -v zsh >/dev/null 2>&1; then
  echo "claude-account-switch requires Zsh." >&2
  exit 1
fi

install_dir="${XDG_DATA_HOME:-$HOME/.local/share}/claude-account-switch"
zshrc="${ZDOTDIR:-$HOME}/.zshrc"
source_line='source "${XDG_DATA_HOME:-$HOME/.local/share}/claude-account-switch/claude-account-switch.zsh"'
plugin_url="${CLAUDE_ACCOUNT_SWITCH_PLUGIN_URL:-https://raw.githubusercontent.com/su66uu/claude-account-switch/main/claude-account-switch.zsh}"
plugin_source=""

case "$0" in
  install.sh|*/install.sh)
    source_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
    if [ -f "$source_dir/claude-account-switch.zsh" ]; then
      plugin_source="$source_dir/claude-account-switch.zsh"
    fi
    ;;
esac

mkdir -p "$install_dir" "$(dirname -- "$zshrc")"

if [ -n "$plugin_source" ]; then
  if [ "$plugin_source" != "$install_dir/claude-account-switch.zsh" ]; then
    cp "$plugin_source" "$install_dir/claude-account-switch.zsh"
  fi
else
  if ! command -v curl >/dev/null 2>&1; then
    echo "Streamed installation requires curl." >&2
    exit 1
  fi

  temporary_file="$install_dir/.claude-account-switch.zsh.$$"
  trap 'rm -f "$temporary_file"' EXIT HUP INT TERM
  curl -fsSL "$plugin_url" -o "$temporary_file"
  if [ ! -s "$temporary_file" ]; then
    echo "Downloaded plugin is empty." >&2
    exit 1
  fi
  mv "$temporary_file" "$install_dir/claude-account-switch.zsh"
  trap - EXIT HUP INT TERM
fi

chmod 644 "$install_dir/claude-account-switch.zsh"
touch "$zshrc"

if ! grep -Fqx "$source_line" "$zshrc"; then
  printf '\n# claude-account-switch\n%s\n' "$source_line" >> "$zshrc"
fi

echo "Installed claude-account-switch."
echo "Restart Zsh or run: source \"$zshrc\""
