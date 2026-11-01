# Bootstrap: set up this kit on a new workstation (a guide an AI agent can execute)

Give this file to a coding agent (Claude Code, Devin, Windsurf, Copilot) running in a terminal on the new machine. A person can follow
it too; [`QUICKSTART.md`](QUICKSTART.md) is the shorter reference and this guide adds the preflight, the decisions to ask and the checks.
It needs only public sources: this repository and Maven Central.

Lines marked **[unverified]** were not confirmed on every platform; check them and report what you found instead of assuming.
Status: macOS and Linux are the usual platforms. One Windows (git bash) cold start passed on 2026-10-11 (Windows 10, git 2.52, JDK 25,
Maven 3.9); Windows 11 and newer toolchains are **[unverified]**.

## Rules for you throughout

- Stage exact paths only: never `git add -A` or `git add .`; run `git status` first.
- Never `git push --force`, never `--no-verify`, never rewrite published history. Do not push unless asked.
- Never put a secret in a file, a command line, a commit or your output.
- Fix only what was asked. Report adjacent problems.
- Gather evidence (command output, error text) before changing anything that fails. "It compiled" is not "it passed".
- Do not read huge files whole. Read a range or grep.
- Ask the owner (see Decisions) instead of guessing. Never overwrite an existing `AGENTS.md`, `CLAUDE.md`, `.claude/settings.json` or shell
  profile without showing a diff and getting a yes.
- When a step fails or you must do something this guide does not say, write it down (step, exact command, exact error, what you did) in
  a log file outside the repository, then continue. Do not edit repository files to make a step pass, except the edits the steps name.

## 0. Preflight (change nothing; report each result)

1. `uname -sm` and `echo $SHELL`. On Windows use **git bash** (Git for Windows), not PowerShell or cmd. Record the Windows version.
2. `git --version` (2.17 or later), `git config user.name`, `git config user.email` (ask if unset; never invent), `git config core.autocrlf`.
3. `java -version` must say 25; `mvn -version` must work. They are needed only to run `syn`, which Maven fetches from Maven Central, so the
   first run needs network access. Neither on `PATH` is fine: step 3 handles it.
4. `jq --version`. The bulk-read guard needs it; without `jq` it silently lets every read through. Install it if missing, after asking
   (Windows: `winget install jqlang.jq`).
5. The agent in use: `claude --version` or the equivalent. Claude Code needs the owner to be signed in.
6. Install anything missing with the platform's package manager only after the owner confirms.

## 1. Decisions to ask before creating anything

1. Which repository gets the kit: a new one from this template, or an existing one (its name, main branch, whether it is public).
2. Workspace location. Suggested: `<workspace>/code/<repo>`, worktrees in `<workspace>/code/wt`, tools in `<workspace>/programs`.
3. Which agents are in use, so only their plan links and hooks are set up.
4. The build, test and lint commands, and which must pass before a push.
5. Whether to keep `syn` (needs Java 25) or drop it for a non-Java stack ([`ADAPT-TO-YOUR-STACK.md`](ADAPT-TO-YOUR-STACK.md)).
6. Whether to set up the coordinator ([`COORDINATOR.md`](COORDINATOR.md)).
7. Whether you may edit shell profiles, set user environment variables, install packages or create links in the home directory.
8. Commit identity, and whether to push at the end.

## 2. Get the kit

