#!/usr/bin/env bash
set -euo pipefail
curl -fsS -o /dev/null -w "http=%{http_code} via_proxy_hint=%{http_connect}\n" https://api.github.com/zen
