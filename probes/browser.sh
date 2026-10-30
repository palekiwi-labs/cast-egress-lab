#!/usr/bin/env bash
set -uo pipefail
rc=0
for url in https://example.com ${LAB_QA_URL:-http://host.docker.internal:3030/}; do
  title=$(agent-browser --session lab-probe open "$url" >/dev/null 2>&1 && agent-browser --session lab-probe get title 2>&1) || rc=1
  echo "$url title=${title:-<none>}"
done
agent-browser --session lab-probe close >/dev/null 2>&1
echo "AGENT_BROWSER_CA_CERT=${AGENT_BROWSER_CA_CERT:-unset} rc=$rc"
exit $rc
