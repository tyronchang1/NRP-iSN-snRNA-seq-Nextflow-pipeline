# Compact Session Log

## Purpose

Whenever context is compacted — either automatically by the harness or manually via `/compact` — save the compacted context summary as a numbered markdown file in `compact/`.

## File naming

```
compact/compact_session01.md
compact/compact_session02.md
compact/compact_session03.md
...
```

Increment the number for each new compaction. Check the highest existing number in `compact/` before writing.

## Each file must include

- **Date and time** (at the top)
- **Primary work covered** — what was built, decided, or changed
- **Key files changed** — table of file paths and status
- **Errors and fixes** — any non-trivial problems encountered and how they were resolved
- **Pending at compaction** — tasks that were in-progress or unfinished when compaction occurred

## When to write

The compact log is triggered by the compaction event itself — not by the next user message.

- **Auto-compact**: when the harness compacts the conversation and the new context window opens, write the compact log as the very first action before producing any response to the user.
- **`/compact` command**: when the user runs `/compact`, write the compact log immediately as the first output — before responding to whatever the user says next.

Do not wait for the user to ask. Do not do pipeline checks, grill-with-docs, or any other work first. The compact log is unconditionally first.

## Session-start sequence reminder

After writing the compact log, the full session-start sequence continues:
1. Read all `.claude/rules/` files
2. Read `.claude/skills/grill-with-docs/CONTEXT.md`
3. Spawn `nextflow-stage-report-agent`
4. Invoke `grill-with-docs`

Compaction does not excuse skipping this sequence.
