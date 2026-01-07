# feat: Improved Handoff with Text Selection Support

## Overview

Improve the handoff feature to support user-selected text. The new workflow allows users to select specific text, press Option+H, choose a target pane, and send only the selected content instead of the entire pane.

## Problem Statement

**Current behavior:**
- `agent-handoff` captures the last 50 non-empty lines of a pane
- No way to send only specific selected text
- User must handoff entire pane context even when only a portion is relevant

**Desired behavior:**
1. User selects text (mouse drag or keyboard copy mode)
2. User presses Option+H
3. User selects target pane
4. Only the selected text is sent to target

**Technical constraint:**
- tmux copy mode and fzf menus cannot coexist
- Once fzf opens, copy mode exits and selection is lost
- BUT: Mouse selection auto-copies to system clipboard via `copy-pipe-and-cancel "pbcopy"`
- Keyboard selection requires explicit yank (`y`) before clipboard has content

## Proposed Solution

Modify `agent-handoff` to detect clipboard content and offer a choice:

```
┌─────────────────────────────────────────────────────────┐
│  HANDOFF - What do you want to send?                    │
│                                                         │
│  → [CLIPBOARD] "def calculate_total(items):..."  (127c) │
│    [PANE]      Last 50 lines from current pane          │
│    [CANCEL]    Cancel handoff                           │
│                                                         │
│  ↑/↓ select • Enter confirm • ESC cancel                │
└─────────────────────────────────────────────────────────┘
```

If clipboard is empty, skip straight to target pane selection (existing behavior).

## Technical Approach

### Files to Modify

| File | Changes |
|------|---------|
| `bin/agent-handoff` | Add clipboard detection and content source menu |

### Implementation Flow

```
┌─────────────────────────────────────────────────────────┐
│                   Option+H Pressed                       │
│                          │                               │
│                          ▼                               │
│              ┌─────────────────────┐                    │
│              │  Check Clipboard    │                    │
│              │  (pbpaste/xclip)    │                    │
│              └──────────┬──────────┘                    │
│                         │                               │
│           ┌─────────────┴─────────────┐                 │
│           │                           │                 │
│      Empty/Error               Has Content              │
│           │                           │                 │
│           ▼                           ▼                 │
│   ┌───────────────┐         ┌─────────────────┐        │
│   │ Skip to pane  │         │ Show choice:    │        │
│   │ selection     │         │ Clipboard/Pane  │        │
│   └───────┬───────┘         └────────┬────────┘        │
│           │                          │                  │
│           └──────────┬───────────────┘                  │
│                      ▼                                  │
│           ┌─────────────────────┐                       │
│           │ Select target pane  │                       │
│           │ (fzf with preview)  │                       │
│           └──────────┬──────────┘                       │
│                      ▼                                  │
│           ┌─────────────────────┐                       │
│           │ Send content via    │                       │
│           │ load-buffer/paste   │                       │
│           └─────────────────────┘                       │
└─────────────────────────────────────────────────────────┘
```

### Key Implementation Details

**1. Clipboard Detection**

```bash
# bin/agent-handoff - new function
get_clipboard_content() {
    local content=""

    if command -v pbpaste &>/dev/null; then
        content=$(pbpaste 2>/dev/null)
    elif command -v xclip &>/dev/null; then
        content=$(xclip -selection clipboard -o 2>/dev/null)
    elif command -v xsel &>/dev/null; then
        content=$(xsel --clipboard --output 2>/dev/null)
    elif command -v wl-paste &>/dev/null; then
        content=$(wl-paste 2>/dev/null)
    fi

    # Return empty if content is just whitespace
    if [[ -z "${content// /}" ]]; then
        echo ""
    else
        echo "$content"
    fi
}
```

**2. Content Source Selection**

```bash
# bin/agent-handoff - new function
select_content_source() {
    local clipboard_content="$1"
    local clipboard_preview="${clipboard_content:0:50}"
    local clipboard_len=${#clipboard_content}

    # Escape special chars for display
    clipboard_preview=$(echo "$clipboard_preview" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g')

    local menu=""
    menu+="CLIPBOARD|[CLIPBOARD] \"${clipboard_preview}...\" (${clipboard_len}c)"$'\n'
    menu+="PANE|[PANE] Last 50 lines from current pane"$'\n'
    menu+="CANCEL|[CANCEL] Cancel handoff"

    local selection
    selection=$(echo -e "$menu" | fzf \
        --height=40% \
        --layout=reverse \
        --border=rounded \
        --prompt="Send what? › " \
        --header="Select content to handoff" \
        --delimiter='|' \
        --with-nth=2 \
        --no-preview \
        --bind='esc:abort')

    echo "$selection" | cut -d'|' -f1
}
```

**3. Modified Main Flow**

