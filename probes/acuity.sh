#!/usr/bin/env bash
set -uo pipefail
start=$(date +%s)
code=$(curl -s --noproxy '*' -m 10 -o /dev/null -w '%{http_code}' "${ACUITY_HOST:?}/events" 2>&1); rc=$?
echo "ACUITY_HOST=$ACUITY_HOST code=$code rc=$rc $(( $(date +%s) - start ))s"
[[ $rc -eq 0 ]]
