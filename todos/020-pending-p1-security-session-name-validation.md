---
status: pending
priority: p1
issue_id: "020"
tags: [code-review, security, validation]
dependencies: ["019"]
---

# Security: Validate SESSION_NAME Consistently

## Problem Statement

The `SESSION_NAME` variable is used in tmux commands and fzf preview commands without consistent validation. While `validate_name()` exists, it's not applied everywhere SESSION_NAME is used.

**Severity:** HIGH (CVSS 7.3)
**Attack Vector:** Environment variable injection via `AGENT_SESSION`

## Findings

### Vulnerable Locations
- **agent-flow-state:21**: `STATE_FILE="$STATE_DIR/${SESSION_NAME}.state"` - Path traversal possible
- **agent-manage:443**: fzf preview uses `$SESSION_NAME` in shell command
- **agent-manage:518**: fzf preview uses `$SESSION_NAME` in shell command
- **agent-manage:606**: fzf preview uses `$SESSION_NAME` in shell command

### Proof of Concept
```bash
export AGENT_SESSION="../../../tmp/evil"
agent-flow-state set PLANNING
# Creates file outside intended directory

export AGENT_SESSION="test'; rm -rf ~ #"
agent-manage copy
# Command injection in fzf preview
```

### Existing Validation
`validate_name()` in agent-manage:17-26 restricts to `^[a-zA-Z0-9_-]+$` but is not consistently applied.

## Proposed Solutions

### Option A: Validate at Source (Recommended)
Add validation in `get_session_name()` before returning.

**Implementation:**
```bash
get_session_name() {
    local name
    if [ -n "$AGENT_SESSION" ]; then
        name="$AGENT_SESSION"
    elif name=$(tmux display-message -p '#{session_name}' 2>/dev/null); then
        :
    else
        name="agents"
    fi

    # Validate before returning
    if ! [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "Error: Invalid session name '$name'" >&2
        return 1
    fi
    echo "$name"
}
```

**Pros:**
- Single point of validation
- All scripts automatically protected

**Cons:**
- Requires shared library (todo 019)

**Effort:** Low (30 min, after 019)
**Risk:** Low

### Option B: Escape Before Use
Use `printf '%q'` to escape SESSION_NAME before shell interpolation.

**Pros:**
- Doesn't require shared library
- Can be applied incrementally

**Cons:**
- Easy to miss locations
- More code to maintain

**Effort:** Medium (1-2 hours)
**Risk:** Medium (might miss spots)

## Recommended Action

Option A after completing todo 019 (shared library). Validation should happen in `get_session_name()` so all scripts are protected automatically.

## Technical Details

### Files to Update
- bin/agent-flow-state:20-21
- bin/agent-manage:443, 518, 606
- bin/agent-handoff:25
- bin/agent-flow:25

### Validation Pattern
```bash
[[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]] || return 1
```

## Acceptance Criteria

- [ ] `get_session_name()` validates input before returning
- [ ] All fzf preview commands use validated session name
- [ ] Path traversal attack no longer works
- [ ] Command injection in fzf preview no longer works

## Work Log

| Date | Action | Notes |
|------|--------|-------|
| 2026-01-05 | Created | From security audit |

## Resources

- Security Audit Report: Full vulnerability details
- CWE-78: OS Command Injection
- CWE-22: Path Traversal
