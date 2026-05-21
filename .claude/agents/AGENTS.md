# Agent Conventions

All agents in this project must follow these conventions. Read this file at the start of every session before doing anything else.

---

## 0. Read all project rules first

Before anything else, read all rule files in order. These are the highest-priority instructions and override everything else:

1. `.claude/rules/00_session-checklist.md`
2. `.claude/rules/01_principles.md`
3. `.claude/rules/02_guardrails.md`
4. `.claude/rules/03_task-gate.md`
5. `.claude/rules/04_path-change-detection.md`
6. `.claude/rules/05_update-report-on-change.md`
7. `.claude/rules/06_compact-log.md`
8. `.claude/rules/07_behavior.md`

---

## 1. Grill-with-docs integration (mandatory for all agents)

Every agent must load and apply the domain glossary and ADR system from the grill-with-docs skill:

| File | What to do with it |
|---|---|
| `.claude/skills/grill-with-docs/CONTEXT.md` | Read at session start — this is the canonical glossary. Challenge any term used in conversation or code that conflicts with it. |
| `.claude/skills/grill-with-docs/CONTEXT-FORMAT.md` | Use this format when adding new terms to CONTEXT.md |
| `.claude/skills/grill-with-docs/ADR-FORMAT.md` | Use this format when offering to write an ADR |
| `.claude/skills/grill-with-docs/adr/` | Write ADRs here (create directory lazily when first ADR is needed) |

### Invoke the skill at session start

After reading CONTEXT.md, **invoke the `grill-with-docs` skill** (via the Skill tool) to self-probe the task before proceeding with any edit or review. Ask questions one at a time about the plan — challenge terminology, probe assumptions, surface ADR candidates. Skip this step only if the agent is purely diagnostic/read-only (i.e., `nextflow-stage-report-agent`).

### During any session

- **Challenge terminology** — if the user or a script uses a term that conflicts with `CONTEXT.md`, call it out immediately before proceeding
- **Update CONTEXT.md inline** — when a term is resolved during the session, update `CONTEXT.md` right then; do not batch
- **Offer ADRs sparingly** — only when all three are true: hard to reverse, surprising without context, result of a real trade-off. Parameter thresholds do not qualify until finalized from a plot
- **Never touch `CONTEXT.md` for implementation details** — it is a glossary only

---

## 2. Project root

```
/scratch/rmlab/rmlab_shared3/tyron/Rscriptv2/iSN/iSN_claude
```

All file paths are relative to this root. Never hardcode absolute paths in scripts except for the `dir <- "..."` / `setwd(dir)` block.

---

## 3. Available agents

| Agent | File | Edits | Reference doc |
|-------|------|-------|---------------|
| scrna-seq-script-agent | `scrna-seq-script-agent.md` | R scripts (`scripts/0*/`) — edits only, never from scratch | `md_files/WORKFLOW.md` |
| nextflow-script-agent | `nextflow-script-agent.md` | Nextflow files (`nextflow/`) — may write from scratch | `md_files/NEXTFLOW.md` |
| script-review-agent | `script-review-agent.md` | Reviews all R + Nextflow scripts; fixes errors from nextflow-stage-report-agent | `md_files/WORKFLOW.md`, `md_files/NEXTFLOW.md` |
| nextflow-stage-report-agent | `nextflow-stage-report-agent.md` | Inspects `.nextflow.log` and `work/`; invokes script-review-agent on error only; logs report on success | `md_files/NEXTFLOW.md` |
| BIOLOGIST | `BIOLOGIST.md` | Reviews plots and parameters for biological interpretability in iSN/DRG context | `md_files/STATUS.md` |
| troubleshoot_agent | `troubleshoot_agent.md` | Reads SLURM/Nextflow error logs, classifies failure, coordinates with script-review-agent to fix | `md_files/NEXTFLOW.md`, `md_files/STATUS.md` |

---

## 4. Hard constraint (agent-specific, not in rules)

Do not set parameter thresholds the user has not confirmed from a plot.
