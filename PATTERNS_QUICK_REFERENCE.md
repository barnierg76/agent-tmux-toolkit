# Agent-Tmux-Toolkit Patterns - Quick Reference

## 1. Send-Keys Command Patterns

### Pattern A: Simple Command with Execution
```bash
# File: demo-setup.sh:48
tmux send-keys -t "$pane_id" "clear" Enter
```
**Use when:** Single shell command that needs to run immediately

### Pattern B: Literal Multi-line Content (no execution)
```bash
# File: demo-setup.sh:51
tmux send-keys -t "$pane_id" -l 'printf "%s\n" "line1" "" "line2"'
# Then send Enter if you want execution:
tmux send-keys -t "$pane_id" Enter
```
**Use when:** Complex content with quotes, special chars, newlines that shouldn't be interpreted

### Pattern C: Literal String + Enter Combo
```bash
# File: agent-manage:440
tmux send-keys -t "$SESSION_NAME.$pane_idx" -l "$content"
# Note: No Enter sent - content may include it or user completes
```
**Use when:** Content may already include newlines or shouldn't auto-execute

### Pattern D: Command in Current Pane Only
```bash
# File: agent-flow:121
tmux send-keys "/compound-engineering:workflows:compound "
```
**Use when:** No explicit pane needed (uses current/active pane)

### Pattern E: Resolved Pane by Role
```bash
# File: agent-flow:60 (in send_to_pane function)
local pane_id=$(get_pane_by_role "$role" "$SESSION_NAME")
tmux send-keys -t "$pane_id" -l "$*"
```
**Use when:** Need to send to specific role (PLAN/WORK/REVIEW)

---

## 2. Pane Resolution Quick Map

### Method 1: By Index (Numeric)
```bash
pane_idx="0"  # First pane
tmux send-keys -t "$SESSION_NAME.$pane_idx" "command"
```
**Format:** `SESSION:WINDOW.INDEX`

### Method 2: By Pane ID (From tmux)
```bash
PANE_IDS=($(tmux list-panes -t "$SESSION_NAME:agents" -F "#{pane_id}"))
tmux send-keys -t "${PANE_IDS[0]}" "command"
```
**Format:** Just the pane ID (e.g., `%0`, `%1`, `%2`)

### Method 3: By Role Attribute
```bash
# From agent-common.sh:138-167
pane_id=$(get_pane_by_role "PLAN" "$SESSION_NAME")
tmux send-keys -t "$pane_id" "command"
```
**Format:** Looks up @role attribute set on pane

### Method 4: By Title
```bash
# From agent-manage:76-77
index=$(tmux list-panes -t "$SESSION_NAME" -F "#{pane_index}:#{pane_title}" | \
    awk -F: -v name="target" '$2 == name {print $1; exit}')
tmux send-keys -t "$SESSION_NAME.$index" "command"
```
**Format:** Finds pane with matching title

---

## 3. Command Argument Parsing Template

### Full Pattern (from agent-session)
```bash
# 1. Declare variables
SESSION_NAME=""
PROJECT_PATH=""

# 2. Parse loop
while [[ $# -gt 0 ]]; do
    case $1 in
        --task|-t)
            SESSION_NAME="agent-$2"
            shift 2
            ;;
        --path|-p)
            PROJECT_PATH="$2"
            shift 2
            ;;
        *)
            SESSION_NAME="$1"
            shift
            ;;
    esac
done

# 3. Validate
validate_name "$SESSION_NAME" "session name" || exit 1

# 4. Set defaults
SESSION_NAME="${SESSION_NAME:-agents}"
```

### Minimal Pattern (from agent-manage copy)
```bash
# Just flags and optional positional
while [[ $# -gt 0 ]]; do
    case "$1" in
        --full|-f) full_history=true; shift ;;
        *) target="$1"; shift ;;
    esac
done
```

---

## 4. Shared Library Functions

### Pane Resolution
| Function | File:Lines | Returns | Example |
|----------|-----------|---------|---------|
| `get_pane_by_role` | agent-common.sh:138-167 | pane_id | `get_pane_by_role "PLAN" "$SESSION"` |
| `resolve_pane` | agent-common.sh:171-205 | pane_index | `resolve_pane "0" "$SESSION"` |

### Session/Validation
| Function | File:Lines | Returns | Example |
|----------|-----------|---------|---------|
| `get_session_name` | agent-common.sh:44-63 | session_name | `SESSION=$(get_session_name)` |
| `validate_name` | agent-common.sh:28-36 | exit_code | `validate_name "name" "type"` |
| `check_fzf` | agent-common.sh:212-218 | exit_code | `check_fzf` |

