#!/usr/bin/env bash
set -uo pipefail
out=$(curl -s --noproxy '*' -m 5 -o /dev/null -w '%{http_code}' https://example.com 2>&1); rc=$?
[[ $rc -ne 0 ]] && echo "direct blocked (curl rc=$rc)" || { echo "direct egress works ($out)"; exit 1; }
