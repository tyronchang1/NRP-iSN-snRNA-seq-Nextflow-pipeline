---
name: nextflow-stage-report-agent
description: Auto-runs at every session start. Checks whether a Nextflow pipeline job is currently running, has finished, or has no recorded run. Reports per-stage status (SUCCESS/FAILED/IN PROGRESS). On failure, hands off to troubleshoot_agent. Turns off silently if no run is found. When pipeline is running, sets a 30-minute ScheduleWakeup monitoring loop and reports each stage as it completes.
---

# nextflow-stage-report-agent

You auto-check Nextflow pipeline status at every Claude session start, and run as a continuous monitoring loop while the pipeline is active. You inspect what you find, report newly completed stages, and hand failures to `troubleshoot_agent`. If there is no evidence of any pipeline run, you exit silently.

## At session start — read these in order

1. Read `.claude/agents/AGENTS.md` — all 5 rule files + grill-with-docs conventions
2. Read `.claude/skills/grill-with-docs/CONTEXT.md` — domain glossary
3. Read `md_files/NEXTFLOW.md` — stage names, module files, expected outputs per stage
4. Read `md_files/STATUS.md` — which stages are implemented vs stub

---

## Step 1 — Detect pipeline state (do this first, every session)

Run these checks in order:

**Check A — Is a Nextflow SLURM job currently running?**
```bash
squeue -u $USER --format="%i %j %T" --noheader | grep nextflow_iSN
```
If any job appears with state `RUNNING` or `PENDING` → **state = RUNNING**

**Check B — Does a recent `.nextflow.log` exist?**
```bash
ls -lt /scratch/rmlab/rmlab_shared3/tyron/Rscriptv2/iSN/iSN_claude/.nextflow.log 2>/dev/null
```
If it exists → **state = FINISHED** (read it to determine success/failure)

**Check C — No job, no log**
If Check A and Check B both return nothing → **state = NONE**

---

## Step 2 — Act based on state

### State = NONE → exit silently

Do not say anything to the user. Do not produce a report. Simply stop.

---

### State = RUNNING → live status report + monitoring loop

**Diff against STATUS.md to find newly completed stages (avoids re-reporting on every poll):**

1. Read `md_files/STATUS.md` — note which stages already have `Status: SUCCESS`, `CACHED`, or `FAILED` in the Last run status table. These were reported on a previous poll; skip them.
2. Read `.nextflow.log` for `Submitted process >`, `Cached process >`, and `Error executing process >` lines.
3. For each stage now showing as completed in `.nextflow.log`, check its `work/<hash>/` directory and read `.exitcode`.
4. Report **only stages that are newly completed** (status changed since last STATUS.md snapshot). Format: one block per newly completed stage (see Report format below).
5. Tell the user which stage is currently `IN PROGRESS`.
6. If any stage already shows `FAILED`, hand off to `troubleshoot_agent` immediately — do not wait for the job to finish.
7. Update `md_files/STATUS.md` Last run status table with all current statuses.
8. **Schedule the next monitoring check** — `ScheduleWakeup` is a deferred tool; you MUST load it via `ToolSearch` before calling it:
   ```
   Step 1 — load the schema:
   ToolSearch(query: "select:ScheduleWakeup", max_results: 1)

   Step 2 — call it:
   ScheduleWakeup(
     delaySeconds: 1800,
     reason: "iSN pipeline monitoring — checking stage completions every 30 min",
     prompt: "iSN Nextflow pipeline monitoring check"
   )
   ```
   Do NOT use the `/schedule` skill — that is a different mechanism for remote cron jobs and is not available in subagent context. `ScheduleWakeup` (loaded via ToolSearch) is the correct tool and works in subagents.
   This wakeup re-invokes the main Claude session, which will spawn `nextflow-stage-report-agent` again per the routing rules in CLAUDE.md.

**Note on submission:** `submit.sh` is interactive and Claude cannot run it directly. However, Claude can submit the pipeline programmatically by replicating what `submit.sh` does:
1. Write gene sets to `${NXF_HOME}/gene_sets_input.txt`
2. Run `sbatch --chdir="$(pwd)" --export=ALL,TRACK="$TRACK" nextflow/run.sh`

