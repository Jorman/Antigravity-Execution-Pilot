---
name: agy-ep-learning
description: Use this skill to manage the controlled rule lifecycle: transform recurring verified fixes into candidate proposals, validate them against regressions, and promote them with expiration dates.
---

# Command Learning Skill

Use this skill for controlled rule learning and proposal promotion.

## 4-Level Learning Lifecycle
1. **Level 1 (Observation)**: Log error in `error-events.jsonl` with SHA256 fingerprint.
2. **Level 2 (Remedy)**: Apply verified workaround without altering global rules.
3. **Level 3 (Proposal)**: Generate a proposal in `proposals/pending/` if the error recurred $\ge 2$ times.
4. **Level 4 (Activation)**: Promote proposal to `rule-registry.json` after running regression tests and obtaining approval.

