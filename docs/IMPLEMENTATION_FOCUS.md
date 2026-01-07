# Implementation Focus: Issues & Fix Patterns

## Context

This document provides **laser-focused guidance** on implementing fixes for the issues identified in the repository. Use this alongside the two reference documents.

---

## Issue 1: Enter Key Not Being Sent After send-keys Commands

### Current Problem
Scripts send commands without Enter, leaving them incomplete in pane.

**Example of Problem Code:**
```bash
# agent-flow:121 - sends command but no Enter
tmux send-keys "/compound-engineering:workflows:compound "
```

### Root Cause Analysis
- `send-keys` requires explicit `Enter` key to execute
- Without Enter, command sits in terminal waiting for confirmation
- `-l` (literal) mode doesn't interpret `Enter` as special key

### Fix Pattern 1: Simple Commands
**BEFORE:**
```bash
tmux send-keys -t "$pane_id" "clear"
```

**AFTER:**
```bash
tmux send-keys -t "$pane_id" "clear" Enter
```

**Where to Apply:**
- agent-flow:121 - `/compound-engineering:workflows:compound` command
- Any simple tmux send-keys without Enter

### Fix Pattern 2: Literal Mode Commands
**BEFORE:**
```bash
tmux send-keys -t "$pane_id" -l 'command with $var'
```

**AFTER:**
```bash
tmux send-keys -t "$pane_id" -l 'command with $var'
tmux send-keys -t "$pane_id" Enter
```

**Why:** `-l` mode sends literal strings, not special keys. Enter must be sent separately.

**Reference:** demo-setup.sh:48-52 shows correct pattern
```bash
tmux send-keys -t "$pane_id" "clear" Enter
sleep 0.3
tmux send-keys -t "$pane_id" -l 'printf "%s\n" "content"'
tmux send-keys -t "$pane_id" Enter
```

### Fix Pattern 3: User Completion Cases (INTENTIONAL no Enter)
**CONTEXT:** Some commands are meant to NOT auto-execute
```bash
# Correct - user must complete:
tmux send-keys -t "$pane_id" -l "/compound-engineering:workflows:plan "
# User types their input, then presses Enter manually
```

**Identification:** Look for comments saying "without Enter so user can..."
- agent-flow:73 comment: "without Enter so user can add description"
- These are CORRECT - don't add Enter

### Affected Files to Check

| File | Line | Issue | Fix |
|------|------|-------|-----|
| agent-flow | 121 | Missing Enter after command | Add `Enter` |
| snippet-picker | 170 | Sends text without Enter | Check if intentional |
| agent-manage | 440 | Sends content with -l | Check if needs Enter |
| demo-setup.sh | 48-52 | Has correct pattern | Reference for fix |

### Implementation Steps

1. **Identify send-keys commands** in each script
2. **Check for Enter**:
   - Simple commands: Should have Enter
   - -l mode: Must be followed by separate Enter if execution needed
   - User input commands: NO Enter (comment explains)
3. **Apply fix**:
   ```bash
   # If simple command, add Enter to same line
   tmux send-keys -t "$pane" "command" Enter

   # If -l mode, add Enter as next line
   tmux send-keys -t "$pane" -l "content"
   tmux send-keys -t "$pane" Enter
   ```
4. **Test**: Verify command executes in pane

### Testing the Fix
```bash
# Create test pane
tmux new-session -d -s test

# Send command with fix
tmux send-keys -t test "echo 'hello'" Enter

# Verify - should show echo output
tmux capture-pane -p -t test
```

---

## Issue 2: Command Batching - Multiple Operations Need Sequencing

### Current Problem
When multiple tmux commands are needed, they must complete sequentially.

### Understanding tmux Sequencing
tmux doesn't batch commands. Each must complete before next:

```bash
# This is CORRECT (sequential)
tmux new-session -d -s "SESSION"
tmux split-window -h -t "SESSION"
tmux select-layout -t "SESSION" even-horizontal
```

