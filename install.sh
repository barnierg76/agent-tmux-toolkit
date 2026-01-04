#!/bin/bash
# install.sh - Install agent-tmux-toolkit

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Installing Agent Tmux Toolkit...${NC}"

# Create directories
mkdir -p ~/.local/bin
mkdir -p ~/.config/agent-snippets

# Copy scripts
echo "Installing scripts to ~/.local/bin/"
cp bin/agent-session ~/.local/bin/
cp bin/agent-manage ~/.local/bin/
cp bin/snippet-picker ~/.local/bin/
cp bin/snippet-edit ~/.local/bin/
chmod +x ~/.local/bin/agent-*
chmod +x ~/.local/bin/snippet-*

# Copy config
echo "Installing config to ~/.config/"
cp config/agent-tmux.conf ~/.config/

# Copy snippets (only if not exists)
if [[ ! -f ~/.config/agent-snippets/snippets.txt ]]; then
    cp config/snippets.txt ~/.config/agent-snippets/
    echo "Installed default snippets"
else
    echo -e "${YELLOW}Snippets file exists, skipping (backup at config/snippets.txt)${NC}"
fi

# Check if tmux.conf sources our config
if [[ -f ~/.tmux.conf ]]; then
    if ! grep -q "agent-tmux.conf" ~/.tmux.conf; then
        echo ""
        echo -e "${YELLOW}Add this line to your ~/.tmux.conf:${NC}"
        echo "  source-file ~/.config/agent-tmux.conf"
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

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Quick start:"
echo "  1. Reload tmux: tmux source ~/.tmux.conf"
echo "  2. Start session: agent-session"
echo "  3. Use Option+A for snippets, Option+M for manager"
