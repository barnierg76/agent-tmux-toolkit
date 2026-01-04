# Agent Tmux Toolkit

A tmux-based workflow for running multiple Claude Code agents in parallel with **compound engineering integration** - snippet support, session management, and git worktree integration.

## Features

- **3-pane layout**: PLAN | WORK | REVIEW for parallel agent workflows
- **Compound workflow orchestration**: PLAN -> WORK -> REVIEW -> COMPOUND loop
- **Pane-aware snippets**: Shows relevant snippets based on current pane
- **Cross-pane handoffs**: Transfer context between panes with smart templates
- **Task-based sessions**: Name sessions by task ID for easy navigation
- **Git worktree integration**: Isolated branches for parallel development
- **Multi-agent delegation**: Spawn multiple agent sessions at once
- **Status dashboard**: View all agent sessions at a glance
- **Copy/paste**: Extract pane content to clipboard or paste into panes
- **Session manager**: Interactive session/pane management
- **Desktop notifications**: Optional alerts when agents need attention

## Installation

```bash
# Clone the repo
git clone https://github.com/YOUR_USERNAME/agent-tmux-toolkit.git
cd agent-tmux-toolkit

# Run installer
./install.sh
```

## Quick Start

```bash
# Start a new agent session
agent-session

# Start a task-specific session
agent-session --task auth-fix

# Spawn multiple parallel agents
agent-delegate task-1 task-2 task-3

# View all agent sessions
agent-status

# Open the interactive manager
agent-manage
```

## Keybindings

| Key | Action |
|-----|--------|
| `Option+S` | Open snippet picker (pane-aware) |
| `Option+F` | Open workflow flow orchestrator |
| `Option+H` | Handoff context between panes |
| `Option+D` | Open status dashboard |
| `Option+M` | Open agent manager |
| `Option+Space` | Open snippet picker (alternative) |
| `Option+1/2/3` | Jump to pane 1/2/3 |
| `Option+Arrows` | Navigate panes |
| `Prefix+R` | Reload tmux config |

## Commands

### agent-session

Creates a new 3-pane tmux session:

```bash
agent-session                    # Creates 'agents' session
agent-session myproject          # Creates 'myproject' session
agent-session --task 42          # Creates 'agent-42' session
agent-session --task auth-fix    # Creates 'agent-auth-fix' session
agent-session -t feat-1 -p ~/code/myapp  # With custom path
```

Panes are named `PLAN`, `WORK`, `REVIEW`. With `--task`, names include the task ID (e.g., `PLAN: auth-fix`).

### agent-manage

Interactive session and pane manager:

```bash
agent-manage              # Interactive menu
agent-manage open         # Pick session to attach
agent-manage new project  # Create new session
agent-manage status       # Show panes and sessions
agent-manage add 2 DEBUG  # Add 2 panes named DEBUG
agent-manage copy 0       # Copy pane 0 to clipboard
agent-manage paste 1      # Paste clipboard to pane 1
agent-manage kill all     # Kill all sessions
```

Menu sections:
- **Sessions**: Create, attach to sessions
- **Actions**: Manage panes, copy/paste
- **Parallel Work**: Worktrees, delegation, status
- **Cleanup**: Close panes, kill sessions

### agent-worktree

Create git worktree + agent session for isolated parallel work:

```bash
agent-worktree feat-auth          # Branch from main
agent-worktree feat-api develop   # Branch from develop
agent-worktree --list             # Show all worktrees
agent-worktree --remove feat-auth # Clean up worktree + session
```

This creates:
1. Git worktree at `../<repo>-<branch>`
2. New branch if it doesn't exist
3. Agent session in the worktree directory

### agent-delegate

Spawn multiple parallel agent sessions:

```bash
agent-delegate auth-fix api-refactor tests
agent-delegate --worktree feat-1 feat-2 feat-3
agent-delegate -w -b develop task-a task-b
```

Options:
- `--worktree, -w`: Also create git worktrees
- `--base, -b <branch>`: Base branch for worktrees (default: main)

### agent-status

Dashboard view of all agent sessions:

