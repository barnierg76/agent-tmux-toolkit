# feat: Smart Compound Engineering Integration

**Created:** 2025-01-04
**Fidelity Level:** 3 (Major feature)
**Category:** Enhancement

## Overview

Transform agent-tmux-toolkit from a session manager into a **compound engineering workflow orchestrator**. Instead of manually picking snippets and copying between panes, the toolkit will understand which phase you're in and orchestrate the PLAN → WORK → REVIEW → COMPOUND loop automatically.

## Problem Statement

**Current state:** The compound-engineering plugin slash commands are accessible via snippets, but integration is manual:
- User must navigate folders to find the right command
- No awareness of which pane (PLAN/WORK/REVIEW) you're in
- No handoff automation between panes
- No prompting for compound step when done
- User must remember the workflow sequence

**Desired state:** The toolkit understands the compound loop and guides you through it:
- Shows only relevant commands for current pane
- Offers to transfer context between panes
- Prompts for next phase when ready
- Auto-suggests /workflows:compound when session ends

## Proposed Solution

Five interconnected features:

```
┌─────────────────────────────────────────────────────────────────┐
│            SMART COMPOUND INTEGRATION                           │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 1. PANE-AWARE SNIPPETS                                   │  │
│  │    Detect current pane → filter to relevant commands     │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              │                                  │
│                              ▼                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 2. WORKFLOW STATE TRACKING                               │  │
│  │    Track phase completion → suggest next step            │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              │                                  │
│                              ▼                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 3. CROSS-PANE HANDOFFS                                   │  │
│  │    Option+h → copy from source → inject to target        │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              │                                  │
│                              ▼                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 4. COMPOUND LOOP COMMANDS                                │  │
│  │    agent-flow: orchestrate full PLAN→WORK→REVIEW→COMPOUND│  │
│  └──────────────────────────────────────────────────────────┘  │
│                              │                                  │
│                              ▼                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 5. SESSION LIFECYCLE HOOKS                               │  │
│  │    On session end → prompt for /workflows:compound       │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Technical Approach

### Feature 1: Pane-Aware Snippets

**Goal:** When you press Option+s, only show snippets relevant to your current pane.

**How it works:**

```bash
# Detect current pane title
current_pane=$(tmux display-message -p '#{pane_title}')

# Filter snippets based on pane
case "$current_pane" in
    PLAN*) show_folders="PLAN|EVERY PLAN|Research" ;;
    WORK*) show_folders="WORK|EVERY WORK|Implementation" ;;
    REVIEW*) show_folders="REVIEW|EVERY REVIEW|Quality" ;;
    *) show_folders=".*" ;;  # Show all if unknown
esac
```

**Implementation:**

#### bin/snippet-picker (modifications)

```bash
#!/bin/bash
# Add at line ~80, before folder selection

# Detect current pane context
CURRENT_PANE=$(tmux display-message -p '#{pane_title}' 2>/dev/null || echo "")

# Map pane to relevant folders
get_pane_folders() {
    case "$CURRENT_PANE" in
        PLAN*)   echo "PLAN|EVERY.*PLAN|Research|Planning" ;;
        WORK*)   echo "WORK|EVERY.*WORK|Implementation|Build" ;;
        REVIEW*) echo "REVIEW|EVERY.*REVIEW|Quality|Test" ;;
        *)       echo ".*" ;;
    esac
}

PANE_FILTER=$(get_pane_folders)

# Filter folders to show (modify line ~85)
if [[ -n "$PANE_FILTER" && "$PANE_FILTER" != ".*" ]]; then
    folders=$(echo "$PARSED_SNIPPETS" | cut -d'/' -f1 | sort -u | grep -E "$PANE_FILTER")

    # Add "📂 All Snippets" option to escape filter
    folder_list="📂 All Snippets"$'\n'"📂 [${CURRENT_PANE}] Suggested"$'\n'
