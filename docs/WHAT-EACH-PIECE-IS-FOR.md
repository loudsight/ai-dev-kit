# What each piece is for

Each piece answers a failure that recurs when agents work in a repository. Keep the ones whose failure you have.

## `AGENTS.md`: one instruction file

*Failure:* each tool wants its own rules file, and the files drift apart. Claude Code reads `CLAUDE.md`, which here is one line
(`@AGENTS.md`); other agents read `AGENTS.md` directly. The 12,000-character cap exists because some agents truncate rule files
past a limit; what does not fit goes in `kb/` with a link. *Cost:* you must keep it short.

## `kb/`: where findings go

*Failure:* an agent learns something expensive, and it vanishes with the session or lands in a plan that is later deleted. The
filing table gives every kind of finding one home, and "relocate before you delete" stops a sweep destroying it. Agent
auto-memory is switched off in `.claude/settings.json` so there is one memory, in the repository, reviewed like code.
*Cost:* writing and dating notes.

## `kb/skills/`: reusable prompts

Five small procedures an agent follows when the situation arises (evidence first, debug by comparison, session close, sweep,
retro). They are plain Markdown; edit them to your habits or delete the ones you will not use.

## `tools/syn/`: the task CLI

*Failure:* a task that takes four commands and a looked-up flag is rediscovered every session. A `syn` command has a name, a
purpose, search keywords and a **tier** (`read-only`, `local-mutate`, `remote-mutate`, `irreversible`), and the head refuses to
let an agent run an irreversible one. `syn catalog <term>` finds it cheaply. `script-check-conventions` fails a command with a
poor name, no "use when" purpose or no keywords, so the catalog stays searchable. `script-check-ceiling` caps shell and Python
files and lets the cap only shrink, so new repeatable work goes into commands. *Cost:* Java 25 and Maven on the machine;
commands are Java (see `ADAPT-TO-YOUR-STACK.md`).

## `scripts/git-hooks/`

The pre-commit hook runs the two checks above. Installing sets `core.hooksPath` for the clone, so the hooks travel with the
repository but must be installed once per clone.

## `.claude/hooks/bulk-read-guard.sh`

*Failure:* an agent reads a 4,000-line file whole and spends its context on it. The hook (needs `jq`) refuses a whole-file `Read`,
`cat` or `less` over 400 lines and says to read a range, grep, or delegate. Tune `THRESHOLD_LINES` and `EXEMPT_PATTERNS` in the
script. It fails open: with no `jq`, or any doubt, it lets the call through.

## `scripts/myEnv.sh`

*Failure:* an agent's shell does not load your profile, so `java` or `mvn` is missing. Source this file first. It also records two
traps (a zsh variable named `path`; no GNU `timeout` on macOS).

## The public-repository guard

For a repository that is, or will be, public: `publish-check-private` fails a commit or push (and a CI check, as a backstop) that
carries a string from a private list you keep outside the repository, or a secret-shaped string. It fails closed. See
`tools/syn/syn publish-install-hooks --help`.
