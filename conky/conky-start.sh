#!/usr/bin/env bash
set -euo pipefail

CONKY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_SRC="${CONKY_ROOT}/conky/config"
CONFIG_GEN="${XDG_CONFIG_HOME:-${HOME}/.config}/conky-crypto/generated"
PRICE_SCRIPT="${CONKY_ROOT}/scripts/osmosis-price.sh"
TOKENS_LIST="${CONKY_ROOT}/config/tokens.list"

mkdir -p "${CONFIG_GEN}"
chmod +x "${PRICE_SCRIPT}"

render_config() {
    local name="$1"
    sed "s|@CONKY_ROOT@|${CONKY_ROOT}|g" \
        "${CONFIG_SRC}/${name}.in" > "${CONFIG_GEN}/${name}"
}

generate_osmosis_config() {
    local out="${CONFIG_GEN}/conky-osmosis"
    {
        sed 's|@CONKY_ROOT@|'"${CONKY_ROOT}"'|g' "${CONFIG_SRC}/conky-osmosis.in"
        echo 'conky.text = [['
        echo '${color darkblue}============= Osmosis ===============${color}'
        echo 'Symbol                                         Price (USD)'
        echo '${hr 1}'
        while IFS= read -r symbol || [[ -n "${symbol}" ]]; do
            [[ -z "${symbol}" || "${symbol}" =~ ^# ]] && continue
            printf '${color blue}%s:${alignr}${color cyan}${execi 60 %s %s}\n' \
                "${symbol}" "${PRICE_SCRIPT}" "${symbol}"
            echo '${color darkblue}${hr 1}'
        done < "${TOKENS_LIST}"
        echo ']]'
    } > "${out}"
}

for widget in conky-general conky-rss; do
    render_config "${widget}"
done

generate_osmosis_config

# Stop previous instances for this install (ignore errors if not running)
pkill -f "conky -d -c ${CONFIG_GEN}/" 2>/dev/null || true

conky -d -c "${CONFIG_GEN}/conky-general"
conky -d -c "${CONFIG_GEN}/conky-osmosis"
conky -d -c "${CONFIG_GEN}/conky-rss"

echo "Conky started (configs in ${CONFIG_GEN})"
