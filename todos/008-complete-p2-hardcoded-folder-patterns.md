---
status: complete
priority: p2
issue_id: "008"
tags: [code-review, maintainability, extensibility]
dependencies: ["007"]
---

# Hardcoded Folder Patterns in AWK Parser

## Problem Statement

The snippet parser has 12+ hardcoded folder patterns. Adding a new folder category requires code changes instead of just editing the snippets file.

**Why it matters:** Users should be able to add custom folder categories by simply using the `# ═══ FOLDERNAME ═══` header syntax. The current implementation defeats this flexibility.

## Findings

**Location:** `bin/snippet-picker:31-49`

```awk
/^# .* PLAN / { folder="PLAN"; next }
/^# .* WORK / { folder="WORK"; next }
/^# .* REVIEW / { folder="REVIEW"; next }
/^# .* HANDOFF / { folder="HANDOFF"; next }
/^# .* QUICK / { folder="QUICK"; next }
/^# .* EVERY WORKFLOWS / { folder="EVERY WORKFLOWS"; next }
/^# .* EVERY PLANNING / { folder="EVERY PLANNING"; next }
/^# .* EVERY TESTING / { folder="EVERY TESTING"; next }
/^# .* EVERY RESOLVE / { folder="EVERY RESOLVE"; next }
/^# .* EVERY BUGS / { folder="EVERY BUGS"; next }
/^# .* EVERY SKILLS / { folder="EVERY SKILLS"; next }
/^# .* EVERY DOCS / { folder="EVERY DOCS"; next }
/^# .* EVERY / { ... }  # Catch-all for EVERY
```

**Problems:**
1. Each line in snippet file tested against 12+ patterns
2. New folders require code changes
3. Pattern order matters (catch-all must be last)
4. Maintenance burden increases with each folder

## Proposed Solutions

### Option A: Generic Header Detection (Recommended)
**Description:** Single regex pattern that extracts folder name from any header.

```awk
BEGIN { folder="General"; label=""; content="" }

# Match any folder header: # ═══ FOLDERNAME ═══
/^# ═══.*═══/ {
    # Extract text between ═══ markers
    folder = $0
    sub(/^# ═══ /, "", folder)
    sub(/ ═══.*$/, "", folder)
    next
}

# Skip other comments
/^#/ { next }

# Rest of parsing logic unchanged...
```

**Pros:**
- Zero code changes for new folders
- Simpler, faster pattern matching (1 regex vs 12+)
- User can create any folder name
- More maintainable

**Cons:**
- Requires consistent `═══` header format
- Existing snippets already use this format (no migration needed)

**Effort:** Small
**Risk:** Low

### Option B: Configuration File for Folders
**Description:** External config defining folder patterns.

**Pros:**
- Maximum flexibility

**Cons:**
- Over-engineering for this use case
- Additional file to manage

**Effort:** Medium
**Risk:** Low

## Recommended Action

**Option A** - Generic header detection. Simple, effective, and the snippets file already uses the required format.

## Technical Details

**Affected file:** `bin/snippet-picker`

**Lines to replace:** 31-49 (19 lines) → 6 lines

**Before (19 lines):**
```awk
/^# .* PLAN / { folder="PLAN"; next }
/^# .* WORK / { folder="WORK"; next }
# ... 10 more patterns ...
```

**After (6 lines):**
```awk
# Match folder headers: # ═══ FOLDERNAME ═══
/^# ═══.*═══/ {
    folder = $0
    sub(/^# ═══ /, "", folder)
    sub(/ ═══.*$/, "", folder)
    next
}
```

**Test cases:**
- `# ═══ PLAN ═══` → folder="PLAN"
- `# ═══ EVERY WORKFLOWS ═══` → folder="EVERY WORKFLOWS"
- `# ═══ MY CUSTOM FOLDER ═══` → folder="MY CUSTOM FOLDER"

## Acceptance Criteria

- [ ] Single generic pattern replaces all hardcoded patterns
- [ ] Existing folders (PLAN, WORK, REVIEW, etc.) still work
- [ ] EVERY folders still work
- [ ] Users can add custom folders without code changes
- [ ] Performance improved (fewer regex operations)
- [ ] Add example of custom folder to README

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-04 | Created finding from architecture/simplicity review | Generic patterns beat hardcoded lists |

## Resources

- Architecture Strategist analysis
- Code Simplicity Reviewer analysis
