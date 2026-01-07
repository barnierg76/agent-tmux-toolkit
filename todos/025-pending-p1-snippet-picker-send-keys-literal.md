---
status: completed
priority: p1
issue_id: "025"
tags: [code-review, security, regression]
dependencies: []
completed_date: "2026-01-07"
---

# Security: snippet-picker Missing -l Flag on tmux send-keys

## Problem Statement

`snippet-picker` uses `tmux send-keys` without the `-l` (literal) flag at line 170, allowing snippets containing special characters like "Enter" to execute as key sequences rather than literal text. This is a security regression - todo 001 was marked complete but the fix was not applied.

**Severity:** HIGH - Command injection via malicious snippets
**Attack Vector:** User creates or edits snippet containing `Enter` key sequence

## Findings

**Location:** `bin/snippet-picker:170`

**Current code:**
```bash
tmux send-keys -t "$TARGET_PANE" "$text"
```

**Problem:** Without `-l`, special sequences like `Enter`, `C-c`, `Tab` are interpreted as key presses.

**Proof of Concept:**
A snippet containing:
```
echo "harmless"
Enter
rm -rf /tmp/test
```

Would execute both commands, not paste them literally.

**Contrast with agent-manage (correct):**
```bash
# bin/agent-manage:440 - CORRECT
tmux send-keys -t "$SESSION_NAME.$pane_idx" -l "$content"
```

## Proposed Solutions

### Option A: Add -l Flag (Recommended)
**Description:** Simple one-character fix.

```bash
# Change line 170 from:
tmux send-keys -t "$TARGET_PANE" "$text"

# To:
tmux send-keys -t "$TARGET_PANE" -l "$text"
```

**Pros:**
- 5-second fix
- Matches agent-manage pattern
- Complete protection

**Cons:**
- None

**Effort:** Trivial (< 1 minute)
**Risk:** None

## Recommended Action

**Option A** - Add `-l` flag immediately. This is a critical security fix.

## Technical Details

**File:** `bin/snippet-picker`
**Line:** 170
**Change:** Add `-l` flag between `-t "$TARGET_PANE"` and `"$text"`

## Acceptance Criteria

- [x] Line 170 uses `tmux send-keys -t "$TARGET_PANE" -l "$text"`
- [x] Snippets containing "Enter" are pasted literally, not executed
- [x] TODO 001 (command injection) is actually resolved

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-07 | Created from security review | Always use `-l` flag with send-keys for user content |
| 2026-01-07 | Fixed: Added -l flag to line 171 | Security regression resolved |

## Resources

- Security Sentinel audit identified this regression
- Related to todo 001 (command injection snippet-picker)
- tmux man page: `-l` flag disables key name lookup
