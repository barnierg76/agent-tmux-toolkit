# Code Review Remediation Sprint

## Overview

This plan addresses the 19 findings from the comprehensive code review of agent-tmux-toolkit. The work is organized into 3 phases targeting security, architecture, and agent-native improvements.

**Total Estimated Effort:** 8-12 hours
**Priority:** P1 issues first (security regression is a 5-minute fix)

## Problem Statement

The code review identified:
- **3 P1 Critical** findings (security regression, DRY violations, agent accessibility gap)
- **11 P2 Important** findings (patterns, performance, agent-native)
- **5 P3 Nice-to-have** findings (cleanup, enhancements)

The most urgent issue is **TODO 025** - a security regression where `snippet-picker:170` is missing the `-l` flag on `tmux send-keys`, allowing command injection via malicious snippets.

## Proposed Solution

### Phase 1: Critical Security & Quick Wins (1-2 hours)

#### Task 1.1: Fix snippet-picker Security Regression ⚠️ FIRST
**Todo:** 025
**Effort:** 5 minutes
**File:** `bin/snippet-picker:170`

```bash
# BEFORE (vulnerable):
tmux send-keys -t "$TARGET_PANE" "$text"

# AFTER (safe):
tmux send-keys -t "$TARGET_PANE" -l "$text"
```

**Test:**
1. Create snippet containing `Enter` in content
2. Verify it pastes literally, not executed as keypress

#### Task 1.2: Add `set -e` to Scripts Missing It
**Todo:** 027
**Effort:** 15 minutes
**Files:** `bin/agent-session`, `bin/snippet-picker`

```bash
#!/bin/bash
set -e  # Add after shebang
```

**Test:**
1. Introduce intentional failure in each script
2. Verify script exits immediately rather than continuing

#### Task 1.3: Fix fzf Preview Security
**Todo:** 016
**Effort:** 15 minutes
**File:** `bin/agent-manage:310,314`

```bash
# Escape session name before use in preview
SAFE_SESSION=$(printf '%q' "$SESSION_NAME")
--preview="tmux capture-pane -p -S -20 -t '${SAFE_SESSION}.{1}' 2>/dev/null | head -20"
```

---

### Phase 2: Architecture & DRY (3-4 hours)

#### Task 2.1: Extract Session Creation to Shared Library
**Todo:** 026
**Effort:** 1-2 hours
**Files:**
- `bin/agent-common.sh` (add function)
- `bin/agent-session:91-120` (replace)
- `bin/agent-delegate:116-152` (replace both blocks)
- `bin/agent-worktree:184-196` (replace)

```bash
# Add to bin/agent-common.sh

# Create standard 3-pane agent session
# Usage: create_agent_session <session_name> <working_dir> [task_id]
# Returns: 0 on success, 1 on failure
create_agent_session() {
    local session_name="$1"
    local working_dir="$2"
    local task_id="${3:-Ready}"

    # Validate inputs
    validate_name "$session_name" "session name" || return 1
    [[ -d "$working_dir" ]] || { echo "Directory not found: $working_dir" >&2; return 1; }

    # Create session with 3 panes (batched for performance)
    tmux new-session -d -s "$session_name" -n "agents" -c "$working_dir" \; \
        split-window -h -c "$working_dir" \; \
        split-window -h -c "$working_dir" \; \
        select-layout even-horizontal

    # Get pane IDs
    local pane_ids
    mapfile -t pane_ids < <(tmux list-panes -t "$session_name" -F "#{pane_id}")

    # Set roles
    tmux set-option -p -t "${pane_ids[0]}" @role "PLAN"
    tmux set-option -p -t "${pane_ids[1]}" @role "WORK"
    tmux set-option -p -t "${pane_ids[2]}" @role "REVIEW"

    # Set titles
    tmux select-pane -t "${pane_ids[0]}" -T "$task_id"
    tmux select-pane -t "${pane_ids[1]}" -T "$task_id"
    tmux select-pane -t "${pane_ids[2]}" -T "$task_id"
}
```

**Update agent-session:**
```bash
# Replace lines 91-120 with:
create_agent_session "$SESSION_NAME" "$PROJECT_PATH" "${TASK_ID:-}"
```

