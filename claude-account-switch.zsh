# Claude Account Switch: isolated Claude Code accounts via CLAUDE_CONFIG_DIR.

_claude_account_switch_valid_name() {
  case "$1" in
    ""|[!A-Za-z0-9]*|*[!A-Za-z0-9_-]*) return 1 ;;
  esac
}

_claude_account_switch_usage() {
  cat <<'EOF'
Usage:
  claude account label-default <name>
  claude account add <name> [existing-config-directory]
  claude account list
  claude switch [name]
EOF
}

claude() {
  emulate -L zsh

  local config_root="${XDG_CONFIG_HOME:-$HOME/.config}/claude-account-switch"
  local data_root="${XDG_DATA_HOME:-$HOME/.local/share}/claude-account-switch"
  local profiles_dir="$config_root/profiles"
  local active_file="$config_root/active"
  local command_name="$1"
  local subcommand="$2"
  local name="$3"
  local config_dir="$4"
  local profile_file mapping old_name active_name file
  local PS3="Select Claude account: "
  local -a account_names

  mkdir -p "$profiles_dir" "$data_root/profiles" || return 1
  chmod 700 "$config_root" "$profiles_dir" "$data_root" "$data_root/profiles" 2>/dev/null

  if [[ "$command_name" == "account" ]]; then
    case "$subcommand" in
      label-default)
        if ! _claude_account_switch_valid_name "$name"; then
          print -u2 "Account names may contain letters, numbers, hyphens and underscores."
          return 2
        fi

        profile_file="$profiles_dir/$name"
        if [[ -e "$profile_file" && "$(<"$profile_file")" != "@default" ]]; then
          print -u2 "Account '$name' already points to another configuration."
          return 2
        fi

        old_name=""
        for file in "$profiles_dir"/*(N.); do
          if [[ "$(<"$file")" == "@default" ]]; then
            old_name="${file:t}"
            break
          fi
        done

        if [[ -n "$old_name" && "$old_name" != "$name" ]]; then
          if [[ -e "$profile_file" ]]; then
            print -u2 "Account '$name' already exists."
            return 2
          fi
          mv "$profiles_dir/$old_name" "$profile_file" || return 1
        else
          print -r -- "@default" > "$profile_file"
        fi

        active_name=""
        [[ -r "$active_file" ]] && active_name="$(<"$active_file")"
        if [[ -z "$active_name" || "$active_name" == "$old_name" ]]; then
          print -r -- "$name" > "$active_file"
        fi

        print "Existing default Claude account labelled: $name"
        return
        ;;

      add)
        if ! _claude_account_switch_valid_name "$name"; then
          print -u2 "Account names may contain letters, numbers, hyphens and underscores."
          return 2
        fi

        profile_file="$profiles_dir/$name"
        if [[ -e "$profile_file" ]]; then
          print -u2 "Account '$name' already exists."
          return 2
        fi

        if [[ -n "$config_dir" ]]; then
          if [[ "$config_dir" != /* ]]; then
            print -u2 "The configuration directory must be an absolute path."
            return 2
          fi
          if [[ ! -d "$config_dir" ]]; then
            print -u2 "Configuration directory does not exist: $config_dir"
            return 2
          fi
          if [[ "$config_dir" == "$HOME/.claude" ]]; then
            print -u2 "Use 'claude account label-default $name' for ~/.claude."
            return 2
          fi
        else
          config_dir="$data_root/profiles/$name"
          mkdir -p "$config_dir" || return 1
          chmod 700 "$config_dir" 2>/dev/null
        fi

        print -r -- "$config_dir" > "$profile_file"
        print "Claude account added: $name"
        return
        ;;

      list)
        active_name=""
        [[ -r "$active_file" ]] && active_name="$(<"$active_file")"
        account_names=("$profiles_dir"/*(N.))

        if (( ${#account_names} == 0 )); then
          print "No Claude accounts registered."
          return
        fi

        for file in "${account_names[@]}"; do
          name="${file:t}"
          mapping="$(<"$file")"
          [[ "$mapping" == "@default" ]] && mapping="default ~/.claude"

          if [[ "$name" == "$active_name" ]]; then
            printf '* %-20s %s\n' "$name" "$mapping"
          else
            printf '  %-20s %s\n' "$name" "$mapping"
          fi
        done
        return
        ;;

      *)
        _claude_account_switch_usage >&2
        return 2
        ;;
    esac
  fi

  if [[ "$command_name" == "switch" ]]; then
    name="$2"

    if [[ -z "$name" ]]; then
      for file in "$profiles_dir"/*(N.); do
        account_names+=("${file:t}")
      done
      if (( ${#account_names} == 0 )); then
        print -u2 "No Claude accounts registered."
        return 2
      fi

      select name in "${account_names[@]}"; do
        [[ -n "$name" ]] && break
      done
      [[ -n "$name" ]] || return 1
    fi

    if [[ ! -f "$profiles_dir/$name" ]]; then
      print -u2 "Unknown Claude account: $name"
      print -u2 "Run 'claude account list' to see registered accounts."
      return 2
    fi

    print -r -- "$name" > "$active_file"
    print "Claude account switched to: $name"
    return
  fi

  if [[ ! -r "$active_file" ]]; then
    (
      unset CLAUDE_CONFIG_DIR
      command claude "$@"
    )
    return $?
  fi

  name="$(<"$active_file")"
  profile_file="$profiles_dir/$name"
  if [[ ! -r "$profile_file" ]]; then
    print -u2 "Active Claude account no longer exists: $name"
    print -u2 "Run 'claude switch' to select another account."
    return 2
  fi

  mapping="$(<"$profile_file")"
  if [[ "$mapping" == "@default" ]]; then
    (
      unset CLAUDE_CONFIG_DIR
      command claude "$@"
    )
    return $?
  fi

  if [[ "$mapping" != /* || ! -d "$mapping" ]]; then
    print -u2 "Invalid configuration for Claude account '$name': $mapping"
    return 2
  fi

  CLAUDE_CONFIG_DIR="$mapping" command claude "$@"
}
