# feat: Copy Pane Content to System Clipboard

**Created:** 2025-01-04
**Fidelity Level:** 2 (Multi-file feature)
**Category:** Enhancement

## Overview

Add a "Copy pane content" action to the agent-manage popup menu that allows users to select a tmux pane and copy its content directly to the system clipboard. This enables quick extraction of agent output, logs, or terminal history without manual selection.

## Problem Statement / Motivation

Currently, users must:
1. Navigate to a specific pane
2. Enter tmux copy mode (`Prefix + v`)
3. Manually select text
4. Copy to tmux buffer (`y`)
5. The content stays in tmux buffer, not system clipboard

This is cumbersome when you want to quickly grab output from an agent pane to paste into documentation, Slack, or another application. The agent-manage popup already provides quick access to pane operations—adding copy-to-clipboard follows that pattern.

## Proposed Solution

Add a new "Copy pane" action to the agent-manage menu that:

1. Shows a list of available panes using fzf
2. Captures the selected pane's content via `tmux capture-pane`
3. Copies to system clipboard using platform-appropriate tool
4. Shows confirmation feedback

### Menu Integration

```
━━━ ACTIONS ━━━
📊 Status
➕ Add panes
📐 Layout
🏷️  Rename pane
🎯 Focus pane
📋 Copy pane        ← NEW
❌ Close pane
💀 Kill session
```

## Technical Approach

### Architecture

The feature integrates into the existing `agent-manage` bash script architecture:

```
┌─────────────────────────────────────────────────────┐
│                   agent-manage                       │
│                                                     │
│  ┌─────────────┐    ┌──────────────┐               │
│  │  cmd_menu() │───▶│ cmd_copy()   │               │
│  │  (fzf UI)   │    │              │               │
│  └─────────────┘    │  1. List panes│               │
│                     │  2. fzf select│               │
│                     │  3. capture   │               │
│                     │  4. clipboard │               │
│                     │  5. confirm   │               │
│                     └──────────────┘               │
│                            │                        │
│                            ▼                        │
│              ┌─────────────────────────┐           │
│              │  tmux capture-pane -p   │           │
│              │         │               │           │
│              │         ▼               │           │
│              │   pbcopy / xclip        │           │
│              └─────────────────────────┘           │
└─────────────────────────────────────────────────────┘
```

### Implementation Details

**File:** `bin/agent-manage`

#### 1. Add copy command handler

```bash
# bin/agent-manage - add after cmd_focus() function (~line 240)

cmd_copy() {
    check_session

    # Get list of panes with identifying info
    local panes
    panes=$(tmux list-panes -t "$SESSION_NAME" \
        -F "#{pane_index}|#{pane_title}|#{pane_current_command}" \
        2>/dev/null)

    if [ -z "$panes" ]; then
        echo -e "${RED}No panes found in session${NC}"
        return 1
    fi

    # Format for fzf display
    local formatted=""
    while IFS='|' read -r idx title cmd; do
        formatted+="$idx: $title ($cmd)"$'\n'
    done <<< "$panes"

    # Let user select pane
    local selected
    selected=$(echo -e "$formatted" | fzf \
        --height=50% \
        --layout=reverse \
        --border=rounded \
        --prompt="Select pane to copy › " \
        --header="Copy pane content to clipboard" \
        --preview="tmux capture-pane -p -S -20 -t '$SESSION_NAME.{1}' 2>/dev/null | head -20" \
        --preview-window=right:50%:wrap)

    [ -z "$selected" ] && return 0  # User cancelled

    # Extract pane index
    local pane_idx
    pane_idx=$(echo "$selected" | cut -d: -f1)

    # Capture pane content (visible only by default, stripping ANSI)
    local content
    content=$(tmux capture-pane -p -t "$SESSION_NAME.$pane_idx" 2>/dev/null | \
        sed 's/\x1b\[[0-9;]*m//g')  # Strip ANSI codes

    if [ -z "$content" ]; then
        echo -e "${YELLOW}⚠ Pane is empty (nothing to copy)${NC}"
        return 0
    fi

    # Copy to clipboard (cross-platform)
    if ! copy_to_clipboard "$content"; then
        echo -e "${RED}Failed to copy to clipboard${NC}"
        return 1
    fi

    # Count lines for feedback
    local line_count
    line_count=$(echo "$content" | wc -l | tr -d ' ')

    echo -e "${GREEN}✓ Copied $line_count lines to clipboard${NC}"
    sleep 1  # Brief pause to show confirmation
}
```