```bash
# bin/agent-handoff - modified interactive section
# Instead of asking for source pane first, check clipboard

clipboard_content=$(get_clipboard_content)

if [[ -n "$clipboard_content" ]]; then
    # Clipboard has content - ask what to send
    content_source=$(select_content_source "$clipboard_content")

    case "$content_source" in
        CLIPBOARD)
            handoff_content="$clipboard_content"
            source_desc="clipboard selection"
            ;;
        PANE)
            # Use current pane as source
            source_id=$(tmux display-message -p '#{pane_id}')
            handoff_content=$(capture_pane_content "$source_id")
            source_desc="pane content"
            ;;
        CANCEL|"")
            exit 0
            ;;
    esac
else
    # No clipboard - use current pane content
    source_id=$(tmux display-message -p '#{pane_id}')
    handoff_content=$(capture_pane_content "$source_id")
    source_desc="pane content"
fi

# Now select target pane
echo -e "${CYAN}Select target pane:${NC}"
target_id=$(select_pane_interactive "Target")

if [[ -z "$target_id" ]]; then
    echo -e "${RED}No target selected${NC}"
    exit 1
fi

# Get target role for template
target_role=$(tmux display-message -p -t "$target_id" '#{@role}')

# Create handoff message
template=$(get_handoff_template "selection" "$target_role")
handoff=$(printf "%s\n\n---\n%s\n---\n" "$template" "$handoff_content")

# Send to target
echo "$handoff" | tmux load-buffer -
tmux paste-buffer -t "$target_id"

echo -e "${GREEN}✓ Sent $source_desc to ${target_role:-pane}${NC}"
```

**4. Updated Template for Clipboard Content**

```bash
# bin/agent-handoff - update get_handoff_template()
get_handoff_template() {
    local from_role="$1"
    local to_role="$2"

    # Handle clipboard/selection source
    if [[ "$from_role" == "selection" || "$from_role" == "clipboard" ]]; then
        case "$to_role" in
            PLAN*) echo "Here's some context to consider for planning:" ;;
            WORK*) echo "Here's content to work with:" ;;
            REVIEW*) echo "Please review this:" ;;
            *) echo "Context:" ;;
        esac
        return
    fi

    # Existing role-to-role templates...
    case "${from_role}_to_${to_role}" in
        PLAN*_to_WORK*) echo "Here's the plan to implement:" ;;
        WORK*_to_REVIEW*) echo "Please review this implementation:" ;;
        REVIEW*_to_WORK*) echo "Review feedback to address:" ;;
        *) echo "Context from ${from_role:-pane}:" ;;
    esac
}
```

## Acceptance Criteria

- [ ] Mouse selection + Option+H shows clipboard content as first option
- [ ] Keyboard yank (`y`) + Option+H shows clipboard content as first option
- [ ] Empty clipboard skips straight to target pane selection (current behavior)
- [ ] Selecting "CLIPBOARD" sends only the selected text
- [ ] Selecting "PANE" sends last 50 lines (existing behavior)
- [ ] Selecting "CANCEL" or ESC exits without sending
- [ ] Target pane selection works as before (fzf with preview)
- [ ] Content is sent via `load-buffer` + `paste-buffer` (preserves formatting)
- [ ] No auto-execution (no trailing newline that would trigger Enter)
- [ ] CLI mode (`agent-handoff --from-clipboard TARGET`) also supported

## MVP Implementation

### bin/agent-handoff modifications

