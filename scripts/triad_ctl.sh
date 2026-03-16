#!/bin/zsh

emulate -LR zsh
setopt pipefail nounset

SCRIPT_DIR="${0:A:h}"
PROJECT_DIR="${SCRIPT_DIR:h}"
source "${SCRIPT_DIR}/common.sh"

ENGINEER_LOG="${LOG_DIR}/engineer.log"
PRODUCT_LOG="${LOG_DIR}/product.log"
DESIGN_LOG="${LOG_DIR}/design.log"

usage() {
  cat <<EOF
Usage: ${0:t} <start|stop|restart|status|tail|attach>
EOF
}

tmux_has_session() {
  tmux has-session -t "${SESSION_NAME}" 2>/dev/null
}

start_window() {
  local window_name="$1"
  local command="$2"
  tmux new-window -d -t "${SESSION_NAME}" -n "${window_name}" /bin/zsh -il >/dev/null
  tmux send-keys -t "${SESSION_NAME}:${window_name}" "${command}" C-m
}

engineer_loop_command() {
  print -r -- "export HOME='${HOME}' PATH='${PATH}'; caffeinate -i /bin/zsh -lc 'cd ${PROJECT_DIR} && while true; do ${SCRIPT_DIR}/engineer_once.sh >> ${ENGINEER_LOG} 2>&1; rc=\$?; if [ \$rc -eq 0 ]; then sleep 15; else sleep 60; fi; done'"
}

product_loop_command() {
  print -r -- "export HOME='${HOME}' PATH='${PATH}'; caffeinate -i /bin/zsh -lc 'cd ${PROJECT_DIR} && while true; do ${SCRIPT_DIR}/product_once.sh >> ${PRODUCT_LOG} 2>&1; rc=\$?; if [ \$rc -eq 0 ]; then sleep 900; else sleep 300; fi; done'"
}

design_loop_command() {
  print -r -- "export HOME='${HOME}' PATH='${PATH}'; caffeinate -i /bin/zsh -lc 'cd ${PROJECT_DIR} && while true; do ${SCRIPT_DIR}/design_once.sh >> ${DESIGN_LOG} 2>&1; rc=\$?; if [ \$rc -eq 0 ]; then sleep 900; else sleep 300; fi; done'"
}

cmd_start() {
  if tmux_has_session; then
    print -r -- "Triad session already running: ${SESSION_NAME}"
    print -r -- "Attach: tmux attach -t ${SESSION_NAME}"
    return 0
  fi

  : > "${ENGINEER_LOG}"
  : > "${PRODUCT_LOG}"
  : > "${DESIGN_LOG}"

  tmux new-session -d -s "${SESSION_NAME}" -n engineer /bin/zsh -il >/dev/null || {
    print -r -- "Failed to create tmux session: ${SESSION_NAME}"
    return 1
  }
  tmux send-keys -t "${SESSION_NAME}:engineer" "$(engineer_loop_command)" C-m
  start_window product "$(product_loop_command)"
  start_window design "$(design_loop_command)"
  tmux select-window -t "${SESSION_NAME}:engineer" >/dev/null 2>&1 || true

  print -r -- "Started triad session: ${SESSION_NAME}"
  print -r -- "Attach: tmux attach -t ${SESSION_NAME}"
  print -r -- "Logs:"
  print -r -- "- ${ENGINEER_LOG}"
  print -r -- "- ${PRODUCT_LOG}"
  print -r -- "- ${DESIGN_LOG}"
}

cmd_stop() {
  if tmux_has_session; then
    tmux kill-session -t "${SESSION_NAME}"
    print -r -- "Stopped triad tmux session: ${SESSION_NAME}"
  else
    print -r -- "Triad is not running"
  fi
}

cmd_restart() {
  cmd_stop
  cmd_start
}

cmd_status() {
  print -r -- "Session: ${SESSION_NAME}"
  print -r -- "Automation project: ${PROJECT_DIR}"
  print -r -- "Target repo: ${TARGET_REPO}"
  print -r -- "Mode: Product/Design provide inputs; Engineer is the only tracked-code writer"
  print -r -- "Engineer branch: ${ENGINEER_BRANCH}"
  print -r -- "Working log: ${WORKING_LOG_REL}"
  print -r -- "Product doc: ${PRODUCT_DOC_REL}"
  print -r -- "Design doc: ${DESIGN_DOC_REL}"

  if tmux_has_session; then
    print -r -- "tmux: running"
    tmux list-windows -t "${SESSION_NAME}" -F "${SESSION_NAME}:#I #W (active=#{window_active})"
  else
    print -r -- "tmux: not running"
  fi

  print -r -- "Logs:"
  print -r -- "- engineer: ${ENGINEER_LOG}"
  print -r -- "- product: ${PRODUCT_LOG}"
  print -r -- "- design: ${DESIGN_LOG}"
}

cmd_tail() {
  touch "${ENGINEER_LOG}" "${PRODUCT_LOG}" "${DESIGN_LOG}"
  tail -n 120 -f "${ENGINEER_LOG}" "${PRODUCT_LOG}" "${DESIGN_LOG}"
}

cmd_attach() {
  if ! tmux_has_session; then
    print -r -- "Triad session is not running"
    return 1
  fi
  exec tmux attach -t "${SESSION_NAME}"
}

case "${1:-}" in
  start)
    cmd_start
    ;;
  stop)
    cmd_stop
    ;;
  restart)
    cmd_restart
    ;;
  status)
    cmd_status
    ;;
  tail)
    cmd_tail
    ;;
  attach)
    cmd_attach
    ;;
  *)
    usage
    exit 1
    ;;
esac
