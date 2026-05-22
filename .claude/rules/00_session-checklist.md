---
paths:
  - "/scratch/rmlab/rmlab_shared3/tyron/Rscriptv2/iSN/iSN_claude/**"
---

# Session-Start Checklist

This file is read FIRST, before all other rules. It defines every file that must be read at session start and every gate that must be checked before doing any work.

## `start` keyword trigger

If the user's first message is exactly `start`, execute this entire checklist explicitly and visibly — announce each step as you complete it so the user can verify compliance. Do not wait for any other input.

---

## Non-negotiable rule

**A checked item means you called the Read tool and received the file contents. No memory substitution. No "I already know this file." No skipping because the file "hasn't changed." Each item requires an actual Read tool call every session.**

Violating this rule — marking something done without reading it — is treated the same as ignoring a user instruction.

---

## Step 0 — Compact log (compaction trigger only)

Fires ONLY when the harness auto-compacts or the user runs `/compact`. Nothing else runs until this is done.

- [ ] Write `compact/compact_sessionNN.md` immediately — check the highest existing number in `compact/` first, then write the next one

After the compact log is written, continue with Steps 1–13 below.

---

## Step 1–7 — Rules (read ALL, in order)

Each item requires a Read tool call. Read the file. Apply its instructions for the rest of the session.

**Display rule:** Print each item as `- [ ] N. Read <file>` before the Read call, then update to `- [x] N. Read <file>` after it completes. One item at a time — do not batch reads and summarise after the fact.

- [ ] 1. Read `.claude/rules/01_principles.md`
- [ ] 2. Read `.claude/rules/02_guardrails.md`
- [ ] 3. Read `.claude/rules/03_task-gate.md`
- [ ] 4. Read `.claude/rules/04_path-change-detection.md`
- [ ] 5. Read `.claude/rules/05_update-report-on-change.md`
- [ ] 6. Read `.claude/rules/06_compact-log.md`
- [ ] 7. Read `.claude/rules/07_behavior.md`

**After reading step 7 — memory bootstrap (runs every session, no-op after first time):**

Find your personal project memory directory from the system context "auto memory" path (format: `~/.claude/projects/<hash>/memory/`).

**First — check `md_files/REPORT.md` for prior bootstrap entries.** Read `md_files/REPORT.md` and search for lines containing `[memory bootstrap]`. Any filename already logged there was already copied in a previous session — skip it entirely, no Read needed.

Files to bootstrap:

| Repo file | Memory filename | MEMORY.md pointer line |
|-----------|----------------|------------------------|
| `.claude/memory/project_behavior_rules.md` | `project_behavior_rules.md` | `- [Project: Behavioral rules](project_behavior_rules.md) — 11 binding rules from 07_behavior.md; covers no-inline-edits, SLURM autonomy, subagent constraints block, Stage 05 removal, rename/delete propagation, and more` |
| `.claude/memory/feedback_checklist_display.md` | `feedback_checklist_display.md` | `- [Feedback: Checklist display](feedback_checklist_display.md) — Print [ ] before and [x] after each Read call, one item at a time — never batch reads or summarize after the fact` |

For each file **not already logged in REPORT.md**, run this check independently:
1. Use the Read tool to attempt `<memory_dir>/<filename>`. If Read succeeds → file already exists, skip to the next file. If "File does not exist" → use the Write tool to copy the exact content from the repo file.
2. Use the Read tool to attempt `<memory_dir>/MEMORY.md`. If "File does not exist" → create it with the Write tool, then add the pointer line. If it exists → check whether the pointer line for this file is already present. If yes → skip. If no → append the pointer line.
3. Append this line to `md_files/REPORT.md`:
   `[memory bootstrap] <filename> copied to <memory_dir> on <date>`

This log entry is the authoritative record that bootstrap ran. On every subsequent session, REPORT.md is checked first — files already logged are skipped without any Read tool calls into the memory directory.

---

## Step 8 — Domain glossary

- [ ] 8. Read `.claude/skills/grill-with-docs/CONTEXT.md`

Challenge any term in the user's request that conflicts with the glossary before doing any work.

---

## Step 9–12 — Pipeline skills (read ALL)

These define the authoritative expected behavior for every stage. Read all four regardless of which stage is being worked on today.

- [ ] 9. Read `.claude/skills/ambient-rna-removal/SKILL.md`
- [ ] 10. Read `.claude/skills/doublet-removal/SKILL.md`
- [ ] 11. Read `.claude/skills/cell-filtering/SKILL.md`
- [ ] 12. Read `.claude/skills/clustering/SKILL.md`

---

## Step 13–15 — Project state (read ALL)

- [ ] 13. Read `md_files/WORKFLOW.md`
- [ ] 14. Read `md_files/STATUS.md` — gitignored; generated at runtime by `nextflow-stage-report-agent`. If the file does not exist, the pipeline has not run yet — skip this step. Step 18 (`nextflow-stage-report-agent`) will create it on first run.
- [ ] 15. Read `md_files/NEXTFLOW.md`

---

## Step 16–17 — Automated checks

Run these after reading all files above.

- [ ] 16. Run path-change detection — grep `.R` scripts for `setwd()`, `Read10X()`, `write10xCounts()` and compare against disk (per `04_path-change-detection.md`)
- [ ] 17. Run REPORT.md staleness check — find recently modified scripts and md files not yet logged (per `05_update-report-on-change.md`)

---

## Step 18–19 — Auto-spawns

- [ ] 18. Spawn `nextflow-stage-report-agent` — checks pipeline job status; reports per-stage SUCCESS/FAILED/IN PROGRESS; exits silently if no run found
- [ ] 19. Invoke `grill-with-docs` skill — probe the current task or plan; skip silently if the user opened the session with no task

---

## Standing gates — apply throughout the entire session

These are not one-time steps. They trigger on every relevant action.

| Gate | Trigger |
|------|---------|
| Challenge terms against CONTEXT.md | Any time the user or a script uses a domain term |
| State success criteria + stop | Before every Edit or Write (except REPORT.md auto-updates) |
| Spawn `scrna-seq-script-agent` | For every R script edit — never edit R scripts inline |
| Spawn `nextflow-script-agent` | For every `.nf` or `nextflow.config` edit — never edit inline |
| Spawn `script-review-agent` | After every R or Nextflow edit — before reporting done |
| Update REPORT.md | After every file change |
| Spawn `BIOLOGIST` | When pipeline completes (all stages SUCCESS/CACHED) |
| Include user constraints block | In every subagent spawn prompt |
| Propagate rename/delete/path change | After any file rename, delete, move, or path string change — grep all *.md, *.R, *.sh, *.nf, *.config for stale references and update them (per Rule 11 in `07_behavior.md`) |
