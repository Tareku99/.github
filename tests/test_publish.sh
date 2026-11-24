#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
publisher="$root/.github/actions/docker-release/publish.sh"
temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT

cat > "$temp_dir/docker" <<'MOCK_DOCKER'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "$MOCK_DOCKER_LOG"

case "${1:-}" in
  image)
    [[ "${2:-}" == "inspect" ]] || exit 20
    exit 0
    ;;
  login)
    [[ "${2:-}" == "ghcr.io" ]] || exit 21
    [[ "${3:-}" == "--username" ]] || exit 22
    [[ "${4:-}" == "$GITHUB_ACTOR" ]] || exit 23
    [[ "${5:-}" == "--password-stdin" ]] || exit 24
    IFS= read -r password || [[ -n "$password" ]]
    [[ "$password" == "$EXPECTED_TOKEN" ]] || exit 25
    exit 0
    ;;
  tag)
    [[ -n "${2:-}" && -n "${3:-}" ]] || exit 26
    exit 0
    ;;
  push)
    [[ -n "${2:-}" ]] || exit 27
    printf '%s: digest: %s size: 1\n' "$2" "$MOCK_DIGEST"
    exit 0
    ;;
  *)
    echo "Unexpected docker command: $*" >&2
    exit 28
    ;;
esac
MOCK_DOCKER
chmod +x "$temp_dir/docker"

export PATH="$temp_dir:$PATH"
export MOCK_DOCKER_LOG="$temp_dir/docker.log"
export EXPECTED_TOKEN="test-token-do-not-log"
export MOCK_DIGEST="sha256:$(printf 'a%.0s' {1..64})"
export GHCR_IMAGE="ghcr.io/tareku99/example"
export GHCR_SOURCE_IMAGE="example:ci"
export GHCR_TAGS=$'latest\nsha-test'
export GHCR_TOKEN="$EXPECTED_TOKEN"
export GITHUB_ACTOR="Tareku99"
export GITHUB_REPOSITORY_OWNER="Tareku99"
export GITHUB_OUTPUT="$temp_dir/output"

bash "$publisher"

[[ "$(grep -c '^push ' "$MOCK_DOCKER_LOG")" -eq 2 ]]
[[ "$(grep -c '^tag ' "$MOCK_DOCKER_LOG")" -eq 2 ]]
grep -Fq "digest=$MOCK_DIGEST" "$GITHUB_OUTPUT"
if grep -Fq "$EXPECTED_TOKEN" "$MOCK_DOCKER_LOG"; then
  echo "The registry token must not appear in docker arguments or logs." >&2
  exit 1
fi

: > "$MOCK_DOCKER_LOG"
if GHCR_TAGS=$'latest\ninvalid tag' bash "$publisher" >"$temp_dir/invalid.log" 2>&1; then
  echo "Invalid tags should be rejected." >&2
  exit 1
fi
if grep -q '^push ' "$MOCK_DOCKER_LOG"; then
  echo "Invalid tags must be rejected before any push." >&2
  exit 1
fi

: > "$MOCK_DOCKER_LOG"
if GHCR_IMAGE="ghcr.io/another-owner/example" bash "$publisher" >"$temp_dir/foreign.log" 2>&1; then
  echo "Images outside the repository owner's namespace should be rejected." >&2
  exit 1
fi
if grep -q '^push ' "$MOCK_DOCKER_LOG"; then
  echo "Foreign image paths must be rejected before any push." >&2
  exit 1
fi

printf '%s\n' "GHCR publisher tests passed."
