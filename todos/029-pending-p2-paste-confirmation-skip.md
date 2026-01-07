---
status: completed
priority: p2
issue_id: "029"
tags: [code-review, agent-native, automation]
dependencies: []
completed_date: "2026-01-07"
---

# Agent-Native: Add --yes Flag to Skip Confirmation Prompts

## Problem Statement

`agent-manage paste` requires interactive confirmation for multi-line content, which blocks non-interactive automation and agent usage.

**Current behavior:**
```bash
agent-manage paste 0
# About to paste 5 lines to pane 0
# First line: echo "hello world"...
# Continue? [y/N]:  ← Agent cannot respond
```

## Findings

**Location:** `bin/agent-manage:427-436`

**Blocking code:**
```bash
# Confirm before pasting multi-line content
if [ "$line_count" -gt 1 ]; then
    echo -e "${YELLOW}About to paste $line_count lines to pane $pane_idx${NC}"
    echo -e "${YELLOW}First line: $(echo "$content" | head -1 | cut -c1-60)...${NC}"
    read -p "Continue? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Cancelled${NC}"
        return 0
    fi
fi
```

**Impact:** Agents using `agent-manage paste` with multi-line content are blocked at the confirmation prompt.

## Proposed Solutions

### Option A: Add --yes/-y Flag (Recommended)
**Description:** Skip confirmation when `--yes` or `-y` flag is provided.

```bash
# Non-interactive usage for agents:
agent-manage paste 0 --yes
echo "multi\nline" | agent-manage paste WORK -y
```

**Implementation:**
```bash
cmd_paste() {
    ...
    local skip_confirm=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --yes|-y) skip_confirm=true; shift ;;
            *) target="$1"; shift ;;
        esac
    done
    ...
    # Modified confirmation
    if [ "$line_count" -gt 1 ] && [ "$skip_confirm" = false ]; then
        echo -e "${YELLOW}About to paste $line_count lines..."
        read -p "Continue? [y/N]: " confirm
        [[ ! "$confirm" =~ ^[Yy]$ ]] && return 0
    fi
    ...
}
```

**Pros:**
- Explicit opt-in for skip
- Safe default (still confirms)
- Standard pattern (matches rm -f, apt -y, etc.)

**Cons:**
- Agents must remember to add flag

**Effort:** Small (15 minutes)
**Risk:** Low

### Option B: Auto-detect Non-Interactive Mode
**Description:** Skip confirmation if not running in terminal.

```bash
if [ "$line_count" -gt 1 ] && [ -t 0 ]; then
    # Only prompt if stdin is a terminal
    read -p "Continue? [y/N]: " confirm
    ...
fi
```

**Pros:**
- Automatic for piped usage
- No flag needed

**Cons:**
- Less explicit
- May skip confirmation unexpectedly

**Effort:** Small
**Risk:** Medium

## Recommended Action

**Option A** - Add explicit `--yes/-y` flag. This is the standard pattern and makes intent clear.

## Technical Details

**File:** `bin/agent-manage`
**Function:** `cmd_paste()` (lines 357-443)
**Also update:** Command router and help text

**Help text addition:**
```
paste, p [n|name] [--yes]   Paste clipboard content to pane
                            --yes, -y: Skip confirmation for multi-line
```

## Acceptance Criteria

- [x] `agent-manage paste 0 --yes` works without prompt
- [x] `agent-manage paste 0 -y` works without prompt
- [x] `agent-manage paste 0` still prompts for multi-line
- [x] Help text documents the --yes flag
- [x] Works correctly with stdin (todo 028)

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-07 | Created from agent-native review | Interactive prompts block automation |
| 2026-01-07 | Implemented --yes/-y flag with skip_confirm variable | Implemented alongside stdin support |

## Resources

- Agent-Native reviewer analysis
- Related to todo 028 (stdin support)