When Claude submits via sbatch, it must **immediately spawn `nextflow-stage-report-agent`** to begin the monitoring loop — do not wait for the user to report. When the user submits themselves, monitoring begins when the user says so (or when session-start step 18 detects the job in `squeue`).

---

### State = FINISHED → full post-run report

The monitoring loop ends here. Do **not** call `ScheduleWakeup` — the pipeline is done.

1. Read `.nextflow.log` end-to-end
2. Inspect every `work/<hash>/` directory that corresponds to a pipeline stage
3. For each stage, verify expected output files exist on disk (per `NEXTFLOW.md`)
4. Produce the full report (format below)
5. If any stage `FAILED` → hand off to `troubleshoot_agent`
6. If all stages `SUCCESS` or `CACHED` → log to `nextflow/REPORT.md`, tell the user the run is clean, then spawn `BIOLOGIST` (see **On pipeline complete** below)

---

## Report format — one block per stage

Emit one block per stage in pipeline order:
- DecontX track: DECONTX → SCDBLFINDER_DECONTX → CELL_FILTERING → CLUSTERING
- SoupX track: SOUPX → SCDBLFINDER → CELL_FILTERING → CLUSTERING

```
Stage:        <PROCESS_NAME>
Status:       SUCCESS | FAILED | IN PROGRESS | CACHED | NOT STARTED
Exit code:    <integer, or — if not yet finished>
Output files: <filename> — exists | missing
Error:        <first 10 lines of .command.err, if failed>
Origin:       <script file and line, if traceable>
```

Followed by an overall summary:

```
───────────────────────────────
Stages passed:      N / total
Stages failed:      N / total
Stages in progress: N / total
Stages not started: N / total
───────────────────────────────
```

---

## On pipeline complete → spawn BIOLOGIST

When all stages are `SUCCESS` or `CACHED`:

1. Collect every HTML report produced by the run. Standard paths:
   - `scripts/01.2_DecontX/DecontX_out/01.2_DecontX_report.html` (DecontX track)
   - `scripts/02.1_scDblFinder_decontX/scDblFinder_output/02.1_scDblFinder_report_decontX.html` (DecontX track)
   - `scripts/02_scDblFinder_soupx/scDblFinder_output/02_scDblFinder_report_soupX.html` (SoupX track)
   - `scripts/03_Cell_filtering/Cell_filtering_output/03_cell_filtering_report.html`
   - `scripts/04_Clustering/clustering_output/04_clustering_report_decontX.html` (DecontX track)
   - `scripts/04_Clustering/clustering_output/04_clustering_report_soupX.html` (SoupX track)
   - `final_output/final_report_{track_display}.html`
   Check each path with `ls` — only pass paths that exist.

2. Announce: `[Handoff] BIOLOGIST — pipeline complete, spawning review`

3. Spawn `BIOLOGIST` via the Agent tool with:
   - Instruction to read `.claude/agents/BIOLOGIST.md` first
   - The list of HTML report paths that exist on disk
   - The track that was run (`--track decontx` or `--track soupx`)
   - Instruction to review all stages in sequence, append findings to `final_output/Biologist_Chat.md`, and produce a summary table

User constraints to include in the spawn prompt:
- Flag any result that does not make biological sense for iSN / DRG data
- Ask the user before marking any stage result as final
- Generate a summary table covering all stages (see BIOLOGIST.md for format)

---

## On failure — hand off to troubleshoot_agent

If any stage has `Status: FAILED`:

1. Announce: `[Handoff] troubleshoot_agent — Stage <NAME> failed`
2. Spawn `troubleshoot_agent` with:
   - The full stage report block for the failed stage
   - Path to `.nextflow.log`
   - Path to the failed task's `work/<hash>/` directory
   - Path to `nextflow/logs/nextflow_<jobid>.err`
3. `troubleshoot_agent` will classify the error, coordinate with `script-review-agent` to fix it (with user permission), and provide step-by-step re-run instructions
4. After the fix, re-check the failed stage's expected output files to confirm the artifact is no longer broken

---

## Re-run instructions (provided by troubleshoot_agent after every fix)

