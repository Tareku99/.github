#!/usr/bin/env bash
set -euo pipefail

required_vars=(GHCR_IMAGE GHCR_SOURCE_IMAGE GHCR_TAGS GHCR_TOKEN GITHUB_ACTOR GITHUB_REPOSITORY_OWNER GITHUB_OUTPUT)
for name in "${required_vars[@]}"; do
  if [[ -z "${!name:-}" ]]; then
    echo "::error::Required publishing input is missing: $name"
    exit 1
  fi
done

owner="${GITHUB_REPOSITORY_OWNER,,}"
prefix="ghcr.io/$owner/"
if [[ "$GHCR_IMAGE" != "$prefix"* ]]; then
  echo "::error::Image must be published under $prefix"
  exit 1
fi
package_name="${GHCR_IMAGE#"$prefix"}"
if [[ ! "$package_name" =~ ^[a-z0-9][a-z0-9._-]*$ ]]; then
  echo "::error::Image must be one valid lowercase GHCR package name under $prefix"
  exit 1
fi
if [[ "$GHCR_SOURCE_IMAGE" =~ [[:space:]] ]]; then
  echo "::error::source_image must not contain whitespace"
  exit 1
fi

mapfile -t raw_tags <<< "$GHCR_TAGS"
tags=()
for tag in "${raw_tags[@]}"; do
  [[ -z "$tag" ]] && continue
  if [[ ! "$tag" =~ ^[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}$ ]]; then
    echo "::error::Invalid Docker tag: $tag"
    exit 1
  fi
  for previous in "${tags[@]}"; do
    if [[ "$previous" == "$tag" ]]; then
      echo "::error::Duplicate Docker tag: $tag"
      exit 1
    fi
  done
  tags+=("$tag")
done
if (( ${#tags[@]} == 0 )); then
  echo "::error::At least one Docker tag is required when publish is true."
  exit 1
fi

if ! docker image inspect "$GHCR_SOURCE_IMAGE" >/dev/null; then
  echo "::error::The tested local image was not found: $GHCR_SOURCE_IMAGE"
  exit 1
fi

printf '%s' "$GHCR_TOKEN" | docker login ghcr.io --username "$GITHUB_ACTOR" --password-stdin

digest=""
for tag in "${tags[@]}"; do
  target="$GHCR_IMAGE:$tag"
  docker tag "$GHCR_SOURCE_IMAGE" "$target"
  if ! push_output="$(docker push "$target" 2>&1)"; then
    printf '%s\n' "$push_output"
    echo "::error::Failed to push $target"
    exit 1
  fi
  printf '%s\n' "$push_output"
  current_digest="$(printf '%s\n' "$push_output" | sed -nE 's/.*digest: (sha256:[0-9a-f]{64}).*/\1/p' | tail -n 1)"
  if [[ ! "$current_digest" =~ ^sha256:[0-9a-f]{64}$ ]]; then
    echo "::error::GHCR did not return a valid image digest for $target"
    exit 1
  fi
  if [[ -n "$digest" && "$digest" != "$current_digest" ]]; then
    echo "::error::GHCR returned different digests for tags of the same tested image."
    exit 1
  fi
  digest="$current_digest"
done

printf 'digest=%s\n' "$digest" >> "$GITHUB_OUTPUT"
