# 2. Strict Command Boundary Separation

Date: 2026-09-17
Status: Accepted

## Context
Past versions of the transcript scanner classified non-zero application exit codes (such as failing unit tests or missing project python dependencies) as system errors, generating erroneous `BLOCK` proposals for standard development commands like `npm run test` or `python init_db.py`.

## Decision
The plugin enforces a strict boundary: governance applies only to the shell command execution layer (syntax compatibility, quoting, tool presence, network share safety, destructive operations, and secret redaction). Application-level failures, project build errors, and unit test results are strictly ignored by the governance rule generator.

## Consequences
- **Positive**: Zero false positive blocks on standard development workflows.
- **Negative**: Application bugs must be handled solely by the agent without plugin-level syntax mediation.