**Update agent-delegate (both locations):**
```bash
# Replace lines 116-128 and 140-152 with:
create_agent_session "$SESSION_NAME" "$WORKTREE_DIR" "$task"
# or
create_agent_session "$SESSION_NAME" "$(pwd)" "$task"
```

**Test:**
1. Run `agent-session --task test1`
2. Verify 3 panes with PLAN/WORK/REVIEW roles
3. Run `agent-delegate task1 task2`
4. Verify both sessions have correct layout

#### Task 2.2: Remove agent-manage Wrapper Functions (Quick Win)
**Todo:** 022 (Phase 1)
**Effort:** 30 minutes
**File:** `bin/agent-manage`

Delete these wrapper functions that just call other scripts:
- Lines 577-590: Worktree menu integration
- Lines 592-605: Delegate menu integration
- Lines 607-611: Status menu integration

Also remove corresponding menu entries from `cmd_menu()`.

**Impact:** -60 lines

---

### Phase 3: Agent-Native Improvements (2-3 hours)

#### Task 3.1: Add stdin Support to paste Command
**Todo:** 028
**Effort:** 15 minutes
**File:** `bin/agent-manage` (cmd_paste function)

```bash
cmd_paste() {
    check_session

    local target="$1"
    local skip_confirm=false

    # Parse --yes flag (from todo 029)
    shift 2>/dev/null || true
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --yes|-y) skip_confirm=true; shift ;;
            *) shift ;;
        esac
    done

    # Get content: stdin first, then clipboard
    local content
    if [ ! -t 0 ]; then
        content=$(cat)
    else
        content=$(paste_from_clipboard 2>/dev/null)
    fi

    if [ -z "$content" ]; then
        echo -e "${YELLOW}No content (stdin empty and clipboard empty)${NC}"
        return 0
    fi

    # ... rest of function with $skip_confirm check for confirmation
}
```

#### Task 3.2: Add --yes Flag to Skip Confirmation
**Todo:** 029
**Effort:** 15 minutes
**File:** `bin/agent-manage` (integrated with Task 3.1)

```bash
# Modified confirmation block:
if [ "$line_count" -gt 1 ] && [ "$skip_confirm" = false ]; then
    echo -e "${YELLOW}About to paste $line_count lines to pane $pane_idx${NC}"
    echo -e "${YELLOW}First line: $(echo "$content" | head -1 | cut -c1-60)...${NC}"
    read -p "Continue? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Cancelled${NC}"
        return 0
    fi
fi
```

**Update help text:**
```
paste, p [n|name] [--yes]   Paste clipboard content to pane
                            --yes, -y: Skip confirmation for multi-line
```

**Test:**
```bash
# Stdin support:
echo "test content" | agent-manage paste 0

# Skip confirmation:
agent-manage paste 0 --yes

# Combined:
echo -e "line1\nline2\nline3" | agent-manage paste WORK -y
```

#### Task 3.3: Create snippet-send Command
**Todo:** 002
**Effort:** 1-2 hours
**New File:** `bin/snippet-send`

