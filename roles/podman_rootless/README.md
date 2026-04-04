# podman_rootless

Kernel tuning, user namespace setup, and rootless Podman configuration for container workloads.

## What it does

- Tunes `user.max_user_namespaces` and `net.ipv4.ip_unprivileged_port_start` via sysctl
- Configures subuid/subgid ranges for the target user
- Enables `loginctl` lingering so user systemd services persist across sessions
- Deploys user-level `~/.config/containers/containers.conf` (events logger, etc.)
- Optionally deploys user-level `~/.config/containers/storage.conf` (driver, fuse-overlayfs)
- Enables the podman user-scope socket (`podman.socket`)
- Optionally symlinks `/var/run/docker.sock` to the podman socket
- Warns if the storage driver is not `overlay`

## Role Variables

| Variable | Default | Description |
|---|---|---|
| `podman_rootless_subuid_start` | `100000` | Starting subuid/subgid value |
| `podman_rootless_subuid_count` | `65536` | Number of subordinate UIDs/GIDs |
| `podman_rootless_user_namespaces_max` | `28633` | `user.max_user_namespaces` sysctl value |
| `podman_rootless_unprivileged_port_start` | `0` | `net.ipv4.ip_unprivileged_port_start` sysctl value |
| `podman_rootless_socket_symlink` | `true` | Create `/var/run/docker.sock` symlink |
| `podman_rootless_enable_linger` | `true` | Enable `loginctl` lingering for the user |
| `podman_rootless_configure_containers_conf` | `true` | Deploy user-level `containers.conf` |
| `podman_rootless_events_logger` | `"file"` | Podman events logger backend (`file`, `journald`, `none`) |
| `podman_rootless_configure_storage_conf` | `false` | Deploy user-level `storage.conf` |
| `podman_rootless_storage_driver` | `"overlay"` | Podman storage driver |
| `podman_rootless_storage_mount_program` | `"/usr/bin/fuse-overlayfs"` | Path to fuse-overlayfs (empty string for native overlay) |

## Dependencies

- `david_igou.devhost.packages`
