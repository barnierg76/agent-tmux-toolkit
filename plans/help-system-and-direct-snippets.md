# feat: Help System and Direct Context-Aware Snippets

## Overview

Add two quality-of-life improvements to the agent-tmux-toolkit:

1. **Help System** - A `?` shortcut (and menu option) that displays keyboard shortcuts and command reference
2. **Direct Context-Aware Snippets** - Skip folder selection and show relevant snippets directly in context-aware mode

## Problem Statement

**Help System:**
- Users have no quick way to see available keyboard shortcuts
- Each command has `--help` but no unified reference
- No in-app help during fzf menu interactions
- The `?` keybinding is currently unused and available

**Context-Aware Snippets:**
- Current flow requires two selections: folder → snippet
- When context is detected (PLAN/WORK/REVIEW), showing folders first adds friction
- Users want to go straight to the relevant snippets

## Proposed Solution

### Feature 1: Help System

Add `?` keybinding that shows a tmux popup with:
- All keyboard shortcuts (Option+S, Option+M, etc.)
- Available commands (agent-session, agent-manage, etc.)
- Quick reference for snippet picker navigation

**Implementation:**
1. Create `bin/agent-help` command
2. Add `bind -n M-? display-popup` in `config/agent-tmux.conf`
3. Add `?` binding in fzf menus via `--bind='?:execute(...)'`

### Feature 2: Direct Snippets

When pane context is detected, show snippets directly instead of folders:
- PLAN pane → Show all snippets from PLAN + EVERY + HANDOFF folders
- WORK pane → Show all snippets from WORK + EVERY + QUICK folders
- REVIEW pane → Show all snippets from REVIEW + EVERY folders

**Escape hatch:** Add "Browse All Folders" as first option to access full folder view

**Display format:** Prefix snippets with folder name: `[PLAN] Create Implementation Plan`

## Technical Approach

### Files to Modify

| File | Changes |
|------|---------|
| `bin/agent-help` | **NEW** - Help display command |
| `bin/snippet-picker` | Modify lines 124-247 to show snippets directly |
| `config/agent-tmux.conf` | Add `M-?` binding around line 120 |
| `install.sh` | Add agent-help to installation |

### Help Command Implementation

```bash
# bin/agent-help (new file)
#!/bin/bash
# agent-help - Quick reference for agent-tmux-toolkit

show_help() {
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║                    AGENT TMUX TOOLKIT                         ║
╠═══════════════════════════════════════════════════════════════╣
║  KEYBOARD SHORTCUTS                                           ║
╠═══════════════════════════════════════════════════════════════╣
║  Option+S        Snippet picker (context-aware)               ║
║  Option+Space    Snippet picker (alternate)                   ║
║  Option+M        Agent manager menu                           ║
║  Option+F        Flow orchestrator                            ║
║  Option+H        Handoff between panes                        ║
║  Option+D        Status dashboard                             ║
║  Option+1/2/3    Jump to pane 1/2/3                           ║
║  Option+Arrows   Navigate between panes                       ║
║  Option+</>      Swap panes left/right                        ║
║  Option+Backspace Clear current line                          ║
║  Option+?        This help screen                             ║
╠═══════════════════════════════════════════════════════════════╣
║  SNIPPET PICKER                                               ║
╠═══════════════════════════════════════════════════════════════╣
║  Enter           Select snippet/folder                        ║
║  ←               Go back to folders / Cancel                  ║
║  ESC             Cancel completely                            ║
║  Type            Filter snippets                              ║
╠═══════════════════════════════════════════════════════════════╣
║  COMMANDS                                                     ║
╠═══════════════════════════════════════════════════════════════╣
║  agent-session   Create new agent session                     ║
║  agent-manage    Interactive session manager                  ║
║  agent-flow      Workflow orchestrator                        ║
║  agent-handoff   Transfer context between panes               ║
║  agent-status    View agent status dashboard                  ║
║  snippet-picker  Open snippet picker                          ║
║  snippet-edit    Edit snippets file                           ║
╠═══════════════════════════════════════════════════════════════╣
║  Press q or ESC to close                                      ║
╚═══════════════════════════════════════════════════════════════╝
EOF
}

# If in tmux, use less for scrolling
if [[ -n "$TMUX" ]]; then
    show_help | less -R
else
    show_help
fi
```

