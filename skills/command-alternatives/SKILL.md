---
name: agy-ep-alternatives
description: Use this skill to discover available tools, identify installed alternatives (such as ripgrep instead of grep, or MCP servers instead of CLI tools), and prevent unnecessary software installations.
---

# Command Alternatives Skill

Use this skill to identify installed alternatives and avoid redundant package installations.

## When to Use
- When a requested tool is missing from PATH (e.g. `grep`, `gh`, `bash`).
- Before suggesting or attempting any `winget`, `choco`, or `npm` global installation.
- When determining the optimal equivalent command for Windows PowerShell.

## Decision Tree
1. Is the command native to Windows? -> Use directly.
2. Is it `grep`? -> Use `rg` (Ripgrep v15.2.0 installed) or PowerShell `Select-String`.
3. Is it `gh`? -> Use the Antigravity `github` MCP server tools.
4. Is it a Unix shell (`bash`/`sh`)? -> Convert syntax to PowerShell.
5. Is an installation strictly required? -> Request user approval first.

