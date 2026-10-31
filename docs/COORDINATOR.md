# Coordinator

A coordinator is one agent session that does no coding. It keeps a table of tasks, gives each ready task to a background
worker in its own git worktree, lands the finished ones onto your main branch one at a time, and has a smaller, faster verifier agent check
the result. You get parallel work without parallel agents editing one checkout.

**Why a table and short sessions.** Early coordinators ran for days, relayed status by message and polled for results. The
context grew with every call, and long-lived sessions became expensive. This design keeps state in a file, lets workers report
in 15 lines, never polls, and ends the session when context gets large.

```
task table (file)  ->  coordinator  ->  worker A (worktree wt-t1)  ->  report
                                    ->  worker B (worktree wt-t2)  ->  report
                       coordinator lands A, then B (fast-forward)  ->  verifier  ->  table updated
```

**Terms.** A *worktree* is a second checkout of the same repository in its own directory, on its own branch, so a worker can
edit without touching your files. *Rebase* replays a branch's commits on top of the latest main. *Fast-forward* moves main
forward to that branch with no merge commit. Row statuses: `ready` (can be dispatched), `running` (a worker has it), `landed`
(merged into main and verified), `broken` (merged but the verifier failed); the full list is in the plan template.

Needs: git 2.17 or later, an agent that can start background subagents (Claude Code does), and a test or check command per
task. From [QUICKSTART.md](QUICKSTART.md) you need only step 1 (copy the files, including `docs/COORDINATOR.md`, which the skill
and template link to) and step 6 (link the skills); the hooks, ceiling and `AGENTS.md` steps are optional here. Java 25 and
Maven are needed only for the final verify command. Examples use `main`; use your main branch's name, and in a toy repository
create it with `git init -b main` if your git defaults to `master`.

Without an agent that can run background subagents, run each worker yourself: open one agent session per worktree (in that
directory), paste the same worker prompt, and bring the reply back to the coordinator session.

## Set up

0. **Commit the kit files first** (QUICKSTART step 1) so that worktrees cut from `main` contain `kb/`, `AGENTS.md` and the rest:
   `git add AGENTS.md CLAUDE.md .gitignore .gitattributes kb docs tools scripts .claude .syn && git commit -m "Add ai-dev-kit"`
   Never commit `tools/syn/.syn-cache/` (a downloaded cache; `.gitignore` excludes it, so do not copy it over).
1. **Link the skill** (skip if QUICKSTART step 6 already linked all of `kb/skills/`):
   `mkdir -p .claude/skills && ln -s ../../kb/skills/coordinate .claude/skills/coordinate`
2. **Create the plan from the template:** `cd kb/plans && cp coordinator-plan.template.md coordinator-plan.md && cd ../..`, then open the new file, **delete the `EXAMPLE` row (keep the table header)** and rewrite the Handover line.
3. **Commit both** so the main tree is clean: `cd kb/plans && git add coordinator-plan.md && cd ../.. && git add .claude/skills/coordinate && git commit -m "Add coordinator plan"`
4. **Start your agent in the main tree** and run `/coordinate` followed by one quoted line per task. Say which files each task touches in the line (as below); if you leave it out, the coordinator infers it from the goal and asks when unsure.

## Worked example: two independent toy tasks

In a scratch repository set up as above, start a session and type:

```
/coordinate "Add five terms, one per line. Touches: docs/glossary.md. Verify: test -s docs/glossary.md" "Add three questions. Touches: docs/faq.md. Verify: test -s docs/faq.md"
```

The coordinator adds two rows. The files differ, so the tasks are independent. Table before:

| id | goal | tree | status | sha | verify | next action |
|---|---|---|---|---|---|---|
| T1 | Add `docs/glossary.md`, five terms | | ready | | `test -s docs/glossary.md` | dispatch |
| T2 | Add `docs/faq.md`, three questions | | ready | | `test -s docs/faq.md` | dispatch |

