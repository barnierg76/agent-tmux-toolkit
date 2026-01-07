---
status: complete
priority: p1
issue_id: "001"
tags: [code-review, security, high-severity]
dependencies: []
---

# Command Injection via Snippet Content

## Problem Statement

The snippet-picker directly sends user-controlled content from `snippets.txt` to tmux with auto-submit (`Enter`), allowing arbitrary command execution when a user selects a snippet. If an attacker can modify the snippets file, they can inject commands that execute in the active pane.

**Why it matters:** This is a HIGH severity security vulnerability (CVSS 8.4) that could lead to arbitrary command execution, data loss, or system compromise.

## Findings

**Location:** `bin/snippet-picker:196`

```bash
tmux send-keys "$text" Enter
```

**Proof of Concept:**
```
# In snippets.txt:
---
Innocent Looking Command
curl https://example.com; rm -rf ~/ #
---
```

When selected, this would execute destructive commands in the active pane.

**Evidence:**
- Line 196 sends text AND presses Enter automatically
- No sanitization or validation of snippet content
- User has no confirmation before execution
- Multi-line and command-chained snippets execute silently

## Proposed Solutions

### Option A: Remove Auto-Submit (Recommended)
**Description:** Remove the `Enter` keypress, requiring user to manually submit commands.

```bash
# Change line 196 from:
tmux send-keys "$text" Enter
# To:
tmux send-keys "$text"
```

**Pros:**
- Simple one-line fix
- User always sees command before execution
- Zero risk of unintended execution

**Cons:**
- Requires extra Enter keypress from user
- Breaks "fire and forget" UX for trusted snippets

**Effort:** Small (1 line change)
**Risk:** Low

### Option B: Add Confirmation for Suspicious Content
**Description:** Prompt before executing multi-line or suspicious snippets.

```bash
if [[ "$text" == *$'\n'* ]] || [[ "$text" == *"rm"* ]] || [[ "$text" == *"curl"* ]]; then
    read -p "Execute this snippet? (y/N) " confirm
    [[ "$confirm" != "y" ]] && exit 0
fi
tmux send-keys "$text" Enter
```

**Pros:**
- Preserves auto-submit for safe snippets
- Catches obvious dangerous patterns

**Cons:**
- Pattern matching is incomplete (can be bypassed)
- Blacklist approach is inherently fragile
- Complex to maintain

**Effort:** Medium
**Risk:** Medium (false sense of security)

### Option C: Whitelist Mode
**Description:** Only allow snippets matching a whitelist pattern (no shell metacharacters).

**Pros:**
- Most secure option

**Cons:**
- Overly restrictive for legitimate use cases
- High implementation effort

**Effort:** Large
**Risk:** Low

## Recommended Action

**Option A** - Remove auto-submit. The security benefit far outweighs the minor UX cost of pressing Enter.

## Technical Details

**Affected files:**
- `bin/snippet-picker:196`

**Components:** Snippet delivery system

## Acceptance Criteria

- [ ] Snippet text is sent to pane WITHOUT auto-submit
- [ ] User must manually press Enter to execute
- [ ] No regression in snippet content delivery
- [ ] Document the change in README

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-04 | Created finding from security review | Auto-submit in user-facing tools is a security anti-pattern |

## Resources

- Security Sentinel agent review
- OWASP Command Injection: https://owasp.org/www-community/attacks/Command_Injection
