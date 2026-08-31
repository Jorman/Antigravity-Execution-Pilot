# Workspace Rules for Command Governance

These rules apply to the local repository and workspace:

## 1. Execution Environment
- Technology stack: Node.js / Python / Git.
- Supported shell: Windows PowerShell.
- Workspace path: verify whether local (C:\) or on an SMB network share (e.g. mapped network drives).

## 2. Operational Directives
- Use `rg` or `Select-String` for text searches within the project.
- Execute build and test commands exclusively on local drives or local temporary directories (%TEMP%) if the project resides on an SMB share.
- Protect all credentials and API keys (automatic secret redaction).
