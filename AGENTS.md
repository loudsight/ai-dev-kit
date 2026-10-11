# AGENTS.md

The one instruction file for every agent working in this repo. Claude Code reads it through `CLAUDE.md` (which is just
`@AGENTS.md`); Codex, Copilot's coding agent, Windsurf and Devin read `AGENTS.md` natively. Keep one file, not one per tool.

**Keep it under 12,000 characters.** Some agents truncate rule files beyond a limit, and `tools/syn/syn script-check-conventions`
fails the commit when this file is over. Keep it to directives and pointers: anything longer, or anything you would open *while*
something is broken, goes in `kb/` with a one-line link here.

## Orient first

- **Read only what the task needs.** A scoped change needs the code it touches, not every document below.
- **Why and what next** (planning only): `kb/plans/README.md` lists live plans. Put your project's objectives and roadmap in `kb/`
  and link them here.
- **Where knowledge goes:** the table in `kb/README.md` § *Where does this go?*. `plans/` holds only work not yet done.

## Build and verify

- Fill in your build, test and lint commands here, one line each. Say which one must pass before a push.
- Never skip tests by default, and never hide a failure by disabling the test: fix the cause.

## Scripts

- **Before any multi-step task, look for an existing command:** `tools/syn/syn catalog <term>` (filtered, so it costs far less than
  reading `scripts/INDEX.md`). Run one as `tools/syn/syn <name>`; `--help` prints its purpose.
- Tiers: `read-only` run freely · `local-mutate` run and report · `remote-mutate` only after explicit confirmation ·
  `irreversible` never (a human runs it).
- **A repeatable task with no command** (second time, three or more steps, flags you had to look up, or output you had to filter):
  `tools/syn/syn script-create-scaffold <area-verb-object> --plugin <plugin>`, fill in its purpose and keywords, then
  `tools/syn/syn script-list-catalog --markdown`. The pre-commit hook runs `script-check-conventions`.
- **No new shell or Python.** Shell and Python files are capped by `scripts/legacy-scripts.tsv` and may only shrink
  (`tools/syn/syn script-check-ceiling`). Shell that must stay shell (a git hook, a sourced env file):
  `script-check-ceiling --raise "<reason>"`; the reviewer sees the reason. Delete this bullet if your stack is not Java and you
  would rather write scripts in your own language (see `docs/ADAPT-TO-YOUR-STACK.md`).

## Evidence and scope

- **No change without conclusive evidence** that it fixes the problem, or that it is purely diagnostic. Gather logs, test output
  and error messages first. `kb/skills/evidence-first/SKILL.md`.
- **Fix only what was asked.** Report adjacent problems; do not fix them without authorisation.
- **Before claiming success**, run the exact thing you changed and say precisely what ran and what it showed. "Compiled" is not
  "tests passed"; a failure is not "unrelated" until you have disproved causation; partial success is reported as partial.
- **A failure that is not obvious:** compare a working case with the failing one before theorising.
  `kb/skills/debug-by-comparison/SKILL.md`.
- **Asking questions:** state the real trade-off. Never invent a rationale the user did not give.

## Git

- Stage **exact paths** only, never `git add -A` or `git add .`. Check `git status` first: parallel work streams share a tree.
- Commit work directly to the main branch unless your team works otherwise; **push only when asked.**
- Never `--no-verify` a hook. Run `scripts/git-hooks/install.sh` once per clone.

## Plans and docs

- Plan-mode output lands in `kb/plans/inbox/`. If the tool named the file by a hash, copy it to
  `inbox/<kebab-case-work-name>.md` and remove the hash file. Filing a plan is a deliberate write to a single flat
  `kb/plans/<work-name>.md`, never a subdirectory.
- Design rationale goes to `kb/decisions/`, procedures to `kb/recipes/`, structural facts to `kb/architecture/`.
- When a plan's work ships, relocate anything durable and retire the plan; the code is the record.
- After moving, renaming or retiring any kb document, run `tools/syn/syn kb-check-links`.
- Write docs only when needed for ongoing work; no recap or status documents unless asked.

## Recording what you learn

Agent auto-memory is off (see `.claude/settings.json`): durable learnings go into `kb/` through the filing table, and
preferences and directives become a line here that links into `kb/`.

- **Codify before narrating.** A failure that can be checked mechanically becomes a test, a check or a command, not prose.
- Record only what a competent reader would otherwise get wrong. Never record "X works". Date what you write, rewrite or delete
  superseded content instead of appending status, and verify a recorded claim against the code before repeating it.

## Local tooling

- Describe here what the agent's shell lacks (a toolchain on `PATH`, an environment file to `source`) and the traps that cost time.
  `scripts/myEnv.sh` is a starting point.
- Secrets are never in the repository. See `kb/recipes/secrets.md`.