```bash
#!/bin/bash
# agent-handoff - Transfer context between agent panes
# MODIFIED: Add clipboard/selection support

set -e

# ... existing color definitions and help ...

# NEW: Clipboard functions
get_clipboard_content() {
    local content=""

    if command -v pbpaste &>/dev/null; then
        content=$(pbpaste 2>/dev/null)
    elif command -v xclip &>/dev/null; then
        content=$(xclip -selection clipboard -o 2>/dev/null)
    elif command -v xsel &>/dev/null; then
        content=$(xsel --clipboard --output 2>/dev/null)
    elif command -v wl-paste &>/dev/null; then
        content=$(wl-paste 2>/dev/null)
    fi

    # Return empty if just whitespace
    if [[ -z "${content// /}" ]]; then
        echo ""
    else
        echo "$content"
    fi
}

# NEW: Content source selection menu
select_content_source() {
    local clipboard_content="$1"

    # Create preview (first 50 chars, single line)
    local preview="${clipboard_content:0:50}"
    preview=$(echo "$preview" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g')
    local len=${#clipboard_content}

    local menu=""
    menu+="CLIPBOARD|📋 [CLIPBOARD] \"${preview}...\" (${len}c)"$'\n'
    menu+="PANE|📄 [PANE] Last 50 lines from current pane"$'\n'
    menu+="CANCEL|❌ [CANCEL] Cancel handoff"

    local selection
    selection=$(echo -e "$menu" | fzf \
        --height=30% \
        --layout=reverse \
        --border=rounded \
        --prompt="Send what? › " \
        --header="HANDOFF - Select content source (ESC to cancel)" \
        --delimiter='|' \
        --with-nth=2 \
        --no-preview \
        --ansi \
        --bind='esc:abort' \
        --expect='esc') || true

    # Handle escape
    local first_line=$(echo "$selection" | head -1)
    if [[ "$first_line" == "esc" ]]; then
        echo "CANCEL"
        return
    fi

    echo "$selection" | tail -1 | cut -d'|' -f1
}

# NEW: Capture pane content (extracted from do_handoff)
capture_pane_content() {
    local pane_id="$1"
    local lines="${2:-50}"

    tmux capture-pane -p -t "$pane_id" | \
        sed 's/\x1b\[[0-9;]*m//g' | \
        grep -v '^[[:space:]]*$' | \
        tail -"$lines"
}

# MODIFIED: Interactive mode with clipboard support
run_interactive() {
    check_fzf

    # Check clipboard first
    local clipboard_content
    clipboard_content=$(get_clipboard_content)

    local handoff_content=""
    local source_desc=""
    local source_role=""

    if [[ -n "$clipboard_content" ]]; then
        # Clipboard has content - ask what to send
        local content_source
        content_source=$(select_content_source "$clipboard_content")

        case "$content_source" in
            CLIPBOARD)
                handoff_content="$clipboard_content"
                source_desc="clipboard selection"
                source_role="selection"
                ;;
            PANE)
                local current_pane
                current_pane=$(tmux display-message -p '#{pane_id}')
                handoff_content=$(capture_pane_content "$current_pane")
                source_role=$(tmux display-message -p '#{@role}')
                source_desc="pane content"
                ;;
            CANCEL|"")
                echo -e "${DIM}Handoff cancelled${NC}"
                exit 0
                ;;
        esac
    else
        # No clipboard - use current pane
        local current_pane
        current_pane=$(tmux display-message -p '#{pane_id}')
        handoff_content=$(capture_pane_content "$current_pane")
        source_role=$(tmux display-message -p '#{@role}')
        source_desc="pane content"
    fi

    # Select target pane
    echo -e "${CYAN}Select target pane:${NC}"
    local target_id
    target_id=$(select_pane_interactive "Target")

    if [[ -z "$target_id" ]]; then
        echo -e "${RED}No target selected${NC}"
        exit 1
    fi

    # Get target role for template
    local target_role
    target_role=$(tmux display-message -p -t "$target_id" '#{@role}')

    # Create handoff message with template
    local template
    template=$(get_handoff_template "$source_role" "$target_role")
    local handoff
    handoff=$(printf "%s\n\n---\n%s\n---\n" "$template" "$handoff_content")

    # Send to target
    echo "$handoff" | tmux load-buffer -
    tmux paste-buffer -t "$target_id"

    echo -e "${GREEN}✓ Sent ${source_desc} to ${target_role:-target pane}${NC}"
}

# ... rest of existing code ...
```

## User Workflows

### Workflow 1: Mouse Selection (Most Common)

```
1. User drags mouse to select text in WORK pane
   → Text is auto-copied to clipboard (via MouseDragEnd1Pane binding)

2. User presses Option+H
   → Popup shows:
     📋 [CLIPBOARD] "def calculate_total(items):..." (127c)
     📄 [PANE] Last 50 lines from current pane
     ❌ [CANCEL] Cancel handoff

3. User presses Enter (CLIPBOARD is highlighted)
   → Shows target pane selection

4. User selects REVIEW pane
   → Selected text is sent to REVIEW pane with context template
```

### Workflow 2: Keyboard Selection (Power Users)

```
1. User presses Prefix+v to enter copy mode
2. Navigates with arrow keys to start of selection
3. Presses 'v' to begin visual selection
4. Navigates to end of selection
5. Presses 'y' to yank (copies to clipboard, exits copy mode)

6. User presses Option+H
   → Same flow as mouse selection
```

### Workflow 3: Full Pane Handoff (Existing Behavior)

```
1. User presses Option+H
   → Clipboard is empty (or user chooses PANE option)
   → Shows target pane selection immediately

2. User selects target pane
   → Last 50 lines sent (existing behavior)
```

## Dependencies & Risks

**Dependencies:**
- System clipboard tools (pbpaste/xclip/xsel/wl-paste) - already used in toolkit
- fzf for menu selection - already required

**Risks:**
- Low: Clipboard might have stale content from other apps → user can choose PANE
- Low: Large clipboard content → no size limit, but unlikely to be huge

## Testing Checklist

- [ ] Mouse selection → Option+H shows clipboard option
- [ ] Keyboard yank → Option+H shows clipboard option
- [ ] Empty clipboard → skips to target selection
- [ ] CLIPBOARD option sends only selected text
- [ ] PANE option sends last 50 lines
- [ ] CANCEL/ESC exits cleanly
- [ ] Multi-line selection preserves newlines
- [ ] Special characters handled correctly
- [ ] Works in all pane roles (PLAN/WORK/REVIEW)
- [ ] Template messages appropriate for source type

## References

- Current implementation: `bin/agent-handoff:167-205`
- Clipboard utils: `bin/agent-manage:28-66`
- Mouse copy binding: `config/agent-tmux.conf:28-36`
- Keyboard copy mode: `config/agent-tmux.conf:18-26`
- Option+H binding: `config/agent-tmux.conf:127`