else
    folders=$(echo "$PARSED_SNIPPETS" | cut -d'/' -f1 | sort -u)
    folder_list="📂 All Snippets"$'\n'
fi
```

**User experience:**

```
# In PLAN pane, press Option+s:
┌─────────────────────────────┐
│ › Select folder             │
│                             │
│ 📂 [PLAN] Suggested         │  ← Auto-selected
│ 📁 PLAN                     │
│ 📁 EVERY PLAN               │
│ 📁 Research                 │
│ ─────────────────           │
│ 📂 All Snippets             │  ← Escape hatch
└─────────────────────────────┘
```

---

### Feature 2: Workflow State Tracking

**Goal:** Track where you are in the compound loop and suggest next steps.

**State machine:**

```
                    ┌─────────┐
                    │  IDLE   │
                    └────┬────┘
                         │ start feature
                         ▼
                    ┌─────────┐
            ┌──────▶│ PLANNING│◀──────┐
            │       └────┬────┘       │
            │            │ plan done  │ needs rework
            │            ▼            │
            │       ┌─────────┐       │
            │       │ WORKING │───────┘
            │       └────┬────┘
            │            │ code done
            │            ▼
            │       ┌─────────┐
            │       │REVIEWING│
            │       └────┬────┘
            │            │ review passed
            │            ▼
            │       ┌─────────┐
            └───────│COMPOUND │
                    └────┬────┘
                         │ documented
                         ▼
                    ┌─────────┐
                    │  DONE   │
                    └─────────┘
```

**Implementation:**

#### bin/agent-flow-state (new file)

```bash
#!/bin/bash
# agent-flow-state - Track and suggest workflow state
set -e

STATE_DIR="${HOME}/.cache/agent-tmux"
mkdir -p "$STATE_DIR"

SESSION_NAME="${AGENT_SESSION:-agents}"
STATE_FILE="$STATE_DIR/${SESSION_NAME}.state"

# Commands: get, set, suggest, clear
case "$1" in
    get)
        cat "$STATE_FILE" 2>/dev/null || echo "IDLE"
        ;;
    set)
        echo "$2" > "$STATE_FILE"
        ;;
    suggest)
        current=$(cat "$STATE_FILE" 2>/dev/null || echo "IDLE")
        case "$current" in
            IDLE)     echo "Start with /workflows:plan in PLAN pane" ;;
            PLANNING) echo "Plan ready? Run /workflows:work in WORK pane" ;;
            WORKING)  echo "Code done? Run /workflows:review in REVIEW pane" ;;
            REVIEWING) echo "Review passed? Run /workflows:compound" ;;
            COMPOUND) echo "Document learnings, then mark DONE" ;;
            DONE)     echo "Feature complete! Start next task?" ;;
        esac
        ;;
    clear)
        rm -f "$STATE_FILE"
        ;;
esac
```

**Integration with snippets:**

When showing snippets, add suggestion header:

```bash
# In snippet-picker, add after folder selection
suggestion=$(agent-flow-state suggest)
header="Select snippet | 💡 $suggestion"
```

---

### Feature 3: Cross-Pane Handoffs

**Goal:** One command to transfer context between panes with smart formatting.

**Keybinding:** Option+h (handoff)

**Implementation:**

#### bin/agent-handoff (new file)

```bash
#!/bin/bash
# agent-handoff - Transfer context between panes
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SESSION_NAME="${AGENT_SESSION:-agents}"

# Get pane info
get_panes() {
    tmux list-panes -t "$SESSION_NAME" -F "#{pane_index}|#{pane_title}" 2>/dev/null
}

# Handoff templates based on source→target
get_handoff_template() {
    local from="$1" to="$2"

    case "${from}→${to}" in
        PLAN*→WORK*)
            echo "Here's the plan to implement:\n\n---\n"
            ;;
        WORK*→REVIEW*)
            echo "Please review this implementation:\n\n---\n"
            ;;
        REVIEW*→WORK*)
            echo "Review feedback to address:\n\n---\n"
            ;;
        REVIEW*→PLAN*)
            echo "Issues found that need re-planning:\n\n---\n"
            ;;
        *)
            echo "Context from ${from}:\n\n---\n"
            ;;
    esac
}

