# Coordinator plan

This file is the coordinator's task table, used by the [coordinate skill](../skills/coordinate/SKILL.md); intro in
[`docs/COORDINATOR.md`](../../docs/COORDINATOR.md). Delete the file when the table is empty.

**Handover (date):** nothing yet. Replace this paragraph each round; state only: what is merged, in flight and unverified.

## Open items

Edit in place, never rewrite wholesale. Format: `- [ ] <item> (source; date)`. Add items as they arise; tick or delete one
only when verified done, naming the evidence.

- [ ] EXAMPLE: sample item, delete it (template; date)

Keep this file small (about 40 KB at most): it is re-read at every session start. Finished items move to a dated archive file
beside it (`coordinator-done-<date>.md`, one line each, evidence kept) by a sweep worker, never by the coordinator. Keep each
item about 300 characters. Land a row only on its worker's quoted verify result line; a check that could not run is
unproven and stays an Open item.

Status: `ready` | `running` | `done-unlanded` | `landed` | `broken` | `blocked` | `needs-split` | `dropped`.

| id | goal | tree | status | sha | verify | next action |
|---|---|---|---|---|---|---|
| EXAMPLE | Sample row, delete it: add `docs/glossary.md` | `../wt-t1` | running | | `test -s docs/glossary.md` | delete this row |
