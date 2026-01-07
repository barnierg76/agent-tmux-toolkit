---
status: complete
priority: p3
issue_id: "014"
tags: [code-review, portability, cross-platform]
dependencies: []
---

# macOS-Only `open` Command in snippet-edit

## Problem Statement

The snippet-edit fallback uses `open` command which is macOS-specific, making the script fail silently on Linux.

**Why it matters:** The toolkit documents support for Linux but this fallback breaks cross-platform compatibility.

## Findings

**Location:** `bin/snippet-edit:14-16`

```bash
elif command -v nano &> /dev/null; then
    nano "$SNIPPETS_FILE"
else
    open "$SNIPPETS_FILE"  # macOS only!
fi
```

On Linux: `open` command doesn't exist, script fails with "command not found".

## Proposed Solutions

### Option A: Platform-Aware Fallback (Recommended)
**Description:** Use `xdg-open` on Linux, `open` on macOS.

```bash
else
    if [[ "$(uname)" == "Darwin" ]]; then
        open "$SNIPPETS_FILE"
    elif command -v xdg-open &> /dev/null; then
        xdg-open "$SNIPPETS_FILE"
    else
        echo "No editor found. Set EDITOR environment variable."
        echo "File location: $SNIPPETS_FILE"
        exit 1
    fi
fi
```

**Pros:**
- Works on both platforms
- Graceful error message

**Cons:**
- More code

**Effort:** Small
**Risk:** Low

## Recommended Action

**Option A** - Add platform-aware fallback with error message.

## Technical Details

**Affected file:** `bin/snippet-edit`

**Lines to change:** 14-16

## Acceptance Criteria

- [ ] Uses `open` on macOS
- [ ] Uses `xdg-open` on Linux
- [ ] Clear error message if no editor found
- [ ] Prints file location for manual editing

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-04 | Created finding from pattern review | Always check platform assumptions |

## Resources

- Pattern Recognition Specialist analysis