### Clipboard
| Function | File:Lines | Returns | Example |
|----------|-----------|---------|---------|
| `copy_to_clipboard` | agent-common.sh:70-88 | exit_code | `copy_to_clipboard "$content"` |
| `paste_from_clipboard` | agent-common.sh:91-107 | content | `CONTENT=$(paste_from_clipboard)` |

### Interactive Selection
| Function | File:Lines | Returns | Example |
|----------|-----------|---------|---------|
| `show_session_picker` | agent-common.sh:237-270 | session_name or 1/2 | `SESSION=$(show_session_picker "prompt")` |
| `show_pane_picker` | agent-common.sh:276-310 | pane_index or 1/2 | `PANE=$(show_pane_picker "$SESSION" "prompt")` |

---

## 5. Error Handling Patterns

### Explicit Check Pattern (Repository Standard)
```bash
# File: agent-manage:54-60
check_session() {
    if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo -e "${RED}Error: Session '$SESSION_NAME' not found.${NC}"
        exit 1
    fi
}
```
**Why:** Allows specific error messages, no set -e overhead

### Conditional Execution Pattern
```bash
# File: agent-manage:191
tmux kill-server 2>/dev/null && \
    echo -e "${GREEN}All sessions killed.${NC}" || \
    echo -e "${YELLOW}No tmux server running.${NC}"
```
**Pattern:** `command 2>/dev/null && success || failure`

### Silent Failure Check
```bash
# File: agent-common.sh:49
if name=$(tmux display-message -p '#{session_name}' 2>/dev/null) && [[ -n "$name" ]]; then
    :  # Command succeeded
fi
```
**Pattern:** `if RESULT=$(cmd 2>/dev/null) && [[ -n "$RESULT" ]]`

---

## 6. Session Creation Sequence

### Standard Flow (from agent-session)
```bash
# Line 91: Create session with first pane
tmux new-session -d -s "$SESSION_NAME" -n "agents" -c "$PROJECT_PATH"

# Line 94: Add second pane
tmux split-window -h -t "$SESSION_NAME:agents" -c "$PROJECT_PATH"

# Line 97: Add third pane
tmux split-window -h -t "$SESSION_NAME:agents" -c "$PROJECT_PATH"

# Line 100: Even out layout
tmux select-layout -t "$SESSION_NAME:agents" even-horizontal

# Line 103: Get pane IDs for options setting
PANE_IDS=($(tmux list-panes -t "$SESSION_NAME:agents" -F "#{pane_id}"))

# Lines 107-109: Set roles
tmux set-option -p -t "${PANE_IDS[0]}" @role "PLAN"
tmux set-option -p -t "${PANE_IDS[1]}" @role "WORK"
tmux set-option -p -t "${PANE_IDS[2]}" @role "REVIEW"

# Lines 113-120: Set titles
tmux select-pane -t "${PANE_IDS[0]}" -T "$TASK_ID"
tmux select-pane -t "${PANE_IDS[1]}" -T "$TASK_ID"
tmux select-pane -t "${PANE_IDS[2]}" -T "$TASK_ID"

# Line 129: Focus first pane
tmux select-pane -t "${PANE_IDS[0]}"

# Line 132: Attach
tmux attach -t "$SESSION_NAME"
```

---

## 7. Color Constants (from agent-common.sh)

```bash
RED='\033[0;31m'      # Error messages
GREEN='\033[0;32m'    # Success messages
YELLOW='\033[1;33m'   # Warnings
BLUE='\033[0;34m'     # Section headers
CYAN='\033[0;36m'     # Info/instructions
DIM='\033[2m'         # Secondary text
BOLD='\033[1m'        # Emphasis
NC='\033[0m'          # No Color (reset)
```

**Usage:**
```bash
echo -e "${RED}Error message${NC}"
echo -e "${GREEN}Success!${NC}"
```

---

## 8. FZF Integration Patterns

### Basic Picker (agent-common.sh:253)
```bash
selected=$(echo "$items" | fzf \
    --height=50% \
    --layout=reverse \
    --border=rounded \
    --prompt="> " \
    --header="Select item (← back, ESC quit)" \
    --bind='left:abort' \
    --expect='left')
```

### Extract Result Handling
```bash
first_line=$(echo "$selected" | head -1)
[[ "$first_line" == "left" ]] && return 2  # Back navigation

selected=$(echo "$selected" | tail -n +2)
[[ -z "$selected" ]] && return 1  # Cancelled
```

**Exit codes:**
- 0: Item selected
- 1: Cancelled (ESC)
- 2: Back navigation (left arrow)

---

