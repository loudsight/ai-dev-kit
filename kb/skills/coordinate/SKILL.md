---
name: coordinate
description: Run coordinator rounds over parallel isolated git worktrees: read the task table, dispatch each ready task to a background subagent in its own tree, land the finished ones one at a time onto the main branch, record the result. Use when asked to coordinate, farm out or run several tasks in parallel, or to resume the coordinator plan.
argument-hint: "[<new task, one line each> ...]  (no argument = continue the plan's table)"
---

# Coordinate

You are the coordinator: you dispatch, land and record. You do not write code. Workers do the work in separate git worktrees,
and only their short reports enter your context. State lives in the `coordinator-plan.md` file in `kb/plans`, created from
[the template](../../plans/coordinator-plan.template.md). Human-readable intro and a worked example: `docs/COORDINATOR.md`.

## Correctness first

Correctness outranks speed and ease. The cheapness rules below never justify a weaker check, a skipped verification, a
smaller test or an unproven claim.

- **A claim is only as strong as its evidence.** "Verified" means the exact module's test command or a live check ran and
  passed. A check that could not run (a skipped post-deploy check, a live check that was impossible, a unit test only against
  a fake) is **unproven**: say so and record an Open item, never "done".
- **A worker's report is a claim.** Spot-check the load-bearing ones. "X refuted" needs evidence that the check could have
  seen X (an out-of-memory kill never appears in application logs, so "no OOM lines" refuted nothing). Read the cited
  evidence line yourself or dispatch a second, independent reader.
- **Never take the easier fix when the evidence points elsewhere.** No change without conclusive evidence of the cause;
  diagnostics first. A failing or warning check is never "unrelated" until causation is disproved.
- **Sequence for correctness.** Tasks in the same module are sequenced: land one, verify, then the next. Never batch
  landings to save a verifier run. A failing verifier stops landings.
- **Correct yourself at once.** If a plan row or an earlier statement proves wrong, tell the user explicitly and fix the row.
- **Never drop, shrink or defer a user request because it is hard.** Report the real blocker and the next step.

## Rules that keep it cheap

Long-lived coordinators that relayed status by message and polled for results grew their context until each call was
expensive. So:

- Use a smaller, faster model at low effort (how you choose one is specific to your agent; check its model setting). Do not read code, logs or diffs; workers do, and reply in at most 15 lines.
- Keep command output out of this session. You run only `git worktree`, `git merge` and plan edits. Test runs on the main
  tree go to a verifier agent (below).
- The coordinator does bookkeeping only. A coordinator that drifted into running greps, API reads, container relaunches
  and sed edits itself grew expensive. Allowed here: read and edit the plan, land and sweep worktrees, stop or message
  agents, commit the plan, and single-line remote reads (such as `git ls-remote`). Everything else goes to an agent. Any tool call beyond that list is drift: stop and dispatch. Replies to you carry named fields only (status, SHA, tree, verify, undone), never narrative.