```bash
#!/bin/bash
# snippet-send - Send snippets programmatically (agent-friendly)
# Usage: snippet-send <label> [--to <pane>] [--list] [--format json]
set -e

source "$(dirname "$0")/agent-common.sh"

SNIPPETS_FILE="${HOME}/.config/agent-snippets/snippets.txt"

show_help() {
    cat << 'EOF'
snippet-send - Send snippets to panes (agent-friendly)

USAGE:
    snippet-send <label>                 Send snippet to current pane
    snippet-send <label> --to <pane>     Send to specific pane
    snippet-send --list                  List all snippets
    snippet-send --list --folder <name>  List snippets in folder
    snippet-send --get <label>           Print content without sending
    snippet-send --list --format json    JSON output

OPTIONS:
    --to, -t <pane>     Target pane (index or name)
    --list, -l          List available snippets
    --folder, -f <name> Filter by folder
    --get, -g <label>   Print content only
    --format <fmt>      Output format: text, json, tsv
    --help, -h          Show this help

EXAMPLES:
    snippet-send "Commit"                # Send to current pane
    snippet-send "Plan" --to PLAN        # Send to PLAN pane
    snippet-send --list --format json    # List as JSON
EOF
}

# Parse snippets file (reuse parsing logic from snippet-picker)
parse_snippets() {
    awk '
        BEGIN { folder="General"; label=""; content="" }
        /^# ═══.*═══/ {
            folder = $0
            sub(/^# ═══ /, "", folder)
            sub(/ ═══.*$/, "", folder)
            next
        }
        /^#/ { next }
        /^[[:space:]]*$/ { next }
        /^---/ {
            if (label != "" && content != "") {
                gsub(/\n/, "\\n", content)
                print folder "\t" label "\t" content
            }
            label = ""
            content = ""
            next
        }
        label == "" { label = $0; next }
        {
            if (content == "") content = $0
            else content = content "\n" $0
        }
        END {
            if (label != "" && content != "") {
                gsub(/\n/, "\\n", content)
                print folder "\t" label "\t" content
            }
        }
    ' "$SNIPPETS_FILE"
}

list_snippets() {
    local folder_filter="$1"
    local format="$2"

    local snippets
    snippets=$(parse_snippets)

    if [[ -n "$folder_filter" ]]; then
        snippets=$(echo "$snippets" | grep "^${folder_filter}	")
    fi

    case "$format" in
        json)
            echo "["
            echo "$snippets" | awk -F'\t' '{
                printf "  {\"folder\": \"%s\", \"label\": \"%s\"}", $1, $2
                if (NR > 1) printf ","
                printf "\n"
            }' | sed '1s/,//'
            echo "]"
            ;;
        tsv)
            echo -e "folder\tlabel"
            echo "$snippets" | cut -f1,2
            ;;
        *)
            echo "$snippets" | awk -F'\t' '{printf "%s/%s\n", $1, $2}'
            ;;
    esac
}

get_snippet() {
    local label="$1"
    local snippet
    snippet=$(parse_snippets | grep "	${label}	" | head -1)

    if [[ -z "$snippet" ]]; then
        echo "ERROR:SNIPPET_NOT_FOUND" >&2
        return 1
    fi

    echo "$snippet" | cut -f3 | sed 's/\\n/\n/g'
}

send_snippet() {
    local label="$1"
    local target_pane="${2:-}"

    local content
    content=$(get_snippet "$label") || return 1

    if [[ -z "$target_pane" ]]; then
        target_pane=$(tmux display-message -p '#{pane_id}')
    fi

    tmux send-keys -t "$target_pane" -l "$content"
    echo "Sent '$label' to $target_pane"
}

# Main argument parsing
main() {
    local action="send"
    local label=""
    local target_pane=""
    local folder=""
    local format="text"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --list|-l) action="list"; shift ;;
            --get|-g) action="get"; label="$2"; shift 2 ;;
            --to|-t) target_pane="$2"; shift 2 ;;
            --folder|-f) folder="$2"; shift 2 ;;
            --format) format="$2"; shift 2 ;;
            --help|-h) show_help; exit 0 ;;
            -*) echo "Unknown option: $1" >&2; exit 1 ;;
            *) label="$1"; shift ;;
        esac
    done

    case "$action" in
        list) list_snippets "$folder" "$format" ;;
        get) get_snippet "$label" ;;
        send)
            [[ -z "$label" ]] && { show_help; exit 1; }
            send_snippet "$label" "$target_pane"
            ;;
    esac
}

main "$@"
```

**Update install.sh:**
```bash
# Add to script list:
cp bin/snippet-send ~/.local/bin/
chmod +x ~/.local/bin/snippet-send
```

**Test:**
```bash
snippet-send --list
snippet-send --list --format json
snippet-send "Commit" --to WORK
echo "$(snippet-send --get 'Plan')"
```

---

## Acceptance Criteria

### Phase 1 (Critical)
- [x] `snippet-picker:171` uses `-l` flag
- [x] `agent-session` has `set -e`
- [x] `snippet-picker` has `set -e`
- [x] fzf previews escape session name

### Phase 2 (Architecture)
- [x] `create_agent_session()` function in agent-common.sh
- [x] All 4 scripts use the shared function
- [x] ~60 lines of duplication removed
- [x] Wrapper functions reviewed (menu entries provide useful UI, kept)

### Phase 3 (Agent-Native)
- [x] `echo "x" | agent-manage paste 0` works
- [x] `agent-manage paste 0 --yes` skips confirmation
- [x] `snippet-send --list` outputs snippet labels
- [x] `snippet-send "Label" --to PANE` sends snippets programmatically
- [ ] JSON output available for status commands (deferred)