The worker prompt template is in [the skill](../kb/skills/coordinate/SKILL.md). The coordinator creates the trees (you could run these yourself):

```
git worktree add -b t1 ../wt-t1 main
git worktree add -b t2 ../wt-t2 main
```

It then starts two background subagents in one message. Worker prompt for T1 (T2 is the same with its own values):

```
You are working in an isolated git worktree (your current directory is its root, on branch t1).
Task T1: Add docs/glossary.md with five terms, one per line.
Touch only: docs/glossary.md. Do not fix unrelated problems; report them.
Read the repository's AGENTS.md rules that apply. Verify with: test -s docs/glossary.md. Never skip or disable tests.
Commit on this branch with exact-path `git add` (never `git add -A` or `git add .`).
Do NOT push, merge, rebase onto other trees, or touch anything outside this directory.
If you pass about 150k tokens of context, or the task is bigger than it looked, stop and reply
`needs-split:` with a proposed split.
Reply in at most 15 lines: status (done | blocked | needs-split), commit SHA, output of `pwd`, files changed,
the verify command's result (pass/fail and failing test names), anything left undone.
```

Each worker replies with `status: done`, a SHA, its path and `verify: pass`. The coordinator lands them one at a time:

```
git -C ../wt-t1 rebase main
git merge --ff-only t1
git -C ../wt-t2 rebase main
git merge --ff-only t2
```

T2's rebase picks up T1's commit; the files do not overlap, so it succeeds. A verifier agent (the skill's verifier prompt) then runs
each verify command on the main tree and replies with at most three lines per module: pass or fail, the test count and any
failing test names.

```
docs/glossary.md: pass, 1 check, no failures
docs/faq.md: pass, 1 check, no failures
repo: pass, 1 check, no failures
```

The `repo:` line is the coordinator's extra check that the kit's own rules still hold after landing
(`tools/syn/syn script-check-conventions`). It is a convention, not a requirement.
The coordinator marks both rows `landed`, cleans up, and commits the plan:

```
git worktree remove ../wt-t1
git branch -d t1
git worktree remove ../wt-t2
git branch -d t2
cd kb/plans
git add coordinator-plan.md
git commit -m "Coordinator: T1, T2 landed"
cd ../..
```

Table after (`<sha>` is what `git log --oneline -1` shows on main right after that task's merge; a rebase changes the worker's SHA, so do not copy the one from its reply):

| id | goal | tree | status | sha | verify | next action |
|---|---|---|---|---|---|---|
| T1 | Add `docs/glossary.md`, five terms | | landed | `<sha>` | `test -s docs/glossary.md` | delete next round |
| T2 | Add `docs/faq.md`, three questions | | landed | `<sha>` | `test -s docs/faq.md` | delete next round |

## Hard rules

- Only the coordinator touches the main tree. Workers commit on their own branch and never land or push.
- Land one task at a time, fast-forward only. A rebase conflict means: `git -C ../wt-tN rebase --abort`, mark the row
  `done-unlanded`, and make the conflict a follow-up task.
- Tasks that touch the same files run one after another. A task that does not fit about 150k tokens of context is split.
- Never push from the coordinator unless you decide to; landing is local.

## What to watch

- **Context.** End the session near 150k tokens or after any compaction and start a fresh one; the plan file carries the state.
- **Collisions.** Besides files, parallel trees share anything outside the checkout: ports, container names, a shared build
  cache. Run those tasks one at a time.
- **Leftovers.** `git worktree list` should show only the main tree when a round ends cleanly.

## Verify

After the example, the main tree has both files and no extra trees:
`git worktree list && test -s docs/glossary.md && test -s docs/faq.md && tools/syn/syn kb-check-links`
The list shows one line, and the other commands exit 0. Only the last command needs Java 25 and Maven; the rest need git alone. The first `syn` run downloads from Maven Central, so it needs network access.
