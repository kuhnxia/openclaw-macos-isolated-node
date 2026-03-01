#!/usr/bin/env bash
set -euo pipefail

SERVICE_LABEL="${SERVICE_LABEL:-com.openclaw.service}"
SERVICE_USER="${SERVICE_USER:-svc_openclaw}"
SERVICE_PORT="${SERVICE_PORT:-3030}"
STDERR_LOG="${STDERR_LOG:-/Users/${SERVICE_USER}/logs/openclaw/stderr.log}"

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

if [[ -f "${STDERR_LOG}" ]]; then
  warn "Last 100 lines of stderr log (${STDERR_LOG}):"
  tail -n 100 "${STDERR_LOG}" || true
else
  warn "stderr log not found: ${STDERR_LOG}"
fi

if [[ "$ok" == true ]]; then
  echo "RESULT: 可用。建议：保留当前配置，并记录版本与配置快照。"
  exit 0
else
  echo "RESULT: 不可用。建议：按顺序检查 launchctl 状态 -> stderr 首错 -> 端口冲突 -> 权限与变量。"
  exit 1
fi
