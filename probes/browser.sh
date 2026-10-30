#!/usr/bin/env bash
set -uo pipefail
rc=0
for url in https://example.com ${LAB_QA_URL:-http://host.docker.internal:3030/}; do
  if out=$(agent-browser --session lab-probe open "$url" 2>&1); then
    echo "$url OK: $(echo "$out" | head -n 1)"
  else
    rc=1; echo "$url FAIL: $out"
  fi
done
agent-browser --session lab-probe close >/dev/null 2>&1
echo "AGENT_BROWSER_CA_CERT=${AGENT_BROWSER_CA_CERT:-unset} rc=$rc"
exit $rc
