#!/usr/bin/env bash
# Regenerate roles/packages/files/mise.lock against roles/packages/files/mise.toml
# in a throwaway CentOS Stream 10 container, using the pinned mise version from
# roles/packages/defaults/main.yml. Mirrors the role's GPG-pinned mise install.
#
# Requires podman or docker + network. A GITHUB_TOKEN in the environment is
# strongly recommended (a full install of the pinned tool set otherwise hits the
# 60/hr anonymous GitHub API limit). Commit mise.toml + mise.lock together.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
FILES="${REPO}/roles/packages/files"
DEFAULTS="${REPO}/roles/packages/defaults/main.yml"

MISE_VERSION="$(awk -F'"' '/^packages_mise_version:/{print $2; exit}' "$DEFAULTS")"
MISE_GPG_FPR="$(awk -F'"' '/^packages_mise_gpg_fpr:/{print $2; exit}' "$DEFAULTS")"
MISE_GPG_URL="$(awk -F'"' '/^packages_mise_gpg_url:/{print $2; exit}' "$DEFAULTS")"
: "${GITHUB_TOKEN:=}"

ENGINE="$(command -v podman || command -v docker || true)"
[ -n "$ENGINE" ] || { echo "need podman or docker on PATH" >&2; exit 1; }
[ -f "${FILES}/mise.toml" ] || { echo "missing ${FILES}/mise.toml" >&2; exit 1; }

echo "==> Regenerating mise.lock (mise ${MISE_VERSION}) in a stream10 container via $(basename "$ENGINE")"

"$ENGINE" run --rm -i \
  -e MISE_VERSION="$MISE_VERSION" \
  -e MISE_GPG_FPR="$MISE_GPG_FPR" \
  -e MISE_GPG_URL="$MISE_GPG_URL" \
  -e GITHUB_TOKEN="$GITHUB_TOKEN" \
  -v "${FILES}:/work:Z" \
  quay.io/centos/centos:stream10 bash -euo pipefail -s <<'EOSH'
dnf install -y -q curl-minimal gnupg2 tar gzip >/dev/null 2>&1 || dnf install -y -q curl gnupg2 tar gzip >/dev/null
case "$(uname -m)" in x86_64) A=x64;; aarch64) A=arm64;; *) echo "unsupported arch" >&2; exit 1;; esac
work="$(mktemp -d)"; cd "$work"; export GNUPGHOME="$work/gnupg"; mkdir -p -m 0700 "$GNUPGHOME"
curl -fsSL -o key.asc "$MISE_GPG_URL"
gpg --batch --import key.asc
gpg --list-keys --with-colons --with-fingerprint | awk -F: '$1=="fpr"{print $10}' | grep -qFx "$MISE_GPG_FPR"
tb="mise-${MISE_VERSION}-linux-${A}.tar.gz"
base="https://github.com/jdx/mise/releases/download/${MISE_VERSION}"
curl -fsSL -o "$tb" "${base}/${tb}"
curl -fsSL -o SHASUMS256.asc "${base}/SHASUMS256.asc"
gpg --batch --status-fd 1 --verify SHASUMS256.asc 2>/dev/null | grep -qF "VALIDSIG $MISE_GPG_FPR"
gpg --batch --decrypt SHASUMS256.asc 2>/dev/null | awk -v f="./${tb}" '$2==f{print $1"  "f}' | sha256sum -c -
tar -xz --strip-components=2 -C /usr/local/bin -f "$tb" mise/bin/mise
chmod +x /usr/local/bin/mise
mkdir -p /etc/mise
cp /work/mise.toml /etc/mise/mise.toml
cp -r /work/aqua-registry /etc/mise/aqua-registry
# mise only writes the lock if it already exists; seed an empty one for a first run.
[ -f /work/mise.lock ] && cp /work/mise.lock /etc/mise/mise.lock || touch /etc/mise/mise.lock
export MISE_DATA_DIR=/opt/mise \
       MISE_GLOBAL_CONFIG_FILE=/etc/mise/mise.toml \
       MISE_TRUSTED_CONFIG_PATHS=/etc/mise/mise.toml \
       MISE_LOCKED=0
mise trust --all --quiet || true
mise install --yes
cp /etc/mise/mise.lock /work/mise.lock
echo "wrote /work/mise.lock"
EOSH

echo "==> Regenerated ${FILES}/mise.lock — commit mise.toml + mise.lock together."
