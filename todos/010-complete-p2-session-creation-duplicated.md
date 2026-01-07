---
status: complete
priority: p2
issue_id: "010"
tags: [code-review, dry, maintainability]
dependencies: []
---

# Session Creation Logic Duplicated in agent-manage

## Problem Statement

The `cmd_new()` function in agent-manage contains fallback logic that duplicates the entire session creation from agent-session. If the session layout changes, two places must be updated.

**Why it matters:** DRY violation creates maintenance burden and risk of the two implementations diverging.

## Findings

**Location:** `bin/agent-manage:397-424`

```bash
cmd_new() {
    local session_name="${1:-agents}"

    if tmux has-session -t "$session_name" 2>/dev/null; then
        echo -e "${YELLOW}Session '$session_name' already exists. Attaching...${NC}"
        tmux attach -t "$session_name"
        return
    fi

    # Use agent-session script if available
    if command -v agent-session &> /dev/null; then
        agent-session "$session_name"
    else
        # Fallback: create basic 3-pane layout (DUPLICATES agent-session)
        tmux new-session -d -s "$session_name" -n "agents"
        tmux split-window -h -t "$session_name:agents"
        tmux split-window -h -t "$session_name:agents"
        tmux select-layout -t "$session_name:agents" even-horizontal

        # Name panes (DUPLICATES agent-session:31-34)
        local panes=($(tmux list-panes -t "$session_name:agents" -F "#{pane_index}"))
        tmux select-pane -t "$session_name:agents.${panes[0]}" -T "PLAN"
        tmux select-pane -t "$session_name:agents.${panes[1]}" -T "WORK"
        tmux select-pane -t "$session_name:agents.${panes[2]}" -T "REVIEW"

        tmux attach -t "$session_name"
    fi
}
```

**Comparison with agent-session:16-34:**
Both have identical:
- 3-pane horizontal split
- even-horizontal layout
- PLAN/WORK/REVIEW pane naming

**Problem:** If we add a 4th pane or change defaults, both files need updating.

## Proposed Solutions

### Option A: Remove Fallback, Require agent-session (Recommended)
**Description:** If agent-session isn't installed, fail with clear error.

```bash
cmd_new() {
    local session_name="${1:-agents}"

    if tmux has-session -t "$session_name" 2>/dev/null; then
        echo -e "${YELLOW}Session '$session_name' already exists. Attaching...${NC}"
        tmux attach -t "$session_name"
        return
    fi

    if ! command -v agent-session &> /dev/null; then
        die "agent-session not found. Run install.sh first."
    fi

    agent-session "$session_name"
}
```

**Pros:**
- Single source of truth
- Clear error message
- Simpler code

**Cons:**
- Requires full installation
- Can't use agent-manage standalone

**Effort:** Small (delete 15 lines)
**Risk:** Low

### Option B: Extract Shared Function
**Description:** Create `create_3pane_session()` in shared library.

**Pros:**
- Keeps fallback capability
- Single implementation

**Cons:**
- Adds complexity (shared lib)
- Overkill for this use case

**Effort:** Medium
**Risk:** Low

## Recommended Action

**Option A** - Remove fallback, require agent-session. The fallback was likely added for convenience but creates maintenance burden. Users should run `install.sh` which installs both scripts.

## Technical Details

**Affected file:** `bin/agent-manage`

**Lines to remove:** 410-423 (fallback block)

## Acceptance Criteria

- [ ] Fallback session creation code removed
- [ ] Clear error message if agent-session missing
- [ ] agent-manage new still works when properly installed
- [ ] Session layout changes only need to update agent-session

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-04 | Created finding from architecture review | Remove fallbacks that duplicate primary implementation |

## Resources

- Architecture Strategist analysis
- Code Simplicity Reviewer analysis
