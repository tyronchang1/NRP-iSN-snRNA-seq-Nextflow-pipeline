---
name: feedback-schedulewakeup-routing
description: When ScheduleWakeup fires with "iSN Nextflow pipeline monitoring check", always spawn nextflow-stage-report-agent first — never handle inline
metadata:
  type: feedback
---

When a `ScheduleWakeup` fires with "iSN Nextflow pipeline monitoring check" in the prompt, the **only valid first action** is spawning `nextflow-stage-report-agent` with `run_in_background: true`. Do not handle it inline under any circumstances.

**Why:** Violated on 2026-05-23 — reasoned "I already have context from the conversation, I can check the log and report faster myself" and bypassed the agent entirely. The routing rule exists for consistency and auditability for all users, not just when context is missing. Inline handling defeats the purpose.

**How to apply:** Check the prompt string before taking any action after a ScheduleWakeup fires. If it contains "iSN Nextflow pipeline monitoring check" → spawn the agent immediately. Prohibited reasoning: "I already know the state," "it would be faster inline," "the pipeline is obviously done."

See Rule 13 in `.claude/rules/07_behavior.md` and the HARD RULE callout in `CLAUDE.md` Agent Routing section.
