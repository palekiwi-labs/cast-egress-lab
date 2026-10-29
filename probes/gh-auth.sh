#!/usr/bin/env bash
set -euo pipefail
gh api user --jq .login
