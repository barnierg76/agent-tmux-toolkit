# feat: Menu Hierarchical Navigation with Session/Pane Picker

**Created:** 2026-01-06
**Fidelity Level:** 2 (Multi-file feature)
**Category:** Enhancement

---

## Overview

Enhance the agent-tmux-toolkit interactive menu (Option+M) with hierarchical navigation and session/pane selection capabilities. When killing a session or closing a pane, users will see an interactive picker showing available sessions/panes. All menus will support left arrow key to navigate to the previous menu level.

---

## Problem Statement / Motivation

Currently, when users want to kill a session or close a pane from the Option+M menu, they must:
1. Know the exact session/pane name beforehand
2. Type it manually when prompted
3. Cannot browse available options before selecting

Additionally, there's no consistent "back" navigation—users must press ESC to exit entirely rather than navigating back through menu levels.

**User pain points:**
- Discoverability: Can't see what sessions/panes exist before acting
- Navigation: No way to explore menu hierarchy and back out
- Safety: Risk of typos when manually entering session/pane names

---

## Proposed Solution

### Core Changes

1. **Session Picker for Kill Session**
   - When selecting "Kill session", show fzf list of all sessions
   - Display: name, window count, attached status, current session indicator
   - Left arrow returns to root menu without killing

2. **Pane Picker for Close Pane**
   - When selecting "Close pane", show fzf list of panes in current session
   - Display: index, role, current command, active indicator
   - Left arrow returns to root menu without closing

3. **Universal Back Navigation**
   - All menus support left arrow to go back one level
   - At root menu, left arrow exits the menu (same as ESC)
   - Consistent across all submenus and pickers

---

## Technical Approach

### Architecture

The implementation follows the existing pattern from `snippet-picker` (lines 92-172) which already implements two-level navigation with left arrow.

```
┌─────────────────────────────────────────────────────────┐
│                    NAVIGATION FLOW                       │
│                                                          │
│  ┌──────────────┐    Left Arrow    ┌─────────────────┐  │
│  │  Root Menu   │ ◄──────────────  │  Session Picker │  │
│  │  (Option+M)  │ ──────────────►  │  (Kill Session) │  │
│  └──────────────┘    Enter/Select  └─────────────────┘  │
│         │                                                │
│         │            Left Arrow    ┌─────────────────┐  │
│         └─────────  ◄──────────────│   Pane Picker   │  │
│                     ──────────────►│  (Close Pane)   │  │
│                      Enter/Select  └─────────────────┘  │
│                                                          │
│  Left Arrow at Root = Exit Menu (same as ESC)           │
└─────────────────────────────────────────────────────────┘
```

### Implementation Pattern

Use the existing `--expect='left'` + `--bind='left:abort'` fzf pattern:

```bash
# Pattern from snippet-picker:92-172
while true; do
    selected=$(echo "$list" | fzf \
        --bind='left:abort' \
        --expect='left' \
        --header="← back | Enter select | ESC quit")

    first_line=$(echo "$selected" | head -1)

    # Check if left arrow was pressed
    if [[ "$first_line" == "left" ]]; then
        break  # Return to previous level
    fi

    # Process selection
    actual_selection=$(echo "$selected" | tail -n +2)
    # ... execute action
done
```

### Files to Modify

| File | Changes |
|------|---------|
| `bin/agent-manage` | Add session/pane pickers, refactor menu loop (lines 446-638) |
| `bin/agent-common.sh` | Add shared picker functions for reuse |

---

## Implementation Phases

### Phase 1: Session Picker for Kill Session

**Tasks:**
- [ ] Create `show_session_picker()` function in `agent-common.sh`
- [ ] Format: `session_name (N windows) [attached/*current]`
- [ ] Add left arrow navigation to return to root menu
- [ ] Handle edge cases: current session, last session

**Format string:**
```bash
tmux list-sessions -F "#{session_name}|#{session_windows}|#{?session_attached,attached,detached}"
```

**Display format:**
```
dev (3 windows) *current
prod (1 window) attached
staging (2 windows) detached
```

### Phase 2: Pane Picker for Close Pane

