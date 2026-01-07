---
status: completed
priority: p2
issue_id: "027"
tags: [code-review, patterns, reliability]
dependencies: []
completed_date: "2026-01-07"
---

# Inconsistent Error Handling Across Scripts

## Problem Statement

Scripts use inconsistent error handling approaches:
- **WITH `set -e`:** agent-status, agent-handoff, agent-worktree, agent-delegate, agent-manage, agent-flow (6 files)
- **WITHOUT `set -e`:** agent-session, snippet-picker (2 files)
- **Stricter `set -euo pipefail`:** triage-issues.sh, fix-stale-todos.sh (2 files)

This creates unpredictable failure behavior - some scripts fail fast on errors, others continue silently.

## Findings

**Scripts WITHOUT `set -e`:**
- `bin/agent-session` - No error trapping
- `bin/snippet-picker` - No error trapping
- `bin/agent-common.sh` - No error trapping (expected for sourced files)

**Example inconsistency:**
```bash
# agent-session - silently continues if tmux attach fails
tmux attach -t "$SESSION_NAME"  # No error check
exit 0

# agent-worktree - fails immediately on any error
set -e  # Line 4
git worktree add ...  # Script exits if this fails
```

**Mixed error checking patterns:**
```bash
# Pattern A: Inline with ||
validate_name "$SESSION_NAME" "session name" || exit 1

# Pattern B: Inline with &&
[[ -z "$target" ]] && { echo -e "${RED}Error..."; exit 1; }

# Pattern C: if statement
if [ -z "$content" ]; then
    echo -e "${YELLOW}..."
    return 0
fi
```

## Proposed Solutions

### Option A: Standardize on `set -e` (Recommended)
**Description:** Add `set -e` to all executable scripts (not sourced files).

**Files to update:**
- `bin/agent-session` - Add `set -e`
- `bin/snippet-picker` - Add `set -e`

**Pros:**
- Fail-fast on unexpected errors
- Easier debugging
- Consistent behavior

**Cons:**
- May expose latent bugs
- Need to verify no silent failures are intentional

**Effort:** Small (15 minutes + testing)
**Risk:** Low-Medium (test thoroughly)

### Option B: Use `set -euo pipefail` Everywhere
**Description:** Use stricter mode for all scripts.

**Pros:**
- Catches more issues (undefined variables, pipe failures)
- Industry best practice

**Cons:**
- More restrictive
- May require code changes for unset variables

**Effort:** Medium (1 hour)
**Risk:** Medium

### Option C: Document Current Behavior
**Description:** Leave as-is but document which scripts fail-fast.

**Pros:**
- No code changes
- No risk of breaking

**Cons:**
- Inconsistency remains
- Silent failures continue

**Effort:** Small
**Risk:** None

## Recommended Action

**Option A** - Standardize on `set -e` for all executable scripts. This is the minimum consistency improvement with low risk.

## Technical Details

**Files to add `set -e`:**
1. `bin/agent-session` - Add after shebang
2. `bin/snippet-picker` - Add after shebang

**Files that correctly have `set -e`:**
- agent-manage, agent-flow, agent-handoff, agent-worktree, agent-delegate, agent-status

**Do NOT add to:**
- `bin/agent-common.sh` - Sourced files shouldn't set shell options

## Acceptance Criteria

- [x] `bin/agent-session` has `set -e`
- [x] `bin/snippet-picker` has `set -e`
- [x] All scripts tested and still function correctly
- [x] Silent failures are caught and handled appropriately

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-07 | Created from pattern recognition review | Inconsistent error handling creates unpredictable behavior |
| 2026-01-07 | Added set -e to agent-session and snippet-picker | All executable scripts now have set -e |

## Resources

- Pattern Recognition Specialist analysis
- Bash strict mode best practices