### Snippet Picker Modification

**Current flow (lines 124-207):**
```
folder_selection → user picks folder → snippet_selection
```

**New flow:**
```
if context_detected:
    direct_snippet_selection (with "Browse All Folders" as first option)
else:
    folder_selection → snippet_selection (unchanged)
```

**Key changes to `bin/snippet-picker`:**

```bash
# After line 37, add new function:
get_direct_snippets() {
    local context="$1"
    local filter_pattern

    case "$context" in
        PLAN)   filter_pattern="^(PLAN|EVERY|HANDOFF)/" ;;
        WORK)   filter_pattern="^(WORK|EVERY|QUICK)/" ;;
        REVIEW) filter_pattern="^(REVIEW|EVERY)/" ;;
        *)      return 1 ;;  # No direct mode
    esac

    # Return snippets with folder prefix: [FOLDER] Label
    parse_snippets | grep -E "$filter_pattern" | \
        awk -F'/' '{folder=$1; label=$2; gsub(/\t.*/, "", label); print "["folder"] "label"\t"$0}'
}

# Modify main loop around line 124:
# Check if we should use direct mode
pane_context=$(detect_pane_context)
direct_snippets=$(get_direct_snippets "$pane_context" 2>/dev/null || echo "")

if [[ -n "$direct_snippets" ]]; then
    # Direct mode: show snippets with escape hatch
    selection=$(echo -e "Browse All Folders\n$direct_snippets" | \
        fzf --height=80% \
            --layout=reverse \
            --border=rounded \
            --prompt="[$pane_context] › " \
            --header="Select snippet (← back, ? help, ESC quit)" \
            --bind='left:abort' \
            --bind='?:execute(agent-help)' \
            --expect='left' \
            --delimiter=$'\t' \
            --with-nth=1)

    if [[ "$selection" == *"Browse All Folders"* ]]; then
        # Fall through to folder selection
        direct_snippets=""
    fi
fi

if [[ -z "$direct_snippets" ]]; then
    # Original folder selection flow
    # ... existing code ...
fi
```

### tmux Config Addition

```bash
# config/agent-tmux.conf - add around line 120:
# Help screen (Option+?)
bind -n M-? display-popup -w 70 -h 25 -E "~/.local/bin/agent-help"
```

## Acceptance Criteria

### Help System
- [ ] `Option+?` shows help popup from any pane
- [ ] `?` within fzf menus shows context-relevant help
- [ ] Help displays all keyboard shortcuts
- [ ] Help displays available commands
- [ ] Press `q` or `ESC` to close help
- [ ] `agent-help --help` shows usage

### Direct Snippets
- [ ] PLAN pane shows PLAN+EVERY+HANDOFF snippets directly
- [ ] WORK pane shows WORK+EVERY+QUICK snippets directly
- [ ] REVIEW pane shows REVIEW+EVERY snippets directly
- [ ] "Browse All Folders" option appears first
- [ ] Selecting "Browse All Folders" shows original folder view
- [ ] Snippets prefixed with folder name: `[PLAN] Label`
- [ ] Left arrow cancels (same as before)
- [ ] ESC cancels completely (same as before)
- [ ] When no context detected, shows folder view (fallback)

## MVP Implementation

### bin/agent-help

