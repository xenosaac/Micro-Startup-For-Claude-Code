#!/bin/zsh

emulate -LR zsh
setopt pipefail nounset

SCRIPT_DIR="${0:A:h}"
PROJECT_DIR="${SCRIPT_DIR:h}"
source "${SCRIPT_DIR}/common.sh"

PROMPT_FILE="${PROJECT_DIR}/prompts/engineer.md"
SESSION_FILE="${RUNTIME_DIR}/engineer_session.json"

log() {
  print -r -- "[$(timestamp)] [engineer] $*"
}

ensure_session_file() {
  local now_utc
  local branch
  local created_at

  now_utc="$(utc_now)"
  branch="$(json_read "${SESSION_FILE}" branch)"
  created_at="$(json_read "${SESSION_FILE}" created_at)"

  if [[ -z "${branch}" ]]; then
    branch="${ENGINEER_BRANCH}"
  fi
  if [[ -z "${created_at}" ]]; then
    created_at="${now_utc}"
  fi

  json_write_engineer_session "${SESSION_FILE}" "" "${branch}" "${created_at}" "${now_utc}"
}

begin_iteration_session() {
  local now_utc
  local branch
  local created_at
  local session_id

  now_utc="$(utc_now)"
  branch="$(json_read "${SESSION_FILE}" branch)"
  created_at="$(json_read "${SESSION_FILE}" created_at)"
  session_id="$(uuidgen | tr "[:upper:]" "[:lower:]")"

  if [[ -z "${branch}" ]]; then
    branch="${ENGINEER_BRANCH}"
  fi
  if [[ -z "${created_at}" ]]; then
    created_at="${now_utc}"
  fi

  log "starting fresh session ${session_id}"
  json_write_engineer_session "${SESSION_FILE}" "${session_id}" "${branch}" "${created_at}" "${now_utc}"
}

build_iteration_prompt() {
  local tree_state="$1"
  local extra_docs="- (none)"

  if [[ -f "${PRODUCT_DOC}" ]]; then
    extra_docs=""
    extra_docs+=$'- '"${PRODUCT_DOC_REL}"$'\n'
  fi
  if [[ -f "${DESIGN_DOC}" ]]; then
    if [[ "${extra_docs}" == "- (none)" ]]; then
      extra_docs=""
    fi
    extra_docs+=$'- '"${DESIGN_DOC_REL}"$'\n'
  fi

  cat <<EOF
Run exactly one unattended Engineer iteration in the target repository.

Target repository: ${TARGET_REPO}
Primary source of truth: ${WORKING_LOG_REL}
Required branch: $(json_read "${SESSION_FILE}" branch)
Working tree status at start: ${tree_state}
Additional role documents to read when present:
${extra_docs}

Workflow:
1. Read ${WORKING_LOG_REL} in full before making any code changes.
2. Read Product Lead and Design Lead documents when present.
3. Inspect git status and the relevant code.
4. If the worktree is dirty, continue the current unfinished task and do not switch tasks.
5. If the worktree is clean, continue any unfinished task recorded in ${WORKING_LOG_REL}; only choose a new task if no unfinished task exists.
6. Before editing code, update ${WORKING_LOG_REL} with your understanding and plan.
7. Implement one smallest useful increment.
8. Run the relevant verification commands yourself.
9. On success, update ${WORKING_LOG_REL}, create exactly one local commit, and leave the worktree clean.
10. On failure or blocker, update ${WORKING_LOG_REL} and leave the worktree dirty for the next repair iteration.
11. Product Lead and Design Lead are input roles only. You are the only role that writes tracked source code.
12. Do not rewrite ${PRODUCT_DOC_REL} or ${DESIGN_DOC_REL}.
13. Do not ask the user questions. Do not spawn sub-agents. Do not push, pull, or rebase. Do not change the branch.

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
if [[ ! -f "${WORKING_LOG}" ]]; then
  log "working log is missing: ${WORKING_LOG}"
  exit 1
fi

ensure_session_file
ensure_engineer_branch
begin_iteration_session

tree_state="clean"
if target_has_dirty_tree; then
  tree_state="dirty"
fi

iteration_prompt="$(build_iteration_prompt "${tree_state}")"
tmp_output="$(mktemp -t micro-startup-engineer-XXXXXX)"
trap 'rm -f "${tmp_output}"' EXIT INT TERM HUP

if ! run_claude "${tmp_output}" "${iteration_prompt}"; then
  cat "${tmp_output}"
  log "engineer iteration failed"
  exit 1
fi

cat "${tmp_output}"

if target_has_dirty_tree; then
  log "Engineer finished but the worktree is still dirty; treating iteration as unfinished"
  exit 1
fi

log "engineer iteration completed with a clean worktree"
