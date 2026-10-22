#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <vm-external-ip-or-hostname> <ssh-username> <private-key-path>" >&2
  exit 2
fi

VM_HOST="$1"
SSH_USER="$2"
KEY_PATH="$3"
LOCAL_HOST="127.0.0.1"
LOCAL_PORT="5678"
REMOTE_HOST="127.0.0.1"
REMOTE_PORT="5678"

if [[ ! -f "$KEY_PATH" ]]; then
  echo "SSH private key not found: $KEY_PATH" >&2
  exit 1
fi

chmod 600 "$KEY_PATH"
echo "Opening SSH tunnel: http://${LOCAL_HOST}:${LOCAL_PORT}"
echo "Keep this process running. Press Ctrl+C to close the tunnel."
exec ssh \
  -i "$KEY_PATH" \
  -o ExitOnForwardFailure=yes \
  -o ServerAliveInterval=30 \
  -o ServerAliveCountMax=3 \
  -N \
  -L "${LOCAL_HOST}:${LOCAL_PORT}:${REMOTE_HOST}:${REMOTE_PORT}" \
  "${SSH_USER}@${VM_HOST}"
