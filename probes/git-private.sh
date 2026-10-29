#!/usr/bin/env bash
set -euo pipefail
: "${LAB_PRIVATE_REPO:?set LAB_PRIVATE_REPO=<org>/<repo>}"
git ls-remote "https://github.com/$LAB_PRIVATE_REPO.git" HEAD
