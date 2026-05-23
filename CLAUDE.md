# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Rules

Before responding to any request, read all files in `.claude/rules/` and apply their instructions. Rules take precedence over everything else.

After reading the rule files, read `.claude/skills/grill-with-docs/CONTEXT.md` and apply grill-with-docs conventions for the rest of the session: challenge any term that conflicts with CONTEXT.md before proceeding, update CONTEXT.md inline when a term is resolved, and offer ADRs sparingly (only when hard to reverse, surprising without context, and the result of a real trade-off).

**Auto-grill rule:** At the start of every session, immediately invoke the `grill-with-docs` skill (via the Skill tool) to probe whatever the user is working on — same as `nextflow-stage-report-agent` auto-runs. Ask questions one at a time about the current task or plan. If there is no plan yet (user just opened a session with no task), skip silently. The always-on conventions (term challenge, CONTEXT.md updates, ADR offers) apply throughout the entire session regardless.

## Agent Routing

When a task matches the table below, spawn a subagent using the `Agent` tool — do not do the work inline. Do not wait for the user to name an agent.

| Task | Agent | Definition file |
|------|-------|-----------------|
| Edit or fix any `scripts/**/*.R` or `scripts/**/*.Rmd` file | `scrna-seq-script-agent` | `.claude/agents/scrna-seq-script-agent.md` |
| Write or edit any `nextflow/**/*.nf` or `nextflow/nextflow.config` | `nextflow-script-agent` | `.claude/agents/nextflow-script-agent.md` |
| Review any R or Nextflow script for correctness; troubleshoot and fix errors | `script-review-agent` | `.claude/agents/script-review-agent.md` |
| Inspect Nextflow stage execution results (`.nextflow.log`, `work/`); produce success/failure report | `nextflow-stage-report-agent` | `.claude/agents/nextflow-stage-report-agent.md` |
| User says the pipeline is running or was just submitted (e.g., "I ran submit.sh", "pipeline started", "I submitted the job", "pipeline running") | `nextflow-stage-report-agent` | `.claude/agents/nextflow-stage-report-agent.md` |
| Claude just ran `sbatch` to submit the Nextflow pipeline (job ID returned) | `nextflow-stage-report-agent` | `.claude/agents/nextflow-stage-report-agent.md` |
| A `ScheduleWakeup` fires with "iSN Nextflow pipeline monitoring check" in the prompt | `nextflow-stage-report-agent` | `.claude/agents/nextflow-stage-report-agent.md` |

> **HARD RULE — no inline handling of ScheduleWakeup:** When the prompt contains "iSN Nextflow pipeline monitoring check", spawn `nextflow-stage-report-agent` as the **first and only action**. Do NOT check `.nextflow.log` yourself, do NOT report stage status inline, do NOT reason "I already have context from the conversation." Spawn the agent unconditionally. See Rule 13 in `.claude/rules/07_behavior.md`.
| Review clustering parameters, QC distributions, doublet rates, or expression plots for biological interpretability | `BIOLOGIST` | `.claude/agents/BIOLOGIST.md` |
| User says the Nextflow pipeline has finished (e.g., "pipeline finished", "nextflow done", "run is complete") | `BIOLOGIST` | `.claude/agents/BIOLOGIST.md` |
| User reports a SLURM job failure, pastes a SLURM/Nextflow error, or shares a log path from a failed run | `troubleshoot_agent` | `.claude/agents/troubleshoot_agent.md` |

**How to spawn:**
1. Announce in the terminal before spawning: `[Agent] <name> — triggered by: <task>`
2. Log the invocation to `md_files/REPORT.md` (agent name, task, date)
3. Call the `Agent` tool with `subagent_type: "claude"`, **`run_in_background: true`**, and a self-contained prompt that includes:
   - Instruction to read the agent definition file at `.claude/agents/<name>.md` first
   - The specific task (files to write/edit, what to change and why)
   - All relevant context the subagent needs (it starts cold with no conversation history)