# Main flow
main() {
    local panes=$(get_panes)

    # Select source pane
    echo -e "${BLUE}Select source pane:${NC}"
    local source=$(echo "$panes" | fzf \
        --height=40% \
        --layout=reverse \
        --delimiter='|' \
        --with-nth=2 \
        --preview="tmux capture-pane -p -t '$SESSION_NAME.{1}' | tail -20" \
        --preview-window=right:50%)

    [ -z "$source" ] && exit 0

    local source_idx=$(echo "$source" | cut -d'|' -f1)
    local source_title=$(echo "$source" | cut -d'|' -f2)

    # Select target pane (exclude source)
    echo -e "${BLUE}Select target pane:${NC}"
    local target=$(echo "$panes" | grep -v "^$source_idx|" | fzf \
        --height=40% \
        --layout=reverse \
        --delimiter='|' \
        --with-nth=2)

    [ -z "$target" ] && exit 0

    local target_idx=$(echo "$target" | cut -d'|' -f1)
    local target_title=$(echo "$target" | cut -d'|' -f2)

    # Capture source content
    local content=$(tmux capture-pane -p -t "$SESSION_NAME.$source_idx" | \
        sed 's/\x1b\[[0-9;]*m//g' | \
        grep -v '^$' | tail -50)

    # Get template
    local template=$(get_handoff_template "$source_title" "$target_title")

    # Format handoff
    local handoff="${template}${content}\n---\n"

    # Send to target
    echo -e "$handoff" | tmux load-buffer -
    tmux paste-buffer -t "$SESSION_NAME.$target_idx"

    echo -e "${GREEN}✓ Handoff: $source_title → $target_title${NC}"

    # Update workflow state
    case "$target_title" in
        WORK*)   agent-flow-state set WORKING ;;
        REVIEW*) agent-flow-state set REVIEWING ;;
        PLAN*)   agent-flow-state set PLANNING ;;
    esac
}

main "$@"
```

#### config/agent-tmux.conf (add keybinding)

```bash
# Handoff between panes
bind -n M-h display-popup -w 60% -h 50% -E "~/.local/bin/agent-handoff"
```

**User experience:**

```
# Press Option+h
┌─────────────────────────────┐
│ Select source pane:         │
│                             │
│ > PLAN                      │  ← Shows preview
│   WORK                      │
│   REVIEW                    │
└─────────────────────────────┘

# After selecting PLAN → WORK:
"Here's the plan to implement:

---
[Last 50 lines from PLAN pane]
---"

# Automatically injected into WORK pane
```

---

### Feature 4: Compound Loop Commands

**Goal:** Single commands that orchestrate the full workflow.

#### bin/agent-flow (new file)

```bash
#!/bin/bash
# agent-flow - Orchestrate compound engineering workflow
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SESSION_NAME="${AGENT_SESSION:-agents}"

show_menu() {
    cat << 'EOF'
━━━ COMPOUND WORKFLOW ━━━
🎯 Start Feature     Start /workflows:plan in PLAN pane
📋 Plan → Work       Handoff plan to WORK, start /workflows:work
⚙️  Work → Review    Handoff code to REVIEW, start /workflows:review
📝 Compound          Run /workflows:compound to document learnings
━━━ QUICK ACTIONS ━━━
🔄 Sync All          Show current pane contents in all others
📊 Status            Show workflow state and pane status
🧹 Reset             Clear workflow state, start fresh
EOF
}