**NOT correct (won't work as intended):**
```bash
# DON'T do this - try to pipe tmux commands
tmux new-session -d -s "SESSION" | tmux split-window -h -t "SESSION"
```

### Fix Pattern: Proper Sequencing
**ALREADY CORRECT in agent-session:91-100**
```bash
tmux new-session -d -s "$SESSION_NAME" -n "agents" -c "$PROJECT_PATH"
tmux split-window -h -t "$SESSION_NAME:agents" -c "$PROJECT_PATH"
tmux split-window -h -t "$SESSION_NAME:agents" -c "$PROJECT_PATH"
tmux select-layout -t "$SESSION_NAME:agents" even-horizontal
```

### When Sequencing Matters
1. **After session creation**: Must create before pane operations
2. **After getting pane IDs**: Can't use PID until after list-panes
3. **After setting attributes**: Takes effect immediately

**Example with variable resolution:**
```bash
# CORRECT: Get IDs after panes exist
PANE_IDS=($(tmux list-panes -t "$SESSION_NAME" -F "#{pane_id}"))

# Then use IDs
tmux set-option -p -t "${PANE_IDS[0]}" @role "PLAN"
tmux set-option -p -t "${PANE_IDS[1]}" @role "WORK"
```

### Files Already Correct
- agent-session (lines 91-120): Perfect sequential pattern
- agent-manage (lines 129-155): Correct add panes pattern
- demo-setup.sh (lines 20-43): Correct setup sequence

### Files to Review for Sequencing Issues
- agent-flow: Check if commands are in correct order
- agent-handoff: Check content retrieval before sending

---

## Issue 3: Flag Handling and Option Parsing

### Current Pattern (Correctly Implemented)
agent-session (lines 31-69) shows the standard:

```bash
# Step 1: Declare variables
SESSION_NAME=""
PROJECT_PATH=""
TASK_ID=""

# Step 2: Parse with while loop
while [[ $# -gt 0 ]]; do
    case $1 in
        --task|-t)
            TASK_ID="$2"
            shift 2
            ;;
        --path|-p)
            PROJECT_PATH="$2"
            shift 2
            ;;
        *)
            # Handle positional args
            if [ -z "$SESSION_NAME" ]; then
                SESSION_NAME="$1"
            fi
            shift
            ;;
    esac
done

# Step 3: Apply defaults and validate
SESSION_NAME="${SESSION_NAME:-agents}"
validate_name "$SESSION_NAME" "session name" || exit 1
```

### Common Issues to Avoid

**Problem 1: Not shifting correctly**
```bash
# WRONG - infinite loop
case $1 in
    --task)
        TASK="$2"
        # forgot to shift!
        ;;
esac

# CORRECT
case $1 in
    --task)
        TASK="$2"
        shift 2  # consume both flag and value
        ;;
esac
```

**Problem 2: Not handling positional args**
```bash
# WRONG - loses "myproject" if provided
agent-session myproject

# CORRECT - handles in *)
case $1 in
    *)
        if [ -z "$SESSION_NAME" ]; then
            SESSION_NAME="$1"
        fi
        shift
        ;;
esac
```

**Problem 3: Not validating inputs**
```bash
# WRONG - accepts invalid names
SESSION_NAME="$1"

# CORRECT
SESSION_NAME="$1"
validate_name "$SESSION_NAME" "session name" || exit 1
```

### Where to Add Flags (if needed)
If implementing new flags, follow agent-manage's approach (lines 268-273):

```bash
while [[ $# -gt 0 ]]; do
    case "$1" in
        --full|-f)
            full_history=true
            shift
            ;;
        *)
            target="$1"
            shift
            ;;
    esac
done
```

### Testing Flag Parsing
```bash
# Test with various combinations
./script.sh                              # defaults
./script.sh --task 42                   # named arg
./script.sh myname                      # positional
./script.sh --task 42 --path ~/code     # multiple
./script.sh --unknown-flag              # error case
```

---

## Issue 4: Error Handling Strategy

### Current Repository Pattern (DO THIS)
```bash
# From agent-manage:54-60
check_session() {
    if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo -e "${RED}Error: Session '$SESSION_NAME' not found.${NC}" >&2
        echo "Start with: agent-session" >&2
        exit 1
    fi
}
```

**Why this pattern:**
- Explicit error handling (no `set -e`)
- Specific error messages (user knows what failed)
- Helpful recovery instructions
- Errors to stderr: `>&2`
- Returns proper exit code

### DON'T Use set -e

**WRONG:**
```bash
#!/bin/bash
set -e  # Don't do this in this project

tmux command 1
tmux command 2  # If this fails, script stops silently
```

**RIGHT:**
```bash
#!/bin/bash
# No set -e

if ! tmux command 1; then
    echo "Error: command 1 failed" >&2
    exit 1
fi

tmux command 2
```

### Error Handling Checklist
- [ ] Check dependencies exist: `check_fzf`, `tmux has-session`
- [ ] Provide helpful error messages
- [ ] Write errors to stderr: `>&2`
- [ ] Return proper exit codes: 0 (success) or 1 (error)
- [ ] Don't use `set -e` or `set -o pipefail`
- [ ] Use `2>/dev/null` for optional operations

---

## Issue 5: Shared Functions vs Local Implementation

### When to Extract to agent-common.sh

**Extract if:**
- Used in 2+ scripts
- Core functionality (not script-specific)
- Well-defined, reusable interface

**Examples of good extractions:**
- `get_pane_by_role` - used in agent-flow, agent-handoff
- `validate_name` - used in agent-session, agent-manage
- `show_session_picker` - interactive UI component

### When to Keep Local

**Keep local if:**
- Only used in this script
- Tightly coupled to specific logic
- Different behavior in different contexts

**Examples of local functions:**
- `cmd_status()` in agent-manage (specific to that tool)
- `send_plan_content()` in demo-setup.sh (demo-specific)

### How to Extract Function

1. **Add to agent-common.sh** with clear docstring
2. **Include usage comment**:
   ```bash
   # Get pane ID by role (PLAN, WORK, REVIEW)
   # Falls back to pane title, then index
   # Usage: get_pane_by_role "PLAN" "$SESSION_NAME"
   ```
3. **Document return values and exit codes**
4. **Source in scripts**: `source "$(dirname "$0")/agent-common.sh"`
5. **Use in scripts**: `pane=$(get_pane_by_role "PLAN" "$SESSION")`

### Reference Existing Functions
Instead of duplicating:

```bash
# DON'T: Write your own
my_get_pane() {
    # custom logic
}

# DO: Use existing
pane=$(get_pane_by_role "$role" "$SESSION_NAME")
```

---

## Issue 6: Multi-pane Operations - Array Handling

### Pattern: Working with Multiple Panes

**From agent-session (lines 103-120):**
```bash
# Get all pane IDs at once
PANE_IDS=($(tmux list-panes -t "$SESSION_NAME:agents" -F "#{pane_id}"))

# Verify array size
if [ ${#PANE_IDS[@]} -lt 3 ]; then
    echo "Error: Expected 3 panes, got ${#PANE_IDS[@]}"
    exit 1
fi

# Access by index
tmux set-option -p -t "${PANE_IDS[0]}" @role "PLAN"
tmux set-option -p -t "${PANE_IDS[1]}" @role "WORK"
tmux set-option -p -t "${PANE_IDS[2]}" @role "REVIEW"

# Or iterate
for i in 0 1 2; do
    tmux send-keys -t "${PANE_IDS[$i]}" "command" Enter
done
```

### Anti-patterns (DON'T do these)

**Problem 1: Hardcoded pane numbers**
```bash
# WRONG - assumes specific layout
tmux send-keys -t "$SESSION_NAME.0" "command"
tmux send-keys -t "$SESSION_NAME.1" "command"

# RIGHT - use roles
pane=$(get_pane_by_role "PLAN" "$SESSION_NAME")
tmux send-keys -t "$pane" "command"
```

**Problem 2: Command substitution in middle of operation**
```bash
# WRONG - fragile, hard to debug
for i in $(seq 0 2); do
    if [ $i -eq 0 ]; then role="PLAN"; fi
    tmux set-option -p -t "$(tmux list-panes -t SESSION -F "#{pane_id}" | sed -n "$((i+1))p")" @role "$role"
done

# RIGHT - get all IDs first, then use
PANE_IDS=($(tmux list-panes -t "$SESSION" -F "#{pane_id}"))
tmux set-option -p -t "${PANE_IDS[0]}" @role "PLAN"
```

---

## Issue 7: Content Handling - Special Characters and Newlines

### When to Use -l (Literal Mode)

**Complex content with special chars:**
```bash
# Content has quotes, $vars, etc.
content='echo "Hello $USER" && ls -la'

# WRONG - shell interprets everything
tmux send-keys -t "$pane" "$content"

# CORRECT - literal mode
tmux send-keys -t "$pane" -l "$content"
```

### Pattern: Multi-line Content

**From demo-setup.sh (lines 51-52):**
```bash
# Send literal multi-line string
tmux send-keys -t "$pane_id" -l 'printf "%s\n" \
    "line 1" \
    "line 2" \
    "line 3"'

# Then send Enter to execute
tmux send-keys -t "$pane_id" Enter
```

**Key points:**
- Use single quotes for literal strings
- Can break across lines (shell concatenates)
- -l prevents interpretation
- Send Enter separately for execution

### Pattern: Replacing Newlines

**From agent-handoff:55-57:**
```bash
# Capture pane with ANSI cleanup
content=$(tmux capture-pane -p -t "$pane_id" 2>/dev/null | \
    sed 's/\x1b\[[0-9;]*m//g')

# If sending to another pane
tmux send-keys -t "$target_pane" -l "$content"
```

---

## Issue 8: Pane Selection and Targeting

### Three Ways to Target Panes

**Method 1: By Index (for known positions)**
```bash
# Use when position is fixed/known
tmux send-keys -t "$SESSION_NAME.0" "command" Enter
```

**Method 2: By Role (preferred)**
```bash
# Use when roles are known (PLAN, WORK, REVIEW)
pane=$(get_pane_by_role "PLAN" "$SESSION_NAME")
tmux send-keys -t "$pane" "command" Enter
```

**Method 3: Current Pane (from within pane)**
```bash
# When running from inside a pane
tmux send-keys "command" Enter
```

### Priority Order (from agent-common.sh:138-167)
```
1. Check @role attribute (custom, set explicitly)
2. Check pane_title (may match role name)
3. Use index fallback (1st/2nd/3rd pane)
```

---

## Issue 9: Testing and Validation

### Unit Testing Patterns

**Test 1: Session creation**
```bash
# Verify session exists
tmux has-session -t "test-session" || echo "Session creation failed"

# Verify pane count
PANE_COUNT=$(tmux list-panes -t "test-session" | wc -l)
[ "$PANE_COUNT" -eq 3 ] || echo "Wrong pane count: $PANE_COUNT"
```

**Test 2: Pane resolution**
```bash
# Verify role assignment
ROLE=$(tmux display-message -p '#{@role}' -t "$SESSION_NAME.0" 2>/dev/null)
[ "$ROLE" = "PLAN" ] || echo "Role assignment failed"
```

**Test 3: Content sending**
```bash
# Send test content
tmux send-keys -t "$pane" "echo 'test-marker'" Enter

# Verify it executed
sleep 0.5
OUTPUT=$(tmux capture-pane -p -t "$pane")
echo "$OUTPUT" | grep -q "test-marker" || echo "Send-keys failed"
```

### Debug Commands

```bash
# See what's in a pane
tmux capture-pane -p -t "SESSION.PANE"

# See all panes and their info
tmux list-panes -t "SESSION" -F "#{pane_index}|#{@role}|#{pane_title}"

# Watch pane in real-time
tmux capture-pane -p -t "SESSION.PANE" -e  # -e = interpret ANSI codes

# Trace script execution
bash -x ./script.sh

# See tmux server logs
tmux show-messages
```

---

## Implementation Checklist

### Before Starting
- [ ] Read REPOSITORY_PATTERNS_RESEARCH.md
- [ ] Review PATTERNS_QUICK_REFERENCE.md
- [ ] Identify exact lines that need fixing
- [ ] Create test case for each fix

### During Implementation
- [ ] Follow repository patterns (not your own style)
- [ ] Use existing shared functions from agent-common.sh
- [ ] Add Enter where needed (but not for user input cases)
- [ ] Maintain sequential command order
- [ ] Use -l flag for literal content
- [ ] Handle errors explicitly (no set -e)
- [ ] Write errors to stderr

### Testing
- [ ] Test basic case (no args)
- [ ] Test with flags/options
- [ ] Test error cases (missing session, etc.)
- [ ] Verify panes execute commands
- [ ] Check output formatting

### Code Review
- [ ] All send-keys commands have Enter (or documented reason not to)
- [ ] Panes referenced by role (not hardcoded numbers)
- [ ] Error messages are helpful
- [ ] Functions extracted to agent-common.sh if reusable
- [ ] Comments explain non-obvious code
- [ ] Colors used correctly for output

---

## Quick Command Reference for Testing

```bash
# Create test session
tmux new-session -d -s test

# Split into 3 panes
tmux split-window -h -t test
tmux split-window -h -t test
tmux select-layout -t test even-horizontal

# Get pane info
tmux list-panes -t test -F "#{pane_index}|#{@role}|#{pane_title}"

# Send test command
tmux send-keys -t test.0 "echo hello" Enter

# Check execution
tmux capture-pane -p -t test.0 | tail -5

# Clean up
tmux kill-session -t test
```

---

## Files Most Likely to Need Fixes

**Priority 1 (Highest impact):**
1. agent-flow (line 121 - missing Enter)
2. agent-manage (copy/paste operations)

**Priority 2 (Good to check):**
3. agent-session (verify sequence)
4. agent-handoff (content sending)
5. snippet-picker (pane targeting)

**Priority 3 (Reference/verify):**
6. demo-setup.sh (already correct - use as reference)
7. agent-common.sh (shared functions - check completeness)

---

This document should guide 80% of the implementation work. Use the other two documents for details when needed.
