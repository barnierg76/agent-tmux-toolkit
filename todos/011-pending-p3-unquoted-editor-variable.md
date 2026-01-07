---
status: pending
priority: p3
issue_id: "011"
tags: [code-review, security, low-severity]
dependencies: []
---

# Unquoted $EDITOR Variable

## Problem Statement

The `$EDITOR` environment variable is executed without quotes, which could cause issues if it contains spaces or special characters.

**Why it matters:** While low risk (users control their own EDITOR), proper quoting is a best practice that prevents edge case issues.

## Findings

**Location:** `bin/snippet-edit:9`

```bash
if [[ -n "$EDITOR" ]]; then
    $EDITOR "$SNIPPETS_FILE"  # $EDITOR unquoted
```

**Potential issue:**
```bash
export EDITOR="code --wait"  # Has space
snippet-edit  # Would try to run "code" with args "--wait" and "$SNIPPETS_FILE"
```

Actually this works correctly for most cases, but not all. The real issue is:
```bash
export EDITOR='/path/with spaces/editor'
```

## Proposed Solutions

### Option A: Quote the Variable (Recommended)
**Description:** Proper quoting of $EDITOR.

```bash
if [[ -n "$EDITOR" ]]; then
    "$EDITOR" "$SNIPPETS_FILE"
```

Wait - this would break `EDITOR="code --wait"`. The correct approach:

```bash
if [[ -n "$EDITOR" ]]; then
    eval "$EDITOR \"\$SNIPPETS_FILE\""
fi
```

Or more safely:
```bash
if [[ -n "$EDITOR" ]]; then
    $EDITOR "$SNIPPETS_FILE"  # Current behavior is actually correct for most EDITOR values
fi
```

Actually the current implementation is the standard pattern. Let's reconsider...

**Verdict:** The current implementation follows the common shell pattern for `$EDITOR`. Quoting would break `EDITOR="vim -c set nocompatible"`. The security finding is a false positive for this specific variable.

**Effort:** None needed
**Risk:** N/A

## Recommended Action

**No action required.** The current implementation is correct for the standard `$EDITOR` pattern. Shell word splitting on `$EDITOR` is intentional to support editors with arguments.

Document this decision and close.

## Technical Details

The `$EDITOR` variable is conventionally used unquoted because users often set it to include arguments:
- `EDITOR="vim -c 'set nobackup'"`
- `EDITOR="code --wait"`
- `EDITOR="emacsclient -nw"`

Quoting would break all of these. The current implementation is correct.

## Acceptance Criteria

- [x] Confirm current implementation is correct (it is)
- [ ] Add comment explaining why $EDITOR is unquoted

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-04 | Created finding from security review | $EDITOR unquoted is intentional standard pattern |
| 2026-01-04 | Determined no fix needed | Not all unquoted variables are bugs |

## Resources

- Security Sentinel analysis (false positive for this case)
- Bash FAQ on EDITOR: https://mywiki.wooledge.org/BashFAQ/089
