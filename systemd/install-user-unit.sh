#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONFIG_DIR="${HOME}/.config/conky-crypto"
ENV_FILE="${CONFIG_DIR}/env"
RUN_SCRIPT="${CONFIG_DIR}/run-conky.sh"
UNIT_SRC="${SCRIPT_DIR}/user/conky-crypto.service"
TIMER_SRC="${SCRIPT_DIR}/user/conky-crypto.timer"
UNIT_DST="${HOME}/.config/systemd/user/conky-crypto.service"
TIMER_DST="${HOME}/.config/systemd/user/conky-crypto.timer"

mkdir -p "${CONFIG_DIR}" "${HOME}/.config/systemd/user"

if [[ ! -f "${ENV_FILE}" ]]; then
    sed "s|CONKY_REPO=.*|CONKY_REPO=${REPO_ROOT}|" \
        "${SCRIPT_DIR}/conky-crypto.env.example" > "${ENV_FILE}"
    echo "Created ${ENV_FILE}"
else
    echo "Using existing ${ENV_FILE}"
fi

cat > "${RUN_SCRIPT}" <<EOF
#!/usr/bin/env bash
set -euo pipefail
source "${ENV_FILE}"
: "\${CONKY_REPO:?Set CONKY_REPO in ${ENV_FILE}}"
export DISPLAY="\${DISPLAY:-:0}"
exec "\${CONKY_REPO}/conky/conky-start.sh"
EOF
chmod +x "${RUN_SCRIPT}"

cp "${UNIT_SRC}" "${UNIT_DST}"
cp "${TIMER_SRC}" "${TIMER_DST}"

systemctl --user daemon-reload
echo ""
echo "Installed:"
echo "  ${UNIT_DST}"
echo "  ${TIMER_DST}"
echo "  ${RUN_SCRIPT}"
echo ""
echo "  systemctl --user enable --now conky-crypto.service"
echo "  # optional delayed start:"
echo "  systemctl --user enable --now conky-crypto.timer"
