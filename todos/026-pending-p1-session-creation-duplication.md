---
status: completed
priority: p1
issue_id: "026"
tags: [code-review, architecture, duplication, dry]
dependencies: []
completed_date: "2026-01-07"
---

# DRY Violation: 3-Pane Session Creation Duplicated in 4 Files

## Problem Statement

The 3-pane agent session creation logic is duplicated across 4 scripts (60-80 lines total):
- `agent-session:91-120` (29 lines)
- `agent-delegate:116-128` (13 lines - worktree mode)
- `agent-delegate:140-152` (13 lines - non-worktree mode)
- `agent-worktree:184-196` (13 lines - fallback)

This violates DRY principle. Bug fixes require 4 synchronized changes, and the implementations are already diverging.

**Why it matters:** Changes to session creation require updating 4 places. Inconsistencies have already appeared in error handling and title setting between the copies.

## Findings

**Duplicated Code Pattern (appears 4 times):**
```bash
tmux new-session -d -s "$SESSION_NAME" -c "$WORKING_DIR"
tmux split-window -h -t "$SESSION_NAME" -c "$WORKING_DIR"
tmux split-window -h -t "$SESSION_NAME" -c "$WORKING_DIR"
tmux select-layout -t "$SESSION_NAME" even-horizontal

PANE_IDS=($(tmux list-panes -t "$SESSION_NAME" -F "#{pane_id}"))
tmux set-option -p -t "${PANE_IDS[0]}" @role "PLAN"
tmux set-option -p -t "${PANE_IDS[1]}" @role "WORK"
tmux set-option -p -t "${PANE_IDS[2]}" @role "REVIEW"
# ... title setting
```

**Evidence of Divergence:**
- `agent-session` has task-aware title setting (lines 112-120)
- `agent-delegate` has simpler title setting (lines 126-128)
- `agent-worktree` checks for agent-session availability first (lines 177-181)

## Proposed Solutions

### Option A: Extract to agent-common.sh (Recommended)
**Description:** Add `create_agent_session()` function to the shared library.

```bash
# Add to bin/agent-common.sh

# Create standard 3-pane agent session
# Usage: create_agent_session <session_name> <working_dir> [task_id]
create_agent_session() {
    local session_name="$1"
    local working_dir="$2"
    local task_id="${3:-}"

    # Create session with 3 panes
    tmux new-session -d -s "$session_name" -n "agents" -c "$working_dir"
    tmux split-window -h -t "$session_name:agents" -c "$working_dir"
    tmux split-window -h -t "$session_name:agents" -c "$working_dir"
    tmux select-layout -t "$session_name:agents" even-horizontal

    # Set roles
    local pane_ids
    mapfile -t pane_ids < <(tmux list-panes -t "$session_name" -F "#{pane_id}")
    tmux set-option -p -t "${pane_ids[0]}" @role "PLAN"
    tmux set-option -p -t "${pane_ids[1]}" @role "WORK"
    tmux set-option -p -t "${pane_ids[2]}" @role "REVIEW"

    # Set titles
    local title="${task_id:-Ready}"
    tmux select-pane -t "${pane_ids[0]}" -T "$title"
    tmux select-pane -t "${pane_ids[1]}" -T "$title"
    tmux select-pane -t "${pane_ids[2]}" -T "$title"
}
```

**Pros:**
- Single source of truth
- ~60 lines eliminated across codebase
- Easier testing and maintenance
- Automatic consistency

**Cons:**
- Requires updating 4 scripts to use new function

**Effort:** Medium (1-2 hours)
**Risk:** Low

## Recommended Action

**Option A** - Extract to shared library. All scripts already source `agent-common.sh`, so this is straightforward.

## Technical Details

**Files to update:**
1. `bin/agent-common.sh` - Add function
2. `bin/agent-session:91-120` - Replace with function call
3. `bin/agent-delegate:116-152` - Replace both blocks with function call
4. `bin/agent-worktree:184-196` - Replace fallback with function call

**Implementation order:**
1. Add function to agent-common.sh
2. Update agent-session first (simplest case)
3. Test agent-session
4. Update agent-delegate
5. Update agent-worktree

## Acceptance Criteria

- [x] `create_agent_session()` function exists in agent-common.sh
- [x] agent-session uses the new function
- [x] agent-delegate uses the new function (both modes)
- [x] agent-worktree uses the new function (fallback path)
- [x] All scripts create identical session layouts
- [x] ~60 lines removed from codebase

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-07 | Created from architecture review | Extract duplicated logic to shared library |
| 2026-01-07 | Implemented create_agent_session() in agent-common.sh | Used batched tmux commands for performance |
| 2026-01-07 | Updated agent-session, agent-delegate (2 locations), agent-worktree | ~60 lines consolidated |

## Resources

- Architecture Strategist analysis
- Pattern Recognition Specialist identified 4 duplicate locations
- Related to todo 010 (session creation duplicated) - but that focused on different duplication
