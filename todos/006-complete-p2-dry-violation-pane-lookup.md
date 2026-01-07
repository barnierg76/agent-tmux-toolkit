---
status: complete
priority: p2
issue_id: "006"
tags: [code-review, dry, maintainability]
dependencies: []
---

# Duplicated Pane Lookup Logic (DRY Violation)

## Problem Statement

The "find pane by name or index" logic is copy-pasted in `cmd_close()` and `cmd_focus()`. If the lookup logic needs to change, two places must be updated, risking divergence.

**Why it matters:** DRY (Don't Repeat Yourself) violations lead to bugs when one copy is updated but not the other. This is a maintenance burden and code smell.

## Findings

**Location 1:** `bin/agent-manage:137-150`
```bash
# In cmd_close()
if [[ "$target" =~ ^[0-9]+$ ]]; then
    tmux kill-pane -t "$SESSION_NAME.$target" 2>/dev/null && \
        echo -e "${GREEN}Closed pane $target${NC}" || \
        echo -e "${RED}Error: Pane $target not found${NC}"
else
    # Find pane by name
    local pane_index=$(tmux list-panes -t "$SESSION_NAME" -F "#{pane_index}:#{pane_title}" | grep ":$target" | cut -d: -f1 | head -1)
    if [[ -n "$pane_index" ]]; then
        tmux kill-pane -t "$SESSION_NAME.$pane_index"
        # ...
```

**Location 2:** `bin/agent-manage:219-231`
```bash
# In cmd_focus() - IDENTICAL logic
if [[ "$target" =~ ^[0-9]+$ ]]; then
    tmux select-pane -t "$SESSION_NAME.$target" 2>/dev/null && \
        # ...
else
    local pane_index=$(tmux list-panes -t "$SESSION_NAME" -F "#{pane_index}:#{pane_title}" | grep ":$target" | cut -d: -f1 | head -1)
    if [[ -n "$pane_index" ]]; then
        # ...
```

**Impact:**
- ~20 lines of duplicated code
- Bug risk if logic diverges
- Multiple tmux calls that could be consolidated

## Proposed Solutions

### Option A: Extract Helper Function (Recommended)
**Description:** Create `resolve_pane()` function that returns pane index.

```bash
# Resolve pane target (name or index) to pane index
# Returns: pane index on stdout, exit 1 if not found
resolve_pane() {
    local target="$1"

    # If already a number, verify it exists
    if [[ "$target" =~ ^[0-9]+$ ]]; then
        if tmux list-panes -t "$SESSION_NAME" -F "#{pane_index}" | grep -q "^$target$"; then
            echo "$target"
            return 0
        fi
    else
        # Find by name
        local index
        index=$(tmux list-panes -t "$SESSION_NAME" -F "#{pane_index}:#{pane_title}" | \
            awk -F: -v name="$target" '$2 == name {print $1; exit}')
        if [[ -n "$index" ]]; then
            echo "$index"
            return 0
        fi
    fi
    return 1
}

# Usage in cmd_close:
cmd_close() {
    check_session
    local target="$1"
    [[ -z "$target" ]] && die "Specify pane index or name"

    local pane
    if ! pane=$(resolve_pane "$target"); then
        die "Pane '$target' not found"
    fi

    tmux kill-pane -t "$SESSION_NAME.$pane"
    info "Closed pane $pane"
}

# Usage in cmd_focus:
cmd_focus() {
    check_session
    local target="$1"
    [[ -z "$target" ]] && die "Specify pane index or name"

    local pane
    if ! pane=$(resolve_pane "$target"); then
        die "Pane '$target' not found"
    fi

    tmux select-pane -t "$SESSION_NAME.$pane"
    info "Focused on pane $pane"
}
```

**Pros:**
- Single source of truth for pane lookup
- Cleaner, more readable command functions
- Easier to test and maintain
- Can add caching if needed

**Cons:**
- Minor refactoring required

**Effort:** Small
**Risk:** Low

## Recommended Action

**Option A** - Extract `resolve_pane()` helper function.

## Technical Details

**Affected file:** `bin/agent-manage`

**Lines to refactor:**
- Lines 137-157: `cmd_close()` pane lookup
- Lines 219-232: `cmd_focus()` pane lookup

**New function location:** After `check_session()`, around line 58

## Acceptance Criteria

- [ ] `resolve_pane()` function extracts common lookup logic
- [ ] `cmd_close()` uses `resolve_pane()`
- [ ] `cmd_focus()` uses `resolve_pane()`
- [ ] Both commands have identical pane resolution behavior
- [ ] Error messages are consistent
- [ ] No regression in functionality

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-04 | Created finding from pattern review | Extract common logic to single function |

## Resources

- Pattern Recognition Specialist analysis
- Code Simplicity Reviewer analysis
