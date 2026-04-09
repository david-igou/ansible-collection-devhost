# host_prep

User-level host preparation for VS Code/Cursor remote-server and devcontainer workflows.

Runs **without** `become` — all tasks operate in the user's home directory.

## What it does

- Creates bind-mount target directories (`~/.ssh`, `~/.kube`, `~/.config/cursor`, `~/workspace`, etc.)
- Seeds `~/.gitconfig` and `~/.claude.json` so bind-mounts have existing targets
- Configures git `user.name` / `user.email` (when set)
- Rewrites GitHub HTTPS URLs to SSH (`url.git@github.com:.insteadOf`)
- Creates 1Password config directory and writes service account token (when set)
- Writes `~/.ssh/config` and `~/.bashrc` from provided content (when set)
- Clones a devcontainer repository to the home directory
- Clones workspace repositories into `~/workspace/`

## Role Variables

| Variable | Default | Description |
|---|---|---|
| `host_prep_git_user_name` | `""` | Git global `user.name` (skipped when empty) |
| `host_prep_git_user_email` | `""` | Git global `user.email` (skipped when empty) |
| `host_prep_git_github_ssh_rewrite` | `true` | Rewrite GitHub HTTPS to SSH URLs |
| `host_prep_directories` | *(see defaults)* | List of directories to create |
| `host_prep_onepassword_service_account_token` | `""` | 1Password service account token (written to `~/.config/op/service-account-token`) |
| `host_prep_ssh_config` | `""` | Content for `~/.ssh/config` (skipped when empty) |
| `host_prep_bashrc` | `""` | Content for `~/.bashrc` (skipped when empty) |
| `host_prep_devcontainer_repository` | `"git@github.com:igou-io/igou-devenv.git"` | Repository to clone for the devcontainer |
| `host_prep_workspace_repositories` | *(see defaults)* | List of repositories to clone into `~/workspace/` |

## Dependencies

None.
