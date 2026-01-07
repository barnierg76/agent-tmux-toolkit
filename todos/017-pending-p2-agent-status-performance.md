---
status: pending
priority: p2
issue_id: "017"
tags: [code-review, performance, optimization]
dependencies: []
---

# agent-status N+1 tmux Query Problem

## Problem Statement

The agent-status script makes 3 tmux subprocess calls per session in its main loop, creating O(3n) overhead. For 10 sessions, this means 30 tmux invocations, adding 150-450ms per refresh. In watch mode, this creates sustained CPU overhead.

**Why it matters:** At 10+ sessions, the dashboard becomes noticeably slow. At 100 sessions, it takes 4+ seconds per refresh.

## Findings

**Location:** `bin/agent-status:94-129`

**Current implementation:**
```bash
while IFS='|' read -r name windows attached activity; do
    # SUBPROCESS #1: Get pane count
    pane_count=$(tmux list-panes -t "$name" 2>/dev/null | wc -l | tr -d ' ')

    # SUBPROCESS #2: Get last output for status detection
    last_line=$(tmux capture-pane -t "$name:0.0" -p 2>/dev/null | ...)

    # SUBPROCESS #3: Get last output again for display
    last_output=$(tmux capture-pane -t "$name:0.0" -p 2>/dev/null | ...)
done <<< "$sessions"
```

**Performance impact:**
- 3 tmux calls × 10 sessions = 30 subprocess invocations
- Each tmux call: ~5-15ms
- Total: 150-450ms per refresh
- Watch mode: 22.5% CPU time waiting on tmux

## Proposed Solutions

### Option A: Batch tmux Queries (Recommended)
**Description:** Use single tmux calls to get all data at once

```bash
# Single call for all pane counts
all_pane_data=$(tmux list-panes -a -F "#{session_name}|#{pane_index}" 2>/dev/null)

# Process in awk without subprocess per session
echo "$all_pane_data" | awk -F'|' '{count[$1]++} END {for(s in count) print s"|"count[s]}'
```

**Pros:**
- 75% reduction in tmux calls
- Scales well to 100+ sessions

**Cons:**
- More complex awk processing
- Requires format string redesign

**Effort:** Medium
**Risk:** Medium

### Option B: Cache and Reuse Capture
**Description:** Capture once per session, reuse for status detection and display

```bash
last_line=$(tmux capture-pane -t "$name:0.0" -p 2>/dev/null | grep -v '^$' | tail -1)
last_output="${last_line:0:33}"  # Reuse instead of re-capturing
```

**Pros:**
- 33% reduction in capture calls
- Simple change

**Cons:**
- Still O(n) captures per refresh

**Effort:** Small
**Risk:** Low

## Recommended Action

**Option B first** (quick win), then **Option A** for full optimization.

## Technical Details

**File:** `bin/agent-status`
**Lines:** 94-129

## Acceptance Criteria

- [ ] Duplicate capture-pane calls eliminated
- [ ] Status refresh completes in <200ms for 10 sessions
- [ ] Watch mode CPU usage reduced by 50%+
- [ ] No regression in status accuracy

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-04 | Created from performance review | Batch tmux queries for scalability |

## Resources

- Performance Oracle analysis
