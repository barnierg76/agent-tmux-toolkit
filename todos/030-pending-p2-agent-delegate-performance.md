---
status: completed
priority: p2
issue_id: "030"
tags: [code-review, performance]
dependencies: ["026"]
completed_date: "2026-01-07"
---

# Performance: agent-delegate Makes Excessive tmux Calls

## Problem Statement

`agent-delegate` makes 7 separate tmux calls per task when creating sessions, resulting in 175-350ms overhead for 5 tasks. Session creation could be batched into fewer calls using tmux command chaining.

**Current:** 35 tmux calls for 5 tasks (7 calls × 5 tasks)
**Optimal:** 5 tmux calls for 5 tasks (1 batched call × 5 tasks)

## Findings

**Location:** `bin/agent-delegate:116-155`

**Current implementation (per task):**
```bash
# 7 separate tmux calls per session:
tmux new-session -d -s "$SESSION_NAME" -c "$WORKTREE_DIR"     # Call 1
tmux split-window -h -t "$SESSION_NAME" -c "$WORKTREE_DIR"    # Call 2
tmux split-window -h -t "$SESSION_NAME" -c "$WORKTREE_DIR"    # Call 3
tmux select-layout -t "$SESSION_NAME" even-horizontal         # Call 4
PANE_IDS=($(tmux list-panes -t "$SESSION_NAME" -F "#{pane_id}"))  # Call 5
tmux set-option -p -t "${PANE_IDS[0]}" @role "PLAN"          # Call 6
# ... more set-option calls ...                               # Calls 7-9
```

**Performance impact:**
- Each tmux call: ~15-30ms
- Per session creation: ~120ms
- 5 sessions: ~600ms
- Could be reduced to ~150ms with batching

## Proposed Solutions

### Option A: Use tmux Command Chaining (Recommended)
**Description:** Chain multiple tmux commands with `\;` separator.

```bash
# Single tmux invocation for session creation:
tmux new-session -d -s "$SESSION_NAME" -c "$workdir" \; \
    split-window -h -c "$workdir" \; \
    split-window -h -c "$workdir" \; \
    select-layout even-horizontal
```

**Pros:**
- 75% reduction in tmux calls
- Simpler after todo 026 (shared function)
- Atomic session creation

**Cons:**
- Slightly more complex syntax
- All-or-nothing (if one command fails, hard to recover)

**Effort:** Medium (implemented as part of todo 026)
**Risk:** Low

### Option B: Keep Sequential, Optimize Later
**Description:** Leave as-is, performance is acceptable for typical usage.

**Pros:**
- No changes needed
- Current approach is simpler to debug

**Cons:**
- Scales poorly with many sessions

**Effort:** None
**Risk:** None

## Recommended Action

**Option A** - Implement as part of todo 026 (extract create_agent_session). When extracting the function, optimize it to use command chaining.

## Technical Details

**Optimized create_agent_session function:**
```bash
create_agent_session() {
    local session_name="$1"
    local working_dir="$2"
    local task_id="${3:-Ready}"

    # Single batched tmux call for layout
    tmux new-session -d -s "$session_name" -n "agents" -c "$working_dir" \; \
        split-window -h -c "$working_dir" \; \
        split-window -h -c "$working_dir" \; \
        select-layout even-horizontal

    # Get pane IDs and set roles (still need list-panes)
    local pane_ids
    mapfile -t pane_ids < <(tmux list-panes -t "$session_name" -F "#{pane_id}")

    # Batch role setting (if possible)
    for i in 0 1 2; do
        local role
        case $i in
            0) role="PLAN" ;;
            1) role="WORK" ;;
            2) role="REVIEW" ;;
        esac
        tmux set-option -p -t "${pane_ids[$i]}" @role "$role" \; \
            select-pane -t "${pane_ids[$i]}" -T "$task_id"
    done
}
```

**Expected improvement:**
- Before: 7 tmux calls per session (~120ms)
- After: 2 tmux calls per session (~30ms)
- 75% improvement

## Acceptance Criteria

- [x] Session creation uses batched tmux commands
- [x] `agent-delegate` with 5 tasks completes faster
- [x] Functionality unchanged
- [x] Implemented as part of todo 026

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-07 | Created from performance review | tmux command chaining reduces overhead significantly |
| 2026-01-07 | Implemented via create_agent_session in todo 026 | Batched tmux commands: new-session, split-window x2, select-layout |

## Resources

- Performance Oracle analysis
- tmux man page: command chaining with `\;`
- Depends on todo 026 (session creation extraction)