## 9. Multi-line Content Sending Example

### Reference: demo-setup.sh (lines 46-53)
```bash
send_plan_content() {
    local pane_id="$1"

    # Step 1: Clear pane
    tmux send-keys -t "$pane_id" "clear" Enter

    # Step 2: Wait for clear to complete
    sleep 0.3

    # Step 3: Send multi-line content (literal mode)
    tmux send-keys -t "$pane_id" -l 'printf "%s\n" \
        "$ claude" \
        "" \
        "> Planning..." \
        "" \
        "## Tasks" \
        "- [x] Done"'

    # Step 4: Send Enter to execute
    tmux send-keys -t "$pane_id" Enter
}
```

**Key Points:**
- Clear first (UX)
- Sleep between operations
- Use `-l` for literal mode
- Send Enter separately
- Break long strings across lines for readability

---

## 10. Common Implementation Checklist

When adding new functionality:

- [ ] Source agent-common.sh at top of script
- [ ] Get session name: `SESSION=$(get_session_name)`
- [ ] Validate inputs: `validate_name "$name" "type"` or `check_fzf`
- [ ] Check session exists: `tmux has-session -t "$SESSION"` or use `check_session`
- [ ] Get pane by role: `pane_id=$(get_pane_by_role "PLAN" "$SESSION")`
- [ ] Send commands with `-l` for literal strings
- [ ] Send Enter separately if execution needed
- [ ] Use colors for output: `${RED}`, `${GREEN}`, etc.
- [ ] Write errors to stderr: `>&2`
- [ ] Return proper exit codes (0/1)
- [ ] Test with `set -x` for debugging

---

## 11. Debugging Commands

### Check What's in a Pane
```bash
tmux capture-pane -p -t "SESSION.PANE_IDX" | head -20
tmux capture-pane -p -S -50 -t "SESSION.PANE_IDX"  # Last 50 lines
```

### List All Panes in Session
```bash
tmux list-panes -t "SESSION" -F "#{pane_index}: #{@role} - #{pane_title}"
```

### Get Specific Pane Info
```bash
tmux display-message -p '#{pane_id}|#{@role}|#{pane_title}'
```

### Debug Script with Tracing
```bash
bash -x /path/to/script.sh
```

---

## 12. File Reference Quick Map

| What to Find | Where to Look |
|--------------|---------------|
| Pane resolution logic | agent-common.sh:138-205 |
| Session creation | agent-session:90-120 |
| Multi-line send | demo-setup.sh:46-69 |
| Command parsing | agent-session:31-69 |
| Error handling | agent-manage:54-60 |
| Clipboard operations | agent-manage:259-354 |
| FZF integration | agent-common.sh:237-310 |
| Array handling | agent-session:103-120 |
| Literal string sending | demo-setup.sh:51, agent-manage:440 |
| Role-based targeting | agent-flow:40-64 |

---

## 13. Common Tmux Format Strings

```bash
# Pane information
#{pane_id}              # ID like %0, %1, %2
#{pane_index}           # Numeric index 0, 1, 2
#{@role}                # Custom attribute (PLAN, WORK, REVIEW)
#{pane_title}           # Pane title/name
#{pane_current_command} # Current command in pane
#{pane_width}           # Width in columns
#{pane_height}          # Height in rows
#{pane_active}          # 1 if active, 0 if not

# Session information
#{session_name}         # Session name
#{session_windows}      # Number of windows
#{?session_attached,attached,detached}  # Attachment status
```

---

## 14. When to Use -l Flag

### USE -l (literal) when:
- Content has special characters (`$`, `"`, `\`, etc.)
- Multi-line content with newlines
- Sending to another script/tool
- Don't want shell interpretation

### DON'T use -l when:
- Simple single command
- Want variables expanded
- Want globbing/wildcards
- User is typing interactively

### Example:
```bash
# Without -l: Variables expanded, special chars interpreted
tmux send-keys -t "$pane" "echo $var && $command"

# With -l: Literal, nothing interpreted
tmux send-keys -t "$pane" -l 'echo $var && $command'
```

---

## 15. Exit Code Reference

| Code | Meaning | Example |
|------|---------|---------|
| 0 | Success | Function completed, selection made |
| 1 | Error/Failure | Invalid input, not found, cancelled |
| 2 | Special (Back) | User pressed left arrow in picker |

**Usage:**
```bash
if function_call; then
    echo "Success (exit 0)"
elif [ $? -eq 2 ]; then
    echo "Back navigation"
else
    echo "Error (exit 1)"
fi
```

---

This quick reference should be bookmarked alongside the main research document for fast implementation reference.