**`run_in_background: true` is mandatory on every Agent call — no exceptions.** This keeps the local session responsive while the agent runs. The result surfaces at the bottom of the conversation when complete.

The subagent reads its own definition file and follows its session-start sequence independently.

**Auto-review rule:** After every R or Nextflow script edit — regardless of size — spawn `script-review-agent` to review the changes before reporting the work as done. No exceptions. Small edits still require review.

**Auto-BIOLOGIST rule:** BIOLOGIST is spawned automatically in two situations:
1. **`nextflow-stage-report-agent` detects pipeline completion** — when all stages are `SUCCESS` or `CACHED`, `nextflow-stage-report-agent` collects all HTML report paths and spawns `BIOLOGIST` directly (no user signal needed).
2. **User signals completion** — if the user says the pipeline finished (e.g., "pipeline done", "nextflow finished"), spawn `BIOLOGIST` immediately even if `nextflow-stage-report-agent` did not catch it.
In both cases: pass paths to all HTML reports that exist on disk. BIOLOGIST reviews all stages in sequence, appends findings to `final_output/Biologist_Chat.md`, and produces a summary table.

**Auto-pipeline-check rule:** At the start of every session, spawn `nextflow-stage-report-agent` at step 18 of the session-start checklist — after all rule files, skill files, and project state files have been read (steps 1–17). Do not spawn it before the reading steps are complete. It will:
- Check if a Nextflow SLURM job is currently running (`squeue`)
- Check if `.nextflow.log` exists with stage results
- If running or finished: report per-stage status and hand failures to `troubleshoot_agent`
- If nothing found: exit silently — do not mention it to the user

After spawning `nextflow-stage-report-agent` and if the pipeline is RUNNING, the **main session** (not the subagent) must set the 30-minute monitoring wakeup:
```
ToolSearch(query: "select:ScheduleWakeup", max_results: 1)
ScheduleWakeup(delaySeconds: 1800, reason: "iSN pipeline monitoring — checking stage completions every 30 min", prompt: "iSN Nextflow pipeline monitoring check")
```
`ScheduleWakeup` is a session-level tool not available to subagents — always call it from the main session.

**`/start` skill rule:** When the user invokes `/start`, immediately execute the full session-start checklist (steps 0–19) in order via the Skill tool, announcing each step as it completes: read all rule files (steps 1–7), run the memory bootstrap, read the domain glossary (step 8), read all pipeline skill files (steps 9–12), read all project state files (steps 13–15), run path-change detection and REPORT.md staleness check (steps 16–17), spawn `nextflow-stage-report-agent` (step 18), and invoke `grill-with-docs` (step 19). Make each step visible to the user so they can verify compliance. **If `/start` is invoked again mid-session and the checklist has already run, do NOT re-run — acknowledge and move on. Exception: after `/compact` or auto-compaction, re-running `/start` is correct.**

## Project Overview

This is a Nextflow snRNA-seq pipeline for **human induced sensory neurons (iSNs)** — iPSC-derived neurons that model dorsal root ganglion (DRG) sensory subtypes. Eight samples from experiment NR00 (timepoints: iPSC, Day7, Day13) are processed through four sequential stages:

| Stage | Tool | Purpose |
|-------|------|---------|
| 01 / 01.2 | SoupX or DecontX | Ambient RNA removal |
| 02 / 02.1 | scDblFinder | Doublet scoring and labeling |
| 03 | Seurat | Cell QC filtering (mito %, nFeature, nCount, doublets) |
| 04 | Seurat + Harmony | Integration, clustering, marker gene analysis |

Two parallel tracks run from the same raw data: **SoupX** (01→02→03→04) and **DecontX** (01.2→02.1→03→04). Track is selected at pipeline launch via `--track soupx` or `--track decontx`. The pipeline ends at Stage 04; Stage 05 (public DRG atlas integration) is excluded from Nextflow and run manually.
