# Micro Startup

`Micro Startup` is a repo-local Claude Code automation scaffold for small startup teams.

It is built around three roles:
- `Product Lead`
- `Design Lead`
- `Engineer`

The model is intentionally simple:
- Product Lead decides what matters next.
- Design Lead decides how the UI and UX should behave.
- Engineer is the only role that writes tracked product code.

This keeps the workflow founder-mode and fast:
- decision inputs can evolve continuously
- code still moves in one verified stream
- no heavy orchestration platform is required

## What It Is

This project is not a new daemon runtime.

It is a thin, transparent workflow layer built from standard tools:
- `tmux`
- `caffeinate`
- `claude -p`
- repo-local prompts
- repo-local working documents

The novel part is the workflow contract, not the low-level primitives.

## Project Layout

```text
Micro Startup/
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

## How It Works

`triad_ctl.sh` starts one tmux session with three loops:
- `engineer`
- `product`
- `design`

All three loops run continuously, but only the Engineer writes tracked source code.

When the target repo is dirty:
- Engineer stays active and continues the unfinished task.
- Product Lead and Design Lead back off until the worktree is clean again.

When the target repo is clean:
- Product Lead can refine priorities and acceptance criteria.
- Design Lead can refine UI rules and design tasks.
- Engineer reads those inputs and executes one verified increment at a time.

## Setup

1. Copy the repo-document templates into your target repo:
   - `templates/repo-docs/working_log.md`
   - `templates/repo-docs/product_lead.md`
   - `templates/repo-docs/design_lead.md`

2. Create a local config:

```bash
cp config/project.env.example config/project.env
```

3. Edit `config/project.env`:
   - set `TARGET_REPO`
   - adjust document paths if needed
   - set your preferred branch name
   - set the Claude binary path if needed

4. Start the triad:

```bash
./scripts/triad_ctl.sh start
```

Check status:

```bash
./scripts/triad_ctl.sh status
./scripts/triad_ctl.sh tail
```

Stop it:

```bash
./scripts/triad_ctl.sh stop
```

## Assumptions

- macOS
- `tmux` installed
- `caffeinate` available
- Claude Code CLI already authenticated in the shell environment where you run the loops

## Suggested Open-Source Direction

Good default roles for small startup teams:
- `Product Lead`
- `Design Lead`
- `Engineer`

Good future optional roles:
- `Reviewer`
- `QA / Reliability`
- `Specialist Engineer`

But this repo intentionally starts with the smallest useful set.
