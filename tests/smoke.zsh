#!/usr/bin/env zsh
set -eu

repo_root="${0:A:h:h}"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/claude-account-switch.XXXXXX")"
trap 'rm -rf "$test_root"' EXIT

export HOME="$test_root/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export ZDOTDIR="$HOME"
export PATH="$test_root/bin:$PATH"

mkdir -p "$HOME" "$test_root/bin"

cat > "$test_root/bin/claude" <<'EOF'
#!/bin/sh
printf 'config=%s args=%s\n' "${CLAUDE_CONFIG_DIR-unset}" "$*"
EOF
chmod +x "$test_root/bin/claude"

source "$repo_root/claude-account-switch.zsh"

if claude account list --active >/dev/null 2>&1; then
  print -u2 "Active account unexpectedly exists before setup."
  exit 1
fi

claude account label-default client >/dev/null
claude account add personal >/dev/null
claude switch personal >/dev/null
[[ "$(claude account list --active)" == "personal" ]]

expected_config="$XDG_DATA_HOME/claude-account-switch/profiles/personal"
[[ "$(claude --version)" == "config=$expected_config args=--version" ]]

project_root="$test_root/projects/client-app"
project_nested="$project_root/packages/web"
mkdir -p "$project_nested" "$project_root/.git"
project_root="${project_root:A}"

(
  cd "$project_nested"
  claude switch client --project >/dev/null
  [[ "$(claude account list --active)" == "client" ]]
  [[ "$(claude --version)" == "config=unset args=--version" ]]
)

[[ "$(claude account list --active)" == "personal" ]]
[[ -f "$XDG_CONFIG_HOME/claude-account-switch/projects/${project_root#/}/account" ]]

(
  cd "$project_root"
  [[ "$(claude account list --active)" == "client" ]]
)

claude switch client >/dev/null
[[ "$(claude --version)" == "config=unset args=--version" ]]

claude account label-default client-renamed >/dev/null
[[ "$(claude account list)" == *"client-renamed"* ]]
[[ "$(claude account list --active)" == "client-renamed" ]]
(
  cd "$project_root"
  [[ "$(claude account list --active)" == "client-renamed" ]]
)

non_git_project="$test_root/projects/notes"
mkdir -p "$non_git_project"
(
  cd "$non_git_project"
  claude switch personal --project >/dev/null
  [[ "$(claude account list --active)" == "personal" ]]
  [[ "$(claude --version)" == "config=$expected_config args=--version" ]]
)

mkdir -p "$test_root/existing-config"
claude account add work "$test_root/existing-config" >/dev/null
claude switch work >/dev/null
[[ "$(claude test)" == "config=$test_root/existing-config args=test" ]]

if claude account add '../invalid' >/dev/null 2>&1; then
  print -u2 "Invalid account name was accepted."
  exit 1
fi

"$repo_root/install.sh" >/dev/null
"$repo_root/install.sh" >/dev/null
grep -Fq 'claude-account-switch.zsh' "$HOME/.zshrc"
[[ "$(grep -Fc 'source "${XDG_DATA_HOME:-$HOME/.local/share}/claude-account-switch/claude-account-switch.zsh"' "$HOME/.zshrc")" == "1" ]]
[[ -f "$XDG_DATA_HOME/claude-account-switch/claude-account-switch.zsh" ]]

rm "$XDG_DATA_HOME/claude-account-switch/claude-account-switch.zsh"
CLAUDE_ACCOUNT_SWITCH_PLUGIN_URL="file://$repo_root/claude-account-switch.zsh" \
  sh -s < "$repo_root/install.sh" >/dev/null
[[ -f "$XDG_DATA_HOME/claude-account-switch/claude-account-switch.zsh" ]]

print "Smoke test passed."
