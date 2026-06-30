# pre-commit — specification

Git hook that warns the user and asks for confirmation before committing directly to the `main` branch.

**Implementation:** `git/hooks/pre-commit`

---

## Purpose

Prevent accidental direct commits to `main`. Acts as a safety net — the user can still proceed by explicitly confirming.

---

## Execution model

```sh
#!/bin/sh
```

- Runs before each `git commit`
- Determines the current branch via `git symbolic-ref --short HEAD`
- If the branch is `main`, prompts for interactive confirmation
- If any other branch, exits 0 immediately (no prompt)

---

## Behavior

### Non-main branch

1. Exit 0 — commit proceeds normally.

### Main branch

1. Print warning: `⚠️  WARNING: You are about to commit directly to 'main'!`
2. Print blank line.
3. Prompt: `Are you sure you want to do this? (y/N):`
4. Read a single line from `/dev/tty` (bypasses stdin piped to git).
5. If input is `y` or `Y`: print `✅ Proceeding with commit to main...`, exit 0.
6. Otherwise: print `❌ Commit aborted.`, exit 1 (commit is rejected).

---

## Notes

- Reads from `/dev/tty` explicitly so the prompt works even when git's stdin is redirected.
- Only checks for exact branch name `main`; does not protect other branches (e.g., `master`, `release/*`).
- The hook is advisory — it does not block commits to `main`, only requires explicit confirmation.
