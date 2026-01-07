# Agent-Tmux-Toolkit Repository Patterns Research

## Overview

This document provides comprehensive analysis of the agent-tmux-toolkit codebase, with specific file:line references for patterns relevant to implementing tmux command batching fixes.

---

## 1. Agent-Common.sh Structure and Usage

**File:** `/Users/iamstudios/Desktop/agent-tmux-toolkit/bin/agent-common.sh`

### Purpose
Shared utility library sourced by all scripts to provide common functions and prevent duplication.

### Loading Pattern
```bash
# Line 3-7: Guard against double-sourcing
source "$(dirname "$0")/agent-common.sh"

[[ -n "$_AGENT_COMMON_LOADED" ]] && return 0
_AGENT_COMMON_LOADED=1
```

**Usage Example:** Every script includes this pattern:
- `agent-session` (line 7)
- `agent-manage` (line 8)
- `agent-flow` (line 7)
- `snippet-picker` (line 8)
- `agent-handoff` (line 7)
- `demo-setup.sh` (line 7)

### Key Functions in agent-common.sh

| Function | Lines | Purpose |
|----------|-------|---------|
| `validate_name` | 28-36 | Validates alphanumeric, dash, underscore naming |
| `get_session_name` | 44-63 | Gets session name from env or tmux, with injection prevention |
| `copy_to_clipboard` | 70-88 | Cross-platform clipboard (macOS, Linux, Wayland, Windows) |
| `paste_from_clipboard` | 91-107 | Cross-platform paste |
| `get_clipboard_content` | 110-129 | Gets clipboard with empty check |
| `get_pane_by_role` | 138-167 | Finds pane by @role, title, or index (PLAN/WORK/REVIEW) |
| `resolve_pane` | 171-205 | Resolves pane by index, name, or role |
| `check_fzf` | 212-218 | Validates fzf availability with helpful message |
| `strip_ansi` | 225-227 | Removes ANSI escape codes |
| `show_session_picker` | 237-270 | Interactive fzf session selection with back navigation |
| `show_pane_picker` | 276-310 | Interactive fzf pane selection with back navigation |

### Color Definitions (Lines 10-20)
```bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'  # No Color
```

### Security Patterns (Lines 44-63)
The `get_session_name` function demonstrates the security pattern used throughout:
- Environment variable check first
- Fallback to tmux detection
- Safe default ("agents")
- Validation before returning to prevent injection attacks

**Example validation regex:** `^[a-zA-Z0-9_-]+$`

---

## 2. Tmux Command Batching Patterns

### Session Creation Pattern

**File:** `agent-session` (lines 90-101)

```bash
# Create new session with first pane (Plan) - Line 91
tmux new-session -d -s "$SESSION_NAME" -n "agents" -c "$PROJECT_PATH"

# Split horizontally for Work pane (middle) - Line 94
tmux split-window -h -t "$SESSION_NAME:agents" -c "$PROJECT_PATH"

# Split horizontally again for Review pane (right) - Line 97
tmux split-window -h -t "$SESSION_NAME:agents" -c "$PROJECT_PATH"

# Even out the three panes (33% each) - Line 100
tmux select-layout -t "$SESSION_NAME:agents" even-horizontal

# Get actual pane IDs (for setting options) - Line 103
PANE_IDS=($(tmux list-panes -t "$SESSION_NAME:agents" -F "#{pane_id}"))

# Set role for each pane - Lines 107-109
tmux set-option -p -t "${PANE_IDS[0]}" @role "PLAN"
tmux set-option -p -t "${PANE_IDS[1]}" @role "WORK"
tmux set-option -p -t "${PANE_IDS[2]}" @role "REVIEW"
```

**Key Insight:** Commands are NOT batched - each tmux operation is separate. Session/pane IDs are resolved between commands.

### Send-Keys Patterns

#### Pattern 1: Simple Command with Enter (demo-setup.sh, line 48)
```bash
tmux send-keys -t "$pane_id" "clear" Enter
```

**When to use:** Single command that needs execution

#### Pattern 2: Literal Multi-line String with -l flag (demo-setup.sh, line 51)
```bash
tmux send-keys -t "$pane_id" -l 'printf "%s\n" "$ claude" "" "> Planning..." "" "## Tasks" "" "- [x] Done" "" "Ready"'
tmux send-keys -t "$pane_id" Enter
```