#### 2. Add clipboard utility function

```bash
# bin/agent-manage - add in utility functions section (~line 20)

copy_to_clipboard() {
    local content="$1"

    if command -v pbcopy &>/dev/null; then
        echo -n "$content" | pbcopy
    elif command -v xclip &>/dev/null; then
        echo -n "$content" | xclip -selection clipboard
    elif command -v xsel &>/dev/null; then
        echo -n "$content" | xsel --clipboard --input
    elif command -v wl-copy &>/dev/null; then
        echo -n "$content" | wl-copy
    elif command -v clip.exe &>/dev/null; then
        echo -n "$content" | clip.exe
    else
        echo -e "${RED}No clipboard tool found. Install pbcopy (macOS), xclip, xsel (Linux), or wl-copy (Wayland)${NC}"
        return 1
    fi
}
```

#### 3. Add menu option

```bash
# bin/agent-manage - modify cmd_menu() function, add to ACTIONS section (~line 276)

# In the menu_items array, add:
"📋 Copy pane"
```

#### 4. Add case handler

```bash
# bin/agent-manage - modify case statement in cmd_menu() (~line 350)

"📋 Copy pane")
    cmd_copy
    ;;
```

### Alternative: Full Scrollback Option

For users who need full scrollback history, add a variant:

```bash
cmd_copy_full() {
    # Same as cmd_copy but use:
    # tmux capture-pane -p -S - -t "$SESSION_NAME.$pane_idx"
    # -S - means start from beginning of scrollback
}
```

This could be a separate menu item "📋 Copy pane (full history)" or a sub-menu.

## Acceptance Criteria

### Functional Requirements

- [ ] "Copy pane" option appears in agent-manage popup menu
- [ ] Selecting "Copy pane" shows fzf list of available panes
- [ ] Pane list shows: index, title, and running command
- [ ] fzf preview shows last 20 lines of pane content
- [ ] Selecting a pane copies visible content to system clipboard
- [ ] ANSI escape codes are stripped from copied content
- [ ] Success message shows number of lines copied
- [ ] Empty pane shows warning message and doesn't modify clipboard
- [ ] ESC/cancel returns to menu without copying

### Non-Functional Requirements

- [ ] Works on macOS (pbcopy)
- [ ] Works on Linux X11 (xclip/xsel)
- [ ] Works on Linux Wayland (wl-copy)
- [ ] Works on WSL (clip.exe)
- [ ] Shows helpful error if no clipboard tool available
- [ ] Copy operation completes in <1 second for typical pane content

### Quality Gates

- [ ] Manual testing on macOS confirms pbcopy integration
- [ ] Code follows existing `agent-manage` patterns
- [ ] Error messages match existing style (colors, format)
- [ ] Menu option placement is logical (with other pane actions)

## Technical Considerations

### Platform Detection

Use command detection in order of preference:
1. `pbcopy` (macOS native)
2. `xclip` (most common Linux clipboard)
3. `xsel` (alternative Linux clipboard)
4. `wl-copy` (Wayland native)
5. `clip.exe` (Windows/WSL)

### ANSI Code Stripping

Use `sed 's/\x1b\[[0-9;]*m//g'` to strip color codes. This pattern handles:
- Bold, italic, underline
- Foreground/background colors
- Reset sequences

### Large Content Protection

For v1, we'll copy visible pane content only (what's on screen). This naturally limits size to ~50KB max. Full scrollback option can be added later with size warnings.

### Preview Performance

The fzf preview runs `tmux capture-pane` with `-S -20` (last 20 lines) and `head -20` to ensure fast rendering even for large panes.

## Dependencies & Prerequisites

**Required:**
- tmux 3.0+ (for capture-pane features)
- fzf (already required by agent-manage)
- One of: pbcopy, xclip, xsel, wl-copy, clip.exe

