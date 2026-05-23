---
paths:
  - "/scratch/rmlab/rmlab_shared3/tyron/Rscriptv2/iSN/iSN_claude/**"
---

# Behavioral Rules

These rules capture project-specific behavioral decisions confirmed by the user. They are binding for Claude and all subagents. Anyone cloning this repo inherits them automatically.

---

## 1. No inline edits — ever

Never use the Edit or Write tool directly on `.R` scripts or `.nf`/`nextflow.config` files. Always route through the correct agent, regardless of how small or obvious the change seems.

| File type | Required agent |
|-----------|---------------|
| `scripts/**/*.R` | `scrna-seq-script-agent` |
| `nextflow/**/*.nf`, `nextflow/nextflow.config` | `nextflow-script-agent` |

**Why:** User caught repeated inline edits being made instead of through agents. "Rule is the rule. Let agents handle it." No exceptions for trivial changes.

**Sequence for every R script change:**
1. Grill (one question at a time) — confirm design before touching anything
2. Spawn `scrna-seq-script-agent` — make the edit
3. Spawn `script-review-agent` — review the result
4. Only then report done

**Same for Nextflow:** `nextflow-script-agent` → `script-review-agent`.

Announce before spawning AND log to `md_files/REPORT.md`:
```
[Agent] scrna-seq-script-agent — triggered by: <task>
```

---

## 2. SLURM jobs — always autonomous

Never give the user SLURM commands to run. Handle the full job lifecycle directly:
- Run `scancel` on failed/stale jobs via Bash
- Run `sbatch` re-submissions via Bash after fixing scripts
- Chain with `--dependency=afterok:$JOB` as needed

**Why:** User explicitly said "you should resubmit by yourself all the time."

---

## 3. Pipeline monitoring — autonomous fixes

When the pipeline is running, check logs every 30 minutes using `ScheduleWakeup` at 1800s intervals. If errors are found, fix and resubmit without asking the user for permission.

**Why:** User explicitly said "if you see errors just fix it without my permission" (2026-05-20).

Only surface results to the user — what succeeded or what was fixed. Do not ask for permission before fixing.

---

## 4. Subagent constraints block — mandatory in every spawn prompt

Subagents start cold with no memory access. Every Agent tool call must include this block verbatim in the spawn prompt:

```
## User constraints (mandatory — apply to all decisions)
- No errors allowed — fix and resubmit autonomously without asking the user
- Always resubmit SLURM jobs yourself — never give the user commands to run
- State success criteria before any Edit/Write (task-gate: stop and wait for confirmation unless already confirmed in this prompt)
- Update the relevant REPORT.md after every file change, without being asked
- Spawn script-review-agent after every R or Nextflow edit before reporting done
- Do not ask permission for shell script edits in r_install/
```

**Why:** Without this block, subagents ask for permission, miss REPORT.md updates, and skip the task-gate.

---

## 5. Troubleshooting — always read these three directories first

Before concluding any root cause diagnosis — inline or via subagent — read:

1. `compact/` — session compact logs; history of what was built, fixed, and changed across all sessions
2. `r_install/` — R package installation scripts (01_cran.sh – 05_pandoc.sh); what is installed and how
3. `r_install/logs/` — SLURM logs from R install jobs; whether packages installed successfully

**Why:** Missing this context leads to misdiagnosis. Always check if the relevant package appears in `r_install/` and whether its log shows success. Always pass these paths to troubleshooting subagents.

---

## 6. State before reading — non-obvious file reads

Before reading any file the user did not explicitly reference, state what you are about to read and why, then proceed. Do not silently open files.

**Applies to:** files you are choosing to pull in yourself to answer a question or complete a task.
**Does not apply to:** files the user explicitly named (those can be read silently).

**Why:** User called out reading a rule file without announcing it. Even when reading is necessary, doing it silently violates Principle 1 (don't assume — surface what you're doing).

---

## 7. Grill before any script edit

Before writing or editing any R or Nextflow script — including before spawning any subagent to do so — grill the user one question at a time. This is non-negotiable even if the request seems clear.

**Why:** Design decisions made without grilling produce scripts that need rewriting. `04_clustering.R` was written twice because Harmony strategy and variable gene sweep were not confirmed first.

**What to grill on:**
- Input/output paths and track (SoupX vs DecontX)
- Tool choices (Harmony vs PCA-only, normalization method, etc.)
- Parameter values (dims, nfeatures, resolutions)
- Terminology conflicts against CONTEXT.md
- Script mode (interactive vs CLI/Nextflow)
- Output structure (what files, where)

