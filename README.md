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

## Stage 2: TLS interception and GitHub token injection

The proxy decrypts TLS with its own CA and swaps the placeholder
`cast-placeholder-gh-token` for the host's `GH_TOKEN_READONLY`, only for
`github.com` and `api.github.com` (plain or Basic-encoded Authorization).
The placeholder sent to any other host gets a 403 and a
`placeholder_blocked` log line. The real token never enters the service.

On the host (`GH_TOKEN_READONLY` exported):

    cast down
    task proxy:down
    task proxy:up:mitm   # generates host/certs/ CA and bundle.pem
    task stage:2
    cast up

Inside the service:

    LAB_PRIVATE_REPO=<org>/<repo> task probe:mitm

Probes: `gh-auth` (gh api user), `git-private` (ls-remote of a private
repo), `leak` (only the placeholder is in env), `exfil` (placeholder to
httpbin.org is refused). The log shows `inject` lines with rule and host,
never the token.

## Stage 3: internal network and host forwarders

The service joins only `cast-egress-int`, an `--internal` network with no
gateway. The proxy (also on `cast-egress-lab`) is its only way out. A
socat forwarder `cast-egress-fwd` carries the alias `host.docker.internal`
on the internal network and relays ports 33222 (acuity), 9000 (MCP), 3030
and 8080 (QA app) to the host. Stage 3 sets `add_host_docker_internal`
to false so the name resolves to the forwarder through docker DNS.
Injection works as in stage 2.

On the host (the stage 2 token vars exported):

    cast down
    task proxy:down
    task proxy:up:internal
    task stage:3
    cast up

Inside the service:

    LAB_PRIVATE_REPO=<org>/<repo> \
      PI_PROBE_ARGS="--model google/gemini-3.8-flash" task probe:internal

Expected: `direct` OK (direct egress blocked), `node` FAIL (bare fetch
bypasses the proxy and now has no route), `dns` OK only if external names
do not resolve. `hostfwd` reports a status per port; `000` means nothing
answered (forwarder down or the host service not running). `acuity` shows
whether the sandbox shell's hardcoded `ACUITY_HOST` (172.17.0.1) still
works; `pi` shows whether an unreachable acuity hangs pi or fails fast.

## Turning it off

    cast down
    task stage:off
    task proxy:down
    cast up   # optional, back on the default bridge
