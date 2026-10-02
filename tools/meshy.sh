#!/usr/bin/env bash
# Runs meshy-cli in the cloud session: the real API key is injected by the egress proxy
# (environment API credential), so the CLI only needs a placeholder key and Node's proxy support.
export MESHY_API_KEY="${MESHY_API_KEY:-msy_injected_by_proxy}"
export NODE_USE_ENV_PROXY=1
export NODE_NO_WARNINGS=1
command -v meshy >/dev/null 2>&1 || npm i -g meshy-cli >/dev/null 2>&1
exec meshy "$@" --output-schema v1 --format json