Every subagent must also grill before editing — remind them explicitly in the spawn prompt.

---

## 8. Pipeline ends at Stage 04

Stage 05 (MergePublicDatasets / DRG atlas integration) was removed from the pipeline on 2026-05-21 per user decision. The pipeline ends at Stage 04 (Clustering).

Do not reference, implement, stub, suggest, or create skills for Stage 05. The `04_seu_clustered_{track}.rds` produced by Stage 04 is the final pipeline output.

---

## 9. WORKFLOW.md and NEXTFLOW.md — audience

- `md_files/WORKFLOW.md` is for Claude and `scrna-seq-script-agent` — R pipeline stages 01–04
- `md_files/NEXTFLOW.md` is for `nextflow-script-agent` — Nextflow modules and pipeline wiring
- Do not add Nextflow-specific content to WORKFLOW.md; do not add R script content to NEXTFLOW.md

---

## 10. SKILL.md files are agent instructions, not slash commands

The files in `.claude/skills/ambient-rna-removal/`, `.claude/skills/doublet-removal/`, `.claude/skills/cell-filtering/`, `.claude/skills/clustering/` are read by `scrna-seq-script-agent` and `script-review-agent` at session start. They are not interactive slash commands. Do not invoke them as `/doublet-removal`, `/ambient-rna-removal`, etc.

---

## 11. File rename / delete / path change — propagate everywhere

Whenever any file is renamed, deleted, moved, or any path string changes (whether Claude made the change or the user did), immediately scan the entire project for stale references and update them without being asked.

**Scope of search — grep all of these for the old name/path:**

| File type | Pattern |
|-----------|---------|
| Markdown files | `find . -name "*.md" -not -path "./.git/*"` |
| R scripts | `find . -name "*.R"` |
| Shell scripts | `find . -name "*.sh"` |
| Nextflow files | `find . -name "*.nf" -o -name "nextflow.config"` |
| CLAUDE.md | project root |
| Agent / rule / skill files | `.claude/agents/*.md`, `.claude/rules/*.md`, `.claude/skills/**/*.md`, `.claude/memory/*.md` |

**Steps:**

1. `grep -r "<old_name_or_path>" . --include="*.md" --include="*.R" --include="*.sh" --include="*.nf" --include="*.config" -l` — list all files with a stale reference
2. For each file found: update the reference inline (Edit tool for md/R/sh; agent routing for .nf/.config and .R script changes)
3. Log every updated file to the relevant `REPORT.md`
4. After updating, re-run the grep to confirm zero stale references remain

**Why:** Rename/delete operations silently break references across md files, agent prompts, CLAUDE.md, run scripts, and R scripts. The Biologist_Chat.md move in session 16 required manual fixes to 4 files — this rule prevents that.

**Applies to:** Any rename, `mv`, `rm`, or path-string change — whether Claude executed it via Bash or the user did it outside the session.

---

## 12. All agent spawns run in the background

Every Agent tool call must include `run_in_background: true`, without exception.

| Agent | run_in_background |
|-------|------------------|
| scrna-seq-script-agent | true |
| nextflow-script-agent | true |
| script-review-agent | true |
| nextflow-stage-report-agent | true |
| BIOLOGIST | true |
| troubleshoot_agent | true |

**Why:** Keeps the local Claude session responsive while agents run. Results surface at the bottom of the conversation when complete.

**Applies to:** Every Agent tool call in every session, for all users.

---

## 13. ScheduleWakeup fires → always spawn nextflow-stage-report-agent first

When a `ScheduleWakeup` fires with "iSN Nextflow pipeline monitoring check" in the prompt, the **only valid first action** is spawning `nextflow-stage-report-agent` via the Agent tool with `run_in_background: true`. Do not handle it inline under any circumstances.

**Prohibited reasoning patterns — all of these are violations:**
- "I already have context from the conversation, I can report faster myself"
- "The pipeline state is obvious from prior messages, no need for an agent"
- "It would be more efficient to just check the log directly"

**Why:** Claude violated this on 2026-05-23 — it reasoned "I already have context" and bypassed the agent entirely, checking `.nextflow.log` and reporting status inline. The routing rule exists to enforce consistency and auditability for all users, not just for cases where Claude lacks context. Inline handling defeats the purpose.

**How to apply:** Before any other action when a ScheduleWakeup fires with this prompt string — spawn `nextflow-stage-report-agent`. No exceptions.
