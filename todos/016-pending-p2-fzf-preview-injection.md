---
status: completed
priority: p2
issue_id: "016"
tags: [code-review, security, medium-severity]
dependencies: []
completed_date: "2026-01-07"
---

# fzf Preview Command Variable Expansion

## Problem Statement

The fzf preview commands in agent-manage use variable expansion within preview strings, which could allow command injection if SESSION_NAME contains malicious characters via the AGENT_SESSION environment variable.

**Why it matters:** An attacker who can control the AGENT_SESSION environment variable could inject commands that execute when the fzf preview renders.

## Findings

**Locations:**
- `bin/agent-manage:443` - Copy pane preview
- `bin/agent-manage:517` - Copy-full preview
- `bin/agent-manage:604` - Paste clipboard preview

**Vulnerable pattern:**
```bash
--preview="tmux capture-pane -p -S -20 -t '$SESSION_NAME.{1}' 2>/dev/null | head -20"
```

**Exploitation scenario:**
```bash
export AGENT_SESSION="test'; echo hacked; echo '"
agent-manage copy  # Preview could execute injected command
```

## Proposed Solutions

### Option A: Escape Session Name (Recommended)
**Description:** Properly escape the session name before use in preview

```bash
SAFE_SESSION=$(printf '%q' "$SESSION_NAME")
--preview="tmux capture-pane -p -S -20 -t \"${SAFE_SESSION}.{1}\" 2>/dev/null | head -20"
```

**Pros:**
- Direct fix
- Minimal code change

**Cons:**
- Must be applied in multiple locations

**Effort:** Small
**Risk:** Low

### Option B: Validate SESSION_NAME Early
**Description:** Add validate_name check when SESSION_NAME is set

**Pros:**
- Prevents bad names at source
- Simpler than escaping everywhere

**Cons:**
- May break legitimate edge cases

**Effort:** Small
**Risk:** Low

## Recommended Action

**Option A** - Escape session name in preview commands.

## Technical Details

**Files affected:** `bin/agent-manage`
**Lines:** 443, 517, 604

## Acceptance Criteria

- [x] SESSION_NAME is safely escaped in all fzf preview commands
- [x] Malicious AGENT_SESSION values don't cause command execution
- [x] Preview functionality still works correctly

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-04 | Created from security review | Always escape variables in shell strings |
| 2026-01-07 | Fixed: Added safe_session=$(printf '%q' "$SESSION_NAME") | Escape applied to copy pane preview commands |

## Resources

- Security Sentinel analysis