```bash
agent-status              # One-time status
agent-status --watch      # Live dashboard (refreshes every 2s)
agent-status --all        # Include non-agent sessions
```

Status indicators:
- `● Active` - Session is attached
- `◐ Waiting` - Session appears to be waiting for input
- `◑ Running` - Session is running a command
- `○ Idle` - Session has been idle for 5+ minutes

### agent-flow

Compound engineering workflow orchestrator:

```bash
agent-flow              # Interactive menu
agent-flow start        # Focus PLAN pane, send /workflows:plan
agent-flow work         # Focus WORK pane, send /workflows:work
agent-flow review       # Focus REVIEW pane, send /workflows:review
agent-flow compound     # Run /workflows:compound
agent-flow status       # Show workflow state
agent-flow reset        # Clear workflow state
```

The flow tracks your workflow state (IDLE -> PLANNING -> WORKING -> REVIEWING -> COMPOUND -> DONE) and suggests the next step.

### agent-handoff

Transfer context between panes with smart templates:

```bash
agent-handoff              # Interactive picker
agent-handoff PLAN WORK    # Transfer from PLAN to WORK
agent-handoff WORK REVIEW  # Transfer from WORK to REVIEW
```

Templates are applied based on source and target panes:
- **PLAN -> WORK**: "Here's the plan to implement:"
- **WORK -> REVIEW**: "Please review this implementation:"
- **REVIEW -> WORK**: "Review feedback to address:"

### snippet-picker

Pane-aware folder-organized snippet picker with fzf:

- **Pane-aware filtering**: In PLAN pane, shows PLAN and EVERY folders first
- Select folder first, then snippet
- Left arrow goes back to folders
- ESC cancels
- Shows workflow suggestion in header

## Snippets

Edit snippets in `~/.config/agent-snippets/snippets.txt`:

```
# ═══ MY FOLDER ═══
Label
Content to send
---
Another Label
Another content
---
```

## Notifications

Desktop notifications are disabled by default. To enable:

1. Edit `~/.config/agent-tmux.conf`
2. Uncomment the notification lines in the `=== NOTIFICATIONS ===` section
3. Reload: `tmux source ~/.tmux.conf`

To disable notifications:
- Set environment variable: `export AGENT_NOTIFY_DISABLED=1`
- Or create file: `touch ~/.agent-notify-disabled`

## Requirements

- tmux 3.0+
- fzf
- git (for worktree features)
- iTerm2 (recommended) with Option key set to Esc+

## iTerm2 Setup

For Option/Meta keys to work:

1. iTerm2 → Preferences → Profiles → Keys
2. Set "Left Option Key" to "Esc+"
3. Set "Right Option Key" to "Esc+"

## Compound Engineering Workflow

The toolkit integrates with the compound engineering loop:

```
PLAN -> WORK -> REVIEW -> COMPOUND
```

### Quick Start

1. **Start a session**: `agent-session --task my-feature`
2. **Press `Option+F`** to open the flow orchestrator
3. **Select "Start Feature"** - focuses PLAN pane, sends `/workflows:plan`
4. After planning, select **"Plan -> Work"** - focuses WORK pane
5. After implementing, select **"Work -> Review"** - focuses REVIEW pane
6. After review passes, select **"Compound"** - documents learnings

### Pane-Aware Snippets

When you press `Option+S`, snippets are filtered based on your current pane:
- **PLAN pane**: Shows PLAN, EVERY, and HANDOFF folders first
- **WORK pane**: Shows WORK, EVERY, and QUICK folders first
- **REVIEW pane**: Shows REVIEW and EVERY folders first

### Cross-Pane Handoffs

Press `Option+H` to transfer context between panes:
1. Select source pane (with preview of content)
2. Select target pane
3. Content is injected with a smart template prefix

## Parallel Workflow Example

```bash
# Start a parallel agent workflow
agent-delegate --worktree auth-module api-refactor ui-update

# Check status
agent-status

# Attach to work on auth
tmux attach -t agent-auth-module

# Use Option+F for workflow orchestration
# Use Option+H to handoff context between panes
# Use Option+S for pane-aware snippets

# When done, clean up
agent-worktree --remove auth-module
```

## License

MIT
