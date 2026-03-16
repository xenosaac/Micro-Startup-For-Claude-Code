#!/bin/zsh

emulate -LR zsh
setopt pipefail nounset

SCRIPT_DIR="${0:A:h}"
PROJECT_DIR="${SCRIPT_DIR:h}"
source "${SCRIPT_DIR}/common.sh"

PROMPT_FILE="${PROJECT_DIR}/prompts/product_lead.md"
SESSION_FILE="${RUNTIME_DIR}/product_session.json"

log() {
  print -r -- "[$(timestamp)] [product] $*"
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

  log "starting fresh Product Lead session ${session_id}"
  json_write_role_session "${SESSION_FILE}" "${session_id}" "${created_at}" "${now_utc}"
}

build_iteration_prompt() {
  cat <<EOF
Run exactly one unattended Product Lead iteration in the target repository.

Target repository: ${TARGET_REPO}
Primary writable document: ${PRODUCT_DOC_REL}

Workflow:
1. Read ${PRODUCT_DOC_REL}, ${WORKING_LOG_REL}, and ${DESIGN_DOC_REL} if present.
2. Inspect the current repo only as needed to understand product reality.
3. Improve priorities, requirements, acceptance criteria, failure-driven direction, competitor insight, and user-facing product clarity.
4. Update ${PRODUCT_DOC_REL} only.
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
if [[ ! -f "${PRODUCT_DOC}" ]]; then
  log "Product Lead doc is missing: ${PRODUCT_DOC}"
  exit 1
fi

if target_has_dirty_tree; then
  log "tracked worktree is dirty; skipping Product Lead iteration until Engineer repairs it"
  exit 0
fi

begin_iteration_session
iteration_prompt="$(build_iteration_prompt)"
tmp_output="$(mktemp -t micro-startup-product-XXXXXX)"
trap 'rm -f "${tmp_output}"' EXIT INT TERM HUP

if ! run_claude "${tmp_output}" "${iteration_prompt}"; then
  cat "${tmp_output}"
  log "Product Lead iteration failed"
  exit 1
fi

cat "${tmp_output}"

if target_has_dirty_tree; then
  log "Product Lead iteration modified tracked files; this is not allowed"
  exit 1
fi

log "Product Lead iteration completed"
