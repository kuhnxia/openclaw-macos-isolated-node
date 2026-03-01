#!/usr/bin/env bash
set -euo pipefail

SERVICE_USER="${SERVICE_USER:-svc_openclaw}"
SERVICE_PORT="${SERVICE_PORT:-3030}"

pass() { printf '[PASS] %s\n' "$1"; }
warn() { printf '[WARN] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; }

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

echo "== OpenClaw preflight (read-only checks) =="

if [[ "$(uname -s)" == "Darwin" ]]; then
  pass "Detected macOS ($(sw_vers -productVersion 2>/dev/null || echo unknown))"
else
  fail "This script is intended for macOS"
fi

for cmd in launchctl zsh node npm; do
  if has_cmd "$cmd"; then
    pass "Command available: $cmd"
  else
    fail "Missing command: $cmd"
  fi
done

if id "$SERVICE_USER" >/dev/null 2>&1; then
  pass "Service user exists: $SERVICE_USER"
else
  warn "Service user not found: $SERVICE_USER (create it in System Settings first)"
fi

for dir in \
  "/Users/$SERVICE_USER/apps" \
  "/Users/$SERVICE_USER/etc" \
  "/Users/$SERVICE_USER/var/openclaw" \
  "/Users/$SERVICE_USER/logs/openclaw"; do
  if [[ -d "$dir" ]]; then
    pass "Directory exists: $dir"
  else
    warn "Directory missing: $dir"
  fi
done

if lsof -nP -iTCP:"$SERVICE_PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  warn "Port $SERVICE_PORT is already in use"
else
  pass "Port $SERVICE_PORT is available"
fi

echo "== Preflight complete =="
