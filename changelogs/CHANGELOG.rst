=================================
david\_igou.devhost Release Notes
=================================

.. contents:: Topics

v28.0.0
=======

Release Summary
---------------

This major release of the ``david_igou.devhost`` collection changes how the ``host_prep`` role manages git configuration. The role no longer deletes ``~/.gitconfig`` and the GitHub HTTPS-to-SSH URL rewrite (along with its ``host_prep_git_github_ssh_rewrite`` variable) has been removed; git identity is now configured idempotently via ``community.general.git_config``. The release also carries a bugfix for the ``ghapp`` broker virtualenv permissions on hardened hosts.

Breaking Changes / Porting Guide
--------------------------------

- host_prep role - The ``host_prep_git_github_ssh_rewrite`` variable and the GitHub HTTPS-to-SSH URL rewrite (``url.git@github.com:.insteadOf``) it configured have been removed. The role no longer deletes ``~/.gitconfig`` before configuring git; it now only seeds the file and sets ``user.name`` / ``user.email`` idempotently via ``community.general.git_config`` (https://github.com/david-igou/ansible-collection-devhost/pull/38).

Bugfixes
--------

- ghapp role - Make the ``/opt/ghapp`` broker virtualenv readable and traversable by the non-root service user. ``python3 -m venv`` honors the login umask, so on a hardened host (``umask 0077``) the venv was created ``0700 root`` and the ``ghbroker`` service died with ``203/EXEC`` permission denied; a recursive ``u=rwX,go=rX`` mode fix is now applied after venv creation (https://github.com/david-igou/ansible-collection-devhost/commit/cbfb70749fc712656654ff033e7ae90ef64edc8d).

v27.1.2
=======

Minor Changes
-------------

- ghapp broker — optional SELinux confinement (``ghapp_broker_selinux_confine``, default true). On SELinux-enabled hosts the role builds and loads a policy module running the broker in a dedicated ``ghbroker_t`` domain with a dedicated socket type, so a confined agent container may connect to the broker socket via a narrowly scoped ``connectto``/``sock_file`` grant instead of disabling the container label or granting connect to a broad host type. Validated enforcing on CentOS Stream 10 via the igou-ansible kubevirt e2e.

v27.1.1
=======

Bugfixes
--------

- ghapp broker unit — add ``SupplementaryGroups={{ ghapp_broker_group }}``: ``Group=`` (the socket-access group) replaces the primary gid, which cost the broker its group-read on the config/policy files and crash-looped the service whenever the socket group differed from the broker group (the Hermes wiring). Found live in the kubevirt e2e scenario.

v27.1.0
=======

Minor Changes
-------------

- New ``ghapp`` role — installs the ghapp CLI / git credential helper (runtime-minted, single-repo, permission-scoped GitHub App tokens) into a dedicated virtualenv, and optionally configures either local-mint client mode (per-user config + gitconfig credential helper) or a hardened systemd token-broker service that owns the App private key as a dedicated system user and serves policy-clamped tokens over a unix socket for containerized agents.

v27.0.0
=======

Major Changes
-------------

- The ``docker`` role now manages the full Docker CE lifecycle including repository setup, CLI installation, compose plugin, daemon, and rootless mode. It no longer depends on the ``packages`` role (https://github.com/david-igou/ansible-collection-devhost/issues/22).
- The ``podman`` role now installs its own packages (podman, buildah, skopeo, fuse-overlayfs, slirp4netns, uidmap/shadow-utils, catatonit) and no longer depends on the ``packages`` role (https://github.com/david-igou/ansible-collection-devhost/issues/22).

Minor Changes
-------------

- packages role - Add 13 binary CLI tool downloads: argocd, flux, kubeseal, tkn, terraform, sops, oc, kubeconform, kube-burner, kube-burner-ocp, act, mc, and rclone. Each tool is gated behind a ``packages_install_*`` flag and version-pinned in ``defaults/main.yml`` (https://github.com/david-igou/ansible-collection-devhost/issues/7).
- packages role - CLI tools (kubectl, helm, kustomize, virtctl, argocd, flux, kubeseal, tkn, terraform, sops, oc, kubeconform, kube-burner, kube-burner-ocp, act, rclone, and Node.js) are now installed and version-pinned via ``mise`` instead of per-tool ``get_url``/``unarchive`` tasks. The tool set (``mise.toml`` + the committed ``mise.lock`` + the GPG postinstall hooks) is fetched from the igou-devenv repo (``packages_mise_source_repo`` / ``packages_mise_source_ref``, pinned to an immutable commit SHA) as the single source of truth, so versions are maintained in one place. mise itself is installed from a GPG-pinned tarball and the tool binaries are symlinked into /usr/local/bin. Distro-agnostic (the same binaries on Debian and RedHat) (https://github.com/david-igou/ansible-collection-devhost/issues/24).

Breaking Changes / Porting Guide
--------------------------------

- Podman and Docker CE package installation moved out of the ``packages`` role into the ``podman`` and ``docker`` roles respectively. The following variables have been renamed: ``packages_install_podman_docker`` → ``podman_docker_compat``, ``packages_install_docker_cli`` → ``docker_install_cli``, ``packages_install_docker_compose_plugin`` → ``docker_install_compose_plugin`` (https://github.com/david-igou/ansible-collection-devhost/issues/22).
- packages role - The 17 per-tool ``packages_install_*`` flags and ``packages_*_version`` vars (and ``packages_install_nodejs_pinned`` / ``packages_nodejs_version``) are removed; CLI tools are now gated by the single ``packages_install_cli_tools`` flag and versioned via the fetched igou-devenv ``mise.toml``. A ``GITHUB_TOKEN`` (via ``packages_github_token`` or the environment) is recommended for ``mise install`` to avoid GitHub API rate limits.
- packages role - When ``packages_install_cli_tools`` is enabled, the GitHub CLI (``gh``) is now provided by mise, so the distro ``gh`` package is no longer installed even when ``packages_install_github_cli`` is true. The distro ``gh`` is only installed as a fallback when the mise tool set is disabled.
