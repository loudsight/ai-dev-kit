#!/usr/bin/env bash
#
# Points this clone's git hooks at scripts/git-hooks/ (tracked, so the hooks travel with the repository).
# Idempotent; run once per clone. Undo with: git config --unset core.hooksPath
set -euo pipefail

cd "$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"
chmod +x scripts/git-hooks/pre-commit
git config core.hooksPath scripts/git-hooks
echo "core.hooksPath -> scripts/git-hooks"
