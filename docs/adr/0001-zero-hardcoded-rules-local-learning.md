# 1. Zero Hardcoded Rules & Pure Local Learning

Date: 2026-09-17
Status: Accepted

## Context
AI agents operating on Windows encounter diverse configurations: different installed tools, different permission tiers, and varied developer setups. Pre-loading the public repository with hardcoded active blocking rules causes false positives on systems with different toolchains or requirements.

## Decision
The public repository ships with zero hardcoded active rules in its registry. All operational rules and tool alternatives are learned dynamically on each machine through local environment audit (`/agy-ep-audit`) and historical transcript scanning (`/agy-ep-scan`, `/agy-ep-scan-all`).

## Consequences
- **Positive**: Universal out-of-the-box compatibility without false assumptions. Clean state on initial install.
- **Negative**: The agent requires either initial environment discovery or local transcript history before learned patterns take full effect.
