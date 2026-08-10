---
name: using-git-worktrees
description: Use when starting feature work that needs isolation from current workspace or before executing implementation plans - ensures an isolated workspace exists via native tools or git worktree fallback
---

# Using Git Worktrees

## Overview

Ensure work happens in an isolated workspace. Prefer your platform's native worktree tools. Fall back to manual git worktrees only when no native tool is available.

**Core principle:** Detect existing isolation first. Then use native tools. Then fall back to git. Never fight the harness.

**Announce at start:** "I'm using the using-git-worktrees skill to set up an isolated workspace."

## Step 0: Detect Existing Isolation

**Before creating anything, check if you are already in an isolated workspace.**

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

**Submodule guard:** `GIT_DIR != GIT_COMMON` is also true inside git submodules. Before concluding "already in a worktree," verify you are not in a submodule:

```bash
# If this returns a path, you're in a submodule, not a worktree — treat as normal repo
git rev-parse --show-superproject-working-tree 2>/dev/null
```

**If `GIT_DIR != GIT_COMMON` (and not a submodule):** You are already in a linked worktree. Skip to Step 2 (Project Setup). Do NOT create another worktree.

Report with branch state:
- On a branch: "Already in isolated workspace at `<path>` on branch `<name>`."
- Detached HEAD: "Already in isolated workspace at `<path>` (detached HEAD, externally managed). Branch creation needed at finish time."

**If `GIT_DIR == GIT_COMMON` (or in a submodule):** You are in a normal repo checkout.

Has the user already indicated their worktree preference in your instructions? If not, ask for consent before creating a worktree:

> "Would you like me to set up an isolated worktree? It protects your current branch from changes."

Honor any existing declared preference without asking. If the user declines consent, work in place and skip to Step 2.

## Step 1: Create Isolated Workspace

**You have two mechanisms. Try them in this order.**

### 1a. Native Worktree Tools (preferred)

The user has asked for an isolated workspace (Step 0 consent). Do you already have a way to create a worktree? It might be a tool with a name like `EnterWorktree`, `WorktreeCreate`, a `/worktree` command, a `--worktree` flag, or a CLI the repo standardizes on (e.g. `orca worktree create`). If you do, use it and skip to Step 2.

**Check the repo's instruction files before you pick one** — `CLAUDE.md` and `AGENTS.md` (plus any scoped variants your runtime loads; not every runtime is given both). If one names the command to use — or rules one out — that wins over your own detection. A harness-native tool the repo has excluded (because it forces a branch name, a base ref, or a directory the repo cannot accept) is the wrong mechanism there, not the preferred one.

**A CLI is not a context switch.** Harness tools like `EnterWorktree` move your session into the worktree; a CLI subprocess cannot change its caller's working directory. If you used a CLI, capture the path it created, enter it, and re-run the Step 0 check. If `GIT_DIR != GIT_COMMON` does not hold afterward, stop and report — do not proceed to Step 2 claiming isolation you don't have.

Native tools handle directory placement, branch creation, and cleanup automatically. Using `git worktree add` when you have a native tool creates phantom state your harness can't see or manage.

Only proceed to Step 1b if you have no native worktree tool available.

### 1b. Git Worktree Fallback

**Only use this if Step 1a does not apply** — you have no native worktree tool available. Create a worktree manually using git.

#### Directory Selection

Follow this priority order. Explicit user preference always beats observed filesystem state.

1. **Check your instructions for a declared worktree directory preference.** If the user has already specified one, use it without asking.

2. **Check for an existing project-local worktree directory:**
   ```bash
   ls -d .worktrees 2>/dev/null     # Preferred (hidden)
   ls -d worktrees 2>/dev/null      # Alternative
   ```
   If found, use it. If both exist, `.worktrees` wins.

3. **If there is no other guidance available**, default to `.worktrees/` at the project root.

#### Safety Verification (project-local directories only)

**MUST verify directory is ignored before creating worktree:**

```bash
LOCATION=.worktrees          # or `worktrees` — whichever step 1–3 selected above
git check-ignore -q "$LOCATION"
```

Check **the directory you selected**, not a fixed pair of names. `check-ignore .worktrees ||
check-ignore worktrees` passes when *either* is ignored, so a repo that ignores `worktrees`
while you create `.worktrees` clears the guard and then commits the worktree contents — the
exact outcome this step exists to prevent.