**When to use:** Complex multi-line content that should NOT interpret special shell characters

**Key Details:**
- `-l` flag = literal string mode (doesn't interpret `Enter`, variables, etc.)
- Must send `Enter` separately if you want command execution
- Allows safe embedding of quotes, variables, newlines

#### Pattern 3: Pane-aware Literal Text (snippet-picker, line 170)
```bash
tmux send-keys -t "$TARGET_PANE" "$text"
```

**When to use:** Sending simple text without Enter

#### Pattern 4: Send Command with -l and Optional Enter (agent-flow, line 60)
```bash
send_to_pane() {
    local role="$1"
    shift
    local pane_id=$(get_pane_by_role "$role" "$SESSION_NAME")

    if [[ -n "$pane_id" ]]; then
        tmux send-keys -t "$pane_id" -l "$*"  # NOTE: No Enter
    else
        echo -e "${YELLOW}Warning: Could not find $role pane${NC}"
    fi
}

# Usage (agent-flow, line 74):
send_to_pane "PLAN" "/compound-engineering:workflows:plan "  # Space at end, no Enter
```

**When to use:** Commands that should NOT auto-execute (user adds completion)

#### Pattern 5: Direct Command with Enter (agent-flow, line 121)
```bash
tmux send-keys "/compound-engineering:workflows:compound "  # Note: No -t flag, goes to current pane
```

**When to use:** Current pane only (no explicit pane target)

### Command Batching Analysis

**Current Approach (NOT batched):**
1. Each tmux command is separate
2. Session/pane IDs resolved between commands
3. No explicit command buffering/batching

**Why Not Batched:**
- Tmux doesn't support command batching natively
- Each command must complete before next (proper ordering)
- Variable expansion happens in shell, not tmux

**Relevant for Fix:** The fix should follow this pattern - send multiple commands sequentially, not batched.

---

## 3. Error Handling Patterns (set -e, set -o pipefail)

### Files Using set -e
```bash
demo-setup.sh:                    Line 4: set -e
```

### Files Using set -euo pipefail
```bash
fix-stale-todos.sh:              Line (from grep output)
triage-issues.sh:                Line (from grep output)
```

**Pattern Analysis:**
- Most scripts do NOT use `set -e` (agent-session, agent-manage, agent-flow, etc.)
- Only older/admin scripts (fix-stale-todos, triage-issues) use strict error handling
- Scripts that use `set -e` are simpler (demo-setup.sh)

**Implications for Fix:**
- Current codebase pattern: liberal error handling, explicit error checks
- New code should follow local patterns (explicit checks rather than set -e)
- Example from agent-manage (line 54-60):
  ```bash
  check_session() {
      if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
          echo -e "${RED}Error: Session '$SESSION_NAME' not found.${NC}"
          echo "Start with: agent-session"
          exit 1
      fi
  }
  ```

---

## 4. Flag/Argument Parsing Patterns

### agent-session Pattern (lines 31-69)
```bash
# Define variables for parsed arguments
SESSION_NAME=""
PROJECT_PATH=""
TASK_ID=""

# While loop with case statement
while [[ $# -gt 0 ]]; do
    case $1 in
        --task|-t)
            TASK_ID="$2"
            shift 2  # Consume both argument and value
            ;;
        --name|-n)
            SESSION_NAME="$2"
            shift 2
            ;;
        --path|-p)
            PROJECT_PATH="$2"
            shift 2
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        -*)
            echo -e "${RED}Unknown option: $1${NC}"
            show_usage
            exit 1
            ;;
        *)
            # Positional arguments (backward compatible)
            if [ -z "$SESSION_NAME" ]; then
                SESSION_NAME="$1"
            elif [ -z "$PROJECT_PATH" ]; then
                PROJECT_PATH="$1"
            fi
            shift
            ;;
    esac
done
```

**Key Pattern Elements:**
1. Pre-declare all variables
2. Use `while [[ $# -gt 0 ]]; do`
3. Use `case $1 in` for pattern matching
4. `shift 2` for flags with values, `shift` for positional
5. Handle unknown options explicitly
6. Support both long/short forms (`--task|-t`)
7. Maintain backward compatibility with positional args

### agent-manage Copy Command Pattern (lines 268-273)
```bash
# Parse arguments with mixed flag and positional handling
while [[ $# -gt 0 ]]; do
    case "$1" in
        --full|-f) full_history=true; shift ;;
        *) target="$1"; shift ;;
    esac
done
```

**Simpler variant:** For commands with flags and optional positional arguments

---

## 5. Function Extraction Pattern to Shared Library

### Example: validate_name Function

**In agent-common.sh (lines 28-36):**
```bash
# Validate name - alphanumeric, dash, underscore only
# Usage: validate_name "my-name" "session name"
validate_name() {
    local name="$1"
    local type="${2:-name}"
    if ! [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo -e "${RED}Error: Invalid $type. Use only alphanumeric, dash, underscore.${NC}" >&2
        return 1
    fi
    return 0
}
```

**Used in multiple places:**
- agent-session (line 79): `validate_name "$SESSION_NAME" "session name" || exit 1`
- agent-manage (line 516): `if ! validate_name "$session_name" "session name"`

### Extraction Pattern:

1. **Identify repeated code** across multiple scripts
2. **Extract to agent-common.sh** with clear documentation
3. **Include usage comment** with examples
4. **Document parameter types** (via comments, not type annotations)
5. **Return proper exit codes** (0 for success, 1 for error)
6. **Write to stderr** for error messages: `>&2`

### Template:
```bash
# Clear description of what function does
# Usage: function_name arg1 arg2
# Returns: stdout on success, stderr on error, exit code (0 or 1)
function_name() {
    local var1="$1"
    local var2="${2:-default}"

    # Validation
    if ! condition; then
        echo -e "${RED}Error message${NC}" >&2
        return 1
    fi

    # Implementation
    echo "success"
    return 0
}
```

### Known Shared Functions to Reference

**Pane Resolution:**
- `get_pane_by_role "PLAN" "$SESSION_NAME"` (agent-common.sh:138-167)
- `resolve_pane "1" "$SESSION_NAME"` (agent-common.sh:171-205)

**Session Management:**
- `get_session_name` (agent-common.sh:44-63)
- `check_session` (agent-manage:54-60) - NOT in common, local pattern

**Clipboard:**
- `copy_to_clipboard "$content"` (agent-common.sh:70-88)
- `paste_from_clipboard` (agent-common.sh:91-107)

**Interactive Selection:**
- `check_fzf` (agent-common.sh:212-218)
- `show_session_picker "prompt"` (agent-common.sh:237-270)
- `show_pane_picker "session" "prompt"` (agent-common.sh:276-310)

---

## 6. Pane Reference Patterns

### Pattern 1: Using Pane Index
```bash
tmux send-keys -t "$SESSION_NAME.$pane_idx" -l "$content"  # agent-manage:440
```

**Format:** `SESSION:WINDOW.PANE` where pane is numeric index

### Pattern 2: Using Pane ID
```bash
PANE_IDS=($(tmux list-panes -t "$SESSION_NAME:agents" -F "#{pane_id}"))
tmux send-keys -t "${PANE_IDS[0]}" "clear" Enter  # agent-session:103-107
```

**Format:** Just the pane ID from `#{pane_id}` format string

### Pattern 3: Current Pane
```bash
tmux send-keys "/compound-engineering:workflows:compound "  # agent-flow:121
```

**Format:** No `-t` argument = current pane only

### Getting Pane by Role

**From agent-common.sh (lines 138-167):**
```bash
get_pane_by_role() {
    local role="$1"
    local session="${2:-$(get_session_name)}"
    local pane_id

    # Try @role first
    pane_id=$(tmux list-panes -t "$session" -F "#{pane_id}|#{@role}" 2>/dev/null | \
        awk -F'|' -v role="$role" '$2 == role {print $1; exit}')

    if [[ -n "$pane_id" ]]; then
        echo "$pane_id"
        return 0
    fi

    # Fallback: try matching pane title
    pane_id=$(tmux list-panes -t "$session" -F "#{pane_id}|#{pane_title}" 2>/dev/null | \
        awk -F'|' -v role="$role" '$2 ~ "^"role {print $1; exit}')

    if [[ -n "$pane_id" ]]; then
        echo "$pane_id"
        return 0
    fi

    # Final fallback: use index
    case "$role" in
        PLAN)   tmux list-panes -t "$session:1" -F "#{pane_id}" 2>/dev/null | sed -n '1p' ;;
        WORK)   tmux list-panes -t "$session:1" -F "#{pane_id}" 2>/dev/null | sed -n '2p' ;;
        REVIEW) tmux list-panes -t "$session:1" -F "#{pane_id}" 2>/dev/null | sed -n '3p' ;;
    esac
}
```

**Priority:**
1. Custom @role attribute (set via `tmux set-option -p`)
2. Pane title matching
3. Fixed index fallback (1st/2nd/3rd pane)

---

## 7. Configuration and Environment

### Tmux Configuration (agent-tmux.conf)

**Key Settings:**
- Lines 1-8: Basic tmux config (mouse, history, pane indexing)
- Line 11-12: Show pane titles with role prefix
- Line 16-26: Vi mode copy/paste bindings
- Line 44-52: Meta+arrow key pane navigation
- Line 71-74: Meta+s/Space for snippet picker
- Line 78: Meta+m for agent-manage
- Line 114: Meta+f for agent-flow

**Important for Context:** The config doesn't handle Enter/key sending - all that happens in scripts via tmux send-keys.

### Environment Variables

**Used in Scripts:**
- `AGENT_SESSION`: Override default session name (used in agent-common.sh:47-48)
- `HOME`: For config file locations (snippet-picker:10)
- `PANE_ROLE`: Set from tmux display-message (snippet-picker:13)

---

## 8. Current Tmux Command Patterns in Use

### List Operations
```bash
# Get session name - agent-common.sh:49
tmux display-message -p '#{session_name}' 2>/dev/null

# List panes with format - agent-common.sh:144
tmux list-panes -t "$session" -F "#{pane_id}|#{@role}" 2>/dev/null

# Get pane info - snippet-picker:13
tmux display-message -p '#{pane_id}|#{@role}|#{pane_title}' 2>/dev/null
```

### Set Operations
```bash
# Set pane role - agent-session:107-109
tmux set-option -p -t "${PANE_IDS[0]}" @role "PLAN"

# Set pane title - agent-session:113
tmux select-pane -t "${PANE_IDS[0]}" -T "$TASK_ID"
```

### String Extraction with awk
```bash
# Extract first matching ID - agent-common.sh:145
awk -F'|' -v role="$role" '$2 == role {print $1; exit}'

# Extract pane index - agent-manage:76-77
awk -F: -v name="$target" '$2 == name {print $1; exit}'
```

### Error Handling Patterns
```bash
# Silent failure check - agent-common.sh:49
if name=$(tmux display-message -p '#{session_name}' 2>/dev/null) && [[ -n "$name" ]]; then

# Conditional execution - agent-manage:191
tmux kill-server 2>/dev/null && echo "Success" || echo "Failed"
```

---

## 9. Specific Code Examples for Implementation

### Example 1: Resolving Multiple Panes and Sending Commands

**From agent-flow (lines 67-81):**
```bash
cmd_start() {
    echo -e "${BLUE}Starting feature workflow...${NC}"

    # Focus PLAN pane
    focus_pane "PLAN"

    # Send the plan command (without Enter so user can add description)
    send_to_pane "PLAN" "/compound-engineering:workflows:plan "

    # Update state
    agent-flow-state set PLANNING 2>/dev/null || true

    echo -e "${GREEN}Switched to PLAN pane${NC}"
    echo -e "${CYAN}Enter your feature description and press Enter${NC}"
}
```

**How it works:**
1. `focus_pane` resolves role to pane_id and focuses
2. `send_to_pane` resolves role to pane_id and sends without Enter
3. User must complete command

### Example 2: Sending Multi-line Content

**From demo-setup.sh (lines 46-53):**
```bash
send_plan_content() {
    local pane_id="$1"
    tmux send-keys -t "$pane_id" "clear" Enter
    sleep 0.3
    # Use printf with echo for clean multi-line output
    tmux send-keys -t "$pane_id" -l 'printf "%s\n" "$ claude" "" "> Planning..." "## Tasks" "- [x] Done"'
    tmux send-keys -t "$pane_id" Enter
}
```

**Pattern:**
1. Clear pane first
2. Send multi-line content with -l flag (literal mode)
3. Send Enter separately to execute
4. Use sleep between operations for visual effect

### Example 3: Getting All Pane Info in One Query

**From snippet-picker (line 13):**
```bash
IFS='|' read -r TARGET_PANE PANE_ROLE PANE_TITLE <<< "$(tmux display-message -p '#{pane_id}|#{@role}|#{pane_title}' 2>/dev/null)"
```

**Pattern:**
1. Single tmux query with multiple format strings
2. Use IFS to split on delimiter
3. Store in multiple variables
4. More efficient than three separate commands

### Example 4: Array of Pane IDs

**From agent-session (line 103):**
```bash
PANE_IDS=($(tmux list-panes -t "$SESSION_NAME:agents" -F "#{pane_id}"))

# Then iterate or access by index
tmux set-option -p -t "${PANE_IDS[0]}" @role "PLAN"
tmux set-option -p -t "${PANE_IDS[1]}" @role "WORK"
tmux set-option -p -t "${PANE_IDS[2]}" @role "REVIEW"
```

**Pattern:**
1. Use command substitution in array declaration
2. Access via index ${PANE_IDS[0]}
3. Works great for fixed-size operations (3 panes)

---

## 10. Key Takeaways for Implementation

### DO:
- Use `-l` flag when sending literal strings with special characters
- Send `Enter` separately after `-l` commands if execution needed
- Resolve pane IDs between operations (don't batch)
- Use `2>/dev/null` to suppress tmux errors
- Check session/pane existence before operations
- Use `get_pane_by_role` for role-based lookups
- Return proper exit codes (0 success, 1 error)
- Write errors to stderr: `>&2`

### DON'T:
- Batch tmux commands (sequential is correct)
- Forget Enter when sending executable commands
- Use `set -e` (pattern is explicit error checking)
- Hardcode pane numbers (use roles instead)
- Ignore 2>/dev/null for optional tmux commands

### Reference Files to Study:
1. **agent-common.sh** - All utility functions, especially pane resolution
2. **agent-session** - Session/pane creation and setup
3. **demo-setup.sh** - Multi-line send-keys examples
4. **agent-manage** - Command argument parsing patterns
5. **agent-flow** - Pane-aware command sending
6. **snippet-picker** - Target pane detection and sending

---

## 11. Commands by Complexity

### Simple (1 operation):
```bash
tmux send-keys -t "$pane" "command" Enter
tmux select-pane -t "$pane" -T "title"
```

### Medium (2-3 operations):
```bash
tmux send-keys -t "$pane" "clear" Enter
sleep 0.3
tmux send-keys -t "$pane" -l "$content"
tmux send-keys -t "$pane" Enter
```

### Complex (resolve, then multi-step):
```bash
pane_id=$(get_pane_by_role "PLAN" "$SESSION_NAME")
if [[ -n "$pane_id" ]]; then
    tmux send-keys -t "$pane_id" -l "content"
    tmux send-keys -t "$pane_id" Enter
fi
```

---

## File Structure Summary

```
/Users/iamstudios/Desktop/agent-tmux-toolkit/
├── bin/
│   ├── agent-common.sh          (Shared utilities library)
│   ├── agent-session            (Create 3-pane sessions)
│   ├── agent-manage             (Interactive session/pane manager)
│   ├── agent-flow               (Workflow orchestrator)
│   ├── agent-handoff            (Cross-pane context transfer)
│   ├── snippet-picker           (Smart snippet selector)
│   ├── demo-setup.sh            (Demo environment)
│   └── [other scripts]
├── config/
│   └── agent-tmux.conf          (Tmux configuration)
├── README.md                    (Main documentation)
└── CONTRIBUTING.md              (Contribution guidelines)
```

---

## Notes for Fix Implementation

When implementing the Enter/send-keys fix, reference:
1. **demo-setup.sh lines 46-53** - How to properly batch send-keys with literal content
2. **agent-common.sh lines 44-63** - Session name resolution pattern
3. **agent-session lines 103-120** - Array handling pattern for multiple panes
4. **agent-manage lines 259-354** - Comprehensive copy/paste with error handling
5. **snippet-picker line 170** - Simple send-keys without Enter pattern

These examples show the established conventions and will guide proper implementation.