```bash
#!/bin/bash
# agent-help - Quick reference for agent-tmux-toolkit
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

show_usage() {
    cat << 'EOF'
agent-help - Quick reference for agent-tmux-toolkit

USAGE:
    agent-help [options]

OPTIONS:
    --help, -h    Show this help message
    --keys        Show only keyboard shortcuts
    --commands    Show only commands

EXAMPLES:
    agent-help           # Show full help
    agent-help --keys    # Show keyboard shortcuts only
EOF
}

show_keys() {
    cat << 'EOF'
═══════════════════════════════════════════════════════════════
 KEYBOARD SHORTCUTS
═══════════════════════════════════════════════════════════════
 Option+S        Snippet picker (context-aware)
 Option+Space    Snippet picker (alternate)
 Option+M        Agent manager menu
 Option+F        Flow orchestrator
 Option+H        Handoff between panes
 Option+D        Status dashboard
 Option+1/2/3    Jump to pane 1/2/3
 Option+Arrows   Navigate between panes
 Option+</>      Swap panes left/right
 Option+Backspace Clear current line
 Option+?        This help screen
═══════════════════════════════════════════════════════════════
EOF
}

show_commands() {
    cat << 'EOF'
═══════════════════════════════════════════════════════════════
 COMMANDS
═══════════════════════════════════════════════════════════════
 agent-session   Create new agent session (3-pane layout)
 agent-manage    Interactive session manager
 agent-flow      Workflow orchestrator (plan/work/review)
 agent-handoff   Transfer context between panes
 agent-status    View agent status dashboard
 agent-worktree  Git worktree management
 agent-delegate  Spawn parallel agents
 agent-notify    Desktop notifications
 snippet-picker  Open snippet picker
 snippet-edit    Edit snippets file in $EDITOR
═══════════════════════════════════════════════════════════════
EOF
}

show_snippets() {
    cat << 'EOF'
═══════════════════════════════════════════════════════════════
 SNIPPET PICKER NAVIGATION
═══════════════════════════════════════════════════════════════
 Enter           Select snippet/folder
 ← (Left arrow)  Go back to folders / Cancel
 ESC             Cancel completely
 Type            Filter snippets by name
 ?               Show this help
═══════════════════════════════════════════════════════════════
 CONTEXT DETECTION
═══════════════════════════════════════════════════════════════
 In PLAN pane:   Shows PLAN, EVERY, HANDOFF snippets
 In WORK pane:   Shows WORK, EVERY, QUICK snippets
 In REVIEW pane: Shows REVIEW, EVERY snippets

 Select "Browse All Folders" for full folder view
═══════════════════════════════════════════════════════════════
EOF
}

show_full_help() {
    echo -e "${BOLD}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║              AGENT TMUX TOOLKIT - QUICK REFERENCE             ║${NC}"
    echo -e "${BOLD}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo
    show_keys
    echo
    show_commands
    echo
    show_snippets
    echo
    echo -e "${DIM}Press q or ESC to close${NC}"
}

case "${1:-}" in
    --help|-h)
        show_usage
        exit 0
        ;;
    --keys)
        show_keys
        exit 0
        ;;
    --commands)
        show_commands
        exit 0
        ;;
    *)
        if [[ -n "$TMUX" ]]; then
            show_full_help | less -R
        else
            show_full_help
        fi
        ;;
esac
```

### config/agent-tmux.conf addition

```bash
# Help screen (Option+?)
bind -n M-? display-popup -w 70 -h 30 -E "~/.local/bin/agent-help"
```

### install.sh modification

Add `agent-help` to the list of scripts to install (around line 32):

```bash
SCRIPTS=(
    "agent-session"
    "agent-manage"
    # ... existing scripts ...
    "agent-help"  # ADD THIS
)
```

## Dependencies & Risks

**Dependencies:**
- tmux 3.2+ for `display-popup` (already required)
- fzf for menu interactions (already required)

**Risks:**
- Low: `M-?` might conflict with some terminal emulators (can use `prefix+?` as fallback)
- Low: Direct snippet mode changes UX - users may need to adjust

## Testing Checklist

- [ ] Fresh install works with new `agent-help` command
- [ ] `Option+?` opens help popup in tmux
- [ ] Help popup closes with `q` or `ESC`
- [ ] Snippet picker in PLAN pane shows direct snippets
- [ ] "Browse All Folders" opens folder view
- [ ] Left arrow cancels from direct snippet view
- [ ] Fallback to folder view when no context detected
- [ ] All existing snippet functionality preserved

## References

- Existing patterns: `bin/agent-status:14-31` (help format)
- Menu patterns: `bin/agent-manage:633-805` (fzf usage)
- Snippet parsing: `bin/snippet-picker:58-112` (AWK parser)
- Context detection: `bin/snippet-picker:9-26` (pane role detection)
- tmux bindings: `config/agent-tmux.conf:61-117` (existing shortcuts)
