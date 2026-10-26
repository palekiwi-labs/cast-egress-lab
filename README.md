# cast-egress-lab

Throwaway lab for the cast egress proxy spike
(cue context `palekiwi-labs/cast/egress-proxy`). Only this repo's cast
service is opted in; every other cast service is untouched.

## Layout

- `host/proxy.sh` - run on the HOST: creates the `cast-egress-lab` docker
  network and the `cast-egress-proxy` mitmproxy container.
- `host/mitm/addon.py` - mitmproxy addon writing `host/logs/egress.jsonl`.
- `stages/<n>/` - `cast.local.json` and `cast.env` per stage; copy into the
  repo root to activate (both are gitignored there).
- `probes/` - run INSIDE the lab cast service. `run-all.sh` writes a
  summary to `results/`.

- `flake.nix` - project devshell filling gaps in the cast sandbox shell
  (nodejs, opencode, jq, go-task). pi, claude-code and gh come from the
  sandbox shell on purpose. Enabled by `project_shell` in the stage config.
- `Taskfile.yml` - `task --list`; `[host]` tasks run on the host,
  `[service]` tasks inside the lab service.

## Stage 1: soft monitoring (no TLS interception, normal bridge network)

Clients that ignore the proxy go direct: gaps in the log, nothing breaks.

On the host:

    task proxy:up
    task stage:1
    cast up            # approve the changed config
    task proxy:logs    # in another terminal

Inside the service (`cast shell`, or an agent):

    task probe:blackhole   # which clients honour proxy vars
    task probe             # real run; compare with proxy log

Reading results:

- `--blackhole`: FAIL means the client honours the proxy vars; OK means it
  bypasses them (or used no network).
- curl prints `via_proxy_hint=200` when it tunnelled through the proxy,
  `000` when it went direct.
- Every client that honours the vars should show `connect` lines in the
  proxy log during the real run.

## Turning it off

    cast down
    task stage:off
    task proxy:down
    cast up   # optional, back on the default bridge
