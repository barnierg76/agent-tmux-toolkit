---
status: pending
priority: p2
issue_id: "005"
tags: [code-review, architecture, maintainability]
dependencies: []
---

# Inconsistent Error Handling Patterns

## Problem Statement

The codebase uses `set -e` in some scripts but not others, mixes error handling patterns (short-circuit vs if-else), and lacks a common error handler. This creates fragile, unpredictable behavior.

**Why it matters:** Inconsistent error handling leads to silent failures, unexpected script termination, and difficult debugging.

## Findings

### Finding 1: Inconsistent set -e Usage
**Files with `set -e`:**
- `bin/agent-manage:5`
- `install.sh:4`

**Files WITHOUT `set -e`:**
- `bin/agent-session`
- `bin/snippet-picker`
- `bin/snippet-edit`

### Finding 2: Mixed Error Patterns

**Pattern A - Short-circuit (agent-manage:138-140):**
```bash
tmux kill-pane -t "$SESSION_NAME.$target" 2>/dev/null && \
    echo -e "${GREEN}Closed pane $target${NC}" || \
    echo -e "${RED}Error: Pane $target not found${NC}"
```

**Pattern B - If-else (agent-manage:143-150):**
```bash
if [[ -n "$pane_index" ]]; then
    tmux kill-pane -t "$SESSION_NAME.$pane_index"
    echo -e "${GREEN}Closed pane '$target'${NC}"
else
    echo -e "${RED}Error: Pane named '$target' not found${NC}"
    exit 1
fi
```

**Pattern C - No error check (agent-session:29):**
```bash
PANES=($(tmux list-panes -t "$SESSION_NAME:agents" -F "#{pane_index}"))
# No validation that this succeeded
```

### Finding 3: No Common Error Handler
Each script defines its own error messages inline with no standard format or function.

## Proposed Solutions

### Option A: Standardize on Explicit Error Handling (Recommended)
**Description:** Remove `set -e`, use `set -u -o pipefail`, create common error helper.

```bash
#!/bin/bash
set -u          # Error on undefined variables
set -o pipefail # Pipe failures propagate

# Common error handler
die() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit "${2:-1}"
}

# Usage
[[ -z "$target" ]] && die "Specify pane index or name"

if ! tmux kill-pane -t "$SESSION_NAME.$target" 2>/dev/null; then
    die "Pane $target not found"
fi
```

**Pros:**
- Predictable behavior
- Clear error messages
- Easy to maintain

**Cons:**
- Requires updating all scripts
- More verbose than short-circuit

**Effort:** Medium
**Risk:** Low

### Option B: Keep set -e, Fix Interactions
**Description:** Add `set -e` to all scripts, fix the problematic patterns.

**Pros:**
- Fail-fast behavior
- Less code than explicit handling

**Cons:**
- `set -e` has many gotchas
- Can cause unexpected exits

**Effort:** Medium
**Risk:** Medium

## Recommended Action

**Option A** - Standardize on explicit error handling with common helper function.

## Technical Details

**Create common library:** `lib/common.sh` or inline in each script

```bash
# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Error handler with exit code
die() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit "${2:-1}"
}

# Info messages
info() {
    echo -e "${GREEN}$1${NC}"
}

warn() {
    echo -e "${YELLOW}$1${NC}"
}
```

**Files to update:**
- `bin/agent-manage` - Replace inline errors with die()
- `bin/agent-session` - Add error checking for pane creation
- `bin/snippet-picker` - Add set -u -o pipefail
- `install.sh` - Standardize error messages

## Acceptance Criteria

- [ ] All scripts use `set -u -o pipefail`
- [ ] Common `die()` function used for all errors
- [ ] No raw `exit 1` without error message
- [ ] All tmux commands have error handling
- [ ] Consistent error message format: "Error: <message>"

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-04 | Created finding from architecture/pattern review | set -e is problematic; explicit handling is clearer |

## Resources

- Architecture Strategist analysis
- Pattern Recognition Specialist analysis
- BashFAQ: http://mywiki.wooledge.org/BashFAQ/105
