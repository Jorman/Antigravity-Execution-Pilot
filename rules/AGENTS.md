# Command Governance Plugin Rules

These rules apply globally to ensure safe and deterministic command execution:

1. **Mandatory Pre-flight**: Every terminal command must pass pre-flight analysis before execution.
2. **No Error Repetition**: Repeating identical failed commands in the same session is strictly prohibited.
3. **Alternative Priority**: Always use `rg` (Ripgrep) or `Select-String` instead of `grep`, and MCP server `github` instead of `gh`.
4. **Script Isolation**: Always use temporary `.cjs` or `.py` files for complex Node/Python code instead of inline `-e` or `-c`.
5. **Git Step Separation**: Execute git commands in distinct sequential steps verifying the outcome; never use `&&`.
6. **Secret Protection**: Logging tokens, passwords, keys, or credentials into log or report files is strictly prohibited.
7. **SMB Network Share Caution**: Do not run heavy builds, tests, or installations on network shares (e.g. `J:\`).
