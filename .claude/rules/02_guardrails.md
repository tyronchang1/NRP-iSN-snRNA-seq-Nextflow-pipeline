---
paths:
  - "/scratch/rmlab/rmlab_shared3/tyron/Rscriptv2/iSN/iSN_claude/**"
---

# Guardrails — Mandatory Rules

These rules override all other instructions.

1. **Do not modify files outside this directory.** The project root is `/scratch/rmlab/rmlab_shared3/tyron/Rscriptv2/iSN/iSN_claude/`. Do not read, write, or delete any file above this path. Any operation that would affect a path above the project root — including the parent directories `/scratch/rmlab/rmlab_shared3/tyron/Rscriptv2/iSN/`, `/scratch/rmlab/rmlab_shared3/tyron/`, or higher — requires explicit user consent before proceeding. The sole exception is `~/.claude/projects/` migrations triggered by a project rename, which follow the confirmation flow defined in `04_path-change-detection.md`.

2. **Do not delete any file without explicit user permission.** Always ask before deleting. Describe what will be deleted and why, and wait for confirmation.

3. **Do not proceed to the next stage without explicit user approval.** After completing all steps in a stage, stop and wait for the user to confirm. Update `md_files/STATUS.md` only after the user approves the completed stage.

4. **Check `md_files/STATUS.md` before starting any stage.** It tracks which stages are Implemented, In Progress, or Planned. Do not implement a stage already marked Implemented. Always update `md_files/STATUS.md` when a stage's status changes.

5. **After any step that produces a plot or graph, stop and discuss it with the user.** Present the output, ask if they are happy with it, and wait for their response. Do not proceed until the user confirms. If not satisfied, modify the plot and show it again. Repeat until approved.

6. **Read `md_files/WORKFLOW.md` and any relevant skill files first.** Before writing, editing, or executing any script for any stage (01–05), read `md_files/WORKFLOW.md` — it maps each stage to the relevant Claude Code skills to invoke. Then check `.claude/skills/` for a stage-specific skill file and read it if present. Do not skip either step.

7. **Do not read `md_files/IDEAS.md`.** This file is for the user's personal notes only and is not part of the pipeline instructions.
