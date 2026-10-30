#!/usr/bin/env bash
set -uo pipefail
url="${CAST_MCP_URL:-http://host.docker.internal:${LAB_MCP_PORT:-30319}/mcp}"
out=$(cast-mcp-client status --cast-mcp-url "$url" 2>&1); rc=$?
echo "$out" | tail -n 5
echo "url=$url rc=$rc"
[[ $rc -eq 0 ]]
