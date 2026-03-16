#!/bin/zsh

emulate -LR zsh
setopt pipefail nounset

SCRIPT_DIR="${0:A:h}"
PROJECT_DIR="${SCRIPT_DIR:h}"
source "${SCRIPT_DIR}/common.sh"

PROMPT_FILE="${PROJECT_DIR}/prompts/design_lead.md"
SESSION_FILE="${RUNTIME_DIR}/design_session.json"

log() {
  print -r -- "[$(timestamp)] [design] $*"
}

begin_iteration_session() {
  local now_utc
  local session_id
  local created_at=""

  now_utc="$(utc_now)"
  session_id="$(uuidgen | tr "[:upper:]" "[:lower:]")"
  created_at="$(json_read "${SESSION_FILE}" created_at)"
  if [[ -z "${created_at}" ]]; then
    created_at="${now_utc}"
  fi

  log "starting fresh Design Lead session ${session_id}"
  json_write_role_session "${SESSION_FILE}" "${session_id}" "${created_at}" "${now_utc}"
}

build_iteration_prompt() {
  cat <<EOF
Run exactly one unattended Design Lead iteration in the target repository.

Target repository: ${TARGET_REPO}
Primary writable document: ${DESIGN_DOC_REL}

Workflow:
1. Read ${DESIGN_DOC_REL}, ${PRODUCT_DOC_REL}, and ${WORKING_LOG_REL}.
2. Inspect the current UI code only as needed.
3. Tighten design rules, UI direction, and engineer-ready implementation tasks.
4. Update ${DESIGN_DOC_REL} only.
5. Do not edit source code or any other tracked file.

Respond with a short human-readable summary only.
EOF
}

run_claude() {
  local output_file="$1"
  local iteration_prompt="$2"
  local prompt_text

  prompt_text="$(<"${PROMPT_FILE}")"
  "${CLAUDE_BIN}" -p \
    --model "${CLAUDE_MODEL}" \
    --dangerously-skip-permissions \
    --append-system-prompt "${prompt_text}" \
    --session-id "$(json_read "${SESSION_FILE}" session_id)" \
    "${iteration_prompt}" >"${output_file}" 2>&1
}

ensure_target_repo

if [[ ! -f "${PROMPT_FILE}" ]]; then
  log "prompt file is missing: ${PROMPT_FILE}"
  exit 1
fi
if [[ ! -f "${DESIGN_DOC}" ]]; then
  log "Design Lead doc is missing: ${DESIGN_DOC}"
  exit 1
fi

if target_has_dirty_tree; then
  log "tracked worktree is dirty; skipping Design Lead iteration until Engineer repairs it"
  exit 0
fi

begin_iteration_session
iteration_prompt="$(build_iteration_prompt)"
tmp_output="$(mktemp -t micro-startup-design-XXXXXX)"
trap 'rm -f "${tmp_output}"' EXIT INT TERM HUP

if ! run_claude "${tmp_output}" "${iteration_prompt}"; then
  cat "${tmp_output}"
  log "Design Lead iteration failed"
  exit 1
fi

cat "${tmp_output}"

if target_has_dirty_tree; then
  log "Design Lead iteration modified tracked files; this is not allowed"
  exit 1
fi

log "Design Lead iteration completed"