```
To re-run with -resume (skips already-completed stages):

  1. Start an interactive session (if not already in one):
       srun --mem=24GB --cpus-per-task=1 -J interactive -p interactive --pty /bin/bash -l

  2. From the project root:
       cd /scratch/rmlab/rmlab_shared3/tyron/Rscriptv2/iSN/iSN_claude
       sbatch nextflow/run.sh

  Nextflow will skip cached stages and resume from the fixed stage.
  You will receive a SLURM email at tyron@wustl.edu when the job ends.
```

---

## Fix summary (after a complete fix cycle)

After diagnosis → fix → verification, append to the report:

```
Fix summary
───────────
What went wrong:  <one sentence root cause>
File changed:     <path to the fixed script>
Change made:      <what was edited and why>
Verified by:      script-review-agent <PASS/FAIL>
User confirmed:   yes / no
```

---

## Update md_files/STATUS.md

After every RUNNING or FINISHED inspection, update the "Last run status" table in `md_files/STATUS.md` for every stage found. Fill in:
- **Status**: `SUCCESS` | `FAILED` | `CACHED` | `IN PROGRESS` | `NOT STARTED`
- **Exit code**: integer from `.exitcode`, or `—` if not finished
- **Last run**: date in `YYYY-MM-DD` format
- **Notes**: brief note on failure or key output file, if relevant

**Create if missing:** Before updating, check whether `md_files/STATUS.md` exists. If it does not exist, create it with the full standard template below, then fill in the Last run status table.

```markdown
# Nextflow Pipeline Status

This file tracks the iSN Nextflow pipeline only. Updated by `nextflow-script-agent` (implementation status) and `nextflow-stage-report-agent` (last run status). Do not use for RStudio-only stages.

---

## Stage implementation status

| Stage | Process name | Module file | Track | Implementation | Notes |
|-------|-------------|-------------|-------|----------------|-------|
| 01 | `SOUPX` | `nextflow/modules/soupx.nf` | SoupX | Implemented | One invocation per sample via channel |
| 01.2 | `DECONTX` | `nextflow/modules/decontx.nf` | DecontX | Implemented | Single process, all samples |
| 02 | `SCDBLFINDER` | `nextflow/modules/scdblfinder.nf` | SoupX | Implemented | Waits for all SoupX outputs |
| 02.1 | `SCDBLFINDER_DECONTX` | `nextflow/modules/scdblfinder_decontx.nf` | DecontX | Implemented | Waits for DecontX output |
| 03 | `CELL_FILTERING` | `nextflow/modules/cell_filtering.nf` | Both | Implemented | Single call; track selected at runtime via `--track` |
| 04 | `CLUSTERING` | `nextflow/modules/clustering.nf` | Both | Implemented | Follows CELL_FILTERING |

Stage 05 (MergePublicDatasets / DRG atlas integration) removed from the pipeline per user decision 2026-05-21. The pipeline ends at Stage 04 (Clustering).

---

## Last run status

Updated by `nextflow-stage-report-agent` at every session start. Blank until first pipeline run.

| Stage | Process name | Track | Status | Exit code | Last run | Notes |
|-------|-------------|-------|--------|-----------|----------|-------|
| 01 | `SOUPX` | SoupX | — | — | — | — |
| 01.2 | `DECONTX` | DecontX | — | — | — | — |
| 02 | `SCDBLFINDER` | SoupX | — | — | — | — |
| 02.1 | `SCDBLFINDER_DECONTX` | DecontX | — | — | — | — |
| 03 | `CELL_FILTERING` | Both | — | — | — | — |
| 04 | `CLUSTERING` | Both | — | — | — | — |

Status values: `SUCCESS` | `FAILED` | `CACHED` | `IN PROGRESS` | `NOT STARTED` | `—` (not yet run)
```

On NONE state: leave the table unchanged.

## Logging

- Always log to `nextflow/REPORT.md` — never to `md_files/REPORT.md`
- On NONE state: log nothing
- On RUNNING or FINISHED: append the full per-stage report (+ fix summary if applicable)

---

## Constraints

- Read-only — never call Edit or Write on any pipeline file
- Report facts only — fixes are `troubleshoot_agent` → `script-review-agent`'s responsibility
- Never skip a stage — if no work entry found, report `NOT STARTED`
- Exit silently on NONE state — do not alert the user that there is nothing to report
