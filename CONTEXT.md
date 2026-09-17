# Antigravity Execution Pilot - Domain Context & Glossary

## Purpose
A Windows PowerShell safety and governance middleware for Google Antigravity AI coding agents. Intercepts, validates, rewrites, and blocks terminal commands before execution, preventing cyclic failures, syntax incompatibilities, and destructive operations.

## Domain Boundaries

### In Scope (Command Governance)
- Shell syntax validation for Windows PowerShell 5.1 (e.g. statement chaining, pipe syntax).
- Quoting and escaping rules (inline script isolation to .ps1, .cjs, .py).
- Tool availability in %PATH% and verified alternatives.
- Filesystem safety (destructive command blocks, SMB network share build locks).
- Credential and secret redaction from execution logs.
- Session-level anti-repetition memory (preventing identical retries).

### Strictly Out of Scope (Application Domain)
- User application code logic, business rules, and syntax.
- Project test outcomes (e.g. failing unit tests or assertions).
- Build compilation errors from project source code.
- Application-level runtime exceptions (e.g. missing python package inside project venv).

## Glossary

### Command Boundary
The interface where the agent's proposed un_command payload meets the host operating system before process creation.

### Pre-Flight Shield
The synchronous, real-time analyzer (scripts/preflight-command.ps1) invoked via the Antigravity PreToolUse hook before any terminal command is dispatched to the OS.

### Tool Resolution Lifecycle
The three-state decision flow when an agent requests a tool not found in %PATH%:
1. **Prompt**: Inform user and query intent (ASK_USER).
2. **Install**: If requested and supported, attempt installation.
3. **Substitute**: If unsupported or declined, map to a verified local alternative and persist to egistry/tool-preferences.json.

### Tool Preferences
Machine-specific configuration (egistry/tool-preferences.json) recording the user's permanent decision for missing tools (e.g. substitute grep with g), avoiding repeated prompts across sessions.

### Script Isolation Pattern
The governance requirement that complex multiline code or commands containing unescaped variables must not be passed via inline -Command, -e, or -c, but isolated in temporary script files (.ps1, .cjs, .py).

### Anti-Loop Fingerprint
The SHA256 digest of a normalized command string observed to have failed at runtime, used to block identical immediate retries within the active session.
