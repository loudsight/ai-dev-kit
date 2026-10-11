# Quickstart

Needs: Java 25 and Maven on `PATH`, git, and (for the file-size guard) `jq`.

1. **Create your repository from this template,** or copy these files into an existing repository: `AGENTS.md`, `CLAUDE.md`,
   `kb/`, `tools/syn/`, `scripts/`, `.claude/`, `.syn/`.
2. **Run `tools/syn/syn catalog`.** The first run has Maven fetch `syn` and its generic commands from Maven Central into
   `tools/syn/.syn-cache/` (a few seconds; a mismatched download fails instead of warning). Ignore `.syn-cache/` in git (the
   `.gitignore` here does).
3. **Install the hooks:** `scripts/git-hooks/install.sh`. From now on a commit runs `script-check-ceiling`, and
   `script-check-conventions` when it touches scripts, plugins or `AGENTS.md`.
4. **Record the shell ceiling:** `tools/syn/syn script-check-ceiling --baseline` writes `scripts/legacy-scripts.tsv`, the manifest
   of shell and Python you already have. Commit it. The ceiling may only go down from here.
   Then `tools/syn/syn script-list-catalog --markdown` writes `scripts/INDEX.md`, the generated index of commands and scripts
   (`script-check-conventions` fails when it is stale). Both read git's file list, so `git add` your files first.
5. **Edit `AGENTS.md`:** fill in the build and verify commands and the local-tooling notes, and delete what does not fit. Keep it
   under 12,000 characters; `tools/syn/syn script-check-conventions` checks.
6. **Give your agent the skills.** Claude Code reads skills from `.claude/skills/`:
   `mkdir -p .claude/skills && for d in kb/skills/*/; do ln -s "../../$d" ".claude/skills/$(basename "$d")"; done`.
7. **Send plan-mode output to the inbox.** Claude Code writes plans to `~/.claude/plans`; point it at the inbox so plans become
   files in your repository: `rm -rf ~/.claude/plans && ln -s "$PWD/kb/plans/inbox" ~/.claude/plans`. The link breaks if you move
   the repository, and other agents keep their plans elsewhere (`~/.windsurf/plans`, `~/.devin/plans`).
8. **Check it:** `tools/syn/syn script-check-conventions && tools/syn/syn kb-check-links`.

## Adding your first command

When you repeat a task for the second time, `tools/syn/syn script-create-scaffold <area-verb-object> --plugin <name>`, and see
[the plugin guide](https://github.com/loudsight/dev-toolbox/blob/master/docs/PLUGIN_SPI.md) for the contract and an example.

## If your repository is public

`tools/syn/syn publish-install-hooks --help`. It installs hooks and a CI workflow that fail a commit or push containing a private
string or a secret. The list of private strings lives outside the repository.
