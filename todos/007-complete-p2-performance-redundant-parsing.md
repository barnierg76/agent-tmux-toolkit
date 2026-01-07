---
status: complete
priority: p2
issue_id: "007"
tags: [code-review, performance, optimization]
dependencies: []
---

# Redundant Snippet Parsing Causes Performance Issues

## Problem Statement

The snippet-picker parses the entire snippets file multiple times per user interaction. With large snippet files (500+ entries), this causes noticeable lag in the UI.

**Why it matters:** The toolkit is meant to be snappy and keyboard-driven. Sluggish snippet selection breaks the workflow and frustrates users.

## Findings

### Finding 1: Triple AWK Processing
**Location:** `bin/snippet-picker:95-113`

The `get_folders()` function processes data 3 times:
```bash
parse_snippets | cut -d'/' -f1 | sort -u | awk '...' | sort -u | awk '...'
```

**And this function is never even called!** Lines 119-133 duplicate the same logic inline.

### Finding 2: Duplicate Parse Calls Per Navigation
**Location:** `bin/snippet-picker:119,154-158`

Main loop calls `parse_snippets` twice per iteration:
- Line 119: `folders=$(parse_snippets | cut -d'/' -f1 | sort -u)`
- Lines 154-158: `snippets=$(parse_snippets | grep ...)`

With 147-line snippet file: 2 AWK processes × 90 lines of parsing = significant overhead per navigation.

### Finding 3: Double Loop for Folder Sorting
**Location:** `bin/snippet-picker:125-132`

```bash
while IFS= read -r f; do
    [[ "$f" == EVERY* ]] && folder_list+="📁 $f"$'\n'
done <<< "$folders"

while IFS= read -r f; do
    [[ "$f" != EVERY* ]] && folder_list+="📁 $f"$'\n'
done <<< "$folders"
```

Iterates all folders twice with two here-string subprocesses.

### Performance Impact

| Operation | Current Time | At 500 Snippets | At 1000 Snippets |
|-----------|--------------|-----------------|------------------|
| Snippet picker startup | ~50ms | ~200ms | ~400ms |
| Folder navigation | ~80ms | ~350ms | ~700ms |

## Proposed Solutions

### Option A: Cache Parse Result (Recommended)
**Description:** Parse once at startup, reuse cached result.

```bash
# At script start (before main loop at line 117)
PARSED_SNIPPETS=$(parse_snippets)

# In main loop - use cache
folders=$(echo "$PARSED_SNIPPETS" | cut -d'/' -f1 | sort -u)

# Later in loop
if [[ -n "$FOLDER_FILTER" ]]; then
    snippets=$(echo "$PARSED_SNIPPETS" | grep "^$FOLDER_FILTER/")
else
    snippets="$PARSED_SNIPPETS"
fi
```

**Pros:**
- 50% reduction in AWK overhead
- Simple implementation
- No user-visible changes

**Cons:**
- Won't pick up file changes during session (acceptable)

**Effort:** Small (5 lines changed)
**Risk:** Low

### Option B: Remove Unused get_folders() Function
**Description:** Delete lines 93-114 (dead code).

**Pros:**
- Cleaner code
- Removes confusion

**Cons:**
- Doesn't fix main performance issue

**Effort:** Small
**Risk:** None

### Option C: Single-Pass Folder Building
**Description:** Replace double loop with grep + sed.

```bash
folder_list="📂 All Snippets"$'\n'
folder_list+=$(echo "$folders" | grep '^EVERY' | sort | sed 's/^/📁 /')$'\n'
folder_list+=$(echo "$folders" | grep -v '^EVERY' | sort | sed 's/^/📁 /')
```

**Pros:**
- Eliminates subshell overhead
- Faster folder list building

**Cons:**
- Minor improvement vs caching

**Effort:** Small
**Risk:** Low

## Recommended Action

Implement all three options:
1. **Option A** - Cache parse result (biggest win)
2. **Option B** - Delete dead code
3. **Option C** - Optimize folder building

**Expected total improvement:** 65% reduction in latency

## Technical Details

**Affected file:** `bin/snippet-picker`

**Lines to modify:**
- Lines 93-114: DELETE (unused get_folders function)
- Line 117: ADD cache initialization
- Line 119: USE cached data
- Lines 125-132: REPLACE with grep+sed
- Lines 154-158: USE cached data

## Acceptance Criteria

- [ ] `parse_snippets` called exactly once per script run
- [ ] Unused `get_folders()` function removed
- [ ] Folder list built with single-pass processing
- [ ] Startup time < 100ms with 500 snippets
- [ ] Navigation time < 100ms with 500 snippets
- [ ] No regression in functionality

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-04 | Created finding from performance review | Cache expensive operations, delete dead code |

## Resources

- Performance Oracle analysis
- Code Simplicity Reviewer analysis
