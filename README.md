# ai-dev-kit

A starting point for working with AI coding agents in a repository: one instruction file every agent reads, a small knowledge base
the agents write their findings into, a task CLI (`syn`) that turns repeated work into named, tiered commands, and git hooks that
keep both honest.

Use this repository as a template (**Use this template** on GitHub), or copy what you want. Nothing here is a runtime dependency
of your product.

| Piece | Where | Why |
|---|---|---|
| Agent instructions | `AGENTS.md`, `CLAUDE.md` | One short file for Claude Code, Codex, Copilot, Windsurf and Devin; size-linted |
| Knowledge base | `kb/` | A filing table so each finding has one home; plans hold only work not done |
| Skills | `kb/skills/*/SKILL.md` | Reusable prompts: evidence first, debug by comparison, session close, sweep, retro |
| Task CLI | `tools/syn/` | `syn catalog`, command scaffold, convention and shell-ceiling checks, dead-link check, public-repo guard |
| Coordinator | `docs/COORDINATOR.md`, `kb/skills/coordinate/` | Run tasks in parallel git worktrees from a task table; land them one at a time |
| Hooks | `scripts/git-hooks/`, `.claude/` | Pre-commit checks; a guard against reading huge files whole |
| Environment | `scripts/myEnv.sh` | Toolchain on `PATH` in a shell that lacks it |

Start with [`docs/QUICKSTART.md`](docs/QUICKSTART.md); on a new workstation, give an agent [`docs/BOOTSTRAP.md`](docs/BOOTSTRAP.md) (preflight, decisions, Windows differences, checks). [`docs/WHAT-EACH-PIECE-IS-FOR.md`](docs/WHAT-EACH-PIECE-IS-FOR.md) explains
each piece and what it costs; [`docs/ADAPT-TO-YOUR-STACK.md`](docs/ADAPT-TO-YOUR-STACK.md) says what to change if you do not use Java.

The `syn` engine and its generic commands are published on Maven Central as `com.loudsight:syn-cli` and
`com.loudsight:syn-plugin-kit`; the launcher in `tools/syn/` fetches them. Licence: Apache-2.0.
