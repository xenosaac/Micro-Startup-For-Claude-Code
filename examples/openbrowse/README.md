# OpenBrowse Example

This example shows how to point `Micro Startup` at the OpenBrowse repo.

Example local config:

```bash
cp config/project.env.example config/project.env
```

Then set:

```bash
TARGET_REPO="/Users/isaaczhang/Desktop/AGENT/Project_OpenBrowse"
ENGINEER_BRANCH="codex/claude-overnight"
WORKING_LOG_REL="docs/working_log.md"
PRODUCT_DOC_REL="docs/product_manager.md"
DESIGN_DOC_REL="docs/ui_design.md"
SESSION_NAME="claude-triad"
```

After that, start the triad from the `Micro Startup` project:

```bash
./scripts/triad_ctl.sh start
```

This leaves the OpenBrowse repo as the target repo, but moves the automation scaffold itself into a standalone, reusable project.
