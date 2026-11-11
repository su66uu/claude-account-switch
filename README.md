# Claude Account Switch

A small, dependency-free Zsh utility for keeping multiple Claude Code accounts signed in at once. Each account gets an isolated [`CLAUDE_CONFIG_DIR`](https://code.claude.com/docs/en/authentication#log-in-with-multiple-accounts), so credentials, settings, plugins, and history stay separate.

## Requirements

- Zsh
- Claude Code installed and available as `claude`

## Install

Install with one command:

```sh
curl -fsSL https://raw.githubusercontent.com/su66uu/claude-account-switch/main/install.sh | sh
```

Then restart Zsh:

```sh
exec zsh
```

The installer downloads the plugin to `~/.local/share/claude-account-switch` and adds one `source` line to `~/.zshrc`. Re-run the same command to update it.

To inspect the code before installing, clone the repository and run `./install.sh` instead.

## Set up accounts

Add more accounts:

```sh
claude account add personal
claude account add company
```

The first time you launch a new account, Claude Code will ask you to sign in.

If an account already has a separate configuration directory, register it instead of creating a new one:

```sh
claude account add company "$HOME/.claude-company"
```

Give the account already stored in `~/.claude` a name without moving it:

```sh
claude account label-default client
```

## Use

```sh
claude account list          # List accounts; * marks the active one
claude account list --active # Print only the active account name
claude switch                # Choose interactively
claude switch personal       # Switch directly
claude                       # Start Claude Code with the active account
```

All normal Claude Code arguments continue to work:

```sh
claude --continue
claude --resume
```

Use the active account in scripts without parsing the formatted list:

```sh
active_account="$(claude account list --active)"
```

Switching affects new Claude Code processes only. Run `/status` inside Claude Code when you need to verify the active account or organization.

## Storage

- Account registry: `${XDG_CONFIG_HOME:-~/.config}/claude-account-switch`
- New account data: `${XDG_DATA_HOME:-~/.local/share}/claude-account-switch/profiles`
- Existing default account: `~/.claude` (unchanged)

The utility stores configuration paths and the active account name. It does not copy or inspect credentials.

## Test

```sh
zsh tests/smoke.zsh
```

## Uninstall

Remove the `claude-account-switch` source line from `~/.zshrc`, then remove the installed plugin. Account data is intentionally left in place:

```sh
rm "$HOME/.local/share/claude-account-switch/claude-account-switch.zsh"
```

This is an unofficial community project and is not affiliated with or endorsed by Anthropic.
