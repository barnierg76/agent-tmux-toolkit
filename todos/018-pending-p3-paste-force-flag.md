---
status: pending
priority: p3
issue_id: "018"
tags: [code-review, agent-native, ux]
dependencies: []
---

# Add --force Flag to Paste Command

## Problem Statement

The paste command has a confirmation prompt for multi-line content that blocks agents from using it programmatically.

**Why it matters:** Agents cannot paste multi-line content without human interaction, breaking agent-native architecture principles.

## Findings

**Location:** `bin/agent-manage:615-624`

```bash
if [ "$line_count" -gt 1 ]; then
    echo -e "${YELLOW}About to paste $line_count lines to pane $pane_idx${NC}"
    echo -e "${YELLOW}First line: $(echo "$content" | head -1 | cut -c1-60)...${NC}"
    read -p "Continue? [y/N]: " confirm </dev/tty
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Cancelled${NC}"
        return 0
    fi
fi
```

**Impact:** Agents hang waiting for confirmation they cannot provide.

## Proposed Solutions

### Option A: Add --force Flag (Recommended)
**Description:** Skip confirmation when --force or --yes is provided

```bash
# At start of cmd_paste()
local force=false
[[ "$1" == "--force" || "$1" == "--yes" ]] && { force=true; shift; }

# Later in function
if [ "$line_count" -gt 1 ] && [ "$force" != true ]; then
    # Show confirmation
fi
```

**Pros:**
- Maintains safety for interactive use
- Enables programmatic access

**Cons:**
- Slightly more complex argument parsing

**Effort:** Small
**Risk:** Low

## Recommended Action

**Option A** - Add --force flag.

## Technical Details

**File:** `bin/agent-manage`
**Function:** `cmd_paste()`
**Lines:** 545-631

## Acceptance Criteria

- [ ] `agent-manage paste 0 --force` works without confirmation
- [ ] Interactive paste still prompts for multi-line content
- [ ] --yes also works as alias

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-04 | Created from agent-native review | All commands need non-interactive mode |

## Resources

- Agent-Native Reviewer analysis
