---
name: session-close
description: Close a finished, abandoned or interrupted agent session so nothing stays open: file its learnings, retire or promote its plans, record leftover work. Use when a session ended with work open.
argument-hint: "[<session-id> | --open]  (no argument = the current session)"
---

# Session close

A session is open when its transcript ends mid-action, on an unanswered question, or on a hand-back (an offer, named leftovers).
Closing it means leaving no loop inside: what it learned is in `kb/`, the plans it wrote are filed or retired, undone work is in a
plan, and a commit says the session is closed.

`tools/syn/syn session-list-open` nominates sessions from your local Claude Code transcripts (it nominates; it does not decide),
and `session-inspect-transcript <id>` shows one session's plans, commits, touched files and ending.

## Rules

- **Never close a live session,** including this one. `session-list-open` shows running ones apart.
- **Propose, then write.** Nothing goes into `kb/` until the proposal is approved. Never push.
- Stage exact paths. Leave alone files with uncommitted changes you did not make.

## Steps

1. **Read the evidence:** the transcript's ending, its commits, its plans, and `git status`.
2. **For each learning,** decide its home with the filing table in `kb/README.md`. Record only what a competent reader would
   otherwise get wrong, dated, and verified against the code.
3. **For each plan the session wrote,** file it under `kb/plans/`, or retire it if the work shipped (relocate before deleting).
4. **For each loop left open,** add it to a plan, or state why it is dropped.
5. **Mark it closed** with a commit trailer, `Closes-session: <id>`. `session-list-open` then skips it.
