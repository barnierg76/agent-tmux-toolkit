---
status: pending
priority: p2
issue_id: "023"
tags: [code-review, performance, optimization]
dependencies: []
---

# Optimize snippet-picker Performance

## Problem Statement

snippet-picker has suboptimal performance patterns that add ~40-80ms to startup:
- 3 separate tmux calls for pane detection (~15ms)
- Subshell spawning in loops (~40ms for 20 snippets)
- Multiple grep passes for folder filtering (~30ms)

For an interactive tool, every millisecond matters for perceived responsiveness.

## Findings

### Current Performance
- Total startup: ~120-200ms
- Pane detection: ~15-20ms (3 tmux calls)
- Snippet formatting: ~80ms (subshells in loop)
- Folder filtering: ~50ms (multiple grep passes)

### Inefficient Patterns

**Lines 12-24**: Three separate tmux calls
```bash
TARGET_PANE=$(tmux display-message -p '#{pane_id}')
local role=$(tmux display-message -p '#{@role}')
local title=$(tmux display-message -p '#{pane_title}')
```

**Lines 126-130**: Subshells in loop
```bash
while IFS=$'\t' read -r path content; do
    folder=$(echo "$path" | cut -d'/' -f1)  # Subshell
    label=$(echo "$path" | cut -d'/' -f2-)   # Subshell
done
```

**Lines 215-241**: Multiple passes through folder list
```bash
while ...; do grep -qE ...; done  # Pass 1
while ...; do grep -qE ...; done  # Pass 2
```

## Proposed Solutions

### Option A: Single tmux Call + Awk Processing (Recommended)
Consolidate tmux calls and use awk for all text processing.

**Implementation:**
```bash
# Single tmux call
read -r TARGET_PANE ROLE TITLE <<< "$(tmux display-message -p '#{pane_id}|#{@role}|#{pane_title}' | tr '|' ' ')"

# Awk-based formatting (no subshells)
format_direct_snippets() {
    echo "$PARSED_SNIPPETS" | awk -F'\t' -v pattern="$1" '
        $1 ~ pattern {
            n = split($1, parts, "/")
            folder = parts[1]
            label = substr($1, length(folder) + 2)
            printf "[%s] %s\t%s\t%s\n", folder, label, $1, $2
        }
    '
}
```

**Pros:**
- ~60% faster (120ms → 80ms)
- Cleaner code
- Fewer processes spawned

**Cons:**
- Awk syntax less readable for some

**Effort:** Low (1-2 hours)
**Risk:** Low

### Option B: Lazy Loading
Only parse snippets when needed, cache results.

**Pros:**
- Faster for quick exits
- Scales better with many snippets

**Cons:**
- More complex code
- Cache invalidation issues

**Effort:** Medium (2-3 hours)
**Risk:** Medium

## Recommended Action

Option A - Replace subshells with awk, consolidate tmux calls.

## Technical Details

### Changes Required

**Line 12-24**: Consolidate to single tmux call
```bash
# Before: 3 calls
TARGET_PANE=$(tmux display-message -p '#{pane_id}')
# ... two more calls

# After: 1 call
IFS='|' read -r TARGET_PANE ROLE TITLE <<< "$(tmux display-message -p '#{pane_id}|#{@role}|#{pane_title}')"
```

**Lines 126-130**: Use awk instead of loop
```bash
# Before: Loop with subshells
while read ...; do
    folder=$(echo "$path" | cut -d'/' -f1)
done

# After: Single awk pass
echo "$data" | awk -F'\t' '{ ... }'
```

**Lines 215-241**: Single awk pass for folder sorting
```bash
# Before: Multiple while loops with grep
# After: Single awk classifying and sorting
```

## Acceptance Criteria

- [ ] Single tmux call for pane detection
- [ ] No subshells in format_direct_snippets loop
- [ ] Single pass for folder filtering
- [ ] Startup time reduced by ~40% (measured)

## Work Log

| Date | Action | Notes |
|------|--------|-------|
| 2026-01-05 | Created | From performance analysis |

## Resources

- Performance Analysis Report: Detailed timings
- Bash performance best practices
