#!/bin/bash

set -euo pipefail

REMOTE_HOST="${REMOTE_HOST:-root@192.168.0.33}"
SSH_KEY_PATH="${SSH_KEY_PATH:-$HOME/.ssh/id_ed25519_clarity}"
SSH_OPTS=(
  -i "$SSH_KEY_PATH"
  -o StrictHostKeyChecking=no
  -o UserKnownHostsFile=/dev/null
  -o LogLevel=ERROR
  -o ServerAliveInterval=30
  -o ServerAliveCountMax=3
  -o BatchMode=yes
)

REMOTE_LOG="/tmp/alpine-build.log"
REMOTE_STATUS="/tmp/alpine-build.status"
REMOTE_EXIT="/tmp/alpine-build.exit"
REMOTE_PID="/tmp/alpine-build.pid"
REMOTE_SUMMARY="/tmp/alpine-build-summary.txt"

TAIL_LINES="${LINES:-40}"

echo "🔍 Checking Alpine build status on ${REMOTE_HOST}"

status=$(ssh "${SSH_OPTS[@]}" "${REMOTE_HOST}" "if [ -f '${REMOTE_STATUS}' ]; then cat '${REMOTE_STATUS}'; else echo pending; fi" 2>/dev/null || echo pending)
exit_code=$(ssh "${SSH_OPTS[@]}" "${REMOTE_HOST}" "if [ -f '${REMOTE_EXIT}' ]; then cat '${REMOTE_EXIT}'; else echo ''; fi" 2>/dev/null || echo '')

pid_output=$(ssh "${SSH_OPTS[@]}" "${REMOTE_HOST}" "if [ -f '${REMOTE_PID}' ]; then cat '${REMOTE_PID}'; else echo ''; fi" 2>/dev/null || echo '')
if [[ -n "${pid_output}" ]]; then
  alive=$(ssh "${SSH_OPTS[@]}" "${REMOTE_HOST}" "if ps -p ${pid_output} >/dev/null 2>&1; then echo alive; else echo dead; fi" 2>/dev/null || echo unknown)
else
  alive="unknown"
fi

echo "Status      : ${status}"
[[ -n "${exit_code}" ]] && echo "Exit Code   : ${exit_code}"
[[ -n "${pid_output}" ]] && echo "Remote PID  : ${pid_output} (${alive})"

if ssh "${SSH_OPTS[@]}" "${REMOTE_HOST}" "test -f '${REMOTE_SUMMARY}'" >/dev/null 2>&1; then
  echo "--- Summary (${REMOTE_SUMMARY}) ---"
  ssh "${SSH_OPTS[@]}" "${REMOTE_HOST}" "cat '${REMOTE_SUMMARY}'"
  echo "-----------------------------------"
fi

if ssh "${SSH_OPTS[@]}" "${REMOTE_HOST}" "test -f '${REMOTE_LOG}'" >/dev/null 2>&1; then
  echo "--- Last ${TAIL_LINES} lines of ${REMOTE_LOG} ---"
  ssh "${SSH_OPTS[@]}" "${REMOTE_HOST}" "tail -n ${TAIL_LINES} '${REMOTE_LOG}'"
else
  echo "Log file ${REMOTE_LOG} not found yet."
fi

echo "Done."