**Tasks:**
- [ ] Create `show_pane_picker()` function in `agent-common.sh`
- [ ] Format: `Pane N: ROLE - command [WxH] *active`
- [ ] Add left arrow navigation to return to root menu
- [ ] Handle edge cases: active pane, last pane

**Format string:**
```bash
tmux list-panes -t "$session" -F "#{pane_index}|#{@role}|#{pane_current_command}|#{pane_width}x#{pane_height}|#{pane_active}"
```

**Display format:**
```
Pane 0: PLAN - vim [120x40]
Pane 1: WORK - agent [120x20] *active
Pane 2: REVIEW - bash [120x20]
```

### Phase 3: Universal Back Navigation

**Tasks:**
- [ ] Audit all submenus in `agent-manage` for left arrow support
- [ ] Add `--expect='left'` + `--bind='left:abort'` to all fzf calls
- [ ] Ensure root menu exits on left arrow (current behavior: refreshes)
- [ ] Update headers to show "← back" consistently

---

## Edge Cases & Decisions

Based on flow analysis, here are the decisions for edge cases:

### Killing Current Session
**Decision:** Allow with clear indicator
- Mark current session with `*current` suffix
- No confirmation prompt (user chose explicitly)
- tmux will switch to next available session automatically

### Killing Last Session
**Decision:** Allow without warning
- Follow tmux default behavior (exits tmux entirely)
- User explicitly selected it from a clearly labeled list
- This is expected behavior for tmux power users

### Left Arrow at Root Menu
**Decision:** Exit menu (same as ESC)
- Consistent mental model: left always "goes back"
- Going back from root = leaving the menu
- Matches behavior of most terminal UIs

### Closing Active Pane
**Decision:** Mark as active, allow closing
- Mark active pane with `*active` suffix
- After closing, focus moves to adjacent pane (tmux default)
- Return to root menu after action

### Closing Last Pane
**Decision:** Allow, follow tmux defaults
- If last pane in window, window closes
- If last window in session, session ends
- Expected behavior for experienced users

---

## Acceptance Criteria

### Functional Requirements
- [ ] Option+M → Kill session shows session picker with all sessions
- [ ] Option+M → Close pane shows pane picker with current session's panes
- [ ] Left arrow in session picker returns to root menu
- [ ] Left arrow in pane picker returns to root menu
- [ ] Left arrow at root menu exits the menu
- [ ] Current session marked with `*current` in session picker
- [ ] Active pane marked with `*active` in pane picker
- [ ] ESC still exits menu from any level

### Non-Functional Requirements
- [ ] No additional dependencies (uses existing fzf)
- [ ] Consistent styling with existing menus
- [ ] Response time < 100ms for picker display

### Quality Gates
- [ ] Manual testing of all navigation flows
- [ ] Edge case testing (current session, last session, active pane)
- [ ] Documentation updated in README

---

## Success Metrics

- Users can kill sessions/close panes without knowing names beforehand
- Navigation feels intuitive (left = back, enter = select)
- No accidental kills due to clear indicators

---

## Dependencies & Prerequisites

- tmux 3.0+ (already required)
- fzf installed (already required)
- No new dependencies

---

## Alternative Approaches Considered

| Approach | Pros | Cons | Decision |
|----------|------|------|----------|
| Native tmux `choose-tree` | Built-in, no fzf needed | Different UX, harder to customize | Rejected - want consistent UX |
| Numbered list (bash select) | Simpler, no fzf | No fuzzy search, clunky UX | Rejected - fzf better UX |
| Confirmation dialog for kills | Safer | Extra step, slows workflow | Rejected - indicators sufficient |

---

## References & Research

### Internal References
- Menu implementation: `bin/agent-manage:446-638`
- Navigation pattern: `bin/snippet-picker:92-172`
- Shared utilities: `bin/agent-common.sh`
- tmux config: `config/agent-tmux.conf:78`