cmd_start_feature() {
    echo -e "${BLUE}Starting feature workflow...${NC}"

    # Focus PLAN pane
    tmux select-pane -t "$SESSION_NAME.0"

    # Send /workflows:plan command
    tmux send-keys -t "$SESSION_NAME.0" "/workflows:plan "

    # Update state
    agent-flow-state set PLANNING

    echo -e "${GREEN}✓ Switched to PLAN pane${NC}"
    echo -e "${CYAN}Enter your feature description and press Enter${NC}"
}

cmd_plan_to_work() {
    echo -e "${BLUE}Transitioning Plan → Work...${NC}"

    # Capture plan summary (last 100 lines)
    local plan=$(tmux capture-pane -p -t "$SESSION_NAME.0" | tail -100)

    # Focus WORK pane
    tmux select-pane -t "$SESSION_NAME.1"

    # Inject context
    tmux send-keys -t "$SESSION_NAME.1" "# Plan to implement:"
    tmux send-keys -t "$SESSION_NAME.1" Enter
    tmux send-keys -t "$SESSION_NAME.1" "/workflows:work "

    # Update state
    agent-flow-state set WORKING

    echo -e "${GREEN}✓ Ready to work. Plan context available.${NC}"
}

cmd_work_to_review() {
    echo -e "${BLUE}Transitioning Work → Review...${NC}"

    # Focus REVIEW pane
    tmux select-pane -t "$SESSION_NAME.2"

    # Send review command
    tmux send-keys -t "$SESSION_NAME.2" "/workflows:review "

    # Update state
    agent-flow-state set REVIEWING

    echo -e "${GREEN}✓ Switched to REVIEW pane${NC}"
}

cmd_compound() {
    echo -e "${BLUE}Starting compound step...${NC}"

    # Can run in any pane
    tmux send-keys "/workflows:compound "

    # Update state
    agent-flow-state set COMPOUND

    echo -e "${GREEN}✓ Document your learnings${NC}"
}

cmd_status() {
    echo -e "${BLUE}━━━ WORKFLOW STATUS ━━━${NC}"
    echo ""

    # Current state
    local state=$(agent-flow-state get)
    echo -e "Phase: ${CYAN}$state${NC}"
    echo -e "Next:  ${YELLOW}$(agent-flow-state suggest)${NC}"
    echo ""

    # Pane status
    echo -e "${BLUE}━━━ PANES ━━━${NC}"
    tmux list-panes -t "$SESSION_NAME" -F "#{pane_index}: #{pane_title} (#{pane_current_command})"
}

# Main menu
main() {
    local choice=$(show_menu | fzf \
        --height=60% \
        --layout=reverse \
        --border=rounded \
        --prompt="› " \
        --header="Compound Engineering Flow" \
        --with-nth=2..)

    [ -z "$choice" ] && exit 0

    case "$choice" in
        *"Start Feature"*)  cmd_start_feature ;;
        *"Plan → Work"*)    cmd_plan_to_work ;;
        *"Work → Review"*)  cmd_work_to_review ;;
        *"Compound"*)       cmd_compound ;;
        *"Status"*)         cmd_status; read -p "Press Enter..." ;;
        *"Reset"*)          agent-flow-state clear; echo "Reset." ;;
    esac
}

main "$@"
```

#### config/agent-tmux.conf (add keybinding)

```bash
# Compound workflow orchestrator
bind -n M-f display-popup -w 50% -h 60% -E "~/.local/bin/agent-flow"
```

**User experience:**

```
# Press Option+f (flow)
┌─────────────────────────────────────────┐
│ › Compound Engineering Flow             │
│                                         │
│ ━━━ COMPOUND WORKFLOW ━━━               │
│ 🎯 Start Feature                        │
│ 📋 Plan → Work                          │
│ ⚙️  Work → Review                        │
│ 📝 Compound                             │
│ ━━━ QUICK ACTIONS ━━━                   │
│ 📊 Status                               │
│ 🧹 Reset                                │
└─────────────────────────────────────────┘
```

---

### Feature 5: Session Lifecycle Hooks

**Goal:** Prompt for compound step when session ends.

#### config/agent-tmux.conf (add hooks)

```bash
# Prompt for compound on session close
set-hook -g client-detached 'run-shell "~/.local/bin/agent-flow-prompt detach"'

