# AGENTS.git.md

## Git and CI

You are allowed to commit and push for this checkout. This overrides the "never run `git commit` or `git push` unless told to" rule in `AGENTS.md`.

### Branches

- Only push to a branch starting with `feat/`, `fix/`, or `chore/`.
- Never push to `main` or any other branch.
- If the current branch does not match, create one before committing. Use a short kebab-case name, for example `feat/booking-refund`.
- Do not open pull requests unless told to.

### Commits

- Make small, focused commits.
- When fixing a CI failure, prefer amending the previous commit and pushing with `git push --force-with-lease` over piling up fix commits.
- Never use plain `--force`.

### Commit messages

Format: `<prefix>: <short summary>`

Prefixes:

- `feat:` features, additions, deletions, and overall changes
- `chore:` minor cleanups, typo fixes, refactoring, tidying, and other housekeeping
- `fix:` code fixes

Special prefixes:

- `ci:` only when the change touches nothing but CI
- `test:` only when the change touches nothing but tests
- `merge:` for merging branches, and for pull requests

If a commit mixes kinds of changes, use the prefix of the main change.

Style:

- Keep the summary short and concise
- Write everything in lowercase. Use uppercase only when needed, such as a file name, type, or method
- Examples:
  - `feat: added http outpost`
  - `fix: performance regression when adding outlines`

Extended description:

- Only add one when the summary alone cannot fit the change. Most commits should have none
- Leave a blank line between the summary and the description
- Use `-` for each item that lists a change, in lowercase and concise
- `>` marks a todo or a maybe-later plan. Never write `>` lines or invent todos. Only the user writes those

Example with a description:

```
fix: performance regression when adding outlines

- added the ability to download more
- improve the fetching
```
