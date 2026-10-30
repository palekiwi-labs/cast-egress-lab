#!/usr/bin/env bash
set -uo pipefail
res=()
for p in ${LAB_FWD_PORTS:-33222 30319 3030 8080}; do
  code=$(curl -s --noproxy '*' -m 5 -o /dev/null -w '%{http_code}' "http://host.docker.internal:$p/")
  res+=("$p=$code")
done
echo "${res[*]} ACUITY_HOST=${ACUITY_HOST:-unset}"
[[ " ${res[*]} " != *"=000 "* ]] || exit 1
