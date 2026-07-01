#!/usr/bin/env bash
# Verification audit: assert each tool in mise.toml resolves to the verification
# method declared in mise-expected-verification.toml. Catches silent
# aqua-registry downgrades (e.g. argocd SLSA -> SHA-only) and dropped GPG hooks.
#
# Runs either on an installed host (reads /etc/mise/{mise.lock,mise.toml,
# aqua-registry}) or statically against the role's files/ dir (the committed
# mise.lock). The checksum-algorithm prefix in the lockfile is the audit signal:
#   checksum = "sha256:..."   # upstream-published checksum
#   checksum = "blake3:..."   # TOFU: mise computed it on first install
set -euo pipefail

# Resolve inputs: prefer the installed system-wide location, else the dir this
# script lives in (the role's files/).
HERE="$(cd "$(dirname "$0")" && pwd)"
if [ -f /etc/mise/mise.lock ]; then
    LOCK=/etc/mise/mise.lock
    MISE_TOML=/etc/mise/mise.toml
    HOOK_DIR=/etc/mise/aqua-registry
else
    LOCK="${HERE}/mise.lock"
    MISE_TOML="${HERE}/mise.toml"
    HOOK_DIR="${HERE}/aqua-registry"
fi
EXPECTED="${HERE}/mise-expected-verification.toml"

[ -f "$LOCK" ] || { echo "[FAIL] lockfile not found at ${LOCK}"; exit 1; }
[ -f "$EXPECTED" ] || { echo "[FAIL] expected manifest not found at ${EXPECTED}"; exit 1; }

PASS=0
FAIL=0
ok()   { echo "  [OK] $1"; PASS=$((PASS + 1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }

echo "==> Verification audit (per tool in mise.toml, checked against mise.lock)"

declare -A EXPECTED_MAP
declare -A BINARY_MAP
while IFS= read -r line; do
    trimmed="${line#"${line%%[![:space:]]*}"}"
    case "$trimmed" in ""|"#"*) continue ;; esac
    case "$line" in *=*) ;; *) continue ;; esac
    k="${line%%=*}"
    rest="${line#*=}"
    k="$(echo "$k" | tr -d '"' | xargs)"
    bin=""
    if echo "$rest" | grep -qE '# *binary: *[^ ]+'; then
        bin="$(echo "$rest" | sed -nE 's/.*# *binary: *([^ #]+).*/\1/p')"
    fi
    v="${rest%%#*}"
    v="$(echo "$v" | tr -d '"' | xargs)"
    [ -n "$k" ] || continue
    EXPECTED_MAP["$k"]="$v"
    [ -n "$bin" ] && BINARY_MAP["$k"]="$bin"
done < "$EXPECTED"

for tool in "${!EXPECTED_MAP[@]}"; do
    expected="${EXPECTED_MAP[$tool]}"
    case "$tool" in
        *[!a-zA-Z0-9_-]*) section_open="[[tools.\"${tool}\"]"; section_dot="[tools.\"${tool}\".";;
        *)               section_open="[[tools.${tool}]";      section_dot="[tools.${tool}.";;
    esac

    if [ "$expected" = "postinstall-gpg" ]; then
        if ! grep -qF "$section_open" "$LOCK"; then
            fail "${tool}: no ${section_open}] section in ${LOCK}"; continue
        fi
        case "$tool" in
            *[!a-zA-Z0-9_-]*) toml_section="[tools.\"${tool}\"]";;
            *)               toml_section="[tools.${tool}]";;
        esac
        post_path=$(awk -v hdr="$toml_section" '
            $0 == hdr { in_block = 1; next }
            /^\[/      { in_block = 0 }
            in_block && /^postinstall *=/ {
                match($0, /"[^"]+"/)
                if (RLENGTH > 0) { print substr($0, RSTART+1, RLENGTH-2); exit }
            }' "$MISE_TOML")
        if [ -z "$post_path" ]; then
            fail "${tool}: mise.toml ${toml_section} has no postinstall = entry"; continue
        fi
        hook="${HOOK_DIR}/$(basename "$post_path")"
        if [ ! -f "$hook" ]; then
            fail "${tool}: postinstall script not found at ${hook}"; continue
        fi
        if ! grep -qE '\bgpg\b' "$hook"; then
            fail "${tool}: postinstall script ${hook} does not reference gpg"; continue
        fi
        ok "${tool} verified via postinstall GPG hook (${post_path##*/})"
        continue
    fi

    signals=$(awk -v open="$section_open" -v dot="$section_dot" '
        function startswith(s, p) { return substr(s, 1, length(p)) == p }
        /^\[/{
            in_tool = startswith($0, open) || startswith($0, dot)
            if (in_tool && match($0, /\.provenance\.[a-zA-Z0-9_-]+/)) {
                kind = substr($0, RSTART+12, RLENGTH-12); gsub(/\]/, "", kind)
                print "provenance:" kind
            }
        }
        in_tool && /^checksum *= *"/{
            match($0, /"[^:]+:/)
            if (RLENGTH > 0) { print "checksum:" substr($0, RSTART+1, RLENGTH-2) }
        }' "$LOCK" | sort -u)

    algs=$(echo "$signals" | awk -F: '/^checksum:/{print $2}' | sort -u)
    provs=$(echo "$signals" | awk -F: '/^provenance:/{print $2}' | sort -u)
    [ -n "$algs" ] || { fail "${tool}: no checksum found in ${LOCK}"; continue; }

    case "$expected" in
        *+*) exp_alg="${expected%%+*}"; exp_prov="${expected#*+}";;
        *)   exp_alg="$expected"; exp_prov="";;
    esac

    mismatch=""
    for a in $algs; do [ "$a" != "$exp_alg" ] && { mismatch="$a"; break; }; done
    [ -n "$mismatch" ] && { fail "${tool}: lockfile uses ${mismatch} (expected ${exp_alg})"; continue; }

    if [ -n "$exp_prov" ]; then
        if echo "$provs" | grep -qFx "$exp_prov"; then
            ok "${tool} verified via ${exp_alg} + ${exp_prov} provenance"
        else
            fail "${tool}: lockfile has no provenance.${exp_prov} entry (expected ${expected})"
        fi
    else
        ok "${tool} verified via ${exp_alg}"
    fi
done

echo ""
echo "==> Binary launch check (every audited tool runs)"
for tool in "${!EXPECTED_MAP[@]}"; do
    bin="${BINARY_MAP[$tool]:-$tool}"
    if "$bin" --version >/dev/null 2>&1 \
        || "$bin" version --client >/dev/null 2>&1 \
        || "$bin" version >/dev/null 2>&1 \
        || "$bin" -v >/dev/null 2>&1; then
        [ "$bin" != "$tool" ] && ok "$tool launches (binary: $bin)" || ok "$tool launches"
    else
        fail "$tool failed to launch (tried binary: $bin)"
    fi
done

echo ""
echo "==> Summary: ${PASS} passed, ${FAIL} failed"
[ "$FAIL" -eq 0 ]