### External References
- [fzf expect key documentation](https://github.com/junegunn/fzf#key-bindings)
- [tmux format strings](https://github.com/tmux/tmux/wiki/Formats)
- [CLI navigation best practices](https://github.com/charmbracelet/gum)

### Related Work
- Prior refactor: commit `c68727e` (extract shared library)
- snippet-picker two-level navigation implementation

---

## MVP Implementation

### bin/agent-common.sh (additions)

```bash
# Show session picker for selection
# Returns: selected session name or empty if cancelled/back
show_session_picker() {
    local header="${1:-Select session}"
    local current_session
    current_session=$(tmux display-message -p '#S')

    local sessions
    sessions=$(tmux list-sessions -F "#{session_name}|#{session_windows}|#{?session_attached,attached,detached}" | \
        while IFS='|' read -r name windows status; do
            local indicator=""
            [[ "$name" == "$current_session" ]] && indicator=" *current"
            echo "$name ($windows windows) $status$indicator"
        done)

    [[ -z "$sessions" ]] && return 1

    local selected
    selected=$(echo "$sessions" | fzf \
        --height=50% \
        --layout=reverse \
        --border=rounded \
        --header="$header (← back, ESC quit)" \
        --bind='left:abort' \
        --expect='left')

    local first_line
    first_line=$(echo "$selected" | head -1)
    [[ "$first_line" == "left" ]] && return 2  # Back navigation

    selected=$(echo "$selected" | tail -n +2 | awk '{print $1}')
    [[ -z "$selected" ]] && return 1  # Cancelled

    echo "$selected"
}

# Show pane picker for selection
# Returns: selected pane index or empty if cancelled/back
show_pane_picker() {
    local session="${1:-$(tmux display-message -p '#S')}"
    local header="${2:-Select pane}"

    local panes
    panes=$(tmux list-panes -t "$session" -F "#{pane_index}|#{@role}|#{pane_current_command}|#{pane_width}x#{pane_height}|#{pane_active}" | \
        while IFS='|' read -r idx role cmd dims active; do
            local indicator=""
            [[ "$active" == "1" ]] && indicator=" *active"
            role="${role:-unknown}"
            echo "Pane $idx: $role - $cmd [$dims]$indicator"
        done)

    [[ -z "$panes" ]] && return 1

    local selected
    selected=$(echo "$panes" | fzf \
        --height=50% \
        --layout=reverse \
        --border=rounded \
        --header="$header (← back, ESC quit)" \
        --bind='left:abort' \
        --expect='left')

    local first_line
    first_line=$(echo "$selected" | head -1)
    [[ "$first_line" == "left" ]] && return 2  # Back navigation

    selected=$(echo "$selected" | tail -n +2 | grep -oP 'Pane \K\d+')
    [[ -z "$selected" ]] && return 1  # Cancelled

    echo "$selected"
}
```

### bin/agent-manage (modifications to cmd_menu)

```bash
# In the menu case statement, replace "💀 Kill session" handler:

"💀 Kill session"*)
    session=$(show_session_picker "Kill which session?")
    case $? in
        0)  # Session selected
            tmux kill-session -t "$session" 2>/dev/null
            echo -e "${GREEN}Session '$session' killed${NC}"
            sleep 0.5
            ;;
        2)  # Back navigation
            continue  # Return to menu loop
            ;;
        *)  # Cancelled
            ;;
    esac
    ;;

# Replace "❌ Close pane" handler:

"❌ Close pane"*)
    pane=$(show_pane_picker "" "Close which pane?")
    case $? in
        0)  # Pane selected
            tmux kill-pane -t "$pane" 2>/dev/null
            echo -e "${GREEN}Pane $pane closed${NC}"
            sleep 0.5
            ;;
        2)  # Back navigation
            continue  # Return to menu loop
            ;;
        *)  # Cancelled
            ;;
    esac
    ;;
```

---

## Testing Checklist

- [ ] Kill session: select session, verify killed
- [ ] Kill session: press left, verify return to menu
- [ ] Kill session: press ESC, verify menu exits
- [ ] Kill session: kill current session, verify switches to another
- [ ] Kill session: kill last session, verify tmux exits
- [ ] Close pane: select pane, verify closed
- [ ] Close pane: press left, verify return to menu
- [ ] Close pane: close active pane, verify focus moves
- [ ] Close pane: close last pane, verify window closes
- [ ] Root menu: press left, verify menu exits