1. `git clone https://github.com/loudsight/ai-dev-kit.git` into an empty directory outside the target repository. On Windows set
   `git config --global core.autocrlf input` first (or rely on the kit's `.gitattributes`, which forces LF on scripts).
2. Read, in this order and only these: `README.md`, `docs/QUICKSTART.md`, `docs/WHAT-EACH-PIECE-IS-FOR.md`, `AGENTS.md`,
   `kb/README.md`. Read `docs/COORDINATOR.md` only if the coordinator is wanted.
3. If you are starting from the template, the clone is the repository; otherwise copy `AGENTS.md`, `CLAUDE.md`, `kb/`, `tools/syn/`,
   `scripts/`, `.claude/`, `.syn/`, `.gitattributes` and your merged `.gitignore` entries into the target. Do not copy `.git/`,
   `tools/syn/.syn-cache/`, `.github/`, `.public-repo` or `.public-allowlist`.
4. Line endings (Windows): `grep -c $'\r' tools/syn/syn scripts/git-hooks/pre-commit .claude/hooks/bulk-read-guard.sh` must print 0 for
   each. If not, re-check out after fixing `.gitattributes`: `git rm --cached -r . && git reset --hard`.

## 3. Toolchain and environment file (QUICKSTART's toolchain note)

`scripts/myEnv.sh` puts the toolchain on `PATH` in a shell that lacks it, typically the agent's.

- **macOS and Linux:** edit its three "Your toolchain" lines (`JAVA_HOME`, `MAVEN_HOME`, `WORK_ROOT`) to the real locations, or delete the
  file if `PATH` already has both tools. An agent shell does not load the user profile, so prefix commands with
  `source scripts/myEnv.sh &&`. To load it everywhere, source it from `~/.zshenv` (and on macOS also `~/.zprofile`, which restores `PATH`
  order after the system `path_helper`) or `~/.bashrc`. Ask first.
- **Windows (git bash):** symlinks are unreliable, so do not use a `current` link layout. Unpack the JDK and Maven into versioned
  directories (for example `/c/dev/programs/java-25.x`, `/c/dev/programs/maven-3.9.x`) and point the three lines at them with git bash
  paths. Then: append `. "/c/path/to/repo/scripts/myEnv.sh"` to `~/.bashrc`, make sure `~/.bash_profile` sources `~/.bashrc`, and set the
  Windows **user** environment variable `BASH_ENV` to the same file in native form. `BASH_ENV` is what makes a non-interactive `bash -c`,
  which is how an agent runs commands, load the file. `mvn` is a `.cmd` file; git bash runs it by that name.
- Traps: in zsh never name a variable `path` (it is tied to `PATH`); macOS has no GNU `timeout`.
- Check in a clean environment: `env -i HOME=$HOME TERM=xterm bash -lc 'java -version; mvn -version'` shows Java 25 and Maven.

## 4. First run of syn and the git hooks (QUICKSTART steps 2 to 4)

1. `tools/syn/syn catalog`. Maven fetches `syn-cli` and `syn-plugin-kit` (pinned in `tools/syn/pom.xml`) into `tools/syn/.syn-cache/`
   (git-ignored; a checksum mismatch fails instead of warning). Expected: a table of commands with a tier each. If it fails on Windows
   with `ClassNotFoundException: com.loudsight.syn.cli.Syn`, run `java` once from `cmd.exe` with
   `-cp C:/path/to/tools/syn/.syn-cache/lib/*` and report it (`MSYS_NO_PATHCONV=1` does not help).
2. `scripts/git-hooks/install.sh`; check `git config --get core.hooksPath` prints `scripts/git-hooks`. This is per clone.
3. `git add` the copied files by exact path (the checks read git's file list), then
   `tools/syn/syn script-check-ceiling --raise "existing scripts"` (the mark may only fall afterwards, with `--lower`), then
   `tools/syn/syn script-list-catalog --markdown` to regenerate `scripts/INDEX.md`.
4. Windows has no executable bit. If `script-check-conventions` reports scripts as not executable, record it with
   `git update-index --chmod=+x <file>`.
5. A failing pre-commit hook may not mean a ceiling breach: `syn` itself failing to start also rejects commits with a ceiling message.
   Read the output above that line.

## 5. Adapt AGENTS.md (QUICKSTART step 5)

Edit `AGENTS.md` for the real project: the exact build and verify commands (one per line, never "skip tests" as a default), the local-tooling
notes from step 3, and pointers to the project's own docs. Delete what does not fit instead of leaving placeholders. Keep it under 12,000
characters (`tools/syn/syn script-check-conventions` checks). Add only rules the owner gives you; do not invent rationales. `CLAUDE.md`
stays exactly `@AGENTS.md`.

## 6. Skills and the plan inbox (QUICKSTART steps 6 and 7)

1. Claude Code reads skills from `.claude/skills/`. Link or copy each `kb/skills/*` directory there
   (`mkdir -p .claude/skills && for d in kb/skills/*/; do ln -s "../../$d" ".claude/skills/$(basename "$d")"; done`). On Windows `ln -s`
   makes copies unless Developer Mode and `MSYS=winsymlinks:nativestrict` are set (and `git config core.symlinks true` before cloning).
   A copy goes stale when `kb/skills` changes: recopy, or make a junction per skill (`cmd //c mklink //J`). Say which method worked.
2. Plan-mode output: Claude Code writes plans to `~/.claude/plans`. Point it at the inbox. If that directory exists, move it aside first
   (`ln -s` onto a directory nests the link inside it). macOS and Linux: `ln -s "$PWD/kb/plans/inbox" ~/.claude/plans`. Windows (no
   elevation): `cmd //c mklink //J "%USERPROFILE%\.claude\plans" "<repo path>\kb\plans\inbox"`. The link breaks if the repository moves.
   Other agents keep plans elsewhere (`~/.windsurf/plans`, `~/.devin/plans`); set up only those in use. Ask before touching the home
   directory.
3. Keep `kb/` inside the repository (the kit's default). A `kb/` that is a symlink to a separate clone works on macOS and Linux but copies
   on Windows, and a worker running in a separate git worktree cannot write through such a symlink.
4. After moving or retiring any kb document run `tools/syn/syn kb-check-links`.

## 7. Optional: the coordinator

Only if the owner says yes. See [`COORDINATOR.md`](COORDINATOR.md). Needs the commit from step 9 (worktrees cut from main must contain
`kb/` and `AGENTS.md`), git 2.17 or later, and an agent that can start background subagents. Copy
`kb/plans/coordinator-plan.template.md` to `coordinator-plan.md` and delete the `EXAMPLE` row and `EXAMPLE` open item. Worktrees live outside the repository
(for example `<workspace>/code/wt/`). The kit's `syn` has no `worktree-*` commands, so landing is plain git: `git -C <tree> rebase main`,
then `git merge --ff-only <branch>`; on a conflict `git rebase --abort`, mark the row `done-unlanded` and make it a follow-up task. On
Windows a build in a linked worktree may need `-Dmaven.gitcommitid.skip=true` if it uses the git-commit-id plugin. **[unverified]**

## 8. Checks (run all; report PASS or FAIL with the actual output; claim PASS only for what ran)

| # | Check | Expected |
|---|---|---|
| 1 | `java -version`, `mvn -version` in a clean shell (step 3) | Java 25, a Maven version |
| 2 | `tools/syn/syn catalog` | table of commands, exit 0 |
| 3 | `tools/syn/syn script-check-conventions` | exit 0, AGENTS.md under 12,000 characters |
| 4 | `tools/syn/syn script-check-ceiling` | exit 0 |
| 5 | `tools/syn/syn kb-check-links` | exit 0 |
| 6 | `git config --get core.hooksPath` | `scripts/git-hooks` |
| 7 | `cat CLAUDE.md` | `@AGENTS.md` |
| 8 | `git check-ignore tools/syn/.syn-cache` | prints the path |
| 9 | Commit a new shell script | rejected by the ceiling check; `script-check-ceiling --raise "test"` then lets it through. Undo the test commit |
| 10 | Pipe a Read request for a 500-line file into `bash .claude/hooks/bulk-read-guard.sh` | denied; with `jq` off `PATH` it fails open (note it) |
| 11 | Skills linked or copied; plan inbox linked | one entry per kb skill; a file written to `~/.claude/plans` appears in `kb/plans/inbox/` |
| 12 | Start the agent; ask "which command finds dead links in the knowledge base?" | it uses `tools/syn/syn catalog`; then ask for a short plan: it lands in `kb/plans/inbox/` |
| 13 | `git status --short` after the commit | clean |

## 9. Commit

`git status`, stage the exact kit paths, `git commit -m "Add ai-dev-kit"` (the pre-commit hook runs the checks; never `--no-verify`).
Commit to the main branch unless the owner's team uses branches. Do not push unless asked. If the target repository is public, stop and
ask how changes get in.

## What this kit does not do

Its `syn` carries ten commands (`catalog`, `kb-check-links`, `publish-check-private`, `publish-install-hooks`, `script-check-ceiling`,
`script-check-conventions`, `script-create-scaffold`, `script-list-catalog`, `session-inspect-transcript`, `session-list-open`). It has no
code index, no worktree helpers, no push-branch guard and no deploy commands; add those as your own `syn` commands when you need them
([the plugin guide](https://github.com/loudsight/dev-toolbox/blob/master/docs/PLUGIN_SPI.md)). It installs no software and holds no secrets.
