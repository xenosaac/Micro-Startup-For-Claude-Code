#!/bin/zsh

emulate -LR zsh
setopt pipefail nounset

SCRIPT_DIR="${0:A:h}"
PROJECT_DIR="${SCRIPT_DIR:h}"
CONFIG_FILE="${PROJECT_DIR}/config/project.env"

if [[ ! -f "${CONFIG_FILE}" ]]; then
  print -r -- "Missing config: ${CONFIG_FILE}"
  print -r -- "Create it from config/project.env.example first."
  exit 1
fi

source "${CONFIG_FILE}"

: "${TARGET_REPO:?TARGET_REPO is required}"

CLAUDE_BIN="${CLAUDE_BIN:-${HOME}/.local/bin/claude}"
CLAUDE_MODEL="${CLAUDE_MODEL:-opus}"
ENGINEER_BRANCH="${ENGINEER_BRANCH:-codex/micro-startup}"
WORKING_LOG_REL="${WORKING_LOG_REL:-docs/working_log.md}"
PRODUCT_DOC_REL="${PRODUCT_DOC_REL:-docs/product_lead.md}"
DESIGN_DOC_REL="${DESIGN_DOC_REL:-docs/design_lead.md}"
SESSION_NAME="${SESSION_NAME:-micro-startup}"

WORKING_LOG="${TARGET_REPO}/${WORKING_LOG_REL}"
PRODUCT_DOC="${TARGET_REPO}/${PRODUCT_DOC_REL}"
DESIGN_DOC="${TARGET_REPO}/${DESIGN_DOC_REL}"
LOG_DIR="${PROJECT_DIR}/logs"
RUNTIME_DIR="${PROJECT_DIR}/runtime"

export PATH="${HOME}/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
mkdir -p "${LOG_DIR}" "${RUNTIME_DIR}"

timestamp() {
  /bin/date "+%Y-%m-%d %H:%M:%S"
}

utc_now() {
  /bin/date -u "+%Y-%m-%dT%H:%M:%SZ"
}

ensure_target_repo() {
  if [[ ! -d "${TARGET_REPO}/.git" ]]; then
    print -r -- "TARGET_REPO is not a git repo: ${TARGET_REPO}"
    exit 1
  fi
}

target_has_dirty_tree() {
  [[ -n "$(git -C "${TARGET_REPO}" status --porcelain)" ]]
}

json_read() {
  local file="$1"
  local key="$2"
  if [[ ! -f "${file}" ]]; then
    return 0
  fi

  node -e '
    const fs = require("fs");
    const [file, key] = process.argv.slice(1);
    const data = JSON.parse(fs.readFileSync(file, "utf8"));
    const value = data[key];
    if (value !== undefined && value !== null) process.stdout.write(String(value));
  ' "${file}" "${key}" 2>/dev/null
}

json_write_engineer_session() {
  local file="$1"
  local session_id="$2"
  local branch="$3"
  local created_at="$4"
  local last_bootstrapped_at="$5"

  node -e '
    const fs = require("fs");
    const [file, sessionId, branch, createdAt, lastBootstrappedAt] = process.argv.slice(1);
    fs.writeFileSync(file, JSON.stringify({
      session_id: sessionId,
      branch,
      created_at: createdAt,
      last_bootstrapped_at: lastBootstrappedAt
    }, null, 2) + "\n");
  ' "${file}" "${session_id}" "${branch}" "${created_at}" "${last_bootstrapped_at}"
}

json_write_role_session() {
  local file="$1"
  local session_id="$2"
  local created_at="$3"
  local last_bootstrapped_at="$4"

  node -e '
    const fs = require("fs");
    const [file, sessionId, createdAt, lastBootstrappedAt] = process.argv.slice(1);
    fs.writeFileSync(file, JSON.stringify({
      session_id: sessionId,
      created_at: createdAt,
      last_bootstrapped_at: lastBootstrappedAt
    }, null, 2) + "\n");
  ' "${file}" "${session_id}" "${created_at}" "${last_bootstrapped_at}"
}

ensure_engineer_branch() {
  local current_branch
  current_branch="$(git -C "${TARGET_REPO}" branch --show-current)"
  if [[ "${current_branch}" == "${ENGINEER_BRANCH}" ]]; then
    return 0
  fi

  if target_has_dirty_tree; then
    print -r -- "Refusing to switch branches with a dirty worktree (${current_branch} -> ${ENGINEER_BRANCH})"
    exit 1
  fi

  if git -C "${TARGET_REPO}" rev-parse --verify "${ENGINEER_BRANCH}" >/dev/null 2>&1; then
    git -C "${TARGET_REPO}" checkout "${ENGINEER_BRANCH}"
  else
    git -C "${TARGET_REPO}" checkout -b "${ENGINEER_BRANCH}"
  fi
}
