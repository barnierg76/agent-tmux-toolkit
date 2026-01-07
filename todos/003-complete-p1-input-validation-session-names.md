---
status: complete
priority: p1
issue_id: "003"
tags: [code-review, security, input-validation]
dependencies: []
---

# Missing Input Validation for Session and Pane Names

## Problem Statement

Session names, pane names, and user input from `read -p` prompts are used directly in tmux commands without validation. Malicious or malformed input could cause unexpected behavior, command parsing errors, or potential injection attacks.

**Why it matters:** Input validation is a fundamental security practice. The current code trusts all user input, which violates defense-in-depth principles.

## Findings

### Finding 1: Session Name Validation
**Location:** `bin/agent-session:6,17`

```bash
SESSION_NAME="${1:-agents}"
tmux new-session -d -s "$SESSION_NAME" -n "agents" -c "$PROJECT_PATH"
```

User can pass arbitrary session names:
```bash
agent-session "../../../etc/passwd"
agent-session "test;malicious-command"
```

### Finding 2: User Input from read -p
**Location:** `bin/agent-manage:307,318,320,331-332,341,348,357`

```bash
read -p "Session name [agents]: " session_name
session_name="${session_name:-agents}"
cmd_new "$session_name"  # Used without validation
```

### Finding 3: Pane Names
**Location:** `bin/agent-manage:94,111-112`

```bash
local names=("$@")
tmux select-pane -t "$SESSION_NAME.$new_pane" -T "${names[$i]}"
```

### Finding 4: Project Path Validation
**Location:** `bin/agent-session:7`

```bash
PROJECT_PATH="${2:-$(pwd)}"
```

No validation that path exists or is accessible.

## Proposed Solutions

### Option A: Regex Validation (Recommended)
**Description:** Validate all user-supplied names against alphanumeric pattern.

```bash
validate_name() {
    local name="$1"
    local type="${2:-name}"
    if ! [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo -e "${RED}Error: Invalid $type. Use only alphanumeric, dash, underscore.${NC}"
        return 1
    fi
}

# Usage in agent-session:
SESSION_NAME="${1:-agents}"
validate_name "$SESSION_NAME" "session name" || exit 1

# Usage in agent-manage read -p:
read -p "Session name [agents]: " session_name
session_name="${session_name:-agents}"
validate_name "$session_name" "session name" || continue
```

**Pros:**
- Simple, clear validation
- Catches all problematic characters
- User-friendly error messages

**Cons:**
- May be too restrictive for some valid use cases
- Need to apply in multiple locations

**Effort:** Small-Medium (add helper function, update ~8 locations)
**Risk:** Low

### Option B: Escape/Quote All Input
**Description:** Escape shell metacharacters instead of rejecting them.

**Pros:**
- Allows more flexible naming

**Cons:**
- Complex to implement correctly
- Easy to miss edge cases
- Security through escaping is fragile

**Effort:** Medium
**Risk:** Medium

## Recommended Action

**Option A** - Implement regex validation with clear error messages.

## Technical Details

**Affected files:**
- `bin/agent-session:6-7` - SESSION_NAME and PROJECT_PATH
- `bin/agent-manage:307,318,320,331,332,341,348,357` - read -p inputs
- `bin/agent-manage:94,111-112` - pane names from CLI args

**Helper function to add:**
```bash
# Add to both agent-session and agent-manage
validate_name() {
    local name="$1"
    local type="${2:-name}"
    if ! [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo -e "${RED}Error: Invalid $type. Use only alphanumeric, dash, underscore.${NC}" >&2
        return 1
    fi
    return 0
}

validate_path() {
    local path="$1"
    if [[ ! -d "$path" ]]; then
        echo -e "${RED}Error: Directory '$path' does not exist${NC}" >&2
        return 1
    fi
    return 0
}
```

## Acceptance Criteria

- [ ] Session names validated against `^[a-zA-Z0-9_-]+$` pattern
- [ ] Pane names validated against same pattern
- [ ] Project paths validated for existence
- [ ] Clear error messages when validation fails
- [ ] All `read -p` inputs are validated before use
- [ ] Scripts exit gracefully on invalid input

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-04 | Created finding from security review | Validate at boundaries, fail early |

## Resources

- Security Sentinel agent analysis
- CWE-20: Improper Input Validation
