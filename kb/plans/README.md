# Plans

A plan is work that is not done. When the work ships, relocate anything durable (a decision to `../decisions/`, a procedure to
`../recipes/`, a structural fact to `../architecture/`) and delete the plan. The code is the record.

One flat file per piece of work: `plans/<kebab-case-work-name>.md`, never a subdirectory. Plan-mode output lands in `inbox/`
first; the agent's tool names it, you rename and file it.

## House style

```
# <What is being done>

## Why        One paragraph: the problem, and what happens if nothing is done.
## Sketch     The approach, concrete enough to execute. What is deliberately not done.
## Open questions   Decisions that are still someone's to make, each with the trade-off.
## Verification     How anyone can tell it worked: the command, and what it should show.
## Out of scope     What a reader might assume is included and is not.
```

Date any result you add (`**Done 2026-01-31:**`), and say what was checked and what was not.

## Live plans

| Plan | What | State |
|---|---|---|
