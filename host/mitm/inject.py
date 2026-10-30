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
    {
        "name": "gemini",
        "placeholder": "cast-placeholder-gemini-key",
        "secret": os.environ.get("GOOGLE_GENERATIVE_AI_API_KEY", ""),
        "hosts": {"generativelanguage.googleapis.com"},
    },
    {
        "name": "jira",
        "placeholder": "cast-placeholder-jira-token",
        "secret": os.environ.get("JIRA_TOKEN_READONLY", ""),
        "hosts": {"api.atlassian.com", "spabreaks.atlassian.net"},
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


def _fields(flow: http.HTTPFlow):
    for name, value in flow.request.headers.items():
        yield "header", name, value
    for name, value in flow.request.query.items():
        yield "query", name, value


def _set(flow: http.HTTPFlow, kind: str, name: str, value: str) -> None:
    if kind == "header":
        flow.request.headers[name] = value
    else:
        flow.request.query[name] = value


def _block(flow: http.HTTPFlow, rule: str, host: str, where: str) -> None:
    _log({"event": "placeholder_blocked", "rule": rule, "host": host, "where": where})
    flow.metadata["cast_blocked"] = True
    flow.response = http.Response.make(403, b"placeholder not allowed for host\n")


def request(flow: http.HTTPFlow) -> None:
    host = flow.request.pretty_host
    for kind, name, value in list(_fields(flow)):
        for rule in RULES:
            swapped = _swap(value, rule["placeholder"], rule["secret"])
            if swapped is None:
                continue
            where = f"{kind}:{name.lower()}"
            if host not in rule["hosts"] or not rule["secret"]:
                _block(flow, rule["name"], host, where)
                return
            _set(flow, kind, name, swapped)
            _log({"event": "inject", "rule": rule["name"], "host": host, "where": where})
            break
    body = flow.request.get_content(strict=False) or b""
    for rule in RULES:
        if rule["placeholder"].encode() in body:
            _block(flow, rule["name"], host, "body")
            return
