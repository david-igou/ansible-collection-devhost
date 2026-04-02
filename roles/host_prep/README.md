# host_prep

User-level host preparation for VS Code/Cursor remote-server and devcontainer workflows.

Runs **without** `become` — all tasks operate in the user's home directory.

## What it does

- Creates bind-mount target directories (`~/.ssh`, `~/.kube`, `~/.config/cursor`, `~/workspace`, etc.)
- Seeds `~/.gitconfig` and `~/.claude.json` so bind-mounts have existing targets
- Configures git `user.name` / `user.email` (when set)
- Rewrites GitHub HTTPS URLs to SSH (`url.git@github.com:.insteadOf`)
- Creates 1Password config directory (when enabled)

## Role Variables

| Variable | Default | Description |
|---|---|---|
| `host_prep_git_user_name` | `""` | Git global `user.name` (skipped when empty) |
| `host_prep_git_user_email` | `""` | Git global `user.email` (skipped when empty) |
| `host_prep_git_github_ssh_rewrite` | `true` | Rewrite GitHub HTTPS to SSH URLs |
| `host_prep_directories` | *(see defaults)* | List of directories to create |

## Dependencies

None.
