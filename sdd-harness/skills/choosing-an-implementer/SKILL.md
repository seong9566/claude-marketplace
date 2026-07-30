---
name: choosing-an-implementer
description: Use before executing an implementation plan, to decide who writes the code — an out-of-harness CLI agent, an in-harness subagent, or you — and to put that choice to your human partner with a recommendation
---

# Choosing an Implementer

Before executing a plan, settle **who writes the code**. There are three answers and
they spend your human partner's budget differently — different model bills, different
context burn, different failure modes. That makes it their call.

But you have read the plan and they have not. So you owe them a recommendation, not a
menu. Listing three options evenly throws away the information you already hold.

**Announce at start:** "I'm using choosing-an-implementer to decide who implements this plan."

## Skip this when

- Everything in the plan is trivial mechanical work — renames, formatting, one-line
  fixes, obvious typo or import cleanup. Just do it.
- Your human partner already named the implementer for this plan, in this session or in
  the repo's CLAUDE.md. Their standing instruction wins; do not re-ask.

## The three options

### ① Out-of-harness CLI agent

A separate coding CLI does the editing — Codex CLI, Copilot CLI, Gemini CLI, or
whatever the repo is set up for, reached through a dispatch subagent.

Cheapest in the harness's own tokens. The cost moves to you as the controller: the
agent does **not** inherit CLAUDE.md, project rules, or hooks, so you must excerpt the
rules each task needs into every dispatch, and you own polling and recovery.

**One dispatch per task.** Never hand a multi-task plan to a single job. When a worker
dies mid-run it records neither success nor failure, so every task after the failure
point vanishes silently and you have to excavate progress from logs and `git`. Writing
a detailed completeness contract into the prompt does not prevent this — splitting does.

### ② In-harness subagent

`sdd-harness:subagent-driven-development` dispatches a fresh subagent per task inside
this harness.

Costs harness tokens but saves your main context. The advantage is that CLAUDE.md,
project rules, and hooks load automatically and fire as usual — nothing has to be
excerpted, so nothing leaks in the excerpting.

### ③ You

You write the code yourself, here in this conversation. No round-trip and no handoff
loss. Highest main-context burn.

## Recommend, don't just list

Put your recommended option **first** and label it as recommended. In its description,
name the one signal below that actually applies to this plan — not a generic pitch.
If the signals genuinely conflict, say so and recommend ①.

| Signal in this plan | Points to |
| --- | --- |
| Task boundaries are crisp and verification is mechanical (a lint/type/test command decides pass or fail) | ① |
| Several genuinely independent tasks that can run at once | ① |
| The rules a task needs are short enough to excerpt faithfully | ① |
| Main context is already large | ① |
| Many project rules or hooks to obey — excerpting them is where they'd leak | ② |
| Design judgment is still open inside the implementation | ② |
| You want fresh-eyes review in the same loop as implementation | ② |
| Spec or requirement wording must land verbatim — handoff loss *is* the defect | ③ |
| Two or three files, and exploration is tangled with the edit | ③ |

## Ask

Use the harness's structured question tool (in Claude Code, `AskUserQuestion`) so the
answer is an explicit selection rather than an inference from prose. Put the cost
implication in each option's description — that is what the decision turns on.

## After the answer

| Choice | Then |
| --- | --- |
| ① | Dispatch one task per job to the CLI agent, with the rule excerpts that task needs |
| ② | `sdd-harness:subagent-driven-development` — see its "Without the Bundled Scripts" section if bash is unavailable |
| ③ | `sdd-harness:executing-plans` — it also notes that subagents are usually stronger; that note is for an open slot and does not re-open yours |

**No nesting.** Do not route work through an in-harness implementer subagent that then
re-delegates to the CLI agent. That is a layer and a bill for nothing. Pick one
implementer slot and fill it.

**Verification does not transfer.** Whoever implements, the final verification, build,
and commit stay with you. A sandboxed CLI agent may be unable to run the project's real
verify commands at all, and a subagent's "tests pass" is a claim you have not yet
checked. See `sdd-harness:verification-before-completion`.
