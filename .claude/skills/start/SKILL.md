# /start — Session Primer

## Purpose

Triggers the full session-start checklist (steps 0–19) to prime Claude and all agents with rules, skills, domain glossary, and project context before any work begins.

## Behavior

**First invocation in the session:** Execute the full checklist in `.claude/rules/00_session-checklist.md` — steps 1–19 in order, announcing each step as it completes so the user can verify compliance.

**If the user included a task after `/start` (e.g., `/start I want to cluster the DecontX track`):** After the checklist completes, automatically invoke `/grill-with-docs` with that task as the input — probe it against the domain glossary before any work begins.

**Subsequent invocations in the same session:** Do NOT re-run the checklist. The session is already primed. Acknowledge: "Session already primed — `/start` already ran this session." Then continue with whatever the user needs.

**After `/compact`, `/clear`, or auto-compaction:** The session context is reset. `/start` must be re-invoked to re-prime. This is the one case where re-running is correct — context was cleared, so priming is needed again.

## Why this matters

Without priming, spawned agents (scrna-seq-script-agent, nextflow-stage-report-agent, BIOLOGIST, etc.) operate without the full behavioral ruleset and may make incorrect decisions. `/start` is the single command that loads everything.
