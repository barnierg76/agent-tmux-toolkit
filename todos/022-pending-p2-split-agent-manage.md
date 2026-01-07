---
status: pending
priority: p2
issue_id: "022"
tags: [code-review, architecture, refactoring]
dependencies: ["019"]
---

# Split agent-manage (God Object)

## Problem Statement

`agent-manage` is 914 lines handling 7+ distinct responsibilities:
- Session management (cmd_new, cmd_open, cmd_list)
- Pane management (cmd_add, cmd_close, cmd_focus)
- Copy/paste operations (cmd_copy, cmd_paste)
- Worktree integration (cmd_worktree)
- Delegation (cmd_delegate)
- Status display (cmd_status_all)
- Interactive menu (cmd_menu)

This violates Single Responsibility Principle and makes the code hard to maintain.

## Findings

### Responsibility Breakdown
| Function | Lines | Responsibility |
|----------|-------|----------------|
| cmd_copy, cmd_copy_full | 150 | Clipboard (duplicated!) |
| cmd_paste | 87 | Clipboard |
| cmd_menu | 173 | Menu orchestration |
| cmd_worktree | 27 | Shells to agent-worktree |
| cmd_delegate | 27 | Shells to agent-delegate |
| cmd_status_all | 25 | Shells to agent-status |

### Duplication in agent-manage
`cmd_copy` and `cmd_copy_full` are 90% identical (150 lines of near-duplicate code).

### Unnecessary Wrappers
`cmd_worktree`, `cmd_delegate`, `cmd_status_all` just shell out to other scripts - these shouldn't be in agent-manage at all.

## Proposed Solutions

### Option A: Remove Unnecessary Wrappers Only (Quick Win)
Remove `cmd_worktree`, `cmd_delegate`, `cmd_status_all` since they just call other scripts.

**Pros:**
- Quick ~80 line reduction
- No structural changes
- Users can call scripts directly

**Cons:**
- agent-manage still has multiple responsibilities
- Copy/paste duplication remains

**Effort:** Low (30 min)
**Risk:** Very Low

### Option B: Extract Clipboard to Shared Library
Move clipboard functions to `agent-common.sh` (from todo 019).

**Pros:**
- Removes ~100 lines from agent-manage
- Clipboard functions shared with agent-handoff
- Single implementation to maintain

**Cons:**
- Depends on shared library work

**Effort:** Low (after 019 complete)
**Risk:** Low

### Option C: Full Split (Future)
Split into:
- `agent-session-manager` (session lifecycle)
- `agent-pane-manager` (pane operations)
- `agent-manage` (menu dispatcher only)

**Pros:**
- Clean separation of concerns
- Each script under 200 lines

**Cons:**
- Significant restructuring
- May confuse existing users

**Effort:** High (1 day)
**Risk:** Medium

## Recommended Action

Phase 1: Option A (remove wrappers) - immediate 80 line reduction
Phase 2: Option B (extract clipboard) - after todo 019

## Technical Details

### Lines to Remove (Option A)
- Lines 314-340: cmd_worktree (27 lines)
- Lines 342-368: cmd_delegate (27 lines)
- Lines 370-393: cmd_status_all (25 lines)
- Related menu entries

### Merge cmd_copy/cmd_copy_full
Extract common logic:
```bash
_copy_pane_internal() {
    local pane_idx="$1"
    local full_history="$2"
    # Common implementation
}

cmd_copy() { _copy_pane_internal "$1" false; }
cmd_copy_full() { _copy_pane_internal "$1" true; }
```

Saves ~70 lines.

## Acceptance Criteria

### Phase 1
- [ ] cmd_worktree, cmd_delegate, cmd_status_all removed
- [ ] Menu updated to not show these options
- [ ] ~80 lines removed

### Phase 2
- [ ] Clipboard functions in shared library
- [ ] cmd_copy/cmd_copy_full merged
- [ ] ~170 additional lines removed

## Work Log

| Date | Action | Notes |
|------|--------|-------|
| 2026-01-05 | Created | From architecture review |

## Resources

- Architecture Analysis: God object identification
- Code Simplicity Review: Duplication analysis
