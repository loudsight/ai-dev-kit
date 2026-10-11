# Secrets

Secrets never live in the repository, in a script, or on an agent's command line.

- **Templates, not values.** A file in the repository names the variable it needs (`${DB_PASSWORD}` in a compose file, a
  `.env.example` with empty values). The value comes from the environment at run time.
- **A secret manager supplies the environment.** Any manager that can run a command with secrets injected works; the repository
  holds only references to items, never their contents. Pick one and write its command here.
- **A secret that was committed is compromised.** Rotate it first; rewriting history is cleanup, not a fix.
- **Public repositories** also need a guard that fails a commit or push carrying a private string or secret:
  `tools/syn/syn publish-install-hooks --help`.
