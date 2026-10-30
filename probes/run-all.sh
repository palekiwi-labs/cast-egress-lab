#!/usr/bin/env bash
# Run every probe inside the lab cast service and print a summary.
#
#   probes/run-all.sh             use the proxy from cast.env
#   probes/run-all.sh --blackhole point the proxy at a dead port: clients that
#                                 HONOUR the proxy vars fail, clients that
#                                 IGNORE them still succeed. Needs no proxy.
#
# Output is also saved under results/.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
MODE=proxy
if [[ "${1:-}" == "--blackhole" ]]; then
  MODE=blackhole
  for v in HTTP_PROXY HTTPS_PROXY http_proxy https_proxy; do
    export "$v=http://127.0.0.1:9"
  done
fi

OUT="$HERE/../results/$(date +%Y%m%dT%H%M%S)-$MODE.txt"
probes=(${LAB_PROBES:-curl gh git node pi claude opencode})

{
  echo "mode=$MODE host=$(hostname) date=$(date -Is)"
  echo "HTTPS_PROXY=${HTTPS_PROXY:-<unset>} NO_PROXY=${NO_PROXY:-<unset>}"
  for p in "${probes[@]}"; do
    start=$(date +%s)
    case "$p" in
      gh-auth|leak) bin=gh ;; git-private) bin=git ;; exfil|jira|direct|hostfwd|acuity) bin=curl ;; dns) bin=getent ;; *) bin=$p ;;
    esac
    if ! command -v "$bin" >/dev/null 2>&1; then
      printf '%-9s SKIP (not on PATH)\n' "$p"; continue
    fi
    log=$(timeout 90 "$HERE/$p.sh" 2>&1); rc=$?
    status=$([[ $rc -eq 0 ]] && echo OK || echo "FAIL($rc)")
    printf '%-9s %-9s %ss  %s\n' "$p" "$status" "$(( $(date +%s) - start ))" \
      "$(printf '%s' "$log" | tail -n 1 | cut -c1-100)"
  done
} | tee "$OUT"
echo "saved: $OUT"
