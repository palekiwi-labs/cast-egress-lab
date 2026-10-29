#!/usr/bin/env bash
set -euo pipefail
[[ "${GH_TOKEN:-}" == cast-placeholder-gh-token ]] || { echo "GH_TOKEN not placeholder"; exit 1; }
if env | grep -E '=(gh[pousr]_|github_pat_)' >/dev/null; then
  echo "real GitHub token value present in env"; exit 1
fi
if gh auth status 2>&1 | grep -qi 'hosts.yml'; then
  echo "gh has a stored token in hosts.yml"; exit 1
fi
echo "placeholder only"
