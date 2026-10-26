#!/usr/bin/env bash
set -euo pipefail
node -e "fetch(\"https://api.github.com/zen\").then(r=>r.text()).then(t=>console.log(t)).catch(e=>{console.error(e.cause??e);process.exit(1)})"
