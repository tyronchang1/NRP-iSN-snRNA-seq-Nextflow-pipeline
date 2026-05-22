---
paths:
  - "/scratch/rmlab/rmlab_shared3/tyron/Rscriptv2/iSN/iSN_claude/**"
---

# Path Change Detection

## When to run

- **At the start of every conversation** — always, without being asked
- **Whenever** a directory or file is moved, renamed, created, or a path inconsistency is noticed

## Triggers

Path-change detection covers all of the following events:

| Event | Examples |
|-------|---------|
| File or directory renamed or moved | `mv scripts/02_old/ scripts/02_new/` |
| File or directory deleted | `rm -rf scripts/01_SoupX/old_output/` |
| **New file created** | A new `.R` script, output directory, or stage folder added |
| **New directory created** | A new pipeline stage folder, output folder, or subdirectory |
| Path string changed in any script | `setwd()`, `Read10X()`, `write10xCounts()` updated |

When a new file or directory is created, immediately check whether any existing scripts, config files, or `.md` files need to reference it — and whether any hardcoded paths need updating to reflect the new structure.

## Steps

1. **Detect** — Grep all `.R` scripts for hardcoded paths: `setwd()`, `load10X()`, `write10xCounts()`, `SaveH5Seurat()`, `Read10X()`. Compare each against what actually exists on disk. Also check whether newly created files or directories are referenced anywhere they should be.
2. **Report** — Tell the user which scripts contain the outdated or missing path and what the new path should be. If multiple scripts are affected, list all of them.
3. **Ask** — Do not update any script path without explicit user confirmation. Always show the old path and the proposed new path before asking.
4. **Update** — Once the user confirms, update the paths in the affected scripts and log the change in the corresponding `REPORT.md`.

## When the project root directory is renamed or removed

If the project root directory is renamed or moved, the Claude project directory in `~/.claude/projects/` must also be migrated. The Claude project directory path is derived by replacing every `/` in the absolute project path with `-` (with a leading `-`).

### Steps

1. **Derive paths** — Compute old and new Claude project directory paths:
   - Old: `~/.claude/projects/` + old absolute path with `/` → `-`
   - New: `~/.claude/projects/` + new absolute path with `/` → `-`

2. **Create and copy** — Run the following and show the output to the user before anything else:
   ```bash
   mkdir -p {new_claude_dir}/memory
   cp -r {old_claude_dir}/memory/. {new_claude_dir}/memory/
   cp {old_claude_dir}/*.jsonl {new_claude_dir}/
   ls {new_claude_dir}/memory/ && ls {new_claude_dir}/*.jsonl
   ```
   Do not proceed to deletion until the user confirms the copy looks correct.

3. **Confirm deletion separately** — After showing the copy output, ask explicitly and stop:
   > "Memory and conversation files copied to `{new_claude_dir}`. Confirm deletion of `{old_claude_dir}`?"
   Do not proceed to step 4 until the user replies with explicit confirmation.

4. **Delete only after confirmation** — Once the user explicitly confirms:
   ```bash
   rm -rf {old_claude_dir}
   ```
