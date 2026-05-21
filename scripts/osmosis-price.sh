#!/usr/bin/env bash
# Print USD price for an Osmosis token symbol (highest-liquidity match).
set -euo pipefail

SYMBOL="${1:?usage: osmosis-price.sh SYMBOL}"

API_URL="${OSMOSIS_API_URL:-https://public-osmosis-api.numia.xyz/tokens/v2/all}"
CACHE_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/conky-crypto"
CACHE_FILE="${CACHE_DIR}/osmosis-tokens.json"
CACHE_MAX_AGE="${OSMOSIS_CACHE_MAX_AGE:-60}"

mkdir -p "${CACHE_DIR}"

refresh_cache() {
    local tmp
    tmp="$(mktemp "${CACHE_DIR}/.tokens.XXXXXX")"
    if curl -fsS --max-time 30 "${API_URL}" -o "${tmp}"; then
        mv "${tmp}" "${CACHE_FILE}"
        return 0
    fi
    rm -f "${tmp}"
    return 1
}

cache_age() {
    if [[ ! -f "${CACHE_FILE}" ]]; then
        echo 999999
        return
    fi
    echo $(($(date +%s) - $(stat -c %Y "${CACHE_FILE}" 2>/dev/null || echo 0)))
}

if [[ "$(cache_age)" -gt "${CACHE_MAX_AGE}" ]]; then
    refresh_cache || true
fi

if [[ ! -s "${CACHE_FILE}" ]]; then
    echo "n/a"
    exit 0
fi

jq -r --arg s "${SYMBOL}" '
  [.[] | select(.symbol == $s and .price != null)]
  | sort_by(-.liquidity)
  | .[0].price // "n/a"
' "${CACHE_FILE}"
