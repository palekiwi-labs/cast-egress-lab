"""Replace placeholder credentials with real ones for allowlisted hosts."""

import base64
import json
import os
import time

from mitmproxy import http

LOG = "/logs/egress.jsonl"

RULES = [
    {
        "name": "github",
        "placeholder": "cast-placeholder-gh-token",
        "secret": os.environ.get("GH_TOKEN_READONLY", ""),
        "hosts": {"github.com", "api.github.com"},
    },
]


def _log(event: dict) -> None:
    event["ts"] = time.time()
    with open(LOG, "a") as fh:
        fh.write(json.dumps(event) + "\n")


def _swap(value: str, placeholder: str, secret: str) -> str | None:
    if placeholder in value:
        return value.replace(placeholder, secret)
    scheme, _, cred = value.partition(" ")
    if scheme.lower() != "basic":
        return None
    try:
        decoded = base64.b64decode(cred).decode()
    except ValueError:
        return None
    if placeholder not in decoded:
        return None
    swapped = decoded.replace(placeholder, secret).encode()
    return f"{scheme} {base64.b64encode(swapped).decode()}"


def request(flow: http.HTTPFlow) -> None:
    auth = flow.request.headers.get("authorization")
    if not auth:
        return
    host = flow.request.pretty_host
    for rule in RULES:
        swapped = _swap(auth, rule["placeholder"], rule["secret"])
        if swapped is None:
            continue
        if host in rule["hosts"] and rule["secret"]:
            flow.request.headers["authorization"] = swapped
            _log({"event": "inject", "rule": rule["name"], "host": host})
        else:
            _log({"event": "placeholder_blocked", "rule": rule["name"], "host": host})
            flow.response = http.Response.make(403, b"placeholder not allowed for host\n")
        return
