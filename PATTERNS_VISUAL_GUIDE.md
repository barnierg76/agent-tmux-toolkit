# Agent-Tmux-Toolkit Patterns - Visual Guide

## 1. Send-Keys Command Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                     SEND-KEYS DECISION TREE                        │
└─────────────────────────────────────────────────────────────────────┘

                            START: Send content?
                                    |
                    ________________|________________
                   |                                |
            Is it special/complex?          Is it simple command?
            (quotes, $var, newlines)        (echo, clear, ls)
                   |                                |
                  YES                              NO
                   |                                |
            Use -l flag              Use simple syntax
            ┌─────────────┐          ┌──────────────┐
            │ -l "content"│          │ "cmd" Enter  │
            └─────────────┘          └──────────────┘
                   |                                |
            ┌──────────┐                     Should user
            │Send Enter│                     complete?
            │separately│                            |
            └──────────┘                    ________|________
                   |                       |                |
                   |                      YES              NO
                   |                       |                |
           ┌───────v───────┐    ┌──────────v───────┐   ┌──v──────┐
           │ tmux send-keys │   │ Don't send Enter │   │Done:    │
           │    Enter       │   │ (comment: user   │   │No Enter │
           └────────────────┘   │  input expected) │   └─────────┘
                   |            └──────────────────┘
                   |
           ┌───────v────────┐
           │ EXECUTION!     │
           │ Command runs   │
           └────────────────┘
```

## 2. Pane Resolution Flowchart

```
┌────────────────────────────────────────────────────┐
│  NEED TO TARGET A PANE?                           │
└────────────────────────────────────────────────────┘
                      |
         ┌────────────┼────────────┐
         |            |            |
    Know role?   Know index?  Current pane?
    (PLAN/      (0, 1, 2)     only?
     WORK/
     REVIEW)
         |            |            |
        YES           YES          YES
         |            |            |
    ┌────v─────┐  ┌───v────┐  ┌───v────┐
    │get_pane_ │  │SESSION.0│  │No -t   │
    │by_role() │  │SESSION.1│  │flag    │
    │          │  │SESSION.2│  │        │
    └────┬─────┘  └────┬───┘  └───┬────┘
         |             |           |
         └─────────────┼───────────┘
                       |
                ┌──────v──────┐
                │ tmux send-  │
                │ keys -t ... │
                └─────────────┘
```

## 3. Error Handling Flow

```
┌────────────────────────────────────┐
│ FUNCTION START                     │
└────────────────────────────────────┘
         |
    ┌────v─────┐
    │Validate  │
    │inputs    │
    └────┬─────┘
         |
    ┌────v──────────────┐
    │Input valid?       │
    └────┬────────┬─────┘
         |        |
        YES      NO
         |        |
         |   ┌────v──────────────┐
         |   │Print error to     │
         |   │stderr with color  │
         |   │echo -e "...${NC}"│
         |   │      >&2         │
         |   └────┬──────────────┘
         |        |
         |   ┌────v──────┐
         |   │return 1   │
         |   │(exit 1)   │
         |   └───────────┘
         |
    ┌────v──────────────┐
    │Execute operation  │
    └────┬───────────────┘
         |
    ┌────v──────────────┐
    │Success?           │
    └────┬────────┬─────┘
         |        |
        YES      NO
         |        |
    ┌────v────┐ ┌──v──────────┐
    │echo ok  │ │echo error    │
    │return 0 │ │return 1      │
    └─────────┘ └──────────────┘
```

## 4. Session Creation Sequence

```
TIMELINE →

Step 1: Create session
├─ tmux new-session -d -s "$SESSION_NAME"
│
Step 2: Split for Work pane
├─ tmux split-window -h -t "$SESSION_NAME"
│
Step 3: Split for Review pane
├─ tmux split-window -h -t "$SESSION_NAME"
│
Step 4: Even out layout
├─ tmux select-layout -t "$SESSION_NAME" even-horizontal
│
Step 5: Get pane IDs
├─ PANE_IDS=($(tmux list-panes ...))
│
Step 6: Set roles (using IDs from Step 5)
├─ tmux set-option -p -t "${PANE_IDS[0]}" @role "PLAN"
├─ tmux set-option -p -t "${PANE_IDS[1]}" @role "WORK"
├─ tmux set-option -p -t "${PANE_IDS[2]}" @role "REVIEW"
│
Step 7: Set titles
├─ tmux select-pane -t "${PANE_IDS[0]}" -T "title"
│
Step 8: Attach
└─ tmux attach -t "$SESSION_NAME"

KEY: Each step completes before next starts
     Variables resolved between steps
     IDs obtained in Step 5 used in Steps 6-7
