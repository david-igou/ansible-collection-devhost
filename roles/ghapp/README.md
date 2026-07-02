# ghapp

Runtime-minted, minimally scoped GitHub tokens from a GitHub App. Installs the
[ghapp CLI / credential helper](https://github.com/david-igou/hermes_github_app_plugin)
and configures one (or both) of its two modes:

- **Client / local-mint mode** — the target user's environment mints
  single-repo, permission-scoped installation tokens in-process. The git
  credential helper makes plain `git push` on HTTPS GitHub remotes work with a
  fresh ~1 h token per operation; nothing is stored. The App private key comes
  from a command resolved at mint time (e.g. `op read ...`), an existing PEM
  path, or inline content the role writes to a `0600` file.
- **Broker mode** — a hardened systemd service (`ghapp serve`) runs as a
  dedicated system user that owns the App key and serves policy-clamped tokens
  over a unix socket. Agent containers get the socket bind-mounted and set
  `GHAPP_BROKER_SOCKET`; they hold no key material, and requests outside the
  repository allowlist / permission ceiling are denied and audited to journald.

## Example: devcontainer host (local mint via 1Password)

```yaml
- role: david_igou.devhost.ghapp
  vars:
    ghapp_client_enabled: true
    ghapp_client_user: igou
    ghapp_client_id: "Iv23exampleclientid"
    ghapp_client_app_slug: igou-dev
    ghapp_client_installations:
      david-igou: "143866260"
      igou-io: "143866153"
    ghapp_client_private_key_cmd: op read op://claude/igou-dev-github-app/private_key
```

## Example: agent VM broker (key delivered from AAP, containers get the socket)

```yaml
- role: david_igou.devhost.ghapp
  vars:
    ghapp_broker_enabled: true
    ghapp_broker_socket_group: hermes
    ghapp_broker_client_id: "Iv23exampleclientid"
    ghapp_broker_app_slug: igou-hermes
    ghapp_broker_installations:
      igou-io: "143866709"
    ghapp_broker_private_key_content: "{{ hermes_github_app_private_key }}"  # no_log source
    ghapp_broker_policy:
      allowed_repos:
        - igou-io/igou-ansible
        - igou-io/igou-inventory
      max_permissions:
        contents: write
        pull_requests: write
        issues: write
      default_permissions:
        contents: read
```

Then mount `/run/ghbroker/ghbroker.sock` into the agent containers and set
`GHAPP_BROKER_SOCKET=/run/ghbroker/ghbroker.sock` in their environment.

See `meta/argument_specs.yml` for all variables.
