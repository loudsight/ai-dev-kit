# Knowledge base (`kb/`)

What the project knows that is not in the code: why it is built the way it is, how to operate it, what is planned. `AGENTS.md`
at the repository root is the short list of directives; this directory is where the detail goes. Agent auto-memory is switched
off, so anything worth keeping is written here.

If two documents disagree, prefer in order: the running code and its configuration; then `tools/syn/syn <command> --help`; then
this directory.

## Where does this go?

Plans had been the only bucket with an obvious owner, so operational findings got written into them and were destroyed when the
plan was retired. **Plans hold work that is not done. Everything else has another home.**

Ask what *kind* of thing you have written, not what you were doing when you wrote it:

| If it is… | It goes in | One-line test |
|---|---|---|
| Work not done yet | `plans/` | Could someone pick this up and execute it? |
| A plan an agent just auto-wrote | `plans/inbox/` | Did you choose this filename, or did the tool? |
| A problem with a lifecycle (found, mitigated, resolved) | `issues/` | Does it have a status that will change? |
| Why the code is the way it is, including what was rejected | `decisions/` | Would someone re-propose the rejected option without this? |
| How the system is put together | `architecture/` | Is this true of the system regardless of any task? |
| A procedure someone follows, possibly under pressure | `recipes/` | Would you open this *while* something is broken? |
| A prompt an agent can invoke | `skills/` | Is it addressed to a model rather than a person? |
| Someone else's system, or an idea not adopted | `explorations/` | Is it aspirational or out of scope? Curated by hand, never swept. |

Two rules do the real work:

1. **A sweep relocates before it deletes.** Before retiring a document, decide which row above each surviving paragraph belongs
   to, and move it there. The procedure is [`skills/sweep-kb/SKILL.md`](skills/sweep-kb/SKILL.md).
2. **Date what you write.** A claim without a date cannot be judged stale. When a fact changes, rewrite or delete the old text
   rather than appending a status line.

Front matter is optional. A document is plain Markdown with a title and, when it can go stale, a date.

## Skills

Each skill is a folder with a `SKILL.md` (name, description and when to use it in its front matter). Claude Code finds them when
they are linked or copied under `.claude/skills/`; see `docs/QUICKSTART.md`.

| Skill | Use it when |
|---|---|
| [`evidence-first`](skills/evidence-first/SKILL.md) | Before changing code to fix something, to check the evidence is conclusive |
| [`debug-by-comparison`](skills/debug-by-comparison/SKILL.md) | A failure is not obvious and a similar thing works |
| [`session-close`](skills/session-close/SKILL.md) | A session ended with work open: move its learnings and leftovers to their homes |
| [`sweep-kb`](skills/sweep-kb/SKILL.md) | Plans have piled up and finished work needs retiring |
| [`task-retro`](skills/task-retro/SKILL.md) | A task is finished: clean up the diff, then look for workflow friction |

After moving, renaming or retiring any document here, run `tools/syn/syn kb-check-links`.