---

## Technical Details

### Files Changed

| File | Changes |
|------|---------|
| `bin/snippet-picker:170` | Add `-l` flag |
| `bin/agent-session:1` | Add `set -e` |
| `bin/snippet-picker:1` | Add `set -e` |
| `bin/agent-manage:310,314` | Escape session name |
| `bin/agent-common.sh` | Add `create_agent_session()` |
| `bin/agent-session:91-120` | Use shared function |
| `bin/agent-delegate:116-152` | Use shared function (2 locations) |
| `bin/agent-worktree:184-196` | Use shared function |
| `bin/agent-manage` | Remove wrappers, add stdin/--yes to paste |
| `bin/snippet-send` | **NEW FILE** |
| `install.sh` | Add snippet-send |

### Impact Summary

| Metric | Before | After |
|--------|--------|-------|
| Security vulnerabilities | 3 | 0 |
| Lines of duplication | ~150 | ~50 |
| Agent accessibility | 73% | 90%+ |
| Scripts with error handling | 6/8 | 8/8 |

---

## Dependencies & Risks

### Dependencies
- Phase 2 depends on Phase 1 (test scripts work first)
- Task 3.3 (snippet-send) can be done independently

### Risks
- **Low:** Adding `set -e` may expose latent bugs (test thoroughly)
- **Low:** Session creation changes affect 4 scripts (test each)
- **None:** Security fixes are minimal changes

---

## Testing Plan

### Manual Tests (Required)
1. **Security regression:** Create snippet with "Enter", verify literal paste
2. **Error handling:** Force failures, verify script exits
3. **Session creation:** Create sessions via all 4 paths, verify identical layout
4. **Paste improvements:** Test stdin, --yes flag, combined usage
5. **snippet-send:** Test list, get, send operations

### Verification Script
```bash
#!/bin/bash
# test-remediation.sh

echo "=== Testing Phase 1 ==="
# Test snippet-picker -l flag
grep -q 'send-keys.*-l.*\$text' bin/snippet-picker && echo "✓ snippet-picker -l flag" || echo "✗ Missing -l flag"

# Test set -e
grep -q '^set -e' bin/agent-session && echo "✓ agent-session set -e" || echo "✗ Missing set -e"
grep -q '^set -e' bin/snippet-picker && echo "✓ snippet-picker set -e" || echo "✗ Missing set -e"

echo ""
echo "=== Testing Phase 2 ==="
# Test shared function exists
grep -q 'create_agent_session()' bin/agent-common.sh && echo "✓ create_agent_session function" || echo "✗ Missing function"

echo ""
echo "=== Testing Phase 3 ==="
# Test snippet-send exists
[[ -x bin/snippet-send ]] && echo "✓ snippet-send exists" || echo "✗ Missing snippet-send"

echo ""
echo "Testing complete!"
```

---

## References

### Internal
- Security audit findings: todos/025-pending-p1-snippet-picker-send-keys-literal.md
- Architecture analysis: todos/026-pending-p1-session-creation-duplication.md
- Agent-native review: todos/002-pending-p1-agent-snippet-api.md

### External
- [tmux send-keys -l flag documentation](https://man7.org/linux/man-pages/man1/tmux.1.html)
- [Bash set -e best practices](https://www.namehero.com/blog/how-to-use-set-e-o-pipefail-in-bash-and-why/)
- [stdin detection in bash](https://www.linuxjournal.com/content/determine-if-shell-input-coming-terminal-or-pipe)

---

## Work Order

**Day 1 (2-3 hours):**
1. ⚡ Task 1.1: Fix snippet-picker security (5 min)
2. Task 1.2: Add set -e to scripts (15 min)
3. Task 1.3: Fix fzf preview security (15 min)
4. Task 2.1: Extract session creation function (1-2 hours)
5. Run verification script

**Day 2 (2-3 hours):**
1. Task 2.2: Remove agent-manage wrappers (30 min)
2. Task 3.1 & 3.2: Add stdin + --yes to paste (30 min)
3. Task 3.3: Create snippet-send command (1-2 hours)
4. Full manual testing
5. Update todos to complete status
