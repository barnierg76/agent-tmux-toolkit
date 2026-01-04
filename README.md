# Agent Tmux Toolkit

A tmux-based workflow for running multiple Claude Code agents in parallel with snippet support and session management.

## Features

- **3-pane layout**: PLAN | WORK | REVIEW for parallel agent workflows
- **Snippet picker**: Quick text snippets with folder organization (Option+A)
- **Session manager**: Interactive session/pane management (Option+M)
- **Keyboard-driven**: Navigate and manage everything without leaving the keyboard

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

# Or use the interactive manager
agent-manage
```

## Keybindings

| Key | Action |
|-----|--------|
| `Option+A` | Open snippet picker |
| `Option+M` | Open agent manager |
| `Option+1/2/3` | Jump to pane 1/2/3 |
| `Option+H/J/K/L` | Navigate panes (vim-style) |
| `Prefix+R` | Reload tmux config |

## Commands

### agent-session

Creates a new 3-pane tmux session:

```bash
agent-session              # Creates 'agents' session
agent-session myproject    # Creates 'myproject' session
```

### agent-manage

Interactive session and pane manager:

```bash
agent-manage              # Interactive menu
agent-manage open         # Pick session to attach
agent-manage new project  # Create new session
agent-manage status       # Show panes and sessions
agent-manage add 2 DEBUG  # Add 2 panes named DEBUG
agent-manage kill all     # Kill all sessions
```

### snippet-picker

Folder-organized snippet picker with fzf:

- Select folder first, then snippet
- Left arrow goes back to folders
- ESC cancels

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

## Requirements

- tmux 3.0+
- fzf
- iTerm2 (recommended) with Option key set to Esc+

## iTerm2 Setup

For Option/Meta keys to work:

1. iTerm2 → Preferences → Profiles → Keys
2. Set "Left Option Key" to "Esc+"
3. Set "Right Option Key" to "Esc+"

## License

MIT
