---
name: debug-by-comparison
description: Find the cause of a failure by comparing a working implementation with the failing one. Use when something fails and a similar component, build, environment or earlier commit works.
argument-hint: The failing thing and a reference that works.
---

# Debug by comparison

Stop changing things. Find a case that works, and find the difference.

1. **State the failure exactly:** the error text or symptom, when it happens, what must be true for it to happen.
2. **Find a reference that works:** a sibling module, another environment, an earlier commit, a colleague's machine. It should
   share the architecture of the failing one. A `git worktree` at the last good commit is a cheap reference.
3. **Compare side by side:** dependency versions, configuration files, build output, environment variables, startup commands,
   the order things happen in.
4. **Trace the working path** to the point where the failing one diverges. Record each difference.
5. **Test one difference at a time** by making the failing case match the reference on that one point. The difference that
   removes the failure is the cause; the others are noise.
6. **Say what you found and how you know:** the difference, the single change that fixed it, and the evidence. Then apply the
   [`evidence-first`](../evidence-first/SKILL.md) check before you change the real code.
