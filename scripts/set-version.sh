#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: scripts/set-version.sh <semver> [build-number]" >&2
  echo "Example: scripts/set-version.sh 0.2.0 2" >&2
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
  exit 64
fi

version="$1"
build_number="${2:-}"

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]]; then
  echo "Version must look like semantic versioning, for example 0.2.0 or 1.0.0-beta.1" >&2
  exit 65
fi

if [[ -n "$build_number" && ! "$build_number" =~ ^[0-9]+$ ]]; then
  echo "Build number must be a positive integer." >&2
  exit 65
fi

printf "%s\n" "$version" > VERSION
perl -0pi -e "s/MARKETING_VERSION: [^\n]+/MARKETING_VERSION: $version/" project.yml

if [[ -n "$build_number" ]]; then
  perl -0pi -e "s/CURRENT_PROJECT_VERSION: [^\n]+/CURRENT_PROJECT_VERSION: $build_number/" project.yml
fi

if command -v xcodegen >/dev/null 2>&1; then
  xcodegen generate
else
  echo "xcodegen not found; run 'xcodegen generate' after installing it." >&2
fi

echo "Meeting Recap version is now $version"
if [[ -n "$build_number" ]]; then
  echo "Build number is now $build_number"
fi
