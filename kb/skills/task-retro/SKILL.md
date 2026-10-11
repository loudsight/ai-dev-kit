---
name: task-retro
description: Two-pass retrospective when a task is finished: clean up the diff, then look at the session for workflow friction. Use when the user says a task is done, complete or shipped.
---

# Task retro

Run pass A first. Run pass B only when asked, or when pass A showed friction worth encoding. **Never edit configuration without
approval,** one finding at a time.

Set the boundary first: `git diff --stat <base>...HEAD`, where `<base>` is where the task started. If you cannot tell, ask. Do not
review an unbounded diff.

## Pass A: the diff

- Dead code, leftover diagnostics, commented-out code, TODOs you added.
- Duplicated logic that now has a second copy.
- Names, comments and docs that no longer match the behaviour.
- Tests: does each new behaviour have one that fails without the change?
- Anything in the diff that was not asked for.

## Pass B: the session

- Where did the agent waste effort: a file it kept re-reading, a command it had to look up, a wrong turn that a rule would have
  prevented?
- Which of those can be **codified** as a command, a check or a test, instead of written down as prose?
- Which instruction in `AGENTS.md` was ignored, wrong or stale?
- What should be a line in `AGENTS.md` linking to `kb/`, and what belongs in `kb/` alone?

Report findings with the evidence for each. Propose the smallest edit that would have prevented the friction.