```

## 5. Argument Parsing State Machine

```
┌──────────────────────────────────────┐
│ ARGUMENT PARSING                     │
│ while [[ $# -gt 0 ]]; do             │
└──────────────────────────────────────┘
         |
         |
    ┌────v─────────────────────────────┐
    │ Check $1                          │
    └────┬────────────┬────────────┬───┘
         |            |            |
    Known flag?  Positional arg?  Other?
         |            |            |
        YES          YES           YES
         |            |            |
    ┌───v──┐     ┌────v──┐   ┌────v──┐
    │--task│    │  name  │   │-x/-y/ │
    │--path│    │ --path │   │unknown│
    │-t -p │    │  value │   │       │
    └───┬──┘    └────┬───┘   └────┬──┘
        |             |            |
    ┌───v──────────┐ |        ┌───v──────┐
    │VAR="$2"      │ |        │Error &   │
    │shift 2       │ |        │show help │
    │(consume both)│ |        │exit 1    │
    └──────────────┘ |        └──────────┘
                     |
              ┌──────v────────┐
              │VAR="$1"       │
              │shift 1        │
              │(consume one)  │
              └───────────────┘
                     |
              ┌──────v──────┐
              │Loop again   │
              │while [[ ... │
              └─────────────┘
```

## 6. Shared Library Dependency Graph

```
┌─────────────────────────────┐
│  agent-common.sh            │
│  (Utilities Library)         │
├─────────────────────────────┤
│ • validate_name             │
│ • get_session_name          │
│ • get_pane_by_role          │
│ • resolve_pane              │
│ • copy_to_clipboard         │
│ • paste_from_clipboard      │
│ • check_fzf                 │
│ • show_session_picker       │
│ • show_pane_picker          │
│ • [colors, ANSI stripping]  │
└──────────────┬──────────────┘
               |
    ┌──────────┼──────────┬──────────┬──────────┐
    |          |          |          |          |
   (1)        (2)        (3)        (4)       (5)
    |          |          |          |          |
┌──v───┐  ┌───v──┐  ┌────v─┐  ┌────v───┐ ┌──v──┐
│agent-│  │agent-│  │agent-│  │snippet │ │demo-│
│session│  │manage│  │flow  │  │picker  │ │setup│
└──────┘  └──────┘  └──────┘  └────────┘ └─────┘

Legend:
(1) Uses: validate_name, get_session_name
(2) Uses: validate_name, get_pane_by_role, copy/paste, show_picker
(3) Uses: get_session_name, get_pane_by_role
(4) Uses: get_session_name, check_fzf, get_pane_by_role
(5) Uses: get_session_name, validate_name, colors
```

## 7. Copy/Paste Workflow

```
USER INPUT
    |
    └──> Is target specified?
         |
    ┌────┴──────┐
   YES         NO
    |           |
    |      ┌────v──────────┐
    |      │show_pane_     │
    |      │picker()       │
    |      │fzf with       │
    |      │preview        │
    |      └────┬──────────┘
    |           |
    ├───────────┘
    |
    v
RESOLVE PANE INDEX
    |
    ├─ By number (0, 1, 2)
    └─ By name (PLAN, WORK, REVIEW)
    |
    v
GET CLIPBOARD CONTENT
    |
    ├─> tmux capture-pane -p
    ├─> sed 's/\x1b\[[0-9;]*m//g'  [strip ANSI]
    └─> grep -v '^[[:space:]]*$'    [remove empty]
    |
    v
CONFIRM IF MULTILINE
    |
    └─> read -p "Continue? [y/N]:"
    |
    v
SEND TO PANE
    |
    └─> tmux send-keys -t "$PANE" -l "$content"
    |
    v
REPORT SUCCESS
    |
    └─> echo "Pasted N lines to pane M"
```

## 8. Tmux Format String Reference

```
┌────────────────────────────────────────────┐
│ PANE FORMAT STRINGS                        │
├────────────────────────────────────────────┤
│ #{pane_id}                                 │
│ └─> %0, %1, %2 (tmux internal ID)         │
│                                            │
│ #{pane_index}                              │
│ └─> 0, 1, 2 (within window position)      │
│                                            │
│ #{@role}                                   │
│ └─> PLAN, WORK, REVIEW (custom attribute) │
│                                            │
│ #{pane_title}                              │
│ └─> "Ready", "auth-feature" (user set)    │
│                                            │
│ #{pane_current_command}                    │
│ └─> "bash", "zsh", "vim" (running cmd)    │
│                                            │
│ #{?pane_active,1,0}                        │
│ └─> 1 if active, 0 if not                 │
│                                            │
│ #{pane_width} x #{pane_height}             │
│ └─> "80x24" (dimensions)                  │
└────────────────────────────────────────────┘
```

## 9. Function Call Chain Example

```
User runs: agent-flow start
           |
           └─> source agent-common.sh
               |
               └─> _AGENT_COMMON_LOADED guard
                   |
                   ├─ Check if already loaded
                   └─ Load utilities if not
           |
           └─> SESSION_NAME=$(get_session_name)
               |
               ├─ Check AGENT_SESSION env
               ├─ Fallback: tmux display-message
               ├─ Validate (regex check)
               └─> Return "agents" or specific name
           |
           └─> focus_pane "PLAN"
               |
               ├─> get_pane_by_role "PLAN" "$SESSION_NAME"
               │   |
               │   ├─ Try: list-panes | grep @role
               │   ├─ Try: list-panes | grep pane_title
               │   └─ Fallback: index [0]
               │   |
               │   └─> Return pane_id (%0, %1, etc)
               │
               └─> tmux select-pane -t <pane_id>
           |
           └─> send_to_pane "PLAN" "/compound-engineering:workflows:plan "
               |
               ├─> get_pane_by_role "PLAN" "$SESSION_NAME"
               │   └─> Return pane_id
               │
               └─> tmux send-keys -t <pane_id> -l "..."
                   (NOTE: No Enter - user inputs description)
           |
           └─> agent-flow-state set PLANNING
               |
               └─> Update workflow state file
```

## 10. Color Output Diagram

```
┌─────────────────────────────────────────┐
│ COLOR CONSTANTS (agent-common.sh)       │
├─────────────────────────────────────────┤
│                                         │
│ RED      = \033[0;31m    [Errors]     │
│ GREEN    = \033[0;32m    [Success]    │
│ YELLOW   = \033[1;33m    [Warnings]   │
│ BLUE     = \033[0;34m    [Headers]    │
│ CYAN     = \033[0;36m    [Info]       │
│ DIM      = \033[2m       [Secondary]  │
│ BOLD     = \033[1m       [Emphasis]   │
│ NC       = \033[0m       [Reset]      │
│                                         │
├─────────────────────────────────────────┤
│ USAGE:                                  │
│                                         │
│ echo -e "${RED}Error${NC}"             │
│ echo -e "${GREEN}Done${NC}"            │
│ echo -e "${YELLOW}Warning${NC}"        │
│                                         │
│ ERROR OUTPUT:                           │
│ echo "message" >&2  [to stderr]         │
│                                         │
└─────────────────────────────────────────┘
```

## 11. Test Scenario Flow

```
TEST: Session Creation
├─ Setup: Clear any existing "test" session
├─ Action: agent-session --task demo
├─ Verify:
│  ├─ Session exists: tmux has-session -t agent-demo
│  ├─ Panes created: tmux list-panes -t agent-demo | wc -l = 3
│  ├─ Roles set: tmux display-message -p '#{@role}' -t agent-demo.0 = PLAN
│  └─ Can send command: tmux send-keys -t agent-demo.0 "echo test" Enter
└─ Cleanup: tmux kill-session -t agent-demo

TEST: Pane Resolution
├─ Setup: Create test session with roles
├─ Action: get_pane_by_role "WORK" "test"
├─ Verify: Returns valid pane_id (%1, %2, etc)
└─ Verify: Can send to returned pane

TEST: Copy/Paste
├─ Setup: Create session, fill pane with content
├─ Action: agent-manage copy PLAN
├─ Verify: Content in clipboard
├─ Action: agent-manage paste WORK
└─ Verify: Content in WORK pane
```

## 12. Directory Structure with Details

```
agent-tmux-toolkit/
│
├── bin/                          [EXECUTABLE SCRIPTS]
│   ├── agent-common.sh           [SHARED LIBRARY - 310 lines]
│   │   ├── Colors (13 definitions)
│   │   ├── Validation (validate_name)
│   │   ├── Session utils (get_session_name)
│   │   ├── Pane utils (get_pane_by_role, resolve_pane)
│   │   ├── Clipboard (copy_to/from_clipboard)
│   │   ├── FZF (check_fzf, show_*_picker)
│   │   └── Text (strip_ansi)
│   │
│   ├── agent-session             [SESSION CREATOR - 132 lines]
│   │   ├── Arg parsing (--task, --name, --path)
│   │   ├── Session creation (new-session)
│   │   ├── Pane setup (3 panes)
│   │   └── Layout (even-horizontal)
│   │
│   ├── agent-manage              [PANE MANAGER - 600+ lines]
│   │   ├── Status display
│   │   ├── Add/close panes
│   │   ├── Copy/paste (comprehensive)
│   │   ├── Rename/focus
│   │   └── Interactive menu (fzf)
│   │
│   ├── agent-flow                [WORKFLOW ORCHESTRATOR]
│   │   ├── Focus by role
│   │   ├── Send commands to panes
│   │   └── Track workflow state
│   │
│   ├── agent-handoff             [CONTEXT TRANSFER]
│   │   ├── Source selection
│   │   ├── Content capture
│   │   └── Smart templates
│   │
│   ├── snippet-picker            [SNIPPET UI]
│   │   ├── Pane detection
│   │   ├── Folder navigation
│   │   └── Content sending
│   │
│   ├── demo-setup.sh             [DEMO ENVIRONMENT]
│   │   ├── Session creation
│   │   ├── Multi-line content
│   │   └── Visual setup
│   │
│   └── [7 more utilities]
│
├── config/
│   └── agent-tmux.conf           [TMUX CONFIG]
│       ├── Keybindings (Meta+keys)
│       ├── Mouse support
│       └── Copy/paste setup
│
└── docs/
    └── (various documentation)
```

---

These visual guides complement the text documentation and provide quick mental models for understanding the code flow and patterns.
