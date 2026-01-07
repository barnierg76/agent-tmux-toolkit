---
status: complete
priority: p1
issue_id: "019"
tags: [code-review, architecture, refactoring, duplication]
dependencies: []
---

# Extract Shared Library Functions

## Problem Statement

The codebase has ~200 lines of duplicated utility code spread across 9+ scripts:
- `get_session_name()` duplicated in 3 files (agent-flow, agent-handoff, agent-flow-state)
- Color variable definitions duplicated in 8 files
- Clipboard functions duplicated in 2 files (agent-manage, agent-handoff)
- `validate_name()` duplicated in 2 files
- Pane resolution logic duplicated in 3 files

This violates DRY principle and creates maintenance burden - bugs need fixing in multiple places.

## Findings

### Pattern Recognition Analysis
- **agent-flow:14-23**: `get_session_name()` function
- **agent-handoff:14-23**: Identical `get_session_name()` function
- **agent-flow-state:10-18**: Identical `get_session_name()` function
- **8 files with color definitions**: RED, GREEN, YELLOW, BLUE, CYAN, DIM, NC

### Clipboard Duplication
- **agent-manage:28-66**: Full clipboard implementation (86 lines)
- **agent-handoff:28-47**: Partial clipboard implementation (20 lines)

### Architecture Impact
Creating a shared library would:
- Reduce total codebase by ~200 lines (7% reduction)
- Single source of truth for common operations
- Easier testing and maintenance

## Proposed Solutions

### Option A: Single Common Library (Recommended)
Create `bin/agent-common.sh` with all shared functions.

**Pros:**
- Single file to maintain
- Easy to source from all scripts
- Consistent behavior guaranteed

**Cons:**
- All scripts depend on one file
- Slightly slower startup (sourcing overhead ~5ms)

**Effort:** Medium (2-3 hours)
**Risk:** Low

### Option B: Multiple Focused Libraries
Create separate library files:
- `lib/colors.sh`
- `lib/clipboard.sh`
- `lib/session.sh`
- `lib/panes.sh`

**Pros:**
- Scripts only load what they need
- Better separation of concerns

**Cons:**
- More files to manage
- Complex dependency tracking

**Effort:** Medium-High (3-4 hours)
**Risk:** Low

### Option C: Inline with Comments
Keep duplication but document it clearly with comments pointing to canonical source.

**Pros:**
- No structural changes
- Scripts remain self-contained

**Cons:**
- Still have duplication
- Drift will occur over time

**Effort:** Low (30 min)
**Risk:** Medium (drift)

## Recommended Action

Option A - Create single `bin/agent-common.sh` library containing:
```bash
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
# ... etc

# Session utilities
get_session_name() { ... }
validate_name() { ... }

# Clipboard utilities
copy_to_clipboard() { ... }
paste_from_clipboard() { ... }

# Pane utilities
get_pane_by_role() { ... }
resolve_pane() { ... }
```

## Technical Details

### Affected Files
- bin/agent-flow
- bin/agent-flow-state
- bin/agent-handoff
- bin/agent-manage
- bin/agent-session
- bin/agent-status
- bin/agent-delegate
- bin/agent-worktree
- bin/snippet-picker

### Implementation Steps
1. Create `bin/agent-common.sh` with extracted functions
2. Update each script to `source` the common library
3. Remove duplicated code from each script
4. Test all scripts still work correctly
5. Update install.sh to include the library

## Acceptance Criteria

- [ ] `bin/agent-common.sh` exists with all shared functions
- [ ] All 9 affected scripts source the common library
- [ ] No duplicated utility functions remain
- [ ] All scripts pass manual testing
- [ ] Total LOC reduced by ~150-200 lines

## Work Log

| Date | Action | Notes |
|------|--------|-------|
| 2026-01-05 | Created | From comprehensive code review |

## Resources

- Pattern Recognition Report: Identified all duplications
- Architecture Analysis: Recommended shared library approach
