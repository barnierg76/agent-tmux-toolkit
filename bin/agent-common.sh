#!/bin/bash
# agent-common.sh - Shared utilities for agent-tmux-toolkit
# Source this file in other scripts: source "$(dirname "$0")/agent-common.sh"

# Prevent double-sourcing
[[ -n "$_AGENT_COMMON_LOADED" ]] && return 0
_AGENT_COMMON_LOADED=1

# ═══════════════════════════════════════════════════════════════════════════════
# COLORS
# ═══════════════════════════════════════════════════════════════════════════════

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'  # No Color

# ═══════════════════════════════════════════════════════════════════════════════
# VALIDATION
# ═══════════════════════════════════════════════════════════════════════════════

# Validate name - alphanumeric, dash, underscore only
# Usage: validate_name "my-name" "session name"
validate_name() {
    local name="$1"
    local type="${2:-name}"
    if ! [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo -e "${RED}Error: Invalid $type. Use only alphanumeric, dash, underscore.${NC}" >&2
        return 1
    fi
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# SESSION UTILITIES
# ═══════════════════════════════════════════════════════════════════════════════

# Get session name from environment or detect from tmux
# Includes security validation to prevent injection
get_session_name() {
    local name

    if [[ -n "$AGENT_SESSION" ]]; then
        name="$AGENT_SESSION"
    elif name=$(tmux display-message -p '#{session_name}' 2>/dev/null) && [[ -n "$name" ]]; then
        :
    else
        name="agents"
    fi

    # Security: validate session name to prevent injection
    if ! [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo -e "${RED}Error: Invalid session name '$name'${NC}" >&2
        echo "agents"  # Return safe default
        return 1
    fi

    echo "$name"
}

# ═══════════════════════════════════════════════════════════════════════════════
# CLIPBOARD UTILITIES
# ═══════════════════════════════════════════════════════════════════════════════

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
        echo -e "${RED}No clipboard tool found${NC}" >&2
        echo "Install one of: pbcopy (macOS), xclip, xsel (Linux), wl-copy (Wayland)" >&2
        return 1
    fi
}

# Cross-platform clipboard paste
paste_from_clipboard() {
    if command -v pbpaste &>/dev/null; then
        pbpaste
    elif command -v xclip &>/dev/null; then
        xclip -selection clipboard -o
    elif command -v xsel &>/dev/null; then
        xsel --clipboard --output
    elif command -v wl-paste &>/dev/null; then
        wl-paste
    elif command -v powershell.exe &>/dev/null; then
        powershell.exe -command "Get-Clipboard" | tr -d '\r'
    else
        echo -e "${RED}No clipboard tool found${NC}" >&2
        echo "Install one of: pbpaste (macOS), xclip, xsel (Linux), wl-paste (Wayland)" >&2
        return 1
    fi
}

# Get clipboard content, returns empty if just whitespace
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

# ═══════════════════════════════════════════════════════════════════════════════
# PANE UTILITIES
# ═══════════════════════════════════════════════════════════════════════════════

# Get pane ID by role (PLAN, WORK, REVIEW)
# Falls back to pane title, then index
# Usage: get_pane_by_role "PLAN" "$SESSION_NAME"
get_pane_by_role() {
    local role="$1"
    local session="${2:-$(get_session_name)}"
    local pane_id

    # Try @role first
    pane_id=$(tmux list-panes -t "$session" -F "#{pane_id}|#{@role}" 2>/dev/null | \
        awk -F'|' -v role="$role" '$2 == role {print $1; exit}')

    if [[ -n "$pane_id" ]]; then
        echo "$pane_id"
        return 0
    fi

    # Fallback: try matching pane title
    pane_id=$(tmux list-panes -t "$session" -F "#{pane_id}|#{pane_title}" 2>/dev/null | \
        awk -F'|' -v role="$role" '$2 ~ "^"role {print $1; exit}')

    if [[ -n "$pane_id" ]]; then
        echo "$pane_id"
        return 0
    fi

    # Final fallback: use index
    case "$role" in
        PLAN)   tmux list-panes -t "$session:1" -F "#{pane_id}" 2>/dev/null | sed -n '1p' ;;
        WORK)   tmux list-panes -t "$session:1" -F "#{pane_id}" 2>/dev/null | sed -n '2p' ;;
        REVIEW) tmux list-panes -t "$session:1" -F "#{pane_id}" 2>/dev/null | sed -n '3p' ;;
    esac
}

# Resolve pane by index, name, or role
# Usage: resolve_pane "1" "$SESSION_NAME" or resolve_pane "PLAN" "$SESSION_NAME"
resolve_pane() {
    local target="$1"
    local session="${2:-$(get_session_name)}"

    # If numeric, validate it exists
    if [[ "$target" =~ ^[0-9]+$ ]]; then
        if tmux list-panes -t "$session" -F "#{pane_index}" 2>/dev/null | grep -q "^${target}$"; then
            echo "$target"
            return 0
        fi
        return 1
    fi

    # Try as role (PLAN, WORK, REVIEW)
    local pane_id
    pane_id=$(get_pane_by_role "$target" "$session")
    if [[ -n "$pane_id" ]]; then
        # Convert pane_id to index
        tmux list-panes -t "$session" -F "#{pane_index}|#{pane_id}" 2>/dev/null | \
            awk -F'|' -v id="$pane_id" '$2 == id {print $1; exit}'
        return 0
    fi

    # Try as pane title
    local index
    index=$(tmux list-panes -t "$session" -F "#{pane_index}|#{pane_title}" 2>/dev/null | \
        awk -F'|' -v name="$target" '$2 == name {print $1; exit}')

    if [[ -n "$index" ]]; then
        echo "$index"
        return 0
    fi

    return 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# FZF UTILITIES
# ═══════════════════════════════════════════════════════════════════════════════

# Check if fzf is available, exit with helpful message if not
check_fzf() {
    if ! command -v fzf &>/dev/null; then
        echo -e "${RED}Error: fzf is required${NC}"
        echo "Install with: brew install fzf"
        exit 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEXT UTILITIES
# ═══════════════════════════════════════════════════════════════════════════════

# Strip ANSI escape codes from text
strip_ansi() {
    sed 's/\x1b\[[0-9;]*m//g'
}
