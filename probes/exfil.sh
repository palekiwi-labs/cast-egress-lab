#!/usr/bin/env bash
set -euo pipefail
code=$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $GH_TOKEN" https://httpbin.org/headers)
[[ "$code" == 403 ]] && echo "blocked ($code)" || { echo "not blocked ($code)"; exit 1; }
