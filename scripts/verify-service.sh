#!/usr/bin/env bash
set -euo pipefail

SERVICE_LABEL="${SERVICE_LABEL:-com.openclaw.service}"
SERVICE_USER="${SERVICE_USER:-svc_openclaw}"
SERVICE_HOME="${SERVICE_HOME:-/Users/${SERVICE_USER}}"
SERVICE_PORT="${SERVICE_PORT:-3030}"
STDERR_LOG="${STDERR_LOG:-${SERVICE_HOME}/logs/openclaw/stderr.log}"
LOG_LINES="${LOG_LINES:-200}"
SAFE_CLI="$(cd "$(dirname "$0")" && pwd)/safe-openclaw-cli.sh"

pass() { printf '[PASS] %s\n' "$1"; }
warn() { printf '[WARN] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; }

ok=true

echo "== OpenClaw service verification =="

if sudo launchctl print "system/${SERVICE_LABEL}" >/tmp/openclaw_launchctl_check.txt 2>/tmp/openclaw_launchctl_err.txt; then
  pass "launchctl can read service: system/${SERVICE_LABEL}"
  if grep -q "state = running" /tmp/openclaw_launchctl_check.txt; then
    pass "Service state is running"
  else
    warn "Service is not in running state"
    ok=false
  fi
else
  fail "Unable to read launchctl service status"
  warn "Details: $(tr '\n' ' ' </tmp/openclaw_launchctl_err.txt | sed 's/  */ /g')"
  ok=false
fi

if lsof -nP -iTCP:"${SERVICE_PORT}" -sTCP:LISTEN >/tmp/openclaw_port_check.txt 2>/dev/null; then
  pass "Port ${SERVICE_PORT} is listening"
else
  fail "Port ${SERVICE_PORT} is not listening"
  ok=false
fi

if ps -o user,pid,command -ax | grep -E "[o]penclaw|[n]ode.*openclaw" >/tmp/openclaw_ps_check.txt 2>/dev/null; then
  if grep -q "^${SERVICE_USER}[[:space:]]" /tmp/openclaw_ps_check.txt; then
    pass "Found process owned by ${SERVICE_USER}"
  else
    warn "OpenClaw-like process found, but owner is not ${SERVICE_USER}"
    ok=false
  fi
else
  warn "No OpenClaw-like process found in process list"
  ok=false
fi

if [[ -x "${SAFE_CLI}" ]]; then
  echo "--- Channel probe (service user) ---"
  if "${SAFE_CLI}" channels status --probe; then
    pass "channels status --probe succeeded"
  else
    warn "channels status --probe failed"
    ok=false
  fi
else
  warn "safe-openclaw-cli.sh not found or not executable; skip channel probe"
fi

if [[ -f "${STDERR_LOG}" ]]; then
  echo "--- Last ${LOG_LINES} lines of stderr (${STDERR_LOG}) ---"
  tail -n "${LOG_LINES}" "${STDERR_LOG}" || true

  # blocking patterns
  if tail -n "${LOG_LINES}" "${STDERR_LOG}" | grep -Eqi 'Config invalid|Unknown model|permission denied|EACCES|No API key|rate limit reached|gateway token missing|too many failed authentication attempts'; then
    warn "Blocking-like errors detected in recent logs"
    ok=false
  else
    pass "No blocking-like error keywords found in recent logs"
  fi

  # ignorable patterns
  if tail -n "${LOG_LINES}" "${STDERR_LOG}" | grep -Eqi 'duplicate plugin id|pyenv: cannot rehash'; then
    warn "Found non-blocking warnings (duplicate plugin id / pyenv rehash)"
  fi
else
  warn "stderr log not found: ${STDERR_LOG}"
fi

if [[ "$ok" == true ]]; then
  echo "RESULT: 可用。建议：保留当前配置并记录可用快照。"
  exit 0
else
  echo "RESULT: 不可用。建议：按顺序检查 launchctl -> channel probe -> stderr 首错 -> openclaw.json(api/baseUrl/apiKey/models/primary/fallbacks) -> 权限。"
  exit 1
fi