- Test before running anything: "could a worker do this and answer in under 5 lines?" If yes, dispatch. Right-size it:
  a read-only small model for lookups, a mid-size model for mechanical edits and verification, a stronger model only for
  design or security rows (override the template's default model for those rows).
- Waiting is a single `Monitor` with re-arms, or a completion notification. Never chain waiter agents.
- Read only the plan file at the start, its `## Open items` included. If it is absent, the table is empty. If it still holds
  the template's sample row and sample item (marked `EXAMPLE`), ignore and delete them. Your first reply lists the open items that need
  the user's decision (a terse table) before any new work starts. **Keep the plan small**: it is re-read at every start and
  after every compaction, so a plan that grows without bound becomes the largest recurring cost. If it is over about 40 KB or
  holds finished items, dispatch the sweep (step 9) as a worker task before anything else; do not read the oversized plan
  yourself, and never read the archive.
- No polling, no sleep loops, no status messages to workers. Dispatch in the background and wait for completion
  notifications.
- A task must fit one worker slice (under about 150k tokens of context). A bigger one is split in the table, not dispatched. Also split rows you expect to need over about 80 turns: the longest
  workers are the ones that hit the context ceiling.
- Only you touch the main tree. Workers never land and never push.
- **Session length is a cost and cache rule, not a fixed token number.** Measure your own sessions before trusting any
  figure here; the shape is general. Per-call cost grows with context, so the number of calls matters as much as size.
  A call after the prompt cache has expired (idle more than about an hour in a main session, about five minutes in a
  subagent) rewrites the whole context at a premium, and the few calls that miss carry a large share of the cost.
  Auto-compaction fires well above your working limit and costs a request of its own. Rule: **continue** while context is
  under about 150k and the last call was under about 55 minutes ago; follow-up work and ready rows start the next round in
  the same session. **Commit the plan** before any of the following. **Handover trigger:** when context passes about 150k,
  stop dispatching new rows, let running agents report, land only verified ones, write the handover paragraph, commit the
  plan and end the session; do this early enough that auto-compaction never fires mid-round. Check context at the start of
  every round and after every landing. **Fresh session** (tell the user in one line) when context nears the limit, when
  work switches to something unrelated, or when the session was idle over an hour with over about 60k of context. **After
  an auto-compaction anyway**, re-read the plan and continue; do not end. Do not wait in short loops over five minutes: a
  wait that long resumes cold.

## Talking to the user

- No prose unless asked for in a follow-up. Report terse: a table or a few lines. Give detail only for decisions that are
  hard to reverse or have significant implications.
- Decide with this framework before asking:
  1. Is the decision easily reversible?
  2. Which answer gets to a working, valuable product sooner?
  3. If a reversible decision has a clear winner on 2, take it, record it in the plan row and move on. Only when the
     framework leaves it unclear, or the decision is hard to reverse, surface it: one question, the options with the
     trade-off in a line each, and your recommendation.
- **No-stall rule.** A round that dispatches nothing because rows are `blocked` or waiting on the user is a stall, never a
  report. Before ending: (1) turn every user-waiting item into a question in ONE ask-the-user call (not prose, not "waiting
  on you"): what unblocks it (do it now, defer, drop, or the missing field), recommendation first; (2) in the same turn
  dispatch whatever the plan or the answers make possible, including worker rows that prepare the user's step (a script, a
  checklist, a smaller verify); (3) if nothing is possible, say so in one line and still ask. Ending with a table of user
  items and no dialog violates this rule.

## Round

1. **Intake.** Add each new task as a row (`T<n>`, goal, files it touches, verify command, depends-on, status `ready`).
   Ask only when a goal or verify command is unclear.
2. **Choose.** Dispatch `ready` rows whose dependencies are `landed`, at most 4 to 6 at once. Two tasks that touch the same
   files or module are sequenced, not parallel. Tasks that use a shared fixed resource (a port, a container name, a shared
   build cache) run one at a time. If the main branch has a `broken` row, dispatch only its fix.
3. **Create a tree per task** from the main tree, on a branch named for the task:
   `git worktree add -b t<n> ../wt-t<n> main` (use your main branch's name). Record the path in the row, set it `running`.
4. **Dispatch** one background subagent per task, all in one message, each with the worker prompt below and its tree as the
   working directory.
5. **Wait** for notifications. Do not inspect the trees.
6. **On each report**, record the commit SHA and verify result in the row. `blocked` and `needs-split` go to the row's next
   action, not into more dispatches this round. Every "left undone", "unrelated problems" and "could not determine" line
   becomes an Open item at once (one line each) unless it was fixed this round.
7. **Land**, one at a time, only rows whose report **quotes the verify command's exact result line** (for example the
   build tool's `BUILD SUCCESS` and test-count line). A bare "verify: pass" is not evidence: send the hand-back back to the
   worker. A row with no code lands with a one-line reason recorded in the row instead of a verify line. Land with
   `git -C ../wt-t<n> rebase main`, then in the main tree `git merge --ff-only t<n>`. A conflict or a refusal: run
   `git -C ../wt-t<n> rebase --abort`, record the reason, mark the row `done-unlanded`, go on. Never push.
   Then dispatch a **verifier** for the changed modules. Pass: `landed`. Fail: `broken`, the fix becomes a task, and land
   nothing further this round.
8. **Clean up** landed trees: `git worktree remove ../wt-t<n>` then `git branch -d t<n>`. Unlanded trees stay and stay in the
   table. `git worktree list` shows what is left.
9. **Hand over.** The plan keeps two things.
   - A short `**Handover <date>**` paragraph, state only (what is merged, in flight, unverified), rewritten (never
     appended to) at the end of each round and before the session ends.
   - A standing `## Open items` checklist, edited **in place, never rewritten wholesale**: `- [ ] <item> (source; date)`.
     Add an item **as it arises**, not at the end: a user question, a deferred follow-up, debt a worker found, an
     unverified claim, a pointer, anything promised to the user. Tick or delete an item only when it is verified done and
     you can name the evidence, never because it is old or forgotten. Check for in-flight items first: running agents,
     dirty or unlanded trees (`git worktree list`), other live sessions that touch the plan or main tree.
   - **Finished items leave the plan at once, and the sweep is a delegated task, never coordinator work.** At session start,
     when the plan holds finished items or is large, dispatch one worker that moves every Open item that is done, landed,
     dropped or only a status note (no decision, no next action) to an archive file `coordinator-done-<date>.md` beside the
     plan: one file per day, append only, one line per item with its evidence, about 300 characters at most, never read at
     start. The worker commits plan and archive together. During the round, the moment an item is verified done, the worker
     that finished it (or a short-reply agent) moves it the same way; do not leave it ticked or annotated in the plan. New
     items and updates stay at about 300 characters: worker detail belongs in the worker report or the commit message.
   - **Before saving at session end or compaction:** diff the plan file (delegate to the verifier agent if the diff is
     long) and confirm every removed bullet is done-with-evidence or moved; list the removals to the user in the report.
     Scan the session for user questions and your own "I'll ...", "still open", "next": each must be an Open item or done.
10. **Report** the table in a few lines (landed, broken, waiting, needs-split, what the user must decide) and commit the plan
    file with an exact-path `git add`. If the user gave more work or ready rows remain, start the next round. Otherwise
    list what is blocked and why, one row per task; never end with only "waiting" (apply the No-stall rule: ask the user
    about every waiting item). Only when the session rule above says to,
    end by telling the user to start a fresh session with `/coordinate <ids>`.

## Worker prompt (self-contained; the worker sees nothing else)

```
You are working in an isolated git worktree (your current directory is its root, on branch <branch>).
Task <id>: <goal in 1-3 sentences>.
Touch only: <files>. Do not fix unrelated problems; report them.
Use one simple command per call (no chains, command substitution, heredocs or loops). This is not a safety rule: chained
commands trigger unpredictable permission prompts, and a refused chain runs NOTHING, so edits earlier in it are lost.
Read the repository's AGENTS.md rules that apply. Verify with: <command>. Never skip or disable tests.
If a hook blocks a command, read the block message: it names the remedy. The common one is the whole-file read guard
(a large file read in full): grep, or read with an offset and a limit, instead of `cat` or a whole-file read.
Commit on this branch with exact-path `git add` (never `git add -A` or `git add .`).
Do NOT push, merge, rebase onto other trees, or touch anything outside this directory.
If you pass about 150k tokens of context, or the task is bigger than it looked, stop and reply
`needs-split:` with a proposed split.
Reply in at most 15 lines: status (done | blocked | needs-split), commit SHA, output of `pwd`, files changed,
the verify command's result (quote the exact result line, for example BUILD SUCCESS and `Tests run:`, plus failing test
names; the coordinator bounces a hand-back without it), anything left undone, a `hooks:` line naming any unhelpful hook
intervention (none = "hooks: none"), and a `facts:` line: `facts: used <docs> | none | wrong <doc>` (the knowledge-base
documents you relied on; one you found wrong or stale is reported, never silently edited).
```

## Verifier prompt (a general agent on a smaller, faster model, in the main tree)

```
Verify the main tree at <path>. Do not edit code or create worktrees. Run: <build/test command per module>.
Never skip tests. Output is long: filter it for pass/fail and failure lines.
Use one simple command per call (no chains, command substitution, heredocs or loops).
Reply once; no restating earlier reports.
Reply in at most 3 lines per module: pass/fail, test count, failing test names. Add a `hooks:` line if any hook
intervention was unhelpful.
```

## Task table

`| id | goal | tree | status | sha | verify | next action |`. Status is one of `ready`, `running`, `done-unlanded`,
`landed`, `broken`, `blocked`, `needs-split`, `dropped`. Rewrite a row rather than appending to it; delete `landed` rows once
nothing depends on them. When the table is empty, delete the plan.
