#!/usr/bin/env bash
set -e

TECHNITIUM_CONFIG_DIR="/config/technitium"
TECHNITIUM_APP="/opt/technitium/dns/DnsServerApp.dll"
TECHNITIUM_RUNTIME_CONFIG="/opt/technitium/dns/DnsServerApp.runtimeconfig.json"
OPTIONS_FILE="/data/options.json"
REQUIRED_DOTNET_MAJOR="10"

read_option() {
  local key="$1"
  local default_value="$2"

  if [ -f "${OPTIONS_FILE}" ]; then
    local value
    value=$(sed -nE "s/.*\"${key}\"[[:space:]]*:[[:space:]]*\"([^\"]*)\".*/\1/p" "${OPTIONS_FILE}" | tail -n 1)
    if [ -n "${value}" ]; then
      printf '%s' "${value}"
      return 0
    fi
  fi

  printf '%s' "${default_value}"
}

LOG_LEVEL=$(read_option "log_level" "info")

level_number() {
  case "$1" in
    trace) echo 0 ;;
    debug) echo 1 ;;
    info) echo 2 ;;
    warning) echo 3 ;;
    error) echo 4 ;;
    *) echo 2 ;;
  esac
}

LOG_LEVEL_NUMBER=$(level_number "${LOG_LEVEL}")

log() {
  local level="$1"
  shift
  if [ "$(level_number "${level}")" -ge "${LOG_LEVEL_NUMBER}" ]; then
    printf '[%s] [%s] %s\n' "$(date -Iseconds)" "${level^^}" "$*"
  fi
}

run_debug_command() {
  local description="$1"
  shift

  log debug "${description}"
  if [ "${LOG_LEVEL_NUMBER}" -le 1 ]; then
    "$@" 2>&1 | sed 's/^/[debug]   /' || true
  fi
}

require_file() {
  local path="$1"
  if [ ! -f "${path}" ]; then
    log error "Required file is missing: ${path}"
    exit 1
  fi
}

require_dotnet_runtime() {
  log info "Checking installed .NET runtimes"
  /usr/bin/dotnet --list-runtimes 2>&1 | sed 's/^/[dotnet] /'

  if ! /usr/bin/dotnet --list-runtimes | grep -Eq "^Microsoft\.NETCore\.App ${REQUIRED_DOTNET_MAJOR}\."; then
    log error "Microsoft.NETCore.App ${REQUIRED_DOTNET_MAJOR}.x is not installed in the add-on image."
    exit 1
  fi

  if ! /usr/bin/dotnet --list-runtimes | grep -Eq "^Microsoft\.AspNetCore\.App ${REQUIRED_DOTNET_MAJOR}\."; then
    log error "Microsoft.AspNetCore.App ${REQUIRED_DOTNET_MAJOR}.x is not installed in the add-on image."
    exit 1
  fi

  log info "Required .NET ${REQUIRED_DOTNET_MAJOR}.x runtimes are installed"
}

log_listeners() {
  if command -v ss >/dev/null 2>&1; then
    ss -lntup 2>&1 | sed 's/^/[listeners] /' || true
  else
    log warning "Cannot list listening sockets because 'ss' is not installed"
  fi
}

wait_for_port() {
  local port="$1"
  local name="$2"
  local attempts="${3:-30}"

  if ! command -v ss >/dev/null 2>&1; then
    log warning "Skipping ${name} listener check because 'ss' is not installed"
    return 0
  fi

  for attempt in $(seq 1 "${attempts}"); do
    if ss -lntup | grep -Eq ":${port}[[:space:]]"; then
      log info "${name} is listening on TCP port ${port}"
      return 0
    fi

    if ! kill -0 "${TECHNITIUM_PID}" 2>/dev/null; then
      log error "Technitium process exited before ${name} started listening"
      wait "${TECHNITIUM_PID}"
      exit $?
    fi

    log debug "Waiting for ${name} on TCP port ${port} (${attempt}/${attempts})"
    sleep 1
  done

  log warning "${name} did not start listening on TCP port ${port} within ${attempts} seconds"
  log warning "Current listening sockets:"
  log_listeners
}

shutdown() {
  log info "Stopping Technitium DNS Server"
  if [ -n "${TECHNITIUM_PID:-}" ] && kill -0 "${TECHNITIUM_PID}" 2>/dev/null; then
    kill -TERM "${TECHNITIUM_PID}"
    wait "${TECHNITIUM_PID}"
  fi
}

trap shutdown TERM INT

mkdir -p "${TECHNITIUM_CONFIG_DIR}"

log info "Starting Technitium DNS Server add-on"
log info "Configured wrapper log level: ${LOG_LEVEL}"
log info "Persistent data directory: ${TECHNITIUM_CONFIG_DIR}"
log info "Technitium application: ${TECHNITIUM_APP}"
log info "Container architecture: $(uname -m)"

require_file "${TECHNITIUM_APP}"
require_file "${TECHNITIUM_RUNTIME_CONFIG}"
require_dotnet_runtime

run_debug_command "Technitium runtime configuration" cat "${TECHNITIUM_RUNTIME_CONFIG}"
run_debug_command "Technitium application directory" ls -la /opt/technitium/dns
run_debug_command "Persistent data directory details" ls -la "${TECHNITIUM_CONFIG_DIR}"
run_debug_command "Listening sockets before Technitium start" log_listeners

log info "Launching Technitium DNS Server"
/usr/bin/dotnet "${TECHNITIUM_APP}" "${TECHNITIUM_CONFIG_DIR}" &
TECHNITIUM_PID=$!
log info "Technitium process started with PID ${TECHNITIUM_PID}"

wait_for_port 5380 "Technitium web UI" 60
wait_for_port 53 "Technitium DNS TCP service" 30

if [ "${LOG_LEVEL_NUMBER}" -le 1 ]; then
  log debug "Listening sockets after Technitium start"
  log_listeners
fi

log info "Technitium DNS Server is running; streaming application logs"
wait "${TECHNITIUM_PID}"
