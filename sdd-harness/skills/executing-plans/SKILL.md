---
name: executing-plans
description: Use when you are implementing a written plan yourself, task by task with review checkpoints, rather than dispatching a fresh subagent per task
---

# Executing Plans

## Overview

Load plan, review critically, execute all tasks, report when complete.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

## ⛔ Gate — do not start at Step 1

Landing here does not mean option ③ was chosen. It is also where you arrive having chosen
nothing. So before Step 1, fill this sentence in using your human partner's **actual words**:

> "The implementer is ______. My human partner chose that, and what they said was: ______."

**Cannot fill the second blank with something they actually said? Then it is not settled.**
Call `sdd-harness:choosing-an-implementer` now, and do not come back to Step 1 without its
answer. Do not judge whether it "seems settled" — run the sentence.

- **"Follow the plan" / "just execute it" / "start now" is not a choice of implementer.**
  Those say *when* to begin, not *who* writes the code. Reading them as a choice makes you
  report an execution path your human partner never picked.
- **Deadlines, repeated nudges, and "stop asking questions" do not waive this gate.** They
  are the conditions under which it gets skipped, which is why it is written down. Pressure
  means ask **once, with a recommendation attached** — not don't ask.
- **Only exemption:** this session is barred from writing code at all (investigation,
  verification, or review only). Then skip the gate — but **state in your final report that
  the implementer slot was left open**, so the next session opens it instead of inheriting a
  choice nobody made.
- If the plan has 3+ mostly independent tasks, your recommendation defaults to
  `sdd-harness:subagent-driven-development`. Say so **while the slot is still open** — once
  it closes, that advice is spent.

**Note:** Where subagents are available (Claude Code, Codex CLI, Codex App, Copilot CLI, and Gemini CLI all qualify), sdd-harness:subagent-driven-development is usually the stronger workflow — say so **while the implementer slot is still open**. Once choosing-an-implementer has settled on ③, that answer stands and you execute here. Re-routing to subagents at this point spends a decision your human partner already made.

## The Process

### Step 1: Load and Review Plan
1. Ensure an isolated workspace: use sdd-harness:using-git-worktrees to create one or verify the existing one
2. Read plan file
3. Review critically - identify any questions or concerns about the plan
4. If concerns: Raise them with your human partner before starting
5. If no concerns: Create todos for the plan items and proceed

### Step 2: Execute Tasks

For each task:
1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Mark as completed

### Step 3: Complete Development

After all tasks complete and verified:
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** Use sdd-harness:finishing-a-development-branch
- Follow that skill to verify tests, present options, execute choice

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

## When to Revisit Earlier Steps

**Return to Review (Step 1) when:**
- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** - stop and ask.

## Remember
- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Reference skills when plan says to
- Stop when blocked, don't guess
- Never start implementation on main/master branch without explicit user consent
