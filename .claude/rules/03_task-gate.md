---
paths:
  - "/scratch/rmlab/rmlab_shared3/tyron/Rscriptv2/iSN/iSN_claude/**"
---

# Task Gate: Confirm Before Editing

## Rule

Before calling any Edit or Write tool on a non-REPORT.md file — including R scripts (.R files) and any other pipeline file — you must:

1. State success criteria — what "done" looks like in concrete, verifiable terms
2. Surface open questions — any ambiguity that has more than one valid answer
3. Stop — do not call Edit or Write in the same response

## Exemptions

- REPORT.md updates that follow an already-confirmed edit — these are autonomous and do not need a separate gate

Wait for the user to reply in a new message. Only proceed after they explicitly confirm.

## What does NOT count as confirmation

- Answering your own questions in the same response
- Inferring confirmation from a prior message in the conversation
- Assuming the user's request implies approval of your interpretation
