#!/usr/bin/env bash
set -euo pipefail
for v in GH_TOKEN GITHUB_TOKEN GH_TOKEN_READONLY GEMINI_API_KEY GOOGLE_GENERATIVE_AI_API_KEY \
         JIRA_TOKEN JIRA_TOKEN_READONLY ATLASSIAN_CLI_TOKEN_SPABREAKS; do
  [[ "${!v:-}" == cast-placeholder-* ]] || { echo "$v not placeholder"; exit 1; }
done
if env | grep -E '=(gh[pousr]_|github_pat_|AIza|ATATT)' >/dev/null; then
  echo "real token value present in env"; exit 1
fi
if gh auth status 2>&1 | grep -qi 'hosts.yml'; then
  echo "gh has a stored token in hosts.yml"; exit 1
fi
echo "placeholders only"
