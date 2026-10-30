#!/usr/bin/env bash
set -uo pipefail
ext=$(getent hosts example.com | awk '{print $1}' | head -1)
proxy=$(getent hosts cast-egress-proxy | awk '{print $1}' | head -1)
hdi=$(getent hosts host.docker.internal | awk '{print $1}' | head -1)
echo "example.com=${ext:-none} proxy=${proxy:-none} host.docker.internal=${hdi:-none}"
[[ -z "$ext" ]] || { echo "external DNS resolves: exfil channel open"; exit 1; }
