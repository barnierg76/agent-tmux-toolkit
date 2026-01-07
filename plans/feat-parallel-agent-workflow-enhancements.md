# feat: Parallel Agent Workflow Enhancements

**Created:** 2025-01-04
**Fidelity Level:** 3 (Major feature set)
**Category:** Enhancement

## Overview

Enhance agent-tmux-toolkit with features inspired by AI coding agent community best practices for running parallel agents. This plan synthesizes learnings from official documentation, Simon Willison's parallel agent patterns, and community workflows into actionable improvements.

The goal: transform agent-tmux-toolkit from a basic session manager into a **parallel agent orchestration system** that supports the modern AI-assisted development workflow.

## Problem Statement / Motivation

**Current Pain Points:**

1. **Manual clipboard workflow** - No quick way to extract agent output for pasting elsewhere
2. **No worktree integration** - Users must manually create git worktrees for parallel work
3. **Generic session names** - Hard to identify which session corresponds to which task
4. **Single-agent focus** - No tooling for delegating work across multiple agents
5. **No status overview** - Must check each session individually to see agent state
6. **Silent completion** - No notification when an agent needs input or finishes

**Community Evidence:**

> "The process involves spinning up agents, allowing them to run unsupervised, then reviewing changes afterward."
> — [WorksForNow: How I Run Claude Code Agents in Parallel](https://worksfornow.pika.page/posts/note-to-a-friend-how-i-run-claude-code-agents-in-parallel)

> "Git worktrees are commonly used for parallel workflows... allows you to clone and branch a git repository into another directory."
> — [Simon Willison: Parallel Coding Agents](https://simonwillison.net/2025/Oct/5/parallel-coding-agents/)

> "Sessions are named after task IDs, allowing easy navigation between concurrent work streams."
> — AI coding community patterns

## Proposed Solution

A phased rollout of 6 interconnected features:

```
┌─────────────────────────────────────────────────────────────────┐
│                 PARALLEL AGENT TOOLKIT v2.0                     │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ 📋 COPY PANE │  │ 🌳 WORKTREE  │  │ 🏷️  TASK     │          │
│  │              │  │              │  │    NAMING    │          │
│  │ Quick copy   │  │ Git worktree │  │              │          │
│  │ to clipboard │  │ integration  │  │ Semantic IDs │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ 🚀 DELEGATE  │  │ 📊 DASHBOARD │  │ 🔔 NOTIFY    │          │
│  │              │  │              │  │              │          │
│  │ Spin up N    │  │ All-session  │  │ macOS alerts │          │
│  │ parallel     │  │ status view  │  │ when agent   │          │
│  │ agents       │  │              │  │ needs input  │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                 │
│         All features accessible via agent-manage popup          │
└─────────────────────────────────────────────────────────────────┘
```

## Technical Approach

### Architecture

```
bin/
├── agent-manage          # Enhanced with new commands
├── agent-session         # Enhanced with --task flag
├── agent-delegate        # NEW: Multi-agent spawner
├── agent-status          # NEW: Dashboard viewer
├── agent-worktree        # NEW: Git worktree helper
├── snippet-picker        # Existing
└── snippet-edit          # Existing

config/
├── agent-tmux.conf       # Add new keybindings
└── snippets.txt          # Existing
```

### Implementation Phases

---

## Phase 1: Copy Pane to Clipboard

**Priority:** High (Quick win, immediate value)

### Description
Add "Copy pane" action to agent-manage popup menu.

### Implementation

#### bin/agent-manage (modifications)

```bash
# Add utility function (~line 20)
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
        return 1
    fi
}

# Add command function (~line 240)
cmd_copy() {
    check_session

    local panes
    panes=$(tmux list-panes -t "$SESSION_NAME" \
        -F "#{pane_index}|#{pane_title}|#{pane_current_command}" 2>/dev/null)

    if [ -z "$panes" ]; then
        echo -e "${RED}No panes found${NC}"
        return 1
    fi

    local display=""
    while IFS='|' read -r idx title cmd; do
        display+="$idx: $title ($cmd)"$'\n'
    done <<< "$panes"

    local selected
    selected=$(echo -e "$display" | sed '/^$/d' | fzf \
        --height=50% \
        --layout=reverse \
        --border=rounded \
        --prompt="Select pane › " \
        --header="Copy pane to clipboard" \
        --preview="tmux capture-pane -p -S -20 -t '$SESSION_NAME.{1}' 2>/dev/null | head -20" \
        --preview-window=right:50%:wrap)

    [ -z "$selected" ] && return 0

    local pane_idx
    pane_idx=$(echo "$selected" | cut -d: -f1 | tr -d ' ')

    local content
    content=$(tmux capture-pane -p -t "$SESSION_NAME.$pane_idx" 2>/dev/null | \
        sed 's/\x1b\[[0-9;]*m//g')

    if [ -z "$(echo "$content" | tr -d '[:space:]')" ]; then
        echo -e "${YELLOW}⚠ Pane is empty${NC}"
        return 0
    fi

    copy_to_clipboard "$content" || return 1

    local lines=$(echo "$content" | wc -l | tr -d ' ')
    echo -e "${GREEN}✓ Copied $lines lines${NC}"
    sleep 1
}
```

### Acceptance Criteria
- [ ] "📋 Copy pane" appears in agent-manage menu
- [ ] fzf shows pane list with preview
- [ ] Content copied to system clipboard
- [ ] Works on macOS, Linux, WSL

---

## Phase 2: Task-Based Session Naming

**Priority:** High (Foundation for other features)

### Description
Enable semantic session names tied to task IDs for easy navigation.

### Implementation

#### bin/agent-session (modifications)

```bash
#!/bin/bash
# agent-session - Create agent tmux session with optional task ID
set -e

TASK_ID=""
SESSION_NAME="agent"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --task|-t)
            TASK_ID="$2"
            SESSION_NAME="agent-${TASK_ID}"
            shift 2
            ;;
        --name|-n)
            SESSION_NAME="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Rest of existing implementation with $SESSION_NAME
```

#### Usage Examples

```bash
# Create session for task 42
agent-session --task 42
# Creates: agent-42

# Create session for feature branch
agent-session --task auth-refactor
# Creates: agent-auth-refactor

# List all agent sessions
tmux list-sessions | grep "^agent-"
```

### Acceptance Criteria
- [ ] `agent-session --task <id>` creates named session
- [ ] Session name follows pattern `agent-<task-id>`
- [ ] Works with existing agent-manage commands
- [ ] Backward compatible (no args = "agent" session)

---

## Phase 3: Git Worktree Integration

**Priority:** High (Critical for parallel work)

### Description
Integrate git worktree creation with agent session spawning for isolated parallel development.

### Implementation

#### bin/agent-worktree (new file)

```bash
#!/bin/bash
# agent-worktree - Create git worktree + tmux session for parallel work
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
    echo "Usage: agent-worktree <branch-name> [base-branch]"
    echo ""
    echo "Creates a git worktree and tmux session for parallel agent work."
    echo ""
    echo "Arguments:"
    echo "  branch-name   Name for new branch and session"
    echo "  base-branch   Branch to create from (default: current branch)"
    echo ""
    echo "Example:"
    echo "  agent-worktree feat-auth main"
    exit 1
}

[ -z "$1" ] && usage

BRANCH_NAME="$1"
BASE_BRANCH="${2:-HEAD}"
WORKTREE_DIR="../${PWD##*/}-${BRANCH_NAME}"
SESSION_NAME="agent-${BRANCH_NAME}"

# Verify git repo
if ! git rev-parse --git-dir &>/dev/null; then
    echo -e "${RED}Error: Not a git repository${NC}"
    exit 1
fi

# Check if branch exists
if git show-ref --verify --quiet "refs/heads/${BRANCH_NAME}"; then
    echo -e "${YELLOW}Branch '${BRANCH_NAME}' exists, checking out${NC}"
    git worktree add "$WORKTREE_DIR" "$BRANCH_NAME" 2>/dev/null || {
        echo -e "${RED}Worktree may already exist at $WORKTREE_DIR${NC}"
        exit 1
    }
else
    echo -e "${GREEN}Creating new branch '${BRANCH_NAME}' from ${BASE_BRANCH}${NC}"
    git worktree add -b "$BRANCH_NAME" "$WORKTREE_DIR" "$BASE_BRANCH"
fi

# Create tmux session in worktree
cd "$WORKTREE_DIR"
agent-session --task "$BRANCH_NAME"

echo -e "${GREEN}✓ Created worktree at: $WORKTREE_DIR${NC}"
echo -e "${GREEN}✓ Session: $SESSION_NAME${NC}"
echo ""
echo "To attach: tmux attach -t $SESSION_NAME"
```

#### bin/agent-manage (add worktree command)

```bash
cmd_worktree() {
    echo -e "${BLUE}Create Git Worktree + Agent Session${NC}"
    echo ""

    # Get branch name
    local branch
    read -p "Branch name: " branch
    [ -z "$branch" ] && return 0

    # Get base branch
    local base
    read -p "Base branch (Enter for current): " base

    # Create worktree and session
    agent-worktree "$branch" "$base"
}
```

### Acceptance Criteria
- [ ] `agent-worktree <name>` creates worktree + session
- [ ] New branch created from specified base
- [ ] Session auto-starts in worktree directory
- [ ] Works with agent-manage menu

---

## Phase 4: Multi-Agent Delegation

**Priority:** Medium (Power user feature)

### Description
Spawn multiple parallel agent sessions from a single command, inspired by the `/delegate` pattern.

### Implementation

#### bin/agent-delegate (new file)

```bash
#!/bin/bash
# agent-delegate - Spawn multiple parallel agent sessions
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    echo "Usage: agent-delegate <task-1> [task-2] [task-3] ..."
    echo ""
    echo "Spawns parallel agent sessions for each task."
    echo ""
    echo "Options:"
    echo "  --worktree    Also create git worktrees (requires git repo)"
    echo ""
    echo "Examples:"
    echo "  agent-delegate auth-fix api-refactor tests"
    echo "  agent-delegate --worktree feat-1 feat-2 feat-3"
    exit 1
}

[ -z "$1" ] && usage

USE_WORKTREE=false
TASKS=()

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --worktree|-w)
            USE_WORKTREE=true
            shift
            ;;
        --help|-h)
            usage
            ;;
        *)
            TASKS+=("$1")
            shift
            ;;
    esac
done

[ ${#TASKS[@]} -eq 0 ] && usage

echo -e "${BLUE}Delegating ${#TASKS[@]} tasks...${NC}"
echo ""

for task in "${TASKS[@]}"; do
    echo -e "${GREEN}→ Spawning agent-${task}${NC}"

    if [ "$USE_WORKTREE" = true ]; then
        agent-worktree "$task" &
    else
        agent-session --task "$task" &
    fi

    sleep 0.5  # Stagger session creation
done

wait

echo ""
echo -e "${GREEN}✓ All agents spawned${NC}"
echo ""
echo "Sessions created:"
tmux list-sessions | grep "^agent-" | sed 's/^/  /'
echo ""
echo "Attach with: tmux attach -t agent-<task>"
```

#### Menu Integration

```bash
# Add to agent-manage menu
"🚀 Delegate tasks"

# Handler
"🚀 Delegate tasks")
    echo "Enter task names (space-separated):"
    read -p "> " tasks
    [ -n "$tasks" ] && agent-delegate $tasks
    ;;
```

### Acceptance Criteria
- [ ] `agent-delegate task1 task2 task3` creates 3 sessions
- [ ] `--worktree` flag creates git worktrees too
- [ ] Sessions created in parallel (non-blocking)
- [ ] Summary shows all created sessions

---

## Phase 5: Agent Status Dashboard

**Priority:** Medium (Monitoring capability)

### Description
View status of all agent sessions at a glance—which are active, waiting for input, or completed.

### Implementation

#### bin/agent-status (new file)

```bash
#!/bin/bash
# agent-status - Dashboard view of all agent sessions
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}━━━ AGENT STATUS DASHBOARD ━━━${NC}"
echo ""

# Get all agent sessions
sessions=$(tmux list-sessions -F "#{session_name}|#{session_windows}|#{session_attached}" 2>/dev/null | grep "^agent" || true)

if [ -z "$sessions" ]; then
    echo -e "${YELLOW}No agent sessions found${NC}"
    exit 0
fi

printf "%-20s %-10s %-12s %-30s\n" "SESSION" "WINDOWS" "STATUS" "LAST OUTPUT"
printf "%-20s %-10s %-12s %-30s\n" "-------" "-------" "------" "-----------"

while IFS='|' read -r name windows attached; do
    # Determine status
    if [ "$attached" = "1" ]; then
        status="${GREEN}● Active${NC}"
    else
        # Check if waiting for input (simplified heuristic)
        last_line=$(tmux capture-pane -t "$name:0.0" -p 2>/dev/null | tail -1)
        if [[ "$last_line" == *"?"* ]] || [[ "$last_line" == *">"* ]] || [[ "$last_line" == *"$"* ]]; then
            status="${YELLOW}◐ Waiting${NC}"
        else
            status="${CYAN}○ Running${NC}"
        fi
    fi

    # Get last output snippet
    last_output=$(tmux capture-pane -t "$name:0.0" -p 2>/dev/null | grep -v '^$' | tail -1 | cut -c1-28)
    [ -z "$last_output" ] && last_output="-"

    printf "%-20s %-10s %-12b %-30s\n" "$name" "$windows" "$status" "$last_output"
done <<< "$sessions"

echo ""
echo -e "${BLUE}Commands:${NC}"
echo "  tmux attach -t <session>  - Attach to session"
echo "  agent-manage              - Open management popup"
```

#### agent-manage integration

```bash
cmd_status_all() {
    agent-status
    echo ""
    read -p "Press Enter to continue..."
}

# Menu option
"📊 All sessions status"
```

### Acceptance Criteria
- [ ] `agent-status` shows all agent sessions
- [ ] Status indicates: Active/Waiting/Running
- [ ] Shows last output line for context
- [ ] Available via agent-manage menu

---

## Phase 6: Completion Notifications

**Priority:** Low (Nice to have)

### Description
macOS notifications when an agent session needs input or completes a task.

### Implementation

#### config/agent-tmux.conf (additions)

```bash
# Monitor for activity/silence
set -g monitor-activity on
set -g monitor-silence 30

# Hook for notifications (macOS)
set-hook -g alert-activity 'run-shell "osascript -e \"display notification \\\"Agent needs attention\\\" with title \\\"Agent Tmux\\\"\""'
set-hook -g alert-silence 'run-shell "osascript -e \"display notification \\\"Agent may be waiting\\\" with title \\\"Agent Tmux\\\"\""'
```

#### bin/agent-notify (new file - optional helper)

```bash
#!/bin/bash
# agent-notify - Send notification for agent events
# Usage: agent-notify "title" "message"

TITLE="${1:-Agent Tmux}"
MESSAGE="${2:-Agent needs attention}"

if command -v osascript &>/dev/null; then
    # macOS
    osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\""
elif command -v notify-send &>/dev/null; then
    # Linux
    notify-send "$TITLE" "$MESSAGE"
fi
```

### Acceptance Criteria
- [ ] Notifications appear when agent is idle for 30s
- [ ] Works on macOS (osascript) and Linux (notify-send)
- [ ] Can be disabled via tmux config

---

## Alternative Approaches Considered

| Approach | Pros | Cons | Decision |
|----------|------|------|----------|
| **tmux plugin (TPM)** | Standard distribution | Adds dependency | Rejected - keep standalone |
| **Daemon process** | Better monitoring | Complexity, resources | Rejected - keep simple |
| **Web dashboard** | Rich UI | Over-engineered | Rejected - stay in terminal |
| **SQLite state** | Persistent history | Unnecessary complexity | Rejected - tmux is source of truth |

## Acceptance Criteria

### Functional Requirements

**Phase 1 - Copy:**
- [ ] Copy pane content to clipboard from menu
- [ ] Cross-platform clipboard support
- [ ] Preview before copy

**Phase 2 - Naming:**
- [ ] `--task` flag for agent-session
- [ ] Semantic session names

**Phase 3 - Worktrees:**
- [ ] `agent-worktree` creates branch + worktree + session
- [ ] Integrated with agent-manage

**Phase 4 - Delegation:**
- [ ] `agent-delegate` spawns multiple sessions
- [ ] Optional worktree creation

**Phase 5 - Dashboard:**
- [ ] `agent-status` shows all sessions
- [ ] Status indicators (active/waiting/running)

**Phase 6 - Notifications:**
- [ ] macOS/Linux notifications on agent idle

### Non-Functional Requirements

- [ ] All features work without new dependencies (except native OS tools)
- [ ] Commands complete in <2 seconds
- [ ] Works with tmux 3.0+
- [ ] Backward compatible with existing sessions

### Quality Gates

- [ ] Manual testing on macOS
- [ ] Documentation updated in README
- [ ] install.sh updated for new scripts

## Success Metrics

- Users can copy agent output in <3 seconds
- Users can spin up 3 parallel agents in <10 seconds
- Users can see all agent status at a glance
- Workflow matches community best practices

## Dependencies & Prerequisites

**Required:**
- tmux 3.0+
- fzf
- git (for worktree features)
- bash 4.0+

**Optional:**
- osascript (macOS notifications)
- notify-send (Linux notifications)
- pbcopy/xclip/wl-copy (clipboard)

## Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `bin/agent-manage` | Modify | Add copy, worktree, delegate menu options |
| `bin/agent-session` | Modify | Add `--task` flag |
| `bin/agent-worktree` | Create | Git worktree + session creator |
| `bin/agent-delegate` | Create | Multi-agent spawner |
| `bin/agent-status` | Create | Dashboard viewer |
| `bin/agent-notify` | Create | Notification helper |
| `config/agent-tmux.conf` | Modify | Add notification hooks |
| `install.sh` | Modify | Install new scripts |
| `README.md` | Modify | Document new features |

## References & Research

### External References
- [Best practices for agentic coding](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Embracing the parallel coding agent lifestyle - Simon Willison](https://simonwillison.net/2025/Oct/5/parallel-coding-agents/)
- [How I Run AI Agents in Parallel](https://worksfornow.pika.page/posts/note-to-a-friend-how-i-run-claude-code-agents-in-parallel)
- [tmux Clipboard Wiki](https://github.com/tmux/tmux/wiki/Clipboard)

### Internal References
- Agent-manage menu: `bin/agent-manage:247-373`
- Session creation: `bin/agent-session`
- tmux config: `config/agent-tmux.conf`

### Related Work
- Initial release: commit `360c04c`
- Previous plan: `plans/feat-copy-pane-to-clipboard.md`

---

## Recommended Implementation Order

```
Phase 1: Copy Pane ──────────────────► Quick win, immediate value
    │
    ▼
Phase 2: Task Naming ────────────────► Foundation for phases 3-5
    │
    ├─────────────────┬───────────────┐
    ▼                 ▼               ▼
Phase 3:          Phase 4:        Phase 5:
Worktrees         Delegate        Dashboard
(parallel)        (parallel)      (parallel)
    │                 │               │
    └─────────────────┴───────────────┘
                      │
                      ▼
              Phase 6: Notifications ──► Nice to have
```

Phases 3, 4, and 5 can be implemented in parallel once Phase 2 is complete.
