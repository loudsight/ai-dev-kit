---
name: sweep-kb
description: Triage plans against the actual tree, move durable knowledge to its proper home, then retire what is finished. Use when plans have piled up or after a large piece of work ships.
argument-hint: Optional directory to sweep; defaults to kb/plans.
---

# Sweep the knowledge base

Read `kb/README.md` § *Where does this go?* first. Do not invent destinations.

**Relocate before you delete.** "Strip what is done, delete what is empty" loses anything durable that was written into a plan
because the plan happened to be where the work started. Judgement work, not a script.

1. **Inventory.** List each file with its last-commit date (`git log -1 --format=%ad --date=short -- <file>`). A bulk-commit date
   says nothing. Note untracked files: they are usually the newest and most live.
2. **Check each plan against the tree.** Is the work done, partly done, abandoned or still wanted? Look at the code, not at the
   plan's own status line.
3. **Classify every surviving paragraph** with the filing table. Work not done stays. A decision, procedure, structural fact or
   open problem moves to its home first.
4. **Strip, then decide.** After the moves, remove shipped sections. If nothing actionable remains, retire the file.
5. **Repoint references,** then run `tools/syn/syn kb-check-links`.
6. **Report** what moved where and what was retired, so the reviewer can check nothing was lost. Propose first; write after approval.
