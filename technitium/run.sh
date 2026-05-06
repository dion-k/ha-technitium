#!/usr/bin/env bash
set -e

TECHNITIUM_CONFIG_DIR="/config/technitium"
TECHNITIUM_APP="/opt/technitium/dns/DnsServerApp.dll"

mkdir -p "${TECHNITIUM_CONFIG_DIR}"

echo "Starting Technitium DNS Server"
echo "Persistent data directory: ${TECHNITIUM_CONFIG_DIR}"

exec /usr/bin/dotnet "${TECHNITIUM_APP}" "${TECHNITIUM_CONFIG_DIR}"
