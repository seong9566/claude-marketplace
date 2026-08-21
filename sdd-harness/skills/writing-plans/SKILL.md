---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

> **Model:** this skill demands architectural judgment. If the session is on a
> cheap tier, move up before starting and back down when done.

**Context:** If working in an isolated worktree, it should have been created via the `sdd-harness:using-git-worktrees` skill at execution time.

**Save plans to:** `docs/plans/YYYY-MM-DD-<feature-name>.md`
- This is a default, not a rule. If the repo's CLAUDE.md (or the user) names a
  plans directory, that wins — check before writing.

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Task Right-Sizing

A task is the smallest unit that carries its own test cycle and is worth a
fresh reviewer's gate. When drawing task boundaries: fold setup,
configuration, scaffolding, and documentation steps into the task whose
deliverable needs them; split only where a reviewer could meaningfully
reject one task while approving its neighbor. Each task ends with an
independently testable deliverable.

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use sdd-harness:choosing-an-implementer to settle who writes the code, then the skill it routes you to, and implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

## Global Constraints

[The spec's project-wide requirements — version floors, dependency limits,
naming and copy rules, platform requirements — one line each, with exact
values copied verbatim from the spec. Every task's requirements implicitly
include this section.]

---
```

## Task Structure

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Interfaces:**
- Consumes: [what this task uses from earlier tasks — exact signatures]
- Produces: [what later tasks rely on — exact function names, parameter
  and return types. A task's implementer sees only their own task; this
  block is how they learn the names and types neighboring tasks use.]

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"
Production path: [where this failure occurs when the app runs — the entrypoint,
  config, or policy that reaches the same code. Write "new — this plan builds it"
  when the path does not exist yet, or "N/A — pure unit" when there is none.]
Config parity: [what the test installs or omits relative to that path — the
  policies, interceptors, and defaults it does *not* inject. Empty means the test
  runs the same wiring production does. For a new path, compare against the
  wiring this plan will install.]
Gate: a non-empty Config parity means this Red is not yet evidence. If that
  wiring **already exists**, re-run with it in place before Step 3 and confirm
  the same failure — if it disappears, stop and report: the premise is a test
  artifact. If **this plan is still building** that wiring, carry the check to
  Step 4 instead: the finished configuration must produce the same failure
  before the fix and pass after. Never skip Step 3 waiting for code Step 3 writes.

- [ ] **Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

## Red Verification — When the Failure Is Wrong, Suspect the Test

Two gates stand before Step 3, and only the first is about a surprising failure.

1. If Step 2 does not fail **for the reason you predicted**, stop. The thing to
   doubt is the test you just wrote, not the implementation.
2. If it *did* fail exactly as predicted, check Step 2's **Config parity** line
   before proceeding. A failure that matches the prediction is what an artifact
   looks like, so a clean Red is not by itself evidence that the bug is real.
   The third case below is reached through this gate.

Gate 2 is about **reproducing behavior that already exists**, so where Step 2
names a real Production path the baseline is that path's current wiring and the
check runs before Step 3. Where the line says the path is new, the gate still
binds — its baseline is the wiring **this plan will install** — but it cannot run
early, because the wiring is what Step 3 writes. There it moves to Step 4: the
finished configuration must show the failure before the fix and its absence
after. A test that only fails under configuration the finished route will never
use sends the implementer after behavior nobody asked for, and that lands in the
first release, not a later one.

**Write the gate into the plan, not just here.** Step 2 above carries a `Gate:`
line for exactly this reason: an implementer receives their task section, not
this skill, so a rule that lives only in the authoring skill never reaches the
person who runs the test.

- **It passed with no implementation** → that test verifies nothing. Common
  causes: an async mock that returns a value immediately instead of exercising
  the real path, an assertion that is always true, or a test that never calls
  the code under test. This failure ships silently — an invalid test is green
  before and after the implementation exists, so nothing ever flags it.
- **It failed for the wrong reason** → dying on a typo, an import error, or a
  missing fixture is not Red.
- **It failed for the predicted reason, but only because of how the test is
  wired** → that is an artifact, not a reproduction. A test that omits a policy
  the app installs — a retry override, an interceptor, a default the production
  entrypoint sets — reproduces the harness, not the bug. Name the production
  path that produces the same failure, then A/B it: keep the app's real
  configuration, leave the fix out, and confirm the failure still appears.
  Measured: a plan was written around "the query screen spins forever", but the
  app already installed `appProviderRetry` — the 30-second timeout came from a
  test that never injected it. An adversarial review overturned the premise
  after the work was done.
In the first two cases, fix the test until it fails **for the intended reason**,
then continue. In the third, give the test the app's real wiring and confirm the
failure survives — or **discard the premise**, because the bug may not exist.

This is why a plan's Red expectation names the failure **message**, not just
`Expected: FAIL` — that alone cannot tell the first two cases apart — and why
Step 2 carries **Production path** and **Config parity** lines, which are what
gate 2 reads. A message matching the prediction is exactly what an artifact
produces, so the prediction alone can never catch the third case.

## No Placeholders

Every step must contain the actual content an engineer needs. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code — the engineer may be reading tasks out of order)
- Steps that describe what to do without showing how (code blocks required for code steps)
- References to types, functions, or methods not defined in any task

**Exception — framework-binding native code.** Where the code binds to a platform
framework (CallKit, Telecom, PushKit, platform channels, lifecycle callbacks), state the
**invariants** the implementation must hold — required call order, which thread, which
callback owns teardown, what must be idempotent — instead of verbatim sample code.
Plan-authored samples for these bindings have been the defect source five times: the plan
cannot check them against the SDK, the implementer trusts them over the real docs, and
review reads them as already-decided. Verbatim code stays the rule for **pure logic**,
where correctness can be judged by reading it.

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.

**2. Placeholder scan:** Search your plan for red flags — any of the patterns from the "No Placeholders" section above. Fix them.

**3. Type consistency:** Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

**4. Symbol grounding — grep, don't recall:** Every symbol, path, and helper the plan references must *already exist in the repo* or be created by an earlier task in this same plan. Grep each one. Steps 1–3 compare the plan against itself and the spec; this is the only step that compares it against the codebase. A plan that calls `AuthRepository.refresh()` when the repo only has `refreshToken()` sends the implementer off to invent an API.

Existing is not the same as usable — read the declaration your grep landed on, not just its line number. Two hits pass the existence check and still mislead: a symbol whose declaration carries a deprecation marker, and a private member whose name repeats in another file, where the hit you read may not be the one the plan's file resolves.

**5. Name collision:** Grep every new class, provider, and file name you introduce. If the name already exists in another feature, the implementer either shadows it or imports the wrong one — and both compile.

Grep only sees what *the repo* declares, so it is blind to names that arrive by inheritance. **Where a task adds a method to a class extending a framework base type, read that base type's public API too.** An inherited member with the same name and a different signature breaks the build, and the plan sails through this step because nothing in the repo declares it. Measured: a plan named a ViewModel method `update`, which collided with riverpod's inherited `AsyncNotifier.update(FutureOr<T> Function(T))` — grep returned zero, and the implementer hit `Too few positional arguments: 1 required, 0 given`.

**6. Test expectations:** For each test the plan writes, ask whether the expected value describes *correct* behavior or merely records *current* behavior. A plan that pins the bug in an assertion turns Red-Green into a ratchet. Watch fixtures where two values coincide by accident — an assertion that passes for the wrong reason reads as coverage and provides none. Negative assertions (`isNot`, `isNotEmpty`, `isNotNull`) slip past this question — current behavior frequently satisfies them already, so the test is green before the implementation exists and the plan's Red never arrives. For each one, state what the code produces *today* and check it against the matcher. Measured: a plan asserted an error message `isNot(contains(<word>))` when the pre-fix message never contained that word.

**7. Repo idiom fit:** Step 4 proves the names exist; this checks the code you wrote *around* them. Every snippet in the plan has to survive this repo's linter and type checker, so compare it against the linter config and against neighboring files that do the same kind of work — annotations the repo does not use, argument values its lint calls redundant, an import order it enforces. Each of these is a convention you can only get right by reading the repo; recalling one from another project puts the defect in the plan, where an implementer will reproduce it verbatim and review will read it as already decided.

**Placement instructions need the same check against a different target.** A snippet that is correct in the file you copied it from can be wrong in the file the task edits, so comparing it to a precedent is not enough — diff the precedent against the *target* on whatever the instruction depends on: the existing import list, whether the handler you are told to wrap already exists, what the surrounding block already does. Measured, both from one plan: "put the `no_retry` import at the top of the block" came from a precedent file that simply had no `logger.dart`, and in both target files the same import sorted later and would have tripped `directives_ordering`; a test step told the implementer to capture `FlutterError.onError` and call `expect` inside it, which in the target's setup died on a binding assertion before reaching the defect.

**8. Verification scope matches the blast radius:** Each task's verify step names the command the implementer runs, and by default that command is scoped to the code the task touches. Where a task widens a shared interface — a new method on an abstract type, a changed signature — that scope is too narrow: implementations live wherever someone wrote one, including fakes in test directories the task never mentions. Scope those tasks' checks to the whole project.

**9. Red grounding — read the wiring you claimed:** Step 2's `Production path` and `Config parity` lines are claims about the repo, and the empty parity line is the one most likely to be wrong — it is what an author writes when they have not looked. Naming a production path does not mean you inspected it. Open the entrypoint that reaches this code and list what it installs (retry policies, interceptors, global defaults, error handlers), then compare that list to what the test sets up. The expensive failure this gate exists to catch comes from a policy the author never knew about, so "no difference" counts only after you have read the entrypoint.

If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.

## Execution Handoff

After saving the plan, report it and hand off the implementer decision:

**"Plan complete and saved to `docs/plans/<filename>.md`."**

- **REQUIRED SUB-SKILL:** Use sdd-harness:choosing-an-implementer, then the skill it routes you to.

Do not ask a two-option "subagent or inline?" question here. That framing drops the third
option — an out-of-harness CLI agent — and offers a menu where choosing-an-implementer
offers a recommendation. Asking twice with different option sets is how a decision gets
made and then quietly re-made.
