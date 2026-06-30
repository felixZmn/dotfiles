# commit-msg — specification

Git hook that validates commit messages against the Conventional Commits format. Rejects the commit if the message does not match.

**Implementation:** `git/hooks/commit-msg`

---

## Purpose

Enforce a consistent commit message style across all repositories that use this hooks directory (via `core.hooksPath` or manual symlink).

---

## Execution model

```sh
#!/bin/sh
```

- Receives the commit message file path as `$1`
- Reads the full message with `cat "$COMMIT_MSG_FILE"`
- Tests the first line against a regex pattern
- Exits 0 on match, exits 1 on mismatch (rejecting the commit)

---

## Allowed commit types

| Type       | Description                                             |
| ---------- | ------------------------------------------------------- |
| `build`    | Build system or external dependency changes             |
| `change`   | General change not covered by other types               |
| `chore`    | Maintenance / tooling                                   |
| `ci`       | CI configuration                                        |
| `docs`     | Documentation only                                      |
| `feat`     | New feature                                             |
| `fix`      | Bug fix                                                 |
| `perf`     | Performance improvement                                 |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `revert`   | Reverts a previous commit                               |
| `style`    | Formatting, whitespace, no logic change                 |
| `test`     | Adding or correcting tests                              |

---

## Pattern

```
^(build|change|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)( \([^)]+\))?: .+
```

| Component       | Meaning                                                   |
| --------------- | --------------------------------------------------------- |
| `^`             | Start of string                                           |
| `(types)`       | One of the allowed types (case-insensitive via `grep -i`) |
| `( \([^)]+\))?` | Optional scope in parentheses, preceded by a space        |
| `: `            | Colon followed by a space                                 |
| `.+`            | At least one character of message text                    |

---

## Valid examples

```
feat: add user login
fix(auth): handle token expiry
docs: update README
refactor (api): simplify error handling
```

---

## Rejection output

When the message does not match:

1. Print `❌ Invalid commit message format!`
2. Print usage hint:
   - Valid format: `<type> (<scope>): message`
   - List of allowed types
   - Example: `fix(auth): handle login timeout`
3. Exit 1 (commit is rejected)

---

## Notes

- Matching is case-insensitive (`grep -iEq`).
- Only the first line of the commit message is validated (the subject line).
- The scope is optional but must be parenthesized when present.
- A space is required between the type and the opening parenthesis of the scope.
