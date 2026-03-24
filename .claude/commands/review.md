# project:review

`project:review`

Please review the current diffs (`git diff` and `git diff --cached`) against this project's Delphi coding standards from `CLAUDE.md` and the appropriate rules inside `rules/`. Ensure that:
- Naming conventions (`T`, `I`, `E`, `F`, `A`, `L` prefixes) are respected.
- `try..finally` is correctly applied to ALL unowned object creations.
- There are no `with` statements.
- Memory leaks are unlikely with the new changes.
- Specific database or framework constraints (Firebird, MySQL, PostgreSQL, etc) are respected.
