# 3. Hybrid Hook Intervention & Tool Preferences

Date: 2026-09-17
Status: Accepted

## Context
When an agent attempts to invoke a command that cannot succeed on Windows, different error categories require different intervention strategies:
- Missing tools with known 1:1 equivalents (e.g. `grep` -> `rg`) can be substituted transparently.
- Missing tools without user consensus require user input (install vs substitute).
- Fragile syntax (e.g. inline PowerShell with variables) requires agent reformatting.

## Decision
Adopt a three-tier intervention model:
1. **1:1 Equivalences**: Transparent rewrite via `decision: "allow"` and `overwrite.CommandLine`.
2. **Missing Tools**: Query user via `decision: "ask"` (`ASK_USER`), persisting choice to `registry/tool-preferences.json`.
3. **Complex Syntax / Inline Code**: Formative rejection via `decision: "deny"` instructing agent to use the temporary script isolation pattern (`.ps1`, `.cjs`, `.py`).

## Consequences
- **Positive**: Optimal token efficiency on simple substitutions; user authority on tool choices; educational feedback on syntax.
- **Negative**: Requires handling interactive prompts when new unknown tools are first encountered.
