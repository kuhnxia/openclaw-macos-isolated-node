#!/usr/bin/env bash
set -euo pipefail

SERVICE_USER="${SERVICE_USER:-svc_openclaw}"
SERVICE_PORT="${SERVICE_PORT:-3030}"
SERVICE_HOME="/Users/${SERVICE_USER}"
CONFIG_FILE="${SERVICE_HOME}/.openclaw/openclaw.json"
OPENCLAW_BIN="${SERVICE_HOME}/.local/npm/bin/openclaw"

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

for cmd in launchctl zsh node npm lsof python3; do
  if has_cmd "$cmd"; then
    pass "Command available: $cmd"
  else
    fail "Missing command: $cmd"
  fi
done

if has_cmd jq; then
  pass "Command available: jq"
else
  warn "Missing optional command: jq (recommended for config checks)"
fi

if has_cmd rg; then
  pass "Optional command available: rg"
else
  warn "Optional command missing: rg (use grep as fallback)"
fi

if id "$SERVICE_USER" >/dev/null 2>&1; then
  pass "Service user exists: $SERVICE_USER"
else
  warn "Service user not found: $SERVICE_USER (create it in System Settings first)"
fi

if [[ -d "$SERVICE_HOME" ]]; then
  pass "Service home exists: $SERVICE_HOME"
else
  warn "Service home missing: $SERVICE_HOME"
fi

for dir in \
  "${SERVICE_HOME}/apps" \
  "${SERVICE_HOME}/etc" \
  "${SERVICE_HOME}/var/openclaw" \
  "${SERVICE_HOME}/logs/openclaw" \
  "${SERVICE_HOME}/.openclaw"; do
  if [[ -d "$dir" ]]; then
    pass "Directory exists: $dir"
  else
    warn "Directory missing: $dir"
  fi
done

if [[ -x "$OPENCLAW_BIN" ]]; then
  pass "OpenClaw binary found: $OPENCLAW_BIN"
else
  warn "OpenClaw binary not found at expected path: $OPENCLAW_BIN"
fi

if lsof -nP -iTCP:"$SERVICE_PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  warn "Port $SERVICE_PORT is already in use"
else
  pass "Port $SERVICE_PORT is available"
fi

if [[ -f "$CONFIG_FILE" ]]; then
  pass "Config file found: $CONFIG_FILE"

  if [[ ! -r "$CONFIG_FILE" ]]; then
    warn "Config file is not readable by current user: $CONFIG_FILE"
    warn "Run with sudo to perform deep config checks, or fix file permission for read-only inspection"
    echo "== Preflight complete =="
    exit 0
  fi

  if has_cmd jq; then
    if jq . "$CONFIG_FILE" >/dev/null 2>&1; then
      pass "openclaw.json is valid JSON"
    else
      fail "openclaw.json has invalid JSON syntax"
    fi

    if jq -e '.models.providers.openai.baseURL?' "$CONFIG_FILE" >/dev/null; then
      fail "Found invalid key models.providers.openai.baseURL (use baseUrl)"
    fi

    if jq -e '.models.providers.openai.baseUrl?' "$CONFIG_FILE" >/dev/null; then
      pass "Found models.providers.openai.baseUrl"
    else
      warn "models.providers.openai.baseUrl not found"
    fi

    if jq -e '.models.providers.openai.models | type == "array" and length > 0' "$CONFIG_FILE" >/dev/null 2>&1; then
      pass "Found models.providers.openai.models[]"
    else
      warn "models.providers.openai.models[] is missing or empty"
    fi

    if jq -e '.models.providers.openai.apiKey? | type == "string" and length > 0' "$CONFIG_FILE" >/dev/null 2>&1; then
      pass "Found models.providers.openai.apiKey (value hidden)"
    else
      warn "models.providers.openai.apiKey is missing or empty"
    fi

    primary="$(jq -r '.agents.defaults.model.primary // empty' "$CONFIG_FILE")"
    if [[ -n "$primary" ]]; then
      if [[ "$primary" == */* ]]; then
        pass "agents.defaults.model.primary is provider-qualified: $primary"
      else
        warn "agents.defaults.model.primary should be provider-qualified, e.g. openai/$primary"
      fi
    else
      warn "agents.defaults.model.primary not found"
    fi

    if jq -e '.agents.defaults.model.fallbacks? | type == "array" and length > 0' "$CONFIG_FILE" >/dev/null 2>&1; then
      pass "Found agents.defaults.model.fallbacks[]"
    else
      warn "agents.defaults.model.fallbacks[] is missing or empty (recommended)"
    fi
  else
    warn "Skip deep config checks because jq is unavailable"
  fi
else
  warn "Config file not found: $CONFIG_FILE"
fi

echo "== Preflight complete =="
