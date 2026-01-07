---
status: pending
priority: p2
issue_id: "021"
tags: [code-review, ux, simplification]
dependencies: []
---

# Simplify snippet-picker Navigation

## Problem Statement

The snippet-picker has confusing "direct mode" behavior:
- Sometimes shows folders, sometimes shows snippets directly
- "Browse All Folders" appears mixed with snippets
- Navigation is unpredictable
- ~107 lines of complex code for a feature that saves 1 keystroke

User feedback: "some things can be more intuitive or better"

## Findings

### Current Complexity
- **Lines 143-197**: Direct mode logic (55 lines)
- **Lines 200-241**: Folder building with "Suggested" vs "All" (42 lines)
- **Lines 204-238**: Three separate loops through folder list

### UX Problems
1. First-time users don't know what to expect
2. "Browse All Folders" appears as a snippet option (confusing)
3. `<-` behavior differs between modes
4. Context detection can fail silently

### Code Simplicity Analysis
Direct mode adds 107 lines to save 1 keystroke (pressing Enter on folder).

## Proposed Solutions

### Option A: Always Folders First, Relevance Sorted (Recommended)
Remove direct mode. Always show folders, but sort by relevance:
1. Matching folders for current pane at top
2. EVERY folders next
3. Other folders last

**Implementation:**
```bash
# Single folder list, relevance sorted
folder_list=$(echo "$all_folders" | awk -v filter="$PANE_FILTER" '
    $0 ~ filter { print "1" $0 }
    $0 !~ filter { print "2" $0 }
' | sort | cut -c2-)
```

**Pros:**
- Predictable behavior always
- Removes 107 lines of code
- Still context-aware (just sorted, not hidden)

**Cons:**
- One extra keystroke to select folder

**Effort:** Low (1 hour)
**Risk:** Low

### Option B: Keep Direct Mode, Fix UX
Keep direct mode but make it clearer:
- Show header explaining mode
- Separate "Browse All" visually
- Consistent `<-` behavior

**Pros:**
- Preserves keystroke savings
- Minimal code changes

**Cons:**
- Still complex
- Doesn't address root issue

**Effort:** Medium (2 hours)
**Risk:** Low

### Option C: Flat List with Folder Prefixes
Show all snippets in one flat list with folder prefixes visible.

**Pros:**
- Single selection step
- Very fast for power users

**Cons:**
- Long list for many snippets
- Loses folder organization benefit

**Effort:** Low (1 hour)
**Risk:** Medium (might be worse)

## Recommended Action

Option A - Remove direct mode, always show folders first but sorted by relevance. This gives:
- Predictable, intuitive UX
- Context awareness via sorting
- 107 fewer lines of code

## Technical Details

### Lines to Remove
- Lines 143-197 (direct mode logic)
- Lines 204-241 (complex folder building)

### Lines to Add
Simple folder sorting (10-15 lines)

### Net Change
~90 lines removed

## Acceptance Criteria

- [ ] Snippet picker always shows folders first
- [ ] Relevant folders appear at top based on pane context
- [ ] `<-` always goes back one level or exits
- [ ] No "Browse All Folders" mixed with snippets
- [ ] ~90 lines of code removed

## Work Log

| Date | Action | Notes |
|------|--------|-------|
| 2026-01-05 | Created | From simplicity review |

## Resources

- Code Simplicity Review: Full analysis
- User feedback: "more intuitive"
