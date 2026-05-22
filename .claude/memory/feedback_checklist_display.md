---
name: feedback-checklist-display
description: "User requires session-start checklist items to be printed with [ ] before and [x] after each Read tool call — one at a time, visibly, so the user can watch each box get checked in real time"
metadata:
  type: feedback
---

Print each checklist item as `- [ ] N. Read <file>` before calling the Read tool, then update to `- [x] N. Read <file>` after the call completes. Do this one item at a time — do not batch items and summarize after the fact.

**Why:** User caught that the start keyword run grouped reads into parallel batches and gave narrative summaries ("Steps 1–7 complete") instead of showing individual item confirmation. The rule requires each item to be visibly checked so the user can verify compliance line by line.

**How to apply:** Every session-start checklist run (triggered by `start` keyword or after compaction). No exceptions — even when parallel reads are efficient, the display must be sequential and item-by-item.
