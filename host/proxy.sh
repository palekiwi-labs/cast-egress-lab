#!/usr/bin/env bash
# Host-side lifecycle for the egress lab proxy. Run on the host, not in cast.
#   proxy.sh up | down | status | logs
set -euo pipefail

NETWORK="${LAB_NETWORK:-cast-egress-lab}"
PROXY="${LAB_PROXY:-cast-egress-proxy}"
IMAGE="${LAB_IMAGE:-docker.io/mitmproxy/mitmproxy:latest}"
HERE="$(cd "$(dirname "$0")" && pwd)"
LOGS="$HERE/logs"
CERTS="$HERE/certs"
MODE="${LAB_MODE:-monitor}"

up() {
  mkdir -p "$LOGS"
  docker network inspect "$NETWORK" >/dev/null 2>&1 \
    || docker network create \
         -o com.docker.network.bridge.name=br-cast-egress \
         "$NETWORK" >/dev/null
  if docker container inspect "$PROXY" >/dev/null 2>&1; then
    echo "proxy already exists: $PROXY"; return
  fi
  # Stage 1: monitor only. --ignore-hosts '.*' passes TLS through untouched,
  # so no CA is needed; the addon still logs every upstream connection.
  local mode_args=(--ignore-hosts '.*') extra=()
  if [[ "$MODE" == mitm ]]; then
    : "${GH_TOKEN_READONLY:?GH_TOKEN_READONLY must be set on the host}"
    mkdir -p "$CERTS"
    mode_args=(-s /addons/inject.py)
    extra=(-v "$CERTS:/home/mitmproxy/.mitmproxy" -e GH_TOKEN_READONLY)
  fi
  docker run -d --name "$PROXY" --network "$NETWORK" \
    -v "$HERE/mitm:/addons:ro" -v "$LOGS:/logs" "${extra[@]}" \
    "$IMAGE" mitmdump --listen-port 8080 \
      --set block_global=false \
      "${mode_args[@]}" \
      -s /addons/addon.py >/dev/null
  [[ "$MODE" == mitm ]] && bundle
  echo "proxy up ($MODE): http://$PROXY:8080 on network $NETWORK"
}

bundle() {
  local ca="$CERTS/mitmproxy-ca-cert.pem" sys="${SYSTEM_CA:-/etc/ssl/certs/ca-certificates.crt}"
  for _ in $(seq 20); do [[ -s "$ca" ]] && break; sleep 0.5; done
  [[ -s "$ca" ]] || { echo "CA not generated: $ca" >&2; exit 1; }
  cat "$sys" "$ca" > "$CERTS/bundle.pem"
  echo "CA: $ca"
  echo "bundle: $CERTS/bundle.pem"
}

down() {
  docker rm -f "$PROXY" >/dev/null 2>&1 || true
  docker network rm "$NETWORK" >/dev/null 2>&1 \
    || echo "network $NETWORK still in use (cast down the lab service first)"
  echo "proxy down"
}

status() {
  docker ps -a --filter "name=^${PROXY}\$" --format '{{.Names}}\t{{.Status}}'
  docker network inspect "$NETWORK" --format \
    '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null || echo "no network"
}

logs() { tail -n "${1:-50}" -F "$LOGS/egress.jsonl"; }

case "${1:-}" in
  up) up ;; down) down ;; status) status ;; logs) shift; logs "$@" ;;
  *) echo "usage: $0 up|down|status|logs [n]" >&2; exit 2 ;;
esac
