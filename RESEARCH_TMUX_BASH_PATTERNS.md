# Research: tmux & Bash Patterns for Help Systems and Interactive Menus

**Research Date:** 2026-01-04
**Focus Areas:** tmux help overlays, bash interactive menus, snippet filtering

---

## Table of Contents

1. [tmux Help Systems](#1-tmux-help-systems)
2. [Interactive Menu Libraries](#2-interactive-menu-libraries)
3. [Snippet Managers](#3-snippet-managers)
4. [Implementation Patterns](#4-implementation-patterns)
5. [Code Examples](#5-code-examples)

---

## 1. tmux Help Systems

### 1.1 Native tmux Key Listing

tmux provides built-in mechanisms for viewing key bindings:

**Commands:**
- `tmux list-keys` - Lists all key bindings as bind-key commands
- `Ctrl+b ?` - Opens interactive help window (shortcut for list-keys)
- `tmux list-keys -N` - Lists only keys with attached notes (cleaner display)
- `tmux list-keys -T <table>` - Lists keys from specific key table (prefix, root, copy-mode, copy-mode-vi)

**Key Tables:**
- **prefix** - Keys pressed after `Ctrl+b` (default prefix)
- **root** - Keys without prefix (use `-n` flag in bind-key)
- **copy-mode** / **copy-mode-vi** - Keys active in copy mode

**Sources:**
- [tmux list-keys documentation](https://waylonwalker.com/tmux-list-keys/)
- [List All tmux Key Bindings](https://til.hashrocket.com/posts/385fee97f3-list-all-tmux-key-bindings)
- [Binding Keys in tmux](https://www.seanh.cc/2020/12/28/binding-keys-in-tmux/)

### 1.2 display-popup for Help Overlays

tmux 3.2+ introduced `display-popup` for creating floating overlay windows.

**Basic Syntax:**
```bash
tmux display-popup [options] [shell-command]
```

**Common Options:**
- `-E` - Close popup when command exits
- `-w <width>` - Width (pixels or percentage like `90%`)
- `-h <height>` - Height (pixels or percentage like `80%`)
- `-x <position>` - Horizontal position (C=center, R=right, L=left)
- `-y <position>` - Vertical position (C=center, T=top, B=bottom)
- `-d <path>` - Working directory

**Help Popup Pattern:**
```bash
# Replace default ? binding with custom help
bind-key ? display-popup -E -w 90% -h 80% "echo 'TMUX SHORTCUTS:
Window/Session Management:
  ctrl+a w/W - fzf window switcher popup
  ctrl+a s/S - fzf session switcher popup
  ctrl+a c   - create new window
  ctrl+a ,   - rename window
...more shortcuts...
' | less"
```

**Toggle Popup Pattern:**
```bash
# Create dismissable popup (press same key to close)
bind-key -n M-3 if-shell -F '#{==:#{session_name},popup}' {
    detach-client
} {
    display-popup -d "#{pane_current_path}" -xC -yC -w 80% -h 75% -E \
        'tmux attach-session -t popup || tmux new-session -s popup'
}
```

**Sources:**
- [tmux Popup Cheat Sheet](https://justyn.io/til/til-tmux-popup-cheatsheet/)
- [How to use popup windows in tmux](https://tmuxai.dev/tmux-popup/)
- [Dismissable Popup Shell in tmux](https://willhbr.net/2023/02/07/dismissable-popup-shell-in-tmux/)
- [Creating a Tmux Keybinding for Pop-up Sessions](https://madprofessorblog.org/articles/creating-a-tmux-keybinding-for-pop-up-sessions/)

### 1.3 display-message for Quick Notifications

For simple status messages without interactive UI:

```bash
# Display message in status line
tmux display-message "Hello World"

# Display with custom duration (milliseconds)
tmux display-message -d 2000 "This disappears in 2 seconds"

# Print to stdout instead of status line
tmux display-message -p "#{session_name}"

# Wait for keypress (0 duration)
tmux display-message -d 0 "Press any key..."
```

**Sources:**
- [tmux display-message](https://waylonwalker.com/tmux-display-message/)

---

## 2. Interactive Menu Libraries

### 2.1 Comparison Table

| Feature | dialog | whiptail | fzf | gum |
|---------|--------|----------|-----|-----|
| Library | ncurses | newt | - | - |
| Pre-installed | Some distros | Debian-based | No | No |
| Features | Full (many box types) | Limited subset | Fuzzy finder | Modern styling |
| Colors | Yes | No | Yes | Yes |
| Weight | Heavier | Lighter | Lightweight | Lightweight |
| Best For | Feature-rich TUIs | Simple menus | Filtering/searching | Modern CLIs |

**Sources:**
- [Creating Interactive Scripts with Dialog or Whiptail](https://aprendeit.com/en/creating-interactive-scripts-in-linux-using-dialog-or-whiptail/)
- [Text Interfaces with Whiptail and Dialog](https://funprojects.blog/2022/04/06/text-interfaces-with-whiptail-and-dialog/)

### 2.2 whiptail (Recommended for Lightweight Scripts)

**Why whiptail:**
- Pre-installed on Debian/Ubuntu systems
- Drop-in compatible with dialog syntax
- Uses newt library (lighter than ncurses)
- Perfect for simple menus and prompts

**Available Box Types:**
- `--yesno` - Yes/No dialog
- `--menu` - Selection menu
- `--inputbox` - Text input
- `--msgbox` - Message display
- `--textbox` - File display
- `--infobox` - Non-blocking info
- `--checklist` - Multiple selection
- `--radiolist` - Single selection
- `--gauge` - Progress bar
- `--passwordbox` - Hidden input

**Menu Example:**
```bash
CHOICE=$(whiptail --title "Menu" --menu "Choose an option" 15 60 4 \
    "1" "First option" \
    "2" "Second option" \
    "3" "Third option" \
    "4" "Exit" \
    3>&1 1>&2 2>&3)

# Note: 3>&1 1>&2 2>&3 redirects stderr to stdout for capturing choice
```

**Checklist Example:**
```bash
CHOICES=$(whiptail --title "Checklist" --checklist \
    "Select items (SPACE to toggle, ENTER to confirm)" 15 60 4 \
    "1" "Item 1" OFF \
    "2" "Item 2" ON \
    "3" "Item 3" OFF \
    "4" "Item 4" ON \
    3>&1 1>&2 2>&3)
```

**Sources:**
- [Bash Shell Scripting/Whiptail](https://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail)
- [Create GUI Dialog Boxes with Whiptail](https://ostechnix.com/create-gui-dialog-boxes-in-bash-scripts-with-whiptail/)
- [How to integrate dialog boxes with Whiptail](https://linuxconfig.org/how-to-integrate-dialog-boxes-in-shell-scripts-with-whiptail)

### 2.3 fzf (Recommended for Fuzzy Finding)

**Why fzf:**
- Best-in-class fuzzy finding algorithm
- Real-time filtering as you type
- Highly scriptable
- Built-in preview pane support
- Excellent for large lists

**Basic Usage:**
```bash
# Read from stdin, output selection to stdout
echo -e "one\ntwo\nthree" | fzf

# Search files in current directory
find . -type f | fzf

# With preview window
find . -type f | fzf --preview 'cat {}'
```

**Search Syntax:**
- `sbtrkt` - Fuzzy match
- `'wild` - Exact match (quote prefix)
- `^music` - Prefix match
- `.mp3$` - Suffix match
- `!fire` - Inverse match
- `^core go$ | rb$ | py$` - OR operator

**Display Options:**
```bash
# Height mode (below cursor instead of fullscreen)
fzf --height 40% --reverse

# tmux popup mode (tmux 3.2+)
fzf --tmux center,90%,80%

# With preview pane
fzf --preview 'bat --color=always {}' --preview-window right,60%

# Multi-select mode
fzf --multi
```

**Scripting Example:**
```bash
#!/bin/bash
# Find and edit file with preview
fzf_find_edit() {
    local file=$(
        fd --type f --strip-cwd-prefix | \
        fzf --query="$1" \
            --no-multi \
            --select-1 \
            --exit-0 \
            --preview 'bat --color=always --line-range :500 {}' \
            --preview-window right,60%
    )

    if [[ -n "$file" ]]; then
        $EDITOR "$file"
    fi
}

alias fe='fzf_find_edit'
```

**Key Bindings:**
- `CTRL-K/CTRL-J` or `CTRL-P/CTRL-N` - Navigate
- `Enter` - Select
- `CTRL-C/CTRL-G/ESC` - Exit
- `TAB/Shift-TAB` - Mark multiple (in multi-select mode)

**Custom Actions:**
```bash
# Use --bind to trigger actions
fzf --bind 'enter:become(vim {})'
fzf --bind 'ctrl-y:execute-silent(echo {} | pbcopy)'
fzf --bind 'ctrl-e:execute(echo {} > /tmp/selected)'
```

**Sources:**
- [fzf GitHub Repository](https://github.com/junegunn/fzf)
- [How to Install and Use fzf on Linux](https://www.linode.com/docs/guides/how-to-use-fzf/)
- [A Practical Guide to fzf: Shell Integration](https://thevaluable.dev/fzf-shell-integration/)
- [Fuzzy Finding in Bash with fzf](https://bluz71.github.io/2018/11/26/fuzzy-finding-in-bash-with-fzf.html)

### 2.4 dialog (Full-Featured Alternative)

**Advantages over whiptail:**
- More box types (calendar, timebox, tailbox, etc.)
- Color support with `--colors` flag
- More customization options

**Example:**
```bash
dialog --colors \
    --title "\Z1Colored Title" \
    --msgbox "\Z4Blue text\Zn normal text" 10 40
```

**Sources:**
- [Text Interfaces with Whiptail and Dialog](https://funprojects.blog/2022/04/06/text-interfaces-with-whiptail-and-dialog/)

### 2.5 Abstraction Libraries

**EasyBashGUI** - Unified interface across multiple backends:
```bash
# Automatically selects best available tool
# (yad, gtkdialog, kdialog, zenity, dialog, whiptail, etc.)
source easybashgui

message "Hello World"
question "Continue?"
menu "Choose" "Option 1" "Option 2" "Option 3"
```

**boxlib** - Pure Bash library for Dialog/Whiptail:
- Backports missing Whiptail features using Dialog-compatible API
- Automatically detects and uses available backend
- Portable across BSD and Linux

**Sources:**
- [EasyBashGUI GitHub](https://github.com/BashGui/easybashgui)
- [boxlib GitHub](https://github.com/iusmac/boxlib)

---

## 3. Snippet Managers

### 3.1 navi - Interactive Cheatsheet Tool

**Overview:**
Interactive command-line cheatsheet tool with fuzzy finding and parameter substitution.

**Cheatsheet Format (`.cheat` files):**
```bash
% git, code

# Change branch
git checkout <branch>

# Create and checkout new branch
git checkout -b <branch_name>

# Delete remote branch
git push origin --delete <branch>

$ branch: git branch | awk '{print $NF}'
$ branch_name: echo
```

**Format Syntax:**
- `%` - Tags (comma-separated categories)
- `#` - Command description
- `;` - Comments (ignored)
- `$` - Variable definition (generates suggestions)
- Other lines - Executable commands

**Variable System:**
- Variables wrapped in `<angle_brackets>`
- Matched to `$ variable: command` definitions
- Command output becomes selection list
- Variables can be: alphanumeric + underscore only

**Filtering:**
```bash
# Pre-filter results by query
navi query <cmd>

# Search online repositories too
navi search <cmd>

# Auto-select best match
navi --best-match
```

**Shell Integration:**
```bash
# Add to ~/.bashrc
source "$(navi widget bash)"

# Add to ~/.zshrc
source "$(navi widget zsh)"

# Add to ~/.config/fish/config.fish
source (navi widget fish)

# Default: Ctrl+G launches navi
```

**Tag Filtering:**
- Load only snippets with specific tags
- Filter by multiple tags
- Hierarchical organization

**Sources:**
- [navi GitHub Repository](https://github.com/denisidoro/navi)
- [Navi - Interactive Commandline Cheatsheet Tool](https://ostechnix.com/navi-an-interactive-commandline-cheatsheet-tool/)

### 3.2 pet - Simple Snippet Manager

**Overview:**
Simple command-line snippet manager with search and parameter substitution.

**Key Commands:**
- `pet new` - Create new snippet
- `pet list` - Display all snippets
- `pet search` - Search snippets (interactive with fzf)
- `pet exec` - Execute selected snippet
- `pet edit` - Edit snippet file

**Parameter Substitution:**
- Prompts for values when executing
- Supports placeholders in commands
- Can copy to clipboard instead of executing

**Sources:**
- [pet GitHub Repository](https://github.com/knqyf263/pet)

### 3.3 SnipKit - Manager Integration Hub

**Overview:**
CLI that integrates with multiple external snippet managers.

**Supported Managers:**
- SnippetsLab
- Snip
- GitHub Gist
- Pet
- MassCode
- File system directories

**Tag Filtering:**
```bash
# Load only snippets with specific tags
includeTags: ["snipkit", "cli"]

# Load all snippets
includeTags: []
```

**Key Features:**
- `snipkit exec` - Execute snippet
- `snipkit print` - Display without executing
- `snipkit manager add` - Add external manager
- Parameter substitution with multiple input types
- Password fields (masked)
- Path inputs with autocomplete

**Sources:**
- [SnipKit GitHub Repository](https://github.com/lemoony/snipkit)
- [SnipKit Documentation](https://lemoony.github.io/snipkit/v1.3.1/getting-started/overview/)

---

## 4. Implementation Patterns

### 4.1 Reading Input from /dev/tty

**Problem:** When stdin is redirected/piped, `read` can't get user input.

**Solution:** Read directly from `/dev/tty`:

```bash
#!/bin/bash

# This script can accept piped input AND prompt user
while IFS= read -r line; do
    echo "Processing: $line"

    # Get user confirmation - read from terminal even when stdin is piped
    read -p "Continue? (y/n): " answer < /dev/tty

    if [[ "$answer" != "y" ]]; then
        echo "Skipping..."
        continue
    fi

    # Process the line
    do_something "$line"
done
```

**When to Use:**
- Script accepts piped input on stdin
- Need interactive prompts during processing
- Menu systems called from piped contexts

**File Descriptor Notes:**
- `0` = stdin
- `1` = stdout
- `2` = stderr
- `/dev/tty` = controlling terminal
- `/dev/stdin` = `/dev/fd/0`
- `/dev/stdout` = `/dev/fd/1`
- `/dev/stderr` = `/dev/fd/2`

**Sources:**
- [Catching user input](https://tldp.org/LDP/Bash-Beginners-Guide/html/sect_08_02.html)
- [How To Use The Bash read Command](https://phoenixnap.com/kb/bash-read)
- [Bash One-Liners: Redirections](https://catonmat.net/bash-one-liners-explained-part-three)

### 4.2 Filtering Menu Items by Context

**Pattern 1: Filter before display**
```bash
#!/bin/bash

# Get all available items
all_items=(
    "global-item-1:Always available"
    "tmux-item-1:Only in tmux"
    "git-item-1:Only in git repo"
)

# Filter based on context
filtered_items=()

for item in "${all_items[@]}"; do
    key="${item%%:*}"

    # Apply context filters
    if [[ "$key" == tmux-* ]] && [[ -z "$TMUX" ]]; then
        continue  # Skip tmux items outside tmux
    fi

    if [[ "$key" == git-* ]] && ! git rev-parse --git-dir &>/dev/null; then
        continue  # Skip git items outside git repo
    fi

    filtered_items+=("$item")
done

# Display only relevant items
printf '%s\n' "${filtered_items[@]}" | fzf
```

**Pattern 2: Tag-based filtering**
```bash
#!/bin/bash

# Items with tags
declare -A items
items=(
    ["cmd1"]="tags:global,edit|desc:Edit file"
    ["cmd2"]="tags:tmux,navigation|desc:Switch window"
    ["cmd3"]="tags:git,repo|desc:Commit changes"
)

# Filter by required tags
filter_by_tags() {
    local required_tags="$1"
    local filtered=()

    for key in "${!items[@]}"; do
        local item="${items[$key]}"
        local tags="${item#*tags:}"
        tags="${tags%%|*}"

        # Check if item has required tags
        local match=true
        for req_tag in ${required_tags//,/ }; do
            if [[ ! "$tags" =~ $req_tag ]]; then
                match=false
                break
            fi
        done

        if $match; then
            filtered+=("$key")
        fi
    done

    printf '%s\n' "${filtered[@]}"
}

# Usage: show only tmux-related commands
filter_by_tags "tmux" | fzf
```

**Pattern 3: Dynamic menu generation**
```bash
#!/bin/bash

build_menu() {
    local menu_items=()

    # Always add global items
    menu_items+=("help" "Show help")
    menu_items+=("exit" "Exit program")

    # Conditionally add context-specific items
    if [[ -n "$TMUX" ]]; then
        menu_items+=("tmux-new-window" "Create tmux window")
        menu_items+=("tmux-split" "Split tmux pane")
    fi

    if git rev-parse --git-dir &>/dev/null 2>&1; then
        menu_items+=("git-status" "Show git status")
        menu_items+=("git-commit" "Commit changes")
    fi

    if [[ -f package.json ]]; then
        menu_items+=("npm-install" "Install dependencies")
        menu_items+=("npm-test" "Run tests")
    fi

    # Display menu with only relevant items
    whiptail --menu "Choose action" 20 60 10 "${menu_items[@]}" 3>&1 1>&2 2>&3
}

choice=$(build_menu)
```

### 4.3 Help Overlay Pattern

**Pattern: tmux popup with filtered help**
```bash
#!/bin/bash
# In tmux.conf

# Generate context-aware help
bind-key ? run-shell 'tmux display-popup -E -w 90% -h 80% \
    "$HOME/.tmux/scripts/show-help.sh"'
```

```bash
#!/bin/bash
# ~/.tmux/scripts/show-help.sh

# Detect context
in_copy_mode=$(tmux display-message -p "#{pane_in_mode}")
current_table=$(tmux display-message -p "#{client_key_table}")

help_text="TMUX KEYBOARD SHORTCUTS\n\n"

# Always show global shortcuts
help_text+="== GLOBAL ==\n"
help_text+="  Ctrl+b ?     - This help\n"
help_text+="  Ctrl+b :     - Command prompt\n"
help_text+="  Ctrl+b c     - New window\n\n"

# Show copy mode shortcuts if in copy mode
if [[ "$in_copy_mode" == "1" ]]; then
    help_text+="== COPY MODE (Active) ==\n"
    help_text+="  v            - Begin selection\n"
    help_text+="  y            - Copy selection\n"
    help_text+="  q            - Exit copy mode\n\n"
fi

# Show pane shortcuts
help_text+="== PANES ==\n"
help_text+="  Ctrl+b %     - Split vertical\n"
help_text+="  Ctrl+b \"     - Split horizontal\n"
help_text+="  Ctrl+b o     - Next pane\n\n"

# Display with less for scrolling
echo -e "$help_text" | less
```

### 4.4 Snippet Display Pattern

**Pattern: Format and display snippets with preview**
```bash
#!/bin/bash

# Snippet database (could be loaded from file)
declare -A snippets
snippets=(
    ["git-commit"]="git commit -m \"<message>\"|Commit with message"
    ["docker-run"]="docker run -it --rm <image> <command>|Run container"
    ["find-large"]="find . -type f -size +<size>M|Find large files"
)

# Format for display
format_snippet() {
    local key="$1"
    local value="${snippets[$key]}"
    local cmd="${value%%|*}"
    local desc="${value##*|}"

    printf "%-20s %s\n" "$key" "$desc"
}

# Preview function
preview_snippet() {
    local key="$1"
    local value="${snippets[$key]}"
    local cmd="${value%%|*}"
    local desc="${value##*|}"

    cat <<EOF
Command: $key
Description: $desc

Command line:
  $cmd

Parameters:
$(echo "$cmd" | grep -o '<[^>]*>' | sed 's/^/  - /')
EOF
}

# Export for fzf
export -f preview_snippet
export -A snippets

# Display with fzf and preview
selected=$(
    for key in "${!snippets[@]}"; do
        format_snippet "$key"
    done | sort | fzf \
        --preview 'bash -c "preview_snippet {1}"' \
        --preview-window right,60% \
        --header "Select a snippet (TAB for preview)"
)

# Extract key and execute
key=$(echo "$selected" | awk '{print $1}')
if [[ -n "$key" ]]; then
    cmd="${snippets[$key]%%|*}"

    # Substitute parameters
    while [[ "$cmd" =~ \<([^>]+)\> ]]; do
        param="${BASH_REMATCH[1]}"
        read -p "Enter $param: " value < /dev/tty
        cmd="${cmd/<$param>/$value}"
    done

    echo "Executing: $cmd"
    eval "$cmd"
fi
```

---

## 5. Code Examples

### 5.1 Complete tmux Help System

```bash
#!/bin/bash
# ~/.tmux/scripts/contextual-help.sh

# Colors for output
readonly RESET="\033[0m"
readonly BOLD="\033[1m"
readonly DIM="\033[2m"
readonly CYAN="\033[36m"
readonly YELLOW="\033[33m"
readonly GREEN="\033[32m"

# Detect context
detect_context() {
    local in_copy_mode=$(tmux display-message -p "#{pane_in_mode}")
    local pane_count=$(tmux display-message -p "#{window_panes}")
    local is_zoomed=$(tmux display-message -p "#{window_zoomed_flag}")

    echo "copy_mode=$in_copy_mode"
    echo "pane_count=$pane_count"
    echo "is_zoomed=$is_zoomed"
}

# Generate help based on context
generate_help() {
    local context="$1"

    # Parse context
    eval "$context"

    cat <<EOF
${BOLD}${CYAN}TMUX KEYBOARD SHORTCUTS${RESET}
${DIM}Context-aware help system${RESET}

${BOLD}${YELLOW}== SESSIONS ==${RESET}
  ${GREEN}Ctrl+a s${RESET}     Session switcher (fzf)
  ${GREEN}Ctrl+a S${RESET}     Session manager
  ${GREEN}Ctrl+a \$${RESET}     Rename session
  ${GREEN}Ctrl+a d${RESET}     Detach session

${BOLD}${YELLOW}== WINDOWS ==${RESET}
  ${GREEN}Ctrl+a c${RESET}     Create new window
  ${GREEN}Ctrl+a w${RESET}     Window switcher (fzf)
  ${GREEN}Ctrl+a ,${RESET}     Rename window
  ${GREEN}Ctrl+a &${RESET}     Kill window
  ${GREEN}Ctrl+a 0-9${RESET}   Switch to window N

${BOLD}${YELLOW}== PANES ==${RESET}
  ${GREEN}Ctrl+a %${RESET}     Split vertical
  ${GREEN}Ctrl+a "${RESET}     Split horizontal
  ${GREEN}Ctrl+a o${RESET}     Next pane
  ${GREEN}Ctrl+a ;${RESET}     Last pane
EOF

    # Context-specific help
    if [[ "$is_zoomed" == "1" ]]; then
        cat <<EOF
  ${GREEN}Ctrl+a z${RESET}     ${CYAN}[ACTIVE]${RESET} Un-zoom pane

EOF
    else
        cat <<EOF
  ${GREEN}Ctrl+a z${RESET}     Zoom pane
EOF
    fi

    if [[ "$pane_count" -gt 1 ]]; then
        cat <<EOF
  ${GREEN}Ctrl+a x${RESET}     Kill current pane
  ${GREEN}Ctrl+a {${RESET}     Move pane left
  ${GREEN}Ctrl+a }${RESET}     Move pane right
  ${GREEN}Ctrl+a Space${RESET} Toggle pane layout

EOF
    fi

    if [[ "$copy_mode" == "1" ]]; then
        cat <<EOF
${BOLD}${YELLOW}== COPY MODE ${CYAN}(ACTIVE)${YELLOW} ==${RESET}
  ${GREEN}v${RESET}            Begin selection
  ${GREEN}y${RESET}            Copy selection
  ${GREEN}V${RESET}            Line selection mode
  ${GREEN}C-v${RESET}          Rectangle selection
  ${GREEN}q / Escape${RESET}   Exit copy mode
  ${GREEN}/${RESET}            Search down
  ${GREEN}?${RESET}            Search up

EOF
    else
        cat <<EOF
${BOLD}${YELLOW}== COPY MODE ==${RESET}
  ${GREEN}Ctrl+a [${RESET}     Enter copy mode
  ${GREEN}Ctrl+a ]${RESET}     Paste from buffer

EOF
    fi

    cat <<EOF
${BOLD}${YELLOW}== OTHER ==${RESET}
  ${GREEN}Ctrl+a :${RESET}     Command prompt
  ${GREEN}Ctrl+a ?${RESET}     This help
  ${GREEN}Ctrl+a t${RESET}     Show time
  ${GREEN}Ctrl+a r${RESET}     Reload config

${DIM}Press 'q' to quit, arrow keys to scroll${RESET}
EOF
}

# Main
context=$(detect_context)
generate_help "$context" | less -R
```

**Add to tmux.conf:**
```tmux
# Bind ? to contextual help
bind-key ? display-popup -E -w 90% -h 90% \
    '$HOME/.tmux/scripts/contextual-help.sh'
```

### 5.2 Dynamic Menu with fzf

```bash
#!/bin/bash
# Dynamic menu that shows only relevant options

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Menu item structure: "key|description|command|tags"
readonly ALL_ITEMS=(
    "help|Show help|show_help|global"
    "reload|Reload config|reload_config|global,tmux"
    "new-window|New window|tmux new-window|tmux"
    "split-h|Split horizontal|tmux split-window -h|tmux"
    "split-v|Split vertical|tmux split-window -v|tmux"
    "git-status|Git status|git status|git"
    "git-log|Git log|git log --oneline --graph|git"
    "npm-install|Install deps|npm install|npm,node"
    "npm-test|Run tests|npm test|npm,node"
)

# Context detection
is_in_tmux() { [[ -n "$TMUX" ]]; }
is_in_git_repo() { git rev-parse --git-dir &>/dev/null 2>&1; }
is_node_project() { [[ -f package.json ]]; }

# Filter items by context
get_available_items() {
    local items=()

    for item in "${ALL_ITEMS[@]}"; do
        local tags="${item##*|}"

        # Check tag requirements
        if [[ "$tags" == *"tmux"* ]] && ! is_in_tmux; then
            continue
        fi

        if [[ "$tags" == *"git"* ]] && ! is_in_git_repo; then
            continue
        fi

        if [[ "$tags" == *"npm"* ]] && ! is_node_project; then
            continue
        fi

        items+=("$item")
    done

    printf '%s\n' "${items[@]}"
}

# Format for display
format_item() {
    local item="$1"
    local key="${item%%|*}"
    local rest="${item#*|}"
    local desc="${rest%%|*}"

    printf "%-20s %s\n" "$key" "$desc"
}

# Preview item
preview_item() {
    local item="$1"
    IFS='|' read -r key desc cmd tags <<< "$item"

    cat <<EOF
Command: $key
Description: $desc
Tags: $tags

Will execute:
  $cmd
EOF
}

# Export for fzf preview
export -f preview_item

# Main menu
show_menu() {
    local available_items=$(get_available_items)

    if [[ -z "$available_items" ]]; then
        echo "No items available in current context"
        return 1
    fi

    local selected=$(
        echo "$available_items" | while read -r item; do
            format_item "$item"
        done | fzf \
            --prompt "Select action: " \
            --header "Available commands (context-filtered)" \
            --preview 'grep "^{1}|" <<< "'"$available_items"'" | head -1 | xargs -I {} bash -c "preview_item \"{}\" "' \
            --preview-window right,50% \
            --height 60% \
            --border \
            --reverse
    )

    if [[ -z "$selected" ]]; then
        return 0
    fi

    # Extract key and find full item
    local key=$(echo "$selected" | awk '{print $1}')
    local full_item=$(echo "$available_items" | grep "^$key|")

    # Extract and execute command
    local cmd=$(echo "$full_item" | cut -d'|' -f3)

    echo "Executing: $cmd"
    eval "$cmd"
}

# Run menu
show_menu
```

### 5.3 Snippet Manager with Parameter Substitution

```bash
#!/bin/bash
# Simple snippet manager with fzf and parameter substitution

readonly SNIPPETS_FILE="$HOME/.snippets"

# Initialize snippets file if it doesn't exist
init_snippets() {
    if [[ ! -f "$SNIPPETS_FILE" ]]; then
        cat > "$SNIPPETS_FILE" <<'EOF'
# Snippet format: key|description|command|tags
git-commit|Commit with message|git commit -m "<message>"|git
git-branch|Create and checkout branch|git checkout -b <branch_name>|git
docker-run|Run container interactively|docker run -it --rm <image> <command>|docker
find-large|Find large files|find . -type f -size +<size>M -ls|filesystem
grep-code|Search in code files|grep -r "<pattern>" --include="<filepattern>" .|search
ssh-tunnel|Create SSH tunnel|ssh -L <local_port>:localhost:<remote_port> <user>@<host>|ssh,network
postgres-dump|Dump PostgreSQL database|pg_dump -U <user> -d <database> > <output_file>|postgres,database
tar-create|Create tar.gz archive|tar -czf <archive_name>.tar.gz <directory>|archive
EOF
    fi
}

# Load snippets
load_snippets() {
    grep -v '^#' "$SNIPPETS_FILE" | grep -v '^[[:space:]]*$'
}

# Format snippet for display
format_snippet() {
    local item="$1"
    IFS='|' read -r key desc cmd tags <<< "$item"
    printf "%-20s %-40s [%s]\n" "$key" "$desc" "$tags"
}

# Preview snippet
preview_snippet() {
    local item="$1"
    IFS='|' read -r key desc cmd tags <<< "$item"

    # Extract parameters
    local params=$(echo "$cmd" | grep -o '<[^>]*>' | sort -u)

    cat <<EOF
KEY: $key
TAGS: $tags

DESCRIPTION:
  $desc

COMMAND:
  $cmd

PARAMETERS:
EOF

    if [[ -n "$params" ]]; then
        echo "$params" | while read -r param; do
            echo "  - ${param:1:-1}"
        done
    else
        echo "  (no parameters)"
    fi
}

# Export for fzf
export -f preview_snippet

# Substitute parameters in command
substitute_parameters() {
    local cmd="$1"

    # Find all parameters
    while [[ "$cmd" =~ \<([^>]+)\> ]]; do
        local param="${BASH_REMATCH[1]}"
        local prompt="Enter ${param//_/ }"

        # Prompt for value
        echo -n "$prompt: " >&2
        read -r value < /dev/tty

        # Substitute in command
        cmd="${cmd/<$param>/$value}"
    done

    echo "$cmd"
}

# Execute snippet
execute_snippet() {
    local item="$1"
    IFS='|' read -r key desc cmd tags <<< "$item"

    echo "Snippet: $desc"
    echo ""

    # Substitute parameters
    local final_cmd=$(substitute_parameters "$cmd")

    echo ""
    echo "Final command:"
    echo "  $final_cmd"
    echo ""

    # Confirm execution
    read -p "Execute? (y/N): " confirm < /dev/tty

    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        echo ""
        eval "$final_cmd"
    else
        echo "Cancelled"
    fi
}

# Add new snippet
add_snippet() {
    echo "Add new snippet"
    echo ""

    read -p "Key (unique identifier): " key < /dev/tty
    read -p "Description: " desc < /dev/tty
    read -p "Command (use <param> for parameters): " cmd < /dev/tty
    read -p "Tags (comma-separated): " tags < /dev/tty

    echo "$key|$desc|$cmd|$tags" >> "$SNIPPETS_FILE"
    echo ""
    echo "Snippet added!"
}

# Edit snippets file
edit_snippets() {
    ${EDITOR:-vim} "$SNIPPETS_FILE"
}

# Main menu
main_menu() {
    local action=$(cat <<EOF | fzf --prompt "Choose action: " --header "Snippet Manager" --height 40%
Execute snippet
Add snippet
Edit snippets file
Exit
EOF
)

    case "$action" in
        "Execute snippet")
            exec_menu
            ;;
        "Add snippet")
            add_snippet
            main_menu
            ;;
        "Edit snippets file")
            edit_snippets
            main_menu
            ;;
        *)
            exit 0
            ;;
    esac
}

# Execute snippet menu
exec_menu() {
    local snippets=$(load_snippets)

    if [[ -z "$snippets" ]]; then
        echo "No snippets found. Add some first!"
        return 1
    fi

    local selected=$(
        echo "$snippets" | while read -r item; do
            format_snippet "$item"
        done | fzf \
            --prompt "Select snippet: " \
            --header "Press Enter to execute, Ctrl+C to cancel" \
            --preview 'grep "^{1}|" "'"$SNIPPETS_FILE"'" | head -1 | xargs -I {} bash -c "preview_snippet \"{}\""' \
            --preview-window right,60% \
            --height 80% \
            --border \
            --reverse
    )

    if [[ -z "$selected" ]]; then
        main_menu
        return 0
    fi

    # Extract key and find full snippet
    local key=$(echo "$selected" | awk '{print $1}')
    local full_item=$(echo "$snippets" | grep "^$key|")

    # Execute
    execute_snippet "$full_item"

    echo ""
    read -p "Press Enter to return to menu..." < /dev/tty
    main_menu
}

# Initialize and run
init_snippets
main_menu
```

### 5.4 Whiptail-Based Menu System

```bash
#!/bin/bash
# Menu system using whiptail

# Check if whiptail is available
if ! command -v whiptail &>/dev/null; then
    echo "Error: whiptail is not installed"
    exit 1
fi

# Configuration
readonly APP_NAME="System Manager"
readonly MENU_HEIGHT=20
readonly MENU_WIDTH=70
readonly MENU_LIST_HEIGHT=12

# Context detection
is_in_tmux() { [[ -n "$TMUX" ]]; }
is_in_git_repo() { git rev-parse --git-dir &>/dev/null 2>&1; }

# Build main menu based on context
build_main_menu() {
    local menu_items=()

    # Always available
    menu_items+=(
        "1" "System Information"
        "2" "Disk Usage"
        "3" "Process Monitor"
    )

    # Context-specific items
    if is_in_tmux; then
        menu_items+=(
            "tmux-1" "Tmux: New Window"
            "tmux-2" "Tmux: Split Pane"
            "tmux-3" "Tmux: List Sessions"
        )
    fi

    if is_in_git_repo; then
        menu_items+=(
            "git-1" "Git: Status"
            "git-2" "Git: Log"
            "git-3" "Git: Branches"
        )
    fi

    menu_items+=("exit" "Exit")

    echo "${menu_items[@]}"
}

# Show main menu
show_main_menu() {
    local menu_items=($(build_main_menu))

    local choice=$(
        whiptail --title "$APP_NAME" \
            --menu "Choose an option:" \
            $MENU_HEIGHT $MENU_WIDTH $MENU_LIST_HEIGHT \
            "${menu_items[@]}" \
            3>&1 1>&2 2>&3
    )

    local exitstatus=$?
    if [ $exitstatus != 0 ]; then
        return 1
    fi

    echo "$choice"
}

# Handle menu selection
handle_choice() {
    local choice="$1"

    case "$choice" in
        1)
            show_system_info
            ;;
        2)
            show_disk_usage
            ;;
        3)
            show_processes
            ;;
        tmux-*)
            handle_tmux_action "$choice"
            ;;
        git-*)
            handle_git_action "$choice"
            ;;
        exit)
            return 1
            ;;
        *)
            whiptail --msgbox "Unknown option: $choice" 8 40
            ;;
    esac

    return 0
}

# System info
show_system_info() {
    local info=$(cat <<EOF
Hostname: $(hostname)
Uptime: $(uptime -p)
Kernel: $(uname -r)
CPU: $(nproc) cores
Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')
EOF
)

    whiptail --title "System Information" --msgbox "$info" 12 60
}

# Disk usage
show_disk_usage() {
    local usage=$(df -h | grep -v tmpfs | grep -v loop)

    whiptail --title "Disk Usage" --msgbox "$usage" 20 80
}

# Process monitor
show_processes() {
    local procs=$(ps aux | head -20)

    whiptail --title "Top Processes" --msgbox "$procs" 24 100
}

# Tmux actions
handle_tmux_action() {
    local action="$1"

    case "$action" in
        tmux-1)
            tmux new-window
            whiptail --msgbox "New window created" 8 40
            ;;
        tmux-2)
            local split_type=$(
                whiptail --title "Split Pane" \
                    --menu "Choose split direction:" \
                    12 50 2 \
                    "h" "Horizontal" \
                    "v" "Vertical" \
                    3>&1 1>&2 2>&3
            )

            if [[ "$split_type" == "h" ]]; then
                tmux split-window -h
            elif [[ "$split_type" == "v" ]]; then
                tmux split-window -v
            fi
            ;;
        tmux-3)
            local sessions=$(tmux list-sessions 2>/dev/null || echo "No sessions")
            whiptail --title "Tmux Sessions" --msgbox "$sessions" 15 70
            ;;
    esac
}

# Git actions
handle_git_action() {
    local action="$1"

    case "$action" in
        git-1)
            local status=$(git status 2>&1)
            whiptail --title "Git Status" --msgbox "$status" 20 80 --scrolltext
            ;;
        git-2)
            local log=$(git log --oneline -n 20 2>&1)
            whiptail --title "Git Log" --msgbox "$log" 20 80 --scrolltext
            ;;
        git-3)
            local branches=$(git branch -a 2>&1)
            whiptail --title "Git Branches" --msgbox "$branches" 20 60 --scrolltext
            ;;
    esac
}

# Main loop
main() {
    while true; do
        local choice=$(show_main_menu)

        if [[ -z "$choice" ]]; then
            break
        fi

        if ! handle_choice "$choice"; then
            break
        fi
    done

    clear
    echo "Goodbye!"
}

# Run
main
```

---

## Summary

### Key Takeaways

1. **tmux Help Systems**:
   - Use `list-keys` for viewing bindings
   - Use `display-popup` for rich help overlays (tmux 3.2+)
   - Context-aware help improves usability

2. **Interactive Menus**:
   - **whiptail** - Best for simple, portable menus
   - **fzf** - Best for fuzzy finding and filtering
   - **dialog** - Best for feature-rich TUIs
   - All can be combined with context detection

3. **Snippet Managers**:
   - **navi** - Best for cheatsheets with tags
   - **pet** - Best for simple snippet storage
   - **SnipKit** - Best for integrating multiple managers
   - All support parameter substitution

4. **Implementation Patterns**:
   - Always use `/dev/tty` when stdin is redirected
   - Filter menu items by context before display
   - Use tags/metadata for flexible filtering
   - Preview panes improve user experience

### Recommended Stack for Bash Scripts

For building robust help and menu systems:

1. **Detection**: Detect context (tmux, git, etc.)
2. **Filtering**: Filter items by context before display
3. **Display**: Use fzf for rich filtering, whiptail for simple menus
4. **Help**: Use tmux popup for overlays, less for scrollable help
5. **Input**: Use `/dev/tty` for interactive prompts

---

## References

### Official Documentation
- [tmux manual page](https://man7.org/linux/man-pages/man1/tmux.1.html)
- [fzf GitHub](https://github.com/junegunn/fzf)
- [navi GitHub](https://github.com/denisidoro/navi)
- [Bash Beginners Guide](https://tldp.org/LDP/Bash-Beginners-Guide/)

### Tutorials and Guides
- [Tmux Cheat Sheet](https://tmuxcheatsheet.com/)
- [A Practical Guide to fzf](https://thevaluable.dev/fzf-shell-integration/)
- [Whiptail Dialog Boxes](https://ostechnix.com/create-gui-dialog-boxes-in-bash-scripts-with-whiptail/)
- [Bash One-Liners Explained](https://catonmat.net/bash-one-liners-explained-part-three)

### Community Resources
- [Waylon Walker's tmux blog](https://waylonwalker.com/tmux-display-message/)
- [Mad Professor: tmux Keybindings](https://madprofessorblog.org/articles/creating-a-tmux-keybinding-for-pop-up-sessions/)
- [Fuzzy Finding in Bash](https://bluz71.github.io/2018/11/26/fuzzy-finding-in-bash-with-fzf.html)

---

**End of Research Document**
