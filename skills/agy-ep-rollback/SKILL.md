---
name: agy-ep-rollback
description: Restores rules and configuration from a backup snapshot
---

# Command Maintenance Skill

Use this skill for state maintenance, backup audits, and rollback procedures.

## When to Use
- Prior to updating configuration files or promoting new rules.
- To execute rollbacks to a previous verified state recorded in `backups/manifest.json`.
- To clean up expired provisional rules.

## Rollback Procedure
1. Check `~/.gemini/config/antigravity-execution-pilot/backups/manifest.json`.
2. Verify SHA256 checksums of backup files.
3. Restore original files and validate restored state.


