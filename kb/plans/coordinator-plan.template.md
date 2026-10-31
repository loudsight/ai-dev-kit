# Coordinator plan

Copy to `coordinator-plan.md` in this directory. Used by the [coordinate skill](../skills/coordinate/SKILL.md); intro in
[`docs/COORDINATOR.md`](../../docs/COORDINATOR.md). Delete the file when the table is empty.

**Handover (date):** nothing yet. Replace this paragraph each round: what is unverified, what waits on a person, pointers for
the next round.

Status: `ready` | `running` | `done-unlanded` | `landed` | `broken` | `blocked` | `needs-split` | `dropped`.

| id | goal | tree | status | sha | verify | next action |
|---|---|---|---|---|---|---|
| T1 | Add `docs/glossary.md` with five terms | `../wt-t1` | running | | `test -s docs/glossary.md` | wait for report |
