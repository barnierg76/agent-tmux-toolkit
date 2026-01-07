---
status: completed
priority: p2
issue_id: "028"
tags: [code-review, agent-native, composability]
dependencies: []
completed_date: "2026-01-07"
---

# Agent-Native: Add stdin Support to agent-manage paste

## Problem Statement

`agent-manage paste` only reads from the system clipboard. Agents cannot pipe content directly to panes, requiring a two-step workflow through the clipboard.

**Current workflow:**
```bash
echo "content" | pbcopy                # Step 1: Write to clipboard
agent-manage paste 0                   # Step 2: Paste from clipboard
```

**Desired workflow:**
```bash
echo "content" | agent-manage paste 0  # Single step, direct pipe
```

## Findings

**Location:** `bin/agent-manage:357-443` (cmd_paste function)

**Current implementation:**
```bash
cmd_paste() {
    ...
    local content
    content=$(paste_from_clipboard 2>/dev/null)  # Only clipboard source

    if [ -z "$content" ]; then
        echo -e "${YELLOW}Clipboard is empty${NC}"
        return 0
    fi
    ...
}
```

**Missing:** Check for stdin before clipboard

## Proposed Solutions

### Option A: Check stdin First (Recommended)
**Description:** If stdin is not a terminal, read from stdin instead of clipboard.

```bash
cmd_paste() {
    ...
    local content

    # Check stdin first (for piped content)
    if [ ! -t 0 ]; then
        content=$(cat)
    else
        content=$(paste_from_clipboard 2>/dev/null)
    fi

    if [ -z "$content" ]; then
        echo -e "${YELLOW}No content to paste (stdin empty and clipboard empty)${NC}"
        return 0
    fi
    ...
}
```

**Pros:**
- Enables pipeline composition
- Backwards compatible (clipboard still works when no stdin)
- Standard Unix pattern
- Better for agents

**Cons:**
- Slight behavior change (stdin takes priority)

**Effort:** Small (15 minutes)
**Risk:** Low

### Option B: Add --stdin Flag
**Description:** Explicit flag to read from stdin.

```bash
agent-manage paste 0 --stdin < content.txt
```

**Pros:**
- Explicit intent
- No ambiguity

**Cons:**
- More verbose for common case
- Less composable

**Effort:** Small
**Risk:** Low

## Recommended Action

**Option A** - Check stdin first. This is the standard Unix pattern and enables natural pipeline composition without breaking existing clipboard usage.

## Technical Details

**File:** `bin/agent-manage`
**Function:** `cmd_paste()` (lines 357-443)
**Change location:** After argument parsing, before clipboard read

**Test cases:**
```bash
# These should all work:
agent-manage paste 0                        # From clipboard
echo "hello" | agent-manage paste 0         # From stdin
cat file.txt | agent-manage paste WORK      # From file via stdin
agent-manage paste 0 < file.txt             # Redirect
```

## Acceptance Criteria

- [x] `echo "test" | agent-manage paste 0` works
- [x] `agent-manage paste 0` still reads from clipboard
- [x] stdin takes priority over clipboard
- [x] Empty stdin falls back to clipboard
- [x] Help text documents stdin support

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-07 | Created from agent-native review | Unix tools should accept stdin for composability |
| 2026-01-07 | Implemented stdin check using [ ! -t 0 ] | Reads from pipe if available, else clipboard |

## Resources

- Agent-Native reviewer analysis
- Unix pipeline philosophy
