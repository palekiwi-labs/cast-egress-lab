#!/usr/bin/env bash
set -euo pipefail
: "${JIRA_EMAIL:?JIRA_EMAIL not set}"
base=https://api.atlassian.com/ex/jira/f9c22791-6b2e-4605-b14a-74ca9f03a46a
code=$(curl -s -o /dev/null -w '%{http_code}' -u "$JIRA_EMAIL:$JIRA_TOKEN" "$base/rest/api/3/myself")
[[ "$code" == 200 ]] && echo "myself ok ($code)" || { echo "myself failed ($code)"; exit 1; }
