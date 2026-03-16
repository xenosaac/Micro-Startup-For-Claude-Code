# Micro Startup Handoff

## What This Project Is

`Micro Startup` is a standalone automation scaffold extracted from the OpenBrowse overnight workflow work.

It is meant to be reusable across many repos, not tied to one product.

Core idea:
- `Product Lead` decides what matters next
- `Design Lead` decides how the UI/UX should behave
- `Engineer` is the only role that writes tracked source code

This is intentionally a small-team, founder-mode workflow:
- lightweight
- repo-local
- role-based
- transparent
- easy to adapt

It is **not** a new runtime platform or agent framework.
It is a workflow kit built on:
- `tmux`
- `caffeinate`
- `claude -p`
- repo-local prompts
- repo-local documents

## Why It Exists

The OpenBrowse-specific automation proved that:
- a repo can be iterated autonomously with Claude Code
- role separation is useful
- PM / Design should provide inputs
- Engineer should remain the only tracked-code writer by default

This project exists to make that pattern reusable and open-source-friendly.

## Current Structure

```text
Micro Startup/
  README.md
  NEXT_SESSION_HANDOFF.md
  .gitignore
  config/
    project.env.example
  prompts/
    engineer.md
    product_lead.md
    design_lead.md
  scripts/
    common.sh
    engineer_once.sh
    product_once.sh
    design_once.sh
    triad_ctl.sh
  templates/
    repo-docs/
      working_log.md
      product_lead.md
      design_lead.md
  examples/
    openbrowse/
      README.md
  logs/
  runtime/
```

## Current Design Decisions

### 1. Three-role default only

For now the scaffold intentionally keeps only:
- `Product Lead`
- `Design Lead`
- `Engineer`

Reason:
- this is the best default role split for a startup team under ~7
- more roles too early create fake complexity
- reviewer / QA / specialist roles can be added later

### 2. Engineer is the only tracked-code writer

This is the most important workflow rule.

Product and Design can run continuously, but they only update their own docs.
Engineer consumes those docs and lands code.

This avoids:
- merge complexity
- branch coordination overhead
- agent collisions in tracked source files

### 3. Dirty-worktree gating

If the target repo is dirty:
- Product Lead backs off
- Design Lead backs off
- Engineer continues repair / unfinished work

This is deliberate.
It keeps code execution single-threaded and stable.

### 4. Repo-targeted by config

The new project does not hardcode OpenBrowse paths into the logic.
Instead it uses:
- `TARGET_REPO`
- repo-relative doc paths
- engineer branch name
- tmux session name
- Claude binary path

from:
- `config/project.env`

Only `project.env.example` exists right now.

## What Was Ported vs. What Was Generalized

### Generalized

- triad control pattern
- role prompts
- engineer/product/design single-iteration scripts
- repo-local document contract
- startup-style workflow rules

### Not Yet Generalized Fully

- cadence values are still hardcoded in shell loops
- branch policy is simple and single-engineer-only
- failure-analysis is not yet a reusable plugin/module
- OpenBrowse-specific learnings are only partially reflected in the generic docs

## Important Intent

This project should be positioned as:
- a `repo-local autonomous workflow scaffold`
- a `multi-role Claude Code supervisor for startups`
- a small, composable, understandable automation kit

It should **not** be positioned as:
- a huge agent platform
- a black-box orchestration engine
- “OpenClaw clone”

The reusable value is the workflow productization, not exotic infrastructure.

## What Still Needs Work

### High priority

1. Create a real `config/project.env`
- Right now only `config/project.env.example` exists.
- To actually run `Micro Startup`, a real local config file needs to be created.

2. End-to-end run against a target repo
- It has not yet been fully exercised from inside `Micro Startup` against a repo target.
- Best first test target is OpenBrowse itself.

3. Improve logging clarity
- Current logs are basic.
- Might want:
  - one role = one clear log
  - cleaner success/failure markers
  - optional iteration summaries

4. Add a cleaner install/setup path
- likely `setup.sh` or a short bootstrap flow
- maybe command to copy templates into a target repo

### Medium priority

5. Make role cadence configurable
- current sleep intervals are embedded in `triad_ctl.sh`
- should probably move into config

6. Formalize extension path for future roles
- likely next optional roles:
  - `Reviewer`
  - `QA / Reliability`
- but do not add them yet unless truly needed

7. Better repo adaptation docs
- how to target a frontend app
- how to target a backend service
- how to target a data/ML repo

8. Create one or two more examples
- OpenBrowse example exists
- later add:
  - generic web app example
  - backend service example

### Lower priority

9. Packaging / open-source polish
- license
- repo name decision
- contribution guidelines
- screenshots / diagrams
- “why this exists” write-up

## Suggested Next Steps

If starting a new session specifically for `Micro Startup`, a strong next sequence is:

1. create `config/project.env`
2. point it at OpenBrowse as the first live target
3. run `./scripts/triad_ctl.sh start`
4. verify that:
   - Product/Design only modify their docs
   - Engineer alone modifies tracked code
   - dirty-worktree gating works
5. clean up any issues discovered in real execution
6. then improve README/setup/install flow

## Open Questions

These are worth deciding later:

- Should `Micro Startup` keep only the three-role default, or ship optional extra roles in a separate `extensions/` area?
- Should setup remain pure shell, or have a tiny generator command?
- Should repo doc templates stay minimal, or offer “lean” and “strict” variants?
- What should the open-source repo be named publicly? `Micro Startup` is a good working name, but maybe not final.

## Relationship To OpenBrowse

OpenBrowse still has its own local automation in:
- `/Users/isaaczhang/Desktop/AGENT/Project_OpenBrowse/.claude/overnight`

That work should remain separate from `Micro Startup`.

`Micro Startup` should become the clean, reusable descendant of that work, not a direct replacement in-place.

## Final Note For The Next Session

Do not treat this project as “done because the files exist”.

The extraction is complete at the scaffold level, but the project still needs:
- real config
- real target-repo run
- real usability polish

The right mindset for the next session is:
- verify
- simplify
- make it reusable
- keep the three-role workflow sharp
- avoid premature complexity
