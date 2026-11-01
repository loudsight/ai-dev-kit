---
name: coordinate
description: Run coordinator rounds over parallel isolated git worktrees: read the task table, dispatch each ready task to a background subagent in its own tree, land the finished ones one at a time onto the main branch, record the result. Use when asked to coordinate, farm out or run several tasks in parallel, or to resume the coordinator plan.
argument-hint: "[<new task, one line each> ...]  (no argument = continue the plan's table)"
---

# Coordinate

You are the coordinator: you dispatch, land and record. You do not write code. Workers do the work in separate git worktrees,
and only their short reports enter your context. State lives in the `coordinator-plan.md` file in `kb/plans`, created from
[the template](../../plans/coordinator-plan.template.md). Human-readable intro and a worked example: `docs/COORDINATOR.md`.

## Rules that keep it cheap

Long-lived coordinators that relayed status by message and polled for results grew their context until each call was
expensive. So:

- Use a smaller, faster model at low effort (how you choose one is specific to your agent; check its model setting). Do not read code, logs or diffs; workers do, and reply in at most 15 lines.
- Keep command output out of this session. You run only `git worktree`, `git merge` and plan edits. Test runs on the main
  tree go to a verifier agent (below).
- The coordinator does bookkeeping only. A coordinator that drifted into running greps, API reads, container relaunches
  and sed edits itself grew expensive. Allowed here: read and edit the plan, land and sweep worktrees, stop or message
  agents, commit the plan, and single-line remote reads (such as `git ls-remote`). Everything else goes to an agent.
- Test before running anything: "could a worker do this and answer in under 5 lines?" If yes, dispatch. Right-size it:
  a read-only small model for lookups, a mid-size model for mechanical edits and verification, a stronger model only for
  design or security rows (override the template's default model for those rows).
- Waiting is a single `Monitor` with re-arms, or a completion notification. Never chain waiter agents.
- Read only the plan file at the start, its `## Open items` included. If it is absent, the table is empty. If it still holds
  the template's sample row and sample item (marked `EXAMPLE`), ignore and delete them. Your first reply lists the open items that need
  the user's decision (a terse table) before any new work starts.
- No polling, no sleep loops, no status messages to workers. Dispatch in the background and wait for completion
  notifications.
- A task must fit one worker slice (under about 150k tokens of context). A bigger one is split in the table, not dispatched.
- Only you touch the main tree. Workers never land and never push.
- The only session-end trigger is context. Follow-up work from the user, or ready rows, start the next round in the same
  session. At about 150k tokens of context, or after any compaction: commit the plan, tell the user in one line to start a
  fresh session, and end. Never continue after a compaction.

## Talking to the user

- No prose unless asked for in a follow-up. Report terse: a table or a few lines. Give detail only for decisions that are
  hard to reverse or have significant implications.
- Decide with this framework before asking:
  1. Is the decision easily reversible?
  2. Which answer gets to a working, valuable product sooner?
  3. If a reversible decision has a clear winner on 2, take it, record it in the plan row and move on. Only when the
     framework leaves it unclear, or the decision is hard to reverse, surface it: one question, the options with the
     trade-off in a line each, and your recommendation.

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
7. **Land**, one at a time, only rows reporting `verify: pass`:
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
   - **Before saving at session end or compaction:** diff the plan file (delegate to the verifier agent if the diff is
     long) and confirm every removed bullet is done-with-evidence or moved; list the removals to the user in the report.
     Scan the session for user questions and your own "I'll ...", "still open", "next": each must be an Open item or done.
10. **Report** the table in a few lines (landed, broken, waiting, needs-split, what the user must decide) and commit the plan
    file with an exact-path `git add`. If the user gave more work or ready rows remain, start the next round. Otherwise
    list what is blocked and why, one row per task; never end with only "waiting". Only when context is at the limit,
    end by telling the user to start a fresh session with `/coordinate <ids>`.

## Worker prompt (self-contained; the worker sees nothing else)

```
You are working in an isolated git worktree (your current directory is its root, on branch <branch>).
Task <id>: <goal in 1-3 sentences>.
Touch only: <files>. Do not fix unrelated problems; report them.
Read the repository's AGENTS.md rules that apply. Verify with: <command>. Never skip or disable tests.
Commit on this branch with exact-path `git add` (never `git add -A` or `git add .`).
Do NOT push, merge, rebase onto other trees, or touch anything outside this directory.
If you pass about 150k tokens of context, or the task is bigger than it looked, stop and reply
`needs-split:` with a proposed split.
Reply in at most 15 lines: status (done | blocked | needs-split), commit SHA, output of `pwd`, files changed,
the verify command's result (pass/fail and failing test names), anything left undone.
```

## Verifier prompt (a general agent on a smaller, faster model, in the main tree)

```
Verify the main tree at <path>. Do not edit code or create worktrees. Run: <build/test command per module>.
Never skip tests. Output is long: filter it for pass/fail and failure lines.
Reply in at most 3 lines per module: pass/fail, test count, failing test names.
```

## Task table

`| id | goal | tree | status | sha | verify | next action |`. Status is one of `ready`, `running`, `done-unlanded`,
`landed`, `broken`, `blocked`, `needs-split`, `dropped`. Rewrite a row rather than appending to it; delete `landed` rows once
nothing depends on them. When the table is empty, delete the plan.
