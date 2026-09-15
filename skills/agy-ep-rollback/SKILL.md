---
name: agy-ep-rollback
description: Retires or deprecates active rules and restores configuration state
---

# Command Maintenance & Rollback Skill

Use this skill for rule status management, deprecation, and rolling back rules in `rule-registry.json`.

## When to Use
- To retire or deprecate a specific active rule that is no longer needed.
- To deactivate a rule or revert proposal states.

## Execution
Run `retire-rule.ps1` with the Target `RuleId`:

```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.gemini\config\plugins\antigravity-execution-pilot\scripts\retire-rule.ps1" -RuleId "<rule-id>" -Reason "<reason>" -NewStatus "retired"
```
