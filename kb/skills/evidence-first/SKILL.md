---
name: evidence-first
description: Check that a fix is backed by conclusive evidence before changing code. Use before editing code to fix a bug, change a config, or revert something.
---

# Evidence first

Do not change code to fix something until you can show that the change fixes it. If you cannot, keep investigating.

## Fine without conclusive evidence

Running tests and collecting the output, adding diagnostic logging, reading logs and stack traces, reading the code, comparing a
working path with the failing one, checking configuration and environment state.

## Not fine without it

Editing code on a hunch, changing configuration "to see if it helps", applying the fix from a similar-looking issue, trial and
error, and reverting a change you do not understand.

## What conclusive means

- **Reproducible:** steps that trigger it every time.
- **Causal:** the root cause explains the symptom, not just coincides with it.
- **Mechanism understood:** you can say why the fix works.
- **Validated:** a test or run shows the fix works and breaks nothing else.

| Situation | Do |
|---|---|
| Reproducible, root cause known | Fix it |
| Reproducible, root cause unknown | Gather more diagnostics |
| Not reproducible | Ask for reproduction steps, or add diagnostics and wait |
| It seems fixed but you do not know why | Find out before committing anything |
| A change failed and you do not know why | Do not retry; investigate the failure |

## While investigating

Only diagnostic changes are allowed: logging, assertions that do not alter behaviour, a failing test that reproduces the issue.
Mark them so they can be removed or kept deliberately.