**No new dependencies** - uses tools already available or commonly installed.

## Success Metrics

- Feature is discoverable in menu
- Copy operation works first try on macOS
- Users can paste into external apps (Slack, docs, etc.)
- No clipboard corruption or encoding issues

## Future Considerations

**v2 enhancements (deferred):**
- Full scrollback option with size warning
- Option to preserve ANSI codes
- Custom line range selection
- OSC 52 support for SSH sessions
- Multi-pane selection

## Files to Modify

| File | Change |
|------|--------|
| `bin/agent-manage` | Add `cmd_copy()`, `copy_to_clipboard()`, menu option |

## References & Research

### Internal References
- Agent-manage menu: `bin/agent-manage:247-373`
- Existing pane listing: `bin/agent-manage:79,108,143`
- tmux config keybindings: `config/agent-tmux.conf:14-30`

### External References
- [tmux capture-pane docs](https://tmuxai.dev/tmux-capture-pane/)
- [tmux Clipboard Wiki](https://github.com/tmux/tmux/wiki/Clipboard)
- [Cross-platform clipboard best practices](https://medium.com/free-code-camp/tmux-in-practice-integration-with-system-clipboard-bcd72c62ff7b)

### Related Work
- Initial release: commit `360c04c`

---

## MVP Implementation

### bin/agent-manage (modifications)

Add utility function after line 20:

```bash
# Cross-platform clipboard copy
copy_to_clipboard() {
    local content="$1"

    if command -v pbcopy &>/dev/null; then
        echo -n "$content" | pbcopy
    elif command -v xclip &>/dev/null; then
        echo -n "$content" | xclip -selection clipboard
    elif command -v xsel &>/dev/null; then
        echo -n "$content" | xsel --clipboard --input
    elif command -v wl-copy &>/dev/null; then
        echo -n "$content" | wl-copy
    elif command -v clip.exe &>/dev/null; then
        echo -n "$content" | clip.exe
    else
        echo -e "${RED}No clipboard tool found${NC}"
        echo "Install one of: pbcopy (macOS), xclip, xsel (Linux), wl-copy (Wayland)"
        return 1
    fi
}
```

Add command function before `cmd_menu()`:

```bash
# Copy pane content to clipboard
cmd_copy() {
    check_session

    local panes
    panes=$(tmux list-panes -t "$SESSION_NAME" \
        -F "#{pane_index}|#{pane_title}|#{pane_current_command}" 2>/dev/null)

    if [ -z "$panes" ]; then
        echo -e "${RED}No panes found in session${NC}"
        return 1
    fi

    # Format for display
    local display=""
    while IFS='|' read -r idx title cmd; do
        display+="$idx: $title ($cmd)"$'\n'
    done <<< "$panes"

    local selected
    selected=$(echo -e "$display" | sed '/^$/d' | fzf \
        --height=50% \
        --layout=reverse \
        --border=rounded \
        --prompt="Select pane to copy › " \
        --header="Copy pane content to clipboard" \
        --preview="tmux capture-pane -p -S -20 -t '$SESSION_NAME.{1}' 2>/dev/null | head -20" \
        --preview-window=right:50%:wrap)

    [ -z "$selected" ] && return 0

    local pane_idx
    pane_idx=$(echo "$selected" | cut -d: -f1 | tr -d ' ')

    local content
    content=$(tmux capture-pane -p -t "$SESSION_NAME.$pane_idx" 2>/dev/null | \
        sed 's/\x1b\[[0-9;]*m//g')

    if [ -z "$content" ] || [ "$(echo "$content" | tr -d '[:space:]')" = "" ]; then
        echo -e "${YELLOW}⚠ Pane is empty (nothing to copy)${NC}"
        return 0
    fi

    if ! copy_to_clipboard "$content"; then
        return 1
    fi

    local line_count
    line_count=$(echo "$content" | wc -l | tr -d ' ')

    echo -e "${GREEN}✓ Copied $line_count lines to clipboard${NC}"
    sleep 1
}
```

Update menu items array (add after "🎯 Focus pane"):

```bash
"📋 Copy pane"
```

Update case statement:

```bash
"📋 Copy pane")
    cmd_copy
    ;;
```
