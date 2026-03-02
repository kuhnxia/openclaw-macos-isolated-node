#!/usr/bin/env bash
set -euo pipefail

SERVICE_USER="${SERVICE_USER:-svc_openclaw}"
SERVICE_HOME="${SERVICE_HOME:-/Users/${SERVICE_USER}}"
CONFIG_FILE="${CONFIG_FILE:-${SERVICE_HOME}/.openclaw/openclaw.json}"
STDERR_LOG="${STDERR_LOG:-${SERVICE_HOME}/logs/openclaw/stderr.log}"
SAFE_CLI="$(cd "$(dirname "$0")" && pwd)/safe-openclaw-cli.sh"

pass() { printf '[PASS] %s\n' "$1"; }
warn() { printf '[WARN] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; }

if [[ ! -f "${CONFIG_FILE}" ]]; then
  fail "Config not found: ${CONFIG_FILE}"
  exit 1
fi

if [[ ! -r "${CONFIG_FILE}" ]]; then
  fail "Config is not readable by current user: ${CONFIG_FILE}"
  echo "Try: sudo bash scripts/check-feishu.sh"
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  fail "jq is required for this script"
  exit 1
fi

echo "== Feishu channel quick check =="

jq '.channels.feishu // {} | {enabled,domain,connectionMode,dmPolicy,groupPolicy,allowFrom,accounts}' "${CONFIG_FILE}"

if jq -e '.channels.feishu.enabled == true' "${CONFIG_FILE}" >/dev/null; then
  pass "channels.feishu.enabled=true"
else
  warn "Feishu channel is not enabled"
fi

if jq -e '.channels.feishu.connectionMode == "websocket"' "${CONFIG_FILE}" >/dev/null; then
  pass "connectionMode=websocket"
else
  warn "connectionMode is not websocket"
fi

if [[ -x "${SAFE_CLI}" ]]; then
  echo "--- channels status --probe ---"
  "${SAFE_CLI}" channels status --probe || warn "channel probe failed"

  echo "--- pairing list feishu ---"
  "${SAFE_CLI}" pairing list feishu || warn "pairing list failed"
else
  warn "safe-openclaw-cli.sh not found or not executable"
fi

if [[ -f "${STDERR_LOG}" ]]; then
  echo "--- recent feishu-related logs (last 120 lines filtered) ---"
  tail -n 120 "${STDERR_LOG}" | grep -Ei 'feishu|pair|message|permission|99991672|event|allowlist|access not configured' || true
else
  warn "stderr log not found: ${STDERR_LOG}"
fi

echo "== Suggested next action =="
echo "1) Verify openclaw.json channels.feishu fields first (enabled/connectionMode/accounts/dmPolicy)."
echo "2) If permission errors exist: add required Feishu scopes and publish a new app version."
echo "3) For first bind use dmPolicy=pairing, then switch to allowlist + allowFrom after success."
