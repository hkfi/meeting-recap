#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: scripts/verify-release-version.sh <release-tag-or-version>" >&2
  echo "Example: scripts/verify-release-version.sh v0.1.0" >&2
  exit 64
fi

release_version="${1#v}"
file_version="$(tr -d '[:space:]' < VERSION)"

if [[ "$release_version" != "$file_version" ]]; then
  echo "Release version mismatch." >&2
  echo "GitHub release/tag version: $release_version" >&2
  echo "VERSION file: $file_version" >&2
  exit 65
fi

if ! grep -q "MARKETING_VERSION: $file_version" project.yml; then
  echo "project.yml MARKETING_VERSION does not match VERSION ($file_version)." >&2
  exit 65
fi

echo "Release version $release_version matches VERSION and MARKETING_VERSION."
