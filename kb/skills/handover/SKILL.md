---
name: handover
description: Pause a coordinator or other long session safely: stop intake, let every live agent reach a safe-to-pause state, reconcile trees and pushes, and write a Handover plus Resume instructions so the next session can pick up without trusting anything stale. Use when asked to pause, hand over or end a coordinator or long session, or when context is genuinely nearly full. Ends the session only after the handover is committed.
argument-hint: "(no argument)"
---

# Handover

A deliberate pause. It works inside a `/coordinate` session and obeys its rules
([the coordinate skill](../coordinate/SKILL.md), "Rules that keep it cheap" and the Round steps for landing, clean-up and
hand over): the coordinator does bookkeeping only here, and everything else goes to short-reply agents. State lives in
`coordinator-plan.md` and `coordinator-handover.md` in `kb/plans`.

**When.** The user asks to pause, or there is real context pressure. Context, not feeling, is the trigger: check actual
context before declaring it.

## Steps

1. **Stop intake.** Dispatch nothing new; land nothing unverified. No polling or `sleep`: wait for completion notifications
   (or one monitor call). List the live agents to see what is running.
2. **Classify every live agent and task** and act by its safe-to-pause state. Never stop an agent in the middle of a git
   operation, a landing, a push or a deploy.

   | State | Action |
   |---|---|
   | Worker committed and replied | Done: land per the coordinate Round if the report quotes a passing verify line |
   | Verifier mid-build | Wait (read-only, short) |
   | Push agent | Wait until it reports; never interrupt a push |
   | Deploy running | **Never stop.** Wait for the post-deploy verdict; record the run id and log path; have an agent summarise the log |
   | Anything writing to a shared environment's data or a remote host | Wait |
   | Long worker not near done | Ask the user: wait, message it to reach a clean commit point and report, or stop it and record its tree and last commit as unlanded |

3. **Reconcile** through a read-only short-reply agent (the coordinator drift rule: only worktree listing, remote-ref reads
   and plan edits run here). It reports: `git status` of the main tree and of `kb`; unpushed commits per repository
   (superproject, `kb`, each submodule); the worktree list (live, landed, unlanded trees); whether the main tree holds any of
   this session's own uncommitted changes; and anything waiting on the user. Unless the user said otherwise, push through a
   short-reply push agent, within your project's push rules (a public repository may need a pull request and permission).
   **Never deploy as part of a handover.**
4. **Write the handover.** Rewrite `**Handover <date>**` in `coordinator-handover.md` beside the plan: a separate file, never
   the plan; state only; it replaces the whole file and is never appended to; the next coordinator deletes it once actioned. Add
   `### Resume instructions` under it: one entry per in-flight item (template below), then the rules for the next coordinator
   (below), copied in or linked here.
5. **Open items check** as in the coordinate Round: add items as they arise, tick one only with named evidence, run
   `git -C kb diff plans/coordinator-plan.md` and list every removed bullet to the user before saving. Commit exact paths:
   `git -C kb add plans/coordinator-plan.md plans/coordinator-handover.md`, then `git -C kb commit`. Push `kb` via the push
   agent.
6. **Report** in a few lines:

   | landed | unlanded | stopped | unproven | waiting on user |
   |---|---|---|---|---|

   End with "Start a fresh session with /coordinate <ids>". End the session on this skill's authority only **after** the
   handover is committed.

## Resume instructions entry (template)

```
- <id> — tree: <path> — last commit: <sha> (<repo>)
  done: <what is committed>
  undone: <what is left>
  verified: <named evidence: module and its verify result, post-deploy verdict, ...> | unproven: <claim, why>
  first action: <exact safe first step for the next coordinator>
```

## Rules for the next coordinator (put these under Resume instructions)

- Read the Handover and Resume instructions **first**. Every claim is unverified until re-checked: `git log` in the tree,
  `git cherry` against the main branch, re-run the verify (by agent).
- The live-agent list is empty in a new session: the old agents are gone, and a message cannot cross sessions.
- A stopped worker's tree is resumed by dispatching a **new** worker whose prompt names the tree path and last SHA and says
  "continue in that tree" (or discard and redo: the user's choice). Never assume the old agent lives.
- Interrupted deploy: first have an agent read the run's summarised log, the current container or service state and whether
  the deploy lock is still held. Never re-run the deploy until the post-deploy verdict is known; a rollback needs the user's
  go.
- Landed-but-unverified row: dispatch the main-tree verifier before anything else.
- Unpushed commits: push first (push agent).
- Waiting-on-user questions: ask them at the start.
- Dirty main-tree files that are not ours: leave alone.

## Rules

- Ask open questions through your agent's question tool, one at a time.
- Reports to the user are terse: a table or a few lines, naming what ran and what it showed.
- Never drop or shrink a user request; an unfinished one becomes an Open item.
- Correctness first: a claim is only as strong as its evidence; anything not re-checked is **unproven**.
