# Adapt it to your stack

Be honest about what is portable.

**Portable as is:** `AGENTS.md`, `CLAUDE.md`, the whole of `kb/` and its skills, `.claude/` (the bulk-read guard needs `jq`),
`scripts/myEnv.sh` after you edit the toolchain lines, and the git hooks. None of them cares what language your product is in.

**Needs Java:** the `syn` task CLI. The head and the generic commands (`catalog`, `script-check-conventions`,
`script-check-ceiling`, `kb-check-links`, `publish-check-private`, the scaffold and catalog commands) run on Java 25 with Maven to
fetch them. They check any repository, whatever its language, but running them needs a JDK on the machine. Commands you add
yourself are Java classes too (`syn-spi` is the interface).

If that is too heavy, you have two choices:

1. **Keep the knowledge base and hooks, drop `syn`.** Delete `tools/syn/`, the `.syn/` directory, the "Scripts" section of
   `AGENTS.md` and the pre-commit hook's `syn` calls, and keep your repeatable tasks in whatever your stack uses (a `Makefile`,
   `just`, npm scripts). You lose the tier rules and the searchable catalog. Replace them with a convention you check yourself.
2. **Write the head for your stack.** The contract is small: find commands, enforce a tier, run one. The commands' behaviour is
   described in each command's class comment. This is a project, not a configuration change.

**Tune per repository:** the `AGENTS.md` build section; `.syn/config.properties` (instruction file name and size cap, ceiling
manifest, the directories the catalog scans); the bulk-read threshold; the plan-inbox link in `QUICKSTART.md` if you do not use
Claude Code.
