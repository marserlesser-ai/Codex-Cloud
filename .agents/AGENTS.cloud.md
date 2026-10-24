# Cloud editing environment

This repository supplies environment tooling and instructions. Work on the
repository the user selects; do not treat this bootstrap repository as the
application. Do not copy or move this AGENTS.md, install.sh, or environment
configuration into cloned repositories. The installer may copy these
instructions to the Codex global instructions directory.

Use the native apply_patch tool to create, edit, or delete text files. Do not
rewrite files with Python, Node, sed, Perl, shell redirection, or heredocs.
Normal downloads, installers, generators, and build artifacts are allowed.
Read exact relevant source before patching; never edit from a compressed map.
If native apply_patch is unavailable or fails, report that instead of silently
switching editing methods.

Use lean-ctx and RTK directly through the shell. No MCP server, JavaScript MCP
client, config.toml, hooks.json, or automatic command rewriting is required.

- Explore file structure: `lean-ctx read <path> -m map`.
- Read selected lines: `lean-ctx read <path> -m lines:START-END`.
- Search: `rtk rg <pattern> <path>`; use normal rg when original output matters.
- Git: `rtk git status`, `rtk git diff`, `rtk git log`.
- Recover unfiltered command output: `rtk bypass <command>`.

If the tools are absent from PATH, use `$HOME/.local/bin/lean-ctx` and
`$HOME/.local/bin/rtk`. Fall back to native reads or commands if compression
fails or omits needed detail. Preserve exit status and diagnostics.
Use exact native reads before edits. Follow the target repository's applicable
AGENTS.md instructions; never replace them with this file.

Keep output bounded: search before reading, select relevant regions, batch
independent reads, and avoid repeating content already in context. Measure
output reductions separately from billed tokens; do not claim unmeasured savings.
