# ADR Format

ADRs live in `.claude/skills/grill-with-docs/adr/` and use sequential numbering: `0001-slug.md`, `0002-slug.md`, etc.

Create the `adr/` directory lazily — only when the first ADR is needed.

## Template

```md
# {Short title of the decision}

{1-3 sentences: what's the context, what did we decide, and why.}
```

That's it. An ADR can be a single paragraph. The value is in recording *that* a decision was made and *why* — not in filling out sections.

## Optional sections

Only include these when they add genuine value. Most ADRs won't need them.

- **Status** frontmatter (`proposed | accepted | deprecated | superseded by ADR-NNNN`) — useful when decisions are revisited
- **Considered Options** — only when the rejected alternatives are worth remembering
- **Consequences** — only when non-obvious downstream effects need to be called out

## Numbering

Scan `docs/adr/` for the highest existing number and increment by one.

## When to offer an ADR

All three of these must be true:

1. **Hard to reverse** — the cost of changing your mind later is meaningful
2. **Surprising without context** — a future reader will look at the code and wonder "why on earth did they do it this way?"
3. **The result of a real trade-off** — there were genuine alternatives and you picked one for specific reasons

If a decision is easy to reverse, skip it — you'll just reverse it. If it's not surprising, nobody will wonder why. If there was no real alternative, there's nothing to record beyond "we did the obvious thing."

### What qualifies

- **Tool selection.** "We use scDblFinder, not DoubletFinder." "We run SoupX and DecontX as parallel branches, not sequentially." Anything a future contributor might swap out without knowing the tradeoffs.
- **Parameter thresholds — only after finalisation from plots.** Thresholds (nCount_RNA cutoff, rho cap, clustering resolution) are not predetermined; they are chosen by running the R script and inspecting the resulting plot. Do not write an ADR speculatively. Once the user has settled on a value from the visual, it qualifies if it deviates from the conventional default in a non-obvious way: "nCount_RNA filter at 700, not the common 500 — justified by the density histogram showing a clear inflection at 700 for these samples."
- **Stage ordering decisions.** "Doublet removal happens before cell QC filtering, not after." A future reader will wonder why.
- **Branching strategy.** "Stage 01 and 01.2 (SoupX and DecontX) run in parallel; downstream stages pick one branch." The explicit rejection of the other is as important as the choice.
- **Constraints not visible in the code.** "scDblFinder must run per-sample using `samples='sample_group'` because merging first inflates doublet scores across batches." "DecontX requires raw Cell Ranger output as background, not just filtered."
- **Rejected alternatives when the rejection is non-obvious.** If you considered DoubletFinder and picked scDblFinder for specific reasons, record it — otherwise someone will suggest DoubletFinder again when troubleshooting.