# Optional: Alert when pane idle for 60s (agent waiting)
set -g monitor-silence 60
set-hook -g alert-silence 'run-shell "~/.local/bin/agent-notify \"Agent Waiting\" \"Pane idle - needs input?\""'
```

#### bin/agent-flow-prompt (new file)

```bash
#!/bin/bash
# agent-flow-prompt - Prompt for workflow actions on events

STATE=$(agent-flow-state get 2>/dev/null || echo "IDLE")

case "$1" in
    detach)
        # Only prompt if in active workflow
        if [[ "$STATE" != "IDLE" && "$STATE" != "DONE" ]]; then
            # Show notification
            agent-notify "Workflow Active" "State: $STATE. Remember to /workflows:compound!"
        fi
        ;;
    idle)
        agent-notify "Agent Idle" "$(agent-flow-state suggest)"
        ;;
esac
```

---

## Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `bin/snippet-picker` | Modify | Add pane-aware filtering |
| `bin/agent-flow` | Create | Workflow orchestrator |
| `bin/agent-flow-state` | Create | State tracking |
| `bin/agent-handoff` | Create | Cross-pane context transfer |
| `bin/agent-flow-prompt` | Create | Lifecycle prompts |
| `config/agent-tmux.conf` | Modify | Add keybindings and hooks |
| `config/snippets.txt` | Modify | Reorganize folders for pane-awareness |
| `install.sh` | Modify | Install new scripts |

---

## New Keybindings

| Key | Command | Description |
|-----|---------|-------------|
| `Option+s` | snippet-picker | Now pane-aware |
| `Option+h` | agent-handoff | Transfer context between panes |
| `Option+f` | agent-flow | Workflow orchestrator menu |

---

## Acceptance Criteria

### Feature 1: Pane-Aware Snippets
- [ ] In PLAN pane, shows PLAN-related snippets first
- [ ] In WORK pane, shows WORK-related snippets first
- [ ] In REVIEW pane, shows REVIEW-related snippets first
- [ ] "All Snippets" option bypasses filter

### Feature 2: Workflow State
- [ ] State persists across pane switches
- [ ] Suggestion shown in snippet header
- [ ] State updates on handoffs

### Feature 3: Cross-Pane Handoffs
- [ ] Option+h opens handoff picker
- [ ] Preview shows source pane content
- [ ] Template text prefixes based on source→target
- [ ] Content injected to target pane

### Feature 4: Compound Loop Commands
- [ ] Option+f opens workflow menu
- [ ] "Start Feature" focuses PLAN, sends /workflows:plan
- [ ] "Plan → Work" transitions with context
- [ ] "Compound" sends /workflows:compound
- [ ] Status shows current phase

### Feature 5: Lifecycle Hooks
- [ ] Notification on detach if workflow active
- [ ] Optional idle notification after 60s

---

## Success Metrics

- Reduce clicks from 4 (folder → snippet → confirm → send) to 2
- Workflow state visible at all times
- Handoffs take <3 seconds
- Zero manual copy-paste between panes needed
- Compound step suggested automatically

---

## References

### Internal
- `bin/snippet-picker:80-120` - Folder filtering logic
- `bin/agent-manage:118-140` - Pane resolution pattern
- `config/agent-tmux.conf:97-105` - Existing hook patterns

### External
- [Compound Engineering: How Every Codes With Agents](https://every.to/chain-of-thought/compound-engineering-how-every-codes-with-agents)
- [EveryInc/compound-engineering-plugin](https://github.com/EveryInc/compound-engineering-plugin)
- [tmux Hooks Documentation](https://man7.org/linux/man-pages/man1/tmux.1.html)
- [tmux send-keys Patterns](https://linuxhaxor.net/code/tmux-send-keys.html)