**If NOT ignored:** Add `$LOCATION` to .gitignore, commit the change, then proceed.

**Why critical:** Prevents accidentally committing worktree contents to repository.

#### Create the Worktree

```bash
# Determine path based on chosen location
path="$LOCATION/$BRANCH_NAME"

git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
```

**Sandbox fallback:** If `git worktree add` fails with a permission error (sandbox denial), tell the user the sandbox blocked worktree creation and you're working in the current directory instead. Then run setup and baseline tests in place.

## Step 2: Project Setup

**A worktree inherits only tracked files.** Dependencies, caches, and generated
sources that the repo gitignores are simply absent — Step 3 then fails to
compile and reads as a broken baseline. Setup exists to regenerate them.

**How much of it you run depends on how you got here**, because these paths do
not own the same files:

- **You just created the worktree** (Step 1) — run everything, generators
  included. Nothing in it is anyone's work in progress.
- **You were already in one** (Step 0), or a Step 1a tool created and set it up
  — someone else prepared this tree. Confirm the outputs are there instead of
  regenerating over them.
- **You are in place** (consent declined, or the sandbox fallback) — this is the
  user's working tree. Installs can mutate it too, through lockfiles and
  `postinstall`-style hooks, so check what the repo's setup actually does and
  ask before running anything that rewrites tracked files.

Don't try to replace that distinction with a file check: one generated file says
nothing about the other two hundred, and builders differ in what they even emit,
so probing for output confuses *missing* with *partial* or *stale*.

Auto-detect and run appropriate setup:

```bash
# Node.js
if [ -f package.json ]; then npm install; fi

# Rust
if [ -f Cargo.toml ]; then cargo build; fi

# Python
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi

# Go
if [ -f go.mod ]; then go mod download; fi

# Dart / Flutter
if [ -f pubspec.yaml ]; then
  if grep -q 'sdk: flutter' pubspec.yaml; then flutter pub get; else dart pub get; fi
fi
```

**Generated sources.** Where a repo generates sources and gitignores the output
— `build_runner`, protobuf, ORM schemas — installing dependencies is not enough:
a worktree you just created has none of it, and Step 3 fails to compile on
missing files rather than on anything you did. Run the repo's generator there
(`dart run build_runner build` for Dart; elsewhere whatever `CLAUDE.md` /
`AGENTS.md` names), and re-read the branches above before running it anywhere
else. This is the setup step that writes into the source tree, which is why the
freshly-created branch is the only one that runs it unasked.

## Step 3: Verify Clean Baseline

Run tests to ensure workspace starts clean:

```bash
# Use project-appropriate command
npm test / cargo test / pytest / go test ./...
```

**If tests fail:** Report failures, ask whether to proceed or investigate.

**If tests pass:** Report ready.

### Report

```
Worktree ready at <full-path>
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

## Quick Reference

| Situation | Action |
|-----------|--------|
| Already in linked worktree | Skip creation (Step 0) |
| In a submodule | Treat as normal repo (Step 0 guard) |
| Native worktree tool available | Use it (Step 1a) |
| No native tool | Git worktree fallback (Step 1b) |
| `.worktrees/` exists | Use it (verify ignored) |
| `worktrees/` exists | Use it (verify ignored) |
| Both exist | Use `.worktrees/` |
| Neither exists | Check instruction file, then default `.worktrees/` |
| Directory not ignored | Add to .gitignore + commit |
| Permission error on create | Sandbox fallback, work in place |
| Tests fail during baseline | Report failures + ask |
| No package.json/Cargo.toml | Skip dependency install |

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "I'm obviously not in a worktree — no need to check" | Run Step 0. Harness-created isolation and submodules both fool eyeballing; the detection commands settle it. |
| "`git worktree add` is quicker than hunting for a native tool" | A native tool (e.g. `EnterWorktree`) owns placement, branching, and cleanup. Bypassing it is the #1 mistake — it creates phantom state your harness can't see or manage. |
| "The worktree directory is surely ignored already" | Run `git check-ignore`. An unignored worktree directory commits the whole tree into the repo. |
| "Any directory name works" | Explicit instructions beat an existing project-local directory, which beats the `.worktrees/` default. |
| "The workspace is fresh — baseline tests can wait" | A dirty baseline makes every later failure ambiguous. Run the tests now; proceeding past failures is your human partner's call. |
