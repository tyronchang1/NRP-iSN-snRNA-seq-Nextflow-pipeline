---
name: project-behavior-rules
description: 11 binding behavioral rules from .claude/rules/07_behavior.md — no inline edits, SLURM autonomy, pipeline auto-fix, subagent constraints block, troubleshoot dirs, state-before-read, grill-before-edit, Stage 05 gone, WORKFLOW/NEXTFLOW audience, SKILL.md not slash commands, propagate file renames/deletes/path changes everywhere
metadata:
  type: project
---

All 10 rules live authoritatively in `.claude/rules/07_behavior.md`. This memory entry is a summary index — always re-read the rule file when you need exact wording.

## Rule 1 — No inline edits
Never use Edit or Write on `.R` or `.nf`/`nextflow.config` files. Always route through agents.
- `.R` files → `scrna-seq-script-agent`
- `.nf` / `nextflow.config` → `nextflow-script-agent`
**Why:** User caught repeated inline edits. "Rule is the rule. Let agents handle it."
**Sequence:** Grill (one question at a time) → spawn agent → spawn script-review-agent → report done.

## Rule 2 — SLURM always autonomous
Never give the user SLURM commands. Run `scancel` and `sbatch` via Bash yourself. Chain with `--dependency=afterok` as needed.
**Why:** User said "you should resubmit by yourself all the time."

## Rule 3 — Pipeline monitoring
Check pipeline logs every 30 min via `ScheduleWakeup` at 1800s. Fix errors and resubmit without asking permission.
**Why:** User said "if you see errors just fix it without my permission" (2026-05-21).

## Rule 4 — Subagent constraints block
Every Agent tool call must include this block verbatim:
```
## User constraints (mandatory — apply to all decisions)
- Always resubmit SLURM jobs yourself — never give the user commands to run
- State success criteria before any Edit/Write (task-gate: stop and wait for confirmation unless already confirmed in this prompt)
- Update the relevant REPORT.md after every file change, without being asked
- Spawn script-review-agent after every R or Nextflow edit before reporting done
- Do not ask permission for shell script edits in r_install/
```
**Why:** Without this block, subagents ask for permission, miss REPORT.md updates, and skip the task-gate.

## Rule 5 — Troubleshoot dirs
Before concluding any root cause diagnosis, read: `compact/`, `r_install/`, `r_install/logs/`.
**Why:** Missing this context leads to misdiagnosis.

## Rule 6 — State before reading
Before reading any file not explicitly referenced by the user, state what you will read and why.
**Why:** Silent file reads violate Principle 1 (don't assume — surface what you're doing).

## Rule 7 — Grill before any script edit
Before writing or editing any R or Nextflow script — including before spawning any subagent — grill one question at a time. Non-negotiable even if the request seems clear.
**Why:** `04_clustering.R` was written twice because Harmony strategy and variable gene sweep were not confirmed first.

## Rule 8 — Pipeline ends at Stage 04
Stage 05 (MergePublicDatasets / DRG atlas integration) was removed 2026-05-21. Do not reference, implement, stub, or suggest Stage 05.
**Why:** User decision — the `04_seu_clustered_{track}.rds` from Stage 04 is the final pipeline output.

## Rule 9 — WORKFLOW.md / NEXTFLOW.md audience
- `md_files/WORKFLOW.md` → Claude + `scrna-seq-script-agent` (R stages 01–04)
- `md_files/NEXTFLOW.md` → `nextflow-script-agent` (Nextflow modules)
Do not cross-pollinate content between them.

## Rule 10 — SKILL.md files are agent instructions
`.claude/skills/*/SKILL.md` files are read by `scrna-seq-script-agent` and `script-review-agent` at session start. They are NOT interactive slash commands.

## Rule 11 — Propagate file renames / deletes / path changes everywhere
Whenever any file is renamed, deleted, moved, or any path string changes: immediately grep all `*.md`, `*.R`, `*.sh`, `*.nf`, `*.config`, and `.claude/**/*.md` for the old name/path and update every reference found. Re-run grep to confirm zero stale references remain. Log all updated files to REPORT.md.
**Why:** Silent renames break references across agent prompts, CLAUDE.md, run scripts, and R scripts without any error — the Biologist_Chat.md move in session 16 required manual fixes to 4 files.

---

**How to apply:** These rules govern every session. When in doubt, re-read `.claude/rules/07_behavior.md` for exact wording.
