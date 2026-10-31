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

- Use a cheap model at low effort. Do not read code, logs or diffs; workers do, and reply in at most 15 lines.
- Keep command output out of this session. You run only `git worktree`, `git merge` and plan edits. Test runs on the main
  tree go to a verifier agent (below).
- Read only the plan file at the start. If it is absent, the table is empty.
- No polling, no sleep loops, no status messages to workers. Dispatch in the background and wait for completion
  notifications.
- A task must fit one worker slice (under about 150k tokens of context). A bigger one is split in the table, not dispatched.
- Only you touch the main tree. Workers never land and never push.
- End the session when context nears 150k or after any compaction: commit the plan and tell the user to start a fresh
  session. Never continue after a compaction.

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
   action, not into more dispatches this round.
7. **Land**, one at a time, only rows reporting `verify: pass`:
   `git -C ../wt-t<n> rebase main`, then in the main tree `git merge --ff-only t<n>`. A conflict or a refusal: run
   `git -C ../wt-t<n> rebase --abort`, record the reason, mark the row `done-unlanded`, go on. Never push.
   Then dispatch a **verifier** for the changed modules. Pass: `landed`. Fail: `broken`, the fix becomes a task, and land
   nothing further this round.
8. **Clean up** landed trees: `git worktree remove ../wt-t<n>` then `git branch -d t<n>`. Unlanded trees stay and stay in the
   table. `git worktree list` shows what is left.
9. **Hand over.** Rewrite (never append to) one `**Handover <date>**` paragraph in the plan: what is unverified, what is
   waiting on a person, pointers the next round needs.
10. **Report** the table in a few lines (landed, broken, waiting, needs-split, what the user must decide) and commit the plan
    file with an exact-path `git add`. If ready rows remain, start the next round.

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

## Verifier prompt (a general agent, cheap model, in the main tree)

```
Verify the main tree at <path>. Do not edit code or create worktrees. Run: <verify commands for the changed modules>.
Never skip tests. Output is long: filter it for pass/fail and failure lines.
Reply in at most 3 lines per module: pass/fail, test count, failing test names.
```

## Task table

`| id | goal | tree | status | sha | verify | next action |`. Status is one of `ready`, `running`, `done-unlanded`,
`landed`, `broken`, `blocked`, `needs-split`, `dropped`. Rewrite a row rather than appending to it; delete `landed` rows once
nothing depends on them. When the table is empty, delete the plan.
