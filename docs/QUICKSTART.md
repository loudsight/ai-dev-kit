# Quickstart

Needs: Java 25 and Maven on `PATH`, git, and (for the file-size guard) `jq`.

1. **Create your repository from this template,** or copy these files into an existing repository: `AGENTS.md`, `CLAUDE.md`,
   `kb/`, `tools/syn/`, `scripts/`, `.claude/`, `.syn/`.
2. **Run `tools/syn/syn catalog`.** The first run has Maven fetch `syn` and its generic commands from Maven Central into
   `tools/syn/.syn-cache/` (a few seconds; a mismatched download fails instead of warning). Ignore `.syn-cache/` in git (the
   `.gitignore` here does).
3. **Install the hooks:** `scripts/git-hooks/install.sh`. From now on a commit runs `script-check-ceiling`, and
   `script-check-conventions` when it touches scripts, plugins or `AGENTS.md`.
4. **Set your shell ceiling.** `scripts/legacy-scripts.tsv` is the high-water mark for shell and Python files (it ships with the
   mark for this kit's own five files). Once you add the files you copy in, `script-check-ceiling` fails until you accept the new
   figures with a reason the reviewer sees: `tools/syn/syn script-check-ceiling --raise "existing scripts"`. From then on the
   mark may only fall (`--lower`). Then `tools/syn/syn script-list-catalog --markdown` rewrites `scripts/INDEX.md`, the generated
   index of commands and scripts (`script-check-conventions` fails when it is stale). Both read git's file list, so `git add`
   your files first.
5. **Edit `AGENTS.md`:** fill in the build and verify commands and the local-tooling notes, and delete what does not fit. Keep it
   under 12,000 characters; `tools/syn/syn script-check-conventions` checks.
6. **Give your agent the skills.** Claude Code reads skills from `.claude/skills/`:
   `mkdir -p .claude/skills && for d in kb/skills/*/; do ln -s "../../$d" ".claude/skills/$(basename "$d")"; done`.
7. **Send plan-mode output to the inbox.** Claude Code writes plans to `~/.claude/plans`; point it at the inbox so plans become
   files in your repository: `rm -rf ~/.claude/plans && ln -s "$PWD/kb/plans/inbox" ~/.claude/plans`. The link breaks if you move
   the repository, and other agents keep their plans elsewhere (`~/.windsurf/plans`, `~/.devin/plans`).
8. **Check it:** `tools/syn/syn script-check-conventions && tools/syn/syn kb-check-links`.

## Windows (git bash)

Run everything from **git bash** (Git for Windows), not PowerShell or cmd. **Status:** one cold-start run on Windows 10, git 2.52, JDK 25 and Maven 3.9 (2026-10-11) confirmed that
LF endings survive checkout, that `ln -s` produces copies, that a junction works (in a scratch home directory), and that the bulk-read guard
denies a large read and fails open without `jq`. It found the classpath failure below, and `syn` has not run end to end on Windows since the fix.
Treat the rest as what to expect, and tell us where it differs. Claude Code on Windows also runs its shell commands through git bash.

- **Line endings.** The kit ships a `.gitattributes` that forces LF on shell scripts, because Git for Windows defaults to
  `core.autocrlf=true`, which would otherwise give them CRLF and break `#!/bin/sh`. If a script fails with `\r: command not found`, check
  that `.gitattributes` came across, then re-checkout: `git rm --cached -r . && git reset --hard`.
- **Toolchain.** Install a JDK 25 and Maven for Windows, and put both on the Windows `PATH`. Point the three "Your toolchain" lines in
  `scripts/myEnv.sh` at them with git bash paths (`/c/tools/jdk-25`), or delete the file if `PATH` already has them. `mvn` is a `.cmd`
  file; git bash runs it by that name.
- **`jq`** is not in git bash. Install it (for example `winget install jqlang.jq`). Without it the bulk-read guard lets every read through.
- **Symlinks (steps 6 and 7).** `ln -s` in git bash copies the target unless Windows Developer Mode is on and `MSYS=winsymlinks:nativestrict` is
  exported (and `git config core.symlinks true` before cloning). A copy of `kb/skills` goes stale; a copy of the plans inbox would
  silently catch plans in the wrong place. For the plans inbox, a directory junction needs no elevation:
  `cmd //c mklink //J "%USERPROFILE%\.claude\plans" "<repo path>\kb\plans\inbox"`.
- **The `syn` launcher** and the classpath. On the first Windows run, `java` failed with `ClassNotFoundException: com.loudsight.syn.cli.Syn`:
  git bash converts POSIX-looking arguments to Windows paths for `java.exe` but skips any argument containing a wildcard, so
  `-cp .syn-cache/lib/*` arrived as `/c/...` and matched no jar. `MSYS_NO_PATHCONV=1` does not help, because it only disables
  conversion. The launcher now passes the drive-letter form on Windows (`cygpath -m`); that change is untested on Windows. If it still
  fails, run `java` once from `cmd.exe` or PowerShell with `-cp C:/path/to/.syn-cache/lib/*`.
- **A failing pre-commit hook may not mean a ceiling breach.** `script-check-ceiling` runs through the launcher, so if `syn` cannot
  start, the hook rejects every commit with a ceiling message. Read the output above that line.
- **Executable bit.** NTFS has none. `script-check-conventions` reports scripts as not executable when git does not record the bit:
  `git update-index --chmod=+x <file>` records it.

## Adding your first command

When you repeat a task for the second time, `tools/syn/syn script-create-scaffold <area-verb-object> --plugin <name>`, and see
[the plugin guide](https://github.com/loudsight/dev-toolbox/blob/master/docs/PLUGIN_SPI.md) for the contract and an example.

## If your repository is public

`tools/syn/syn publish-install-hooks --help`. It installs hooks and a CI workflow that fail a commit or push containing a private
string or a secret. The list of private strings lives outside the repository.

The template carries a CI workflow, `.github/workflows/public-guard.yml`, that is switched off in your repository: its job runs only in
the repository named in its `if` line, because the check needs a denylist you do not have yet. When you have one, set the repository secret
`PRIVATE_DENYLIST` and delete that `if` line (or rerun `publish-install-hooks --ci`, which writes the unconditional version).
