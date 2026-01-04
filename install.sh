#!/bin/bash
# install.sh - Install agent-tmux-toolkit

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Backup file if it exists
backup_if_exists() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup="${file}.backup.$(date +%Y%m%d%H%M%S)"
        cp "$file" "$backup"
        echo -e "${YELLOW}Backed up $file to $backup${NC}"
    fi
}

echo -e "${GREEN}Installing Agent Tmux Toolkit...${NC}"

# Create directories
mkdir -p ~/.local/bin
mkdir -p ~/.config/agent-snippets

# Copy scripts
echo "Installing scripts to ~/.local/bin/"

# Backup existing scripts
for script in agent-session agent-manage agent-worktree agent-delegate agent-status agent-notify agent-flow agent-flow-state agent-flow-prompt agent-handoff agent-help snippet-picker snippet-edit; do
    backup_if_exists ~/.local/bin/$script
done

# Core scripts
cp bin/agent-session ~/.local/bin/
cp bin/agent-manage ~/.local/bin/
cp bin/agent-worktree ~/.local/bin/
cp bin/agent-delegate ~/.local/bin/
cp bin/agent-status ~/.local/bin/
cp bin/agent-notify ~/.local/bin/
cp bin/snippet-picker ~/.local/bin/
cp bin/snippet-edit ~/.local/bin/

# Compound workflow scripts
cp bin/agent-flow ~/.local/bin/
cp bin/agent-flow-state ~/.local/bin/
cp bin/agent-flow-prompt ~/.local/bin/
cp bin/agent-handoff ~/.local/bin/

# Help system
cp bin/agent-help ~/.local/bin/

# Set permissions
chmod +x ~/.local/bin/agent-session
chmod +x ~/.local/bin/agent-manage
chmod +x ~/.local/bin/agent-worktree
chmod +x ~/.local/bin/agent-delegate
chmod +x ~/.local/bin/agent-status
chmod +x ~/.local/bin/agent-notify
chmod +x ~/.local/bin/agent-flow
chmod +x ~/.local/bin/agent-flow-state
chmod +x ~/.local/bin/agent-flow-prompt
chmod +x ~/.local/bin/agent-handoff
chmod +x ~/.local/bin/agent-help
chmod +x ~/.local/bin/snippet-picker
chmod +x ~/.local/bin/snippet-edit

# Create workflow state cache directory
mkdir -p ~/.cache/agent-tmux

# Copy config
echo "Installing config to ~/.config/"
backup_if_exists ~/.config/agent-tmux.conf
cp config/agent-tmux.conf ~/.config/

# Copy snippets (only if not exists)
if [[ ! -f ~/.config/agent-snippets/snippets.txt ]]; then
    cp config/snippets.txt ~/.config/agent-snippets/
    echo "Installed default snippets"
else
    echo -e "${YELLOW}Snippets file exists, skipping (backup at config/snippets.txt)${NC}"
fi

# Configure tmux to source our config
if [[ -f ~/.tmux.conf ]]; then
    if ! grep -q "agent-tmux.conf" ~/.tmux.conf; then
        echo "" >> ~/.tmux.conf
        echo "# Agent Tmux Toolkit" >> ~/.tmux.conf
        echo "source-file ~/.config/agent-tmux.conf" >> ~/.tmux.conf
        echo "Added source line to existing ~/.tmux.conf"
    else
        echo "~/.tmux.conf already sources agent-tmux.conf"
    fi
else
    echo "source-file ~/.config/agent-tmux.conf" > ~/.tmux.conf
    echo "Created ~/.tmux.conf"
fi

# Check PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo ""
    echo -e "${YELLOW}Add ~/.local/bin to your PATH:${NC}"
    echo '  export PATH="$HOME/.local/bin:$PATH"'
fi

# Check dependencies
echo ""
echo "Checking dependencies..."
command -v tmux &>/dev/null && echo "  ✓ tmux" || echo "  ✗ tmux (required)"
command -v fzf &>/dev/null && echo "  ✓ fzf" || echo "  ✗ fzf (install: brew install fzf)"
command -v git &>/dev/null && echo "  ✓ git" || echo "  ✗ git (needed for worktrees)"

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Quick start:"
echo "  1. Reload tmux: tmux source ~/.tmux.conf"
echo "  2. Start session: agent-session"
echo ""
echo "Keybindings:"
echo "  Option+S     Snippets (pane-aware)"
echo "  Option+F     Flow orchestrator (PLAN->WORK->REVIEW->COMPOUND)"
echo "  Option+H     Handoff context between panes"
echo "  Option+D     Status dashboard"
echo "  Option+M     Manager menu"
echo "  Option+?     Help reference"
echo "  Option+1/2/3 Jump to pane"
echo ""
echo "Commands:"
echo "  agent-session --task <id>     Create task-specific session"
echo "  agent-flow                    Compound workflow orchestrator"
echo "  agent-handoff                 Transfer context between panes"
echo "  agent-worktree <branch>       Create worktree + session"
echo "  agent-delegate <t1> <t2>      Spawn multiple agents"
echo "  agent-status                  View all agent sessions"
