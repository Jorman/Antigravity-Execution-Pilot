<div align="center">

# ✈️ Antigravity Execution Pilot

**A Windows PowerShell safety middleware for AI agents powered by Google Antigravity.**

[![Tests](https://img.shields.io/badge/tests-113%2F113%20passing-brightgreen)](#testing)
[![Platform](https://img.shields.io/badge/platform-Windows%20PowerShell%205.1-blue)](#requirements)
[![Antigravity](https://img.shields.io/badge/Antigravity-2.0-purple)](#installation)

</div>

---

## The Problem

AI coding agents are predominantly trained on Linux/Bash environments. When they run on **Windows**, they consistently make the same mistakes:

| What the AI tries | What happens on Windows |
|---|---|
| `git add . && git commit -m "msg"` | `ParseError: & was unexpected` |
| `grep -r "pattern" .` | `'grep' is not recognized` |
| `node -e "console.log(1)"` | `SyntaxError: Invalid or unexpected token` |
| `bash -c 'ls'` | `'bash' is not recognized` |
| `npm run build` (on a network drive) | `Access denied` or silent failure |
| Retrying the same failing command | Infinite loop, wasted tokens |

**Antigravity Execution Pilot** is a plugin that sits between the AI's "brain" and your operating system, silently intercepting every terminal command before it runs, and either fixing it, blocking it, or redirecting it to the right tool — all automatically.

---

## How It Works: The Two Engines

Antigravity Execution Pilot operates using two distinct mechanisms to work around current architectural limits (Antigravity has a PreToolUse hook to intercept commands *before* they run, but currently lacks a PostToolUse hook to natively monitor if they failed).

### 1. The Pre-Flight Shield (100% Automatic 🟢)
Every time the AI attempts to run a terminal command, the plugin intercepts it **before** the OS sees it.
- Dangerous commands (like recursive system deletions) are instantly **blocked**.
- Syntax errors (like using `&&`) are automatically **rewritten**.
- Missing tools (like `grep`) are silently **redirected** to alternatives (like `rg`).

*You don't have to do anything. This happens silently and automatically on every command.*

### 2. The Anti-Loop Learning System (On-Demand 🟡)
If a completely new or safe-looking command passes the shield but fails during OS execution (e.g., `git push` fails due to permissions), the plugin doesn't automatically know it failed because there's no Post-Hook.

This is where the **Slash Commands** come in. If you see the AI getting stuck in an error loop:
1. You type `/agy-ep-scan` in the chat.
2. The plugin scans the conversation, extracts the failed commands, calculates their SHA256 fingerprints, and adds them to the `error-events.jsonl` registry.
3. From that moment on, if the AI attempts to run that *exact same command* again, the **Automatic Shield** recognizes the fingerprint and hard-blocks it, breaking the loop.

**In short: It defends automatically, but it learns on command.**

---

## Features

### 🛡️ Pre-flight Interceptor
Every command is validated before hitting the OS. The interceptor catches:
- `&&` operator (not supported in PowerShell 5.1)
- Unix shells: `bash`, `zsh`, `sh`
- Missing tools: `grep`, `gh` (GitHub CLI)
- Inline script eval: `node -e`, `python -c`
- Destructive commands: recursive drive deletions, disk formats
- Heavy operations on SMB network drives

### 🔧 Auto-Remediation (REWRITE / USE_ALTERNATIVE)
Instead of just blocking, the plugin rewrites commands on the fly:
- `grep` → `rg` (Ripgrep, already installed)
- `node -e "..."` → creates a temporary `.cjs` file, runs it, deletes it
- `git add . && git commit` → rewrites to sequential steps
- `gh pr list` → redirected to the MCP GitHub server

### 🛑 Anti-Loop Memory
When a command fails, its SHA256 fingerprint is stored in an error log. If the AI attempts to run the **exact same command again** in the same session, it is **hard-blocked** with a clear message: *"This command already failed. Try a different approach."*

### 🔍 Error Classifier
`classify-error.ps1` parses `stderr`/`stdout` and maps every error to a structured category with a specific remedy:

| Category | Trigger | Remedy |
|---|---|---|
| `syntax_error` | `& era imprevisto` | Split commands into separate steps |
| `missing_tool` | `'grep' is not recognized` | Use `rg` or `Select-String` |
| `wrong_shell` | `execvpe(/bin/bash) failed` | Rewrite in PowerShell/Node |
| `quoting_error` | `SyntaxError: unexpected token` | Use temp script file |
| `permission_denied` | `Accesso negato` | Check permissions or run as admin |
| `smb_error` | Access denied on `J:\` | Use local temp folder |
| `timeout` | `Connection timed out` | Check connectivity |
| `authentication_required` | `Authentication failed` | Check credentials |

### 🔒 Secret Redactor
All logged commands are automatically scrubbed of sensitive data:
- GitHub tokens (`ghp_`, `gho_`, `ghu_`)
- OpenAI keys (`sk-...`)
- Google API keys (`AIzaSy...`)
- Bearer tokens
- Passwords in URLs (`https://user:password@host`)
- Parameters like `password=`, `api_key=`, `token=`

### 🌐 Environment Awareness
On first run, the plugin scans your machine and creates a registry of:
- PowerShell version and architecture
- Available tools in PATH
- Filesystem types (local vs SMB network drives)
- Permission levels (standard user vs admin)
- All installed Antigravity plugins and skills

---

## Real-World Examples

### Example 1: The `&&` Disaster

**What the AI sends:**
```bash
git add . && git commit -m "feat: new feature" && git push
```

**Without Execution Pilot:**
```
In riga:1 car:11
+ git add . && git commit -m "feat: new feature" && git push
           ~~
& era imprevisto.
```
The AI panics and retries. Loop begins.

**With Execution Pilot:**
```json
{
  "action": "REWRITE",
  "rewrittenCommand": "git add .\n# then:\ngit commit -m \"feat: new feature\"\n# then:\ngit push",
  "motivation": "Separate commands chained with '&&' into individual steps."
}
```
The agent is instructed to run each step sequentially. No errors, no loop.

---

### Example 2: The `grep` Loop

**What the AI sends:**
```bash
grep -r "TODO" .
```

**Without Execution Pilot:**
```
grep : The term 'grep' is not recognized as the name of a cmdlet...
```
The AI tries `grep -rn`, then `grep -rl`, then installs `grep`... all fail.

**With Execution Pilot:**
```json
{
  "action": "USE_ALTERNATIVE",
  "recommendedCommand": "rg -n \"TODO\" .",
  "motivation": "'grep' is not installed. Use 'rg' (Ripgrep) instead."
}
```

---

### Example 3: The SMB Lock Nightmare

**What the AI sends:**
```bash
npm run build
```
*(while working on `J:\Progetti\MyProject` - an SMB network share)*

**Without Execution Pilot:**
Silent hang, locked `node_modules`, file corruption.

**With Execution Pilot:**
```json
{
  "action": "BLOCK",
  "category": "smb_error",
  "motivation": "Heavy builds on SMB drives (J:\) cause lock contention. Stage to local drive first."
}
```

---

## Architecture

```
                   AI Agent generates a command
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                 Antigravity PreToolUse Hook                 │
│                 (scripts/hook-pre-tool.ps1)                 │
└─────────────────────────────┬───────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Pre-Flight Analyzer                      │
│                (scripts/preflight-command.ps1)              │
│                                                             │
│  1. Check for dangerous commands  ──► BLOCK                 │
│  2. Check for anti-loop memory   ──► BLOCK (already failed) │
│  3. Check for syntax issues      ──► REWRITE                │
│  4. Check for missing tools      ──► USE_ALTERNATIVE       │
│  5. Check for SMB restrictions   ──► BLOCK                  │
│  6. Command is safe              ──► ALLOW                  │
└─────────────────────────────┬───────────────────────────────┘
                              │
               ┌──────────────┴──────────────┐
               ▼                             ▼
        Command ALLOWED               Command MODIFIED/BLOCKED
               │                             │
               ▼                             ▼
     Windows PowerShell 5.1           AI receives clear guidance
       executes safely                without wasting tokens
```

---

## Requirements

- **Operating System**: Windows 10 / 11 / Server 2016+
- **Shell**: Windows PowerShell 5.1 (built-in, no installation needed)
- **Host**: [Google Antigravity](https://antigravity.google.com) 2.0+

---

## Installation

### Step 1 - Clone the repository

```powershell
git clone https://github.com/Jorman/Antigravity-Execution-Pilot.git
```

### Step 2 - Copy to Antigravity plugins directory

```powershell
Copy-Item -Recurse -Force ".\Antigravity-Execution-Pilot" "$env:USERPROFILE\.gemini\config\plugins\antigravity-execution-pilot"
```

### Step 3 - Enable the plugin in `config.json`

Open `%USERPROFILE%\.gemini\config\config.json` and add the plugin entry:

```json
{
  "plugins": {
    "antigravity-execution-pilot": {
      "enabled": true
    }
  }
}
```

> If `config.json` does not exist yet, create it with the content above.

### Step 4 - Restart Antigravity

Close and reopen Antigravity (or start a new chat). The `PreToolUse` hook will be active immediately.

### Step 5 - Verify installation

In a new Antigravity chat, type:

```
/agy-ep-audit
```

The plugin will scan your environment and confirm it is active.

---

## Moving to a New PC

The plugin contains **no hardcoded usernames or paths** — it dynamically uses `$env:USERPROFILE` on Windows.

```powershell
# On the new machine, in PowerShell:

# 1. Clone the repo
git clone https://github.com/Jorman/Antigravity-Execution-Pilot.git

# 2. Copy to Antigravity plugins
Copy-Item -Recurse -Force ".\Antigravity-Execution-Pilot" "$env:USERPROFILE\.gemini\config\plugins\antigravity-execution-pilot"

# 3. Enable in config.json (see Step 3 above)

# 4. Restart Antigravity
```

The plugin state and rule registry are stored in:
```
%USERPROFILE%\.gemini\config\antigravity-execution-pilot\
```
You can copy this folder too to preserve your learned rules and error history across machines.

---

## Slash Commands

After installation, the following interactive slash commands are available in any Antigravity chat:

| Command | What it does |
|---|---|
| `/agy-ep-scan` | Scans the **current conversation** for recurring error patterns (Fast, local learning) |
| `/agy-ep-scan-all` | Scans **all historical conversations** across all projects (Global learning) |
| `/agy-ep-audit` | Audits your local environment: PATH, tools, permissions, SMB drives |
| `/agy-ep-regression` | Runs the full regression test suite |
| `/agy-ep-report` | Generates a report of all intercepted commands in this session |
| `/agy-ep-rollback` | Restores rules and configuration from a backup snapshot |
| `/agy-ep-update` | Updates the alternative registry with newly discovered tools |

---

## File Structure

```
antigravity-execution-pilot/
├── plugin.json              # Plugin metadata (name, version, description)
├── hooks.json               # PreToolUse hook definition
├── README.md                # Documentation and guide
│
├── scripts/                 # 14 PowerShell scripts
│   ├── hook-pre-tool.ps1        # Entry point: intercepts run_command calls
│   ├── preflight-command.ps1    # Core engine: analyzes and rewrites commands
│   ├── classify-error.ps1       # Maps stderr/stdout to structured error categories
│   ├── redact-secrets.ps1       # Scrubs tokens, keys, passwords from logs
│   ├── detect-environment.ps1   # Scans PATH, tools, filesystems, permissions
│   ├── discover-alternatives.ps1# Builds the registry of tool alternatives
│   ├── discover-tools.ps1       # Discovers installed tools in PATH
│   ├── record-event.ps1         # Persists events to error-events.jsonl
│   ├── safe-command.ps1         # Executes commands with timeout and capture
│   ├── scan-transcripts.ps1     # Scans Antigravity chat transcripts for patterns
│   ├── propose-rule.ps1         # Proposes a new governance rule from a failure
│   ├── promote-rule.ps1         # Promotes a proposed rule to active status
│   ├── retire-rule.ps1          # Retires/expires an active rule
│   └── run-regression-tests.ps1 # Runs the full test suite
│
├── skills/                  # 9 bundled Antigravity 2.0 skills (Slash Commands)
│   ├── agy-ep-preflight/        # Pre-flight validation skill
│   ├── agy-ep-update/           # Tool discovery and substitution skill
│   ├── agy-ep-diagnostics/      # Error classification and RCA skill
│   ├── agy-ep-audit/            # Environment scanning skill
│   ├── agy-ep-regression/       # Regression testing skill
│   ├── agy-ep-rollback/         # Backup and rollback skill
│   ├── agy-ep-scan/             # Local pattern learning skill
│   ├── agy-ep-scan-all/         # Global pattern learning skill
│   └── agy-ep-report/           # Session reporting skill
│
└── tests/                   # Test definitions
    ├── preflight.tests.json     # Preflight command tests
    └── permissions.tests.json   # Permission and SMB tests
```

---

## Testing

The plugin ships with a **113-test suite** split across two layers:

### Layer 1: Sandbox Tests (78 tests, 10 groups)

Isolated ad-hoc tests that run each script in a temporary sandbox directory:

```
Group A: preflight-command.ps1    → 17 tests
Group B: classify-error.ps1       → 11 tests
Group C: redact-secrets.ps1       → 10 tests
Group D: hook-pre-tool.ps1        →  7 tests
Group E: detect-environment.ps1   →  8 tests
Group F: discover-alternatives    →  5 tests
Group G: Configuration Integrity  →  6 tests
Group H: Skills Integrity         →  4 tests
Group I: Workflows Integrity      →  7 tests
Group J: GEMINI.md Rules          →  3 tests
```

**Result: 78/78 (100%)**

### Layer 2: Regression Tests (35 tests)

End-to-end behavioral tests that simulate real AI agent scenarios:

```
T01  Tool available (git)           → ALLOW
T02  Missing tool (gh)              → missing_tool
T05  grep                           → USE_ALTERNATIVE (rg)
T10  bash                           → BLOCK
T14  && operator                    → REWRITE
T15  node -e inline                 → REWRITE
T16  python -c inline               → REWRITE
T19  npm build on SMB               → BLOCK
T22  destructive command            → BLOCK
T23  Secret redaction (token + pwd) → REDACTED
T27  Anti-repetition (fingerprint)  → BLOCK
T33  Plugin persistence             → PASS
T34  Hook bypass attempt            → DENY
... and 22 more
```

**Result: 35/35 (100%)**

### Running the tests yourself

```powershell
# Regression tests
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.gemini\config\plugins\antigravity-execution-pilot\scripts\run-regression-tests.ps1"

# Or trigger from within Antigravity
/agy-ep-regression
```

---

## Why is this a good plugin?

1. **It fixes a structural problem, not a symptom.** AI agents trained on Linux/Bash will *always* generate Unix-style commands. This plugin intercepts at the execution boundary where the real damage happens.
2. **It's fully transparent.** The AI still "sees" the commands it wants to run. The plugin just quietly fixes them before the OS does. No hallucinations, no confusion.
3. **It prevents token waste.** Every failed command triggers an AI retry loop. With anti-loop memory, one failure is one failure — not ten.
4. **It protects your data.** Destructive commands are blocked at the gate. Secrets are scrubbed from logs before they are written to disk.
5. **It works out of the box.** No configuration needed. Just copy, enable, and restart.

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

<div align="center">
Built for resilient AI-assisted development on Windows.<br>
<a href="https://github.com/Jorman/Antigravity-Execution-Pilot/issues">Report a Bug</a> · <a href="https://github.com/Jorman/Antigravity-Execution-Pilot/issues">Request a Feature</a>
</div>
