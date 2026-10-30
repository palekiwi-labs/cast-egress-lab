"""Append one JSON line per observed egress event to /logs/egress.jsonl."""

import json
import time

from mitmproxy import http
from mitmproxy.proxy import server_hooks

LOG = "/logs/egress.jsonl"


def _write(event: dict) -> None:
    event["ts"] = time.time()
    with open(LOG, "a") as fh:
        fh.write(json.dumps(event) + "\n")


def http_connect(flow: http.HTTPFlow) -> None:
    # HTTPS through the proxy: host:port is visible even without interception.
    _write({
        "event": "connect",
        "client": flow.client_conn.peername[0],
        "host": flow.request.host,
        "port": flow.request.port,
    })


def request(flow: http.HTTPFlow) -> None:
    # Plain HTTP (or intercepted HTTPS in later stages).
    if flow.request.method == "CONNECT":
        return
    _write({
        "event": "request",
        "client": flow.client_conn.peername[0],
        "method": flow.request.method,
        "url": flow.request.pretty_url,
    })


def server_disconnected(data: server_hooks.ServerConnectionHookData) -> None:
    _write({
        "event": "upstream_closed",
        "client": data.client.peername[0] if data.client.peername else None,
        "address": list(data.server.address or ()),
    })


def response(flow: http.HTTPFlow) -> None:
    _write({
        "event": "response",
        "client": flow.client_conn.peername[0],
        "status": flow.response.status_code,
        "host": flow.request.pretty_host,
        "path": flow.request.path.split("?", 1)[0],
        "origin": "proxy" if flow.response.timestamp_start is None or not flow.server_conn.connected else "upstream",
    })
