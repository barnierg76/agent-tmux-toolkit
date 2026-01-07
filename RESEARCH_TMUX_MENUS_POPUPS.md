# tmux Dynamic Menus, Popups, and Navigation Research

Comprehensive research on tmux's built-in `display-menu` and `display-popup` commands, format strings for dynamic content generation, and programmatic session/pane querying for the agent-tmux-toolkit project.

---

## Table of Contents

1. [display-menu Command](#display-menu-command)
2. [display-popup Command](#display-popup-command)
3. [Dynamic Menu Generation](#dynamic-menu-generation)
4. [Listing Sessions and Panes](#listing-sessions-and-panes)
5. [Format Variables](#format-variables)
6. [Styling Options](#styling-options)
7. [Key Binding for Menus](#key-binding-for-menus)
8. [Practical Examples](#practical-examples)
9. [Capturing Menus and Popups (Screenshots)](#capturing-menus-and-popups-screenshots)
10. [References](#references)

---

## display-menu Command

### Overview

The `display-menu` command (alias: `menu`) displays an interactive menu on the client. Menus can contain static or dynamic content and support mouse and keyboard navigation.

### Syntax

```bash
tmux display-menu [-OM] [-b border-lines] [-c target-client] [-C starting-choice] \
  [-H selected-style] [-s style] [-S border-style] [-t target-pane] \
  [-T title] [-x position] [-y position] \
  name key command [name key command ...]
```

### Key Options

#### Menu Structure

Each menu item requires three arguments:
- **name**: Menu item text (can use format variables like `#{session_name}`)
- **key**: Keyboard shortcut (single character, or empty `""` for none)
- **command**: tmux command to execute when selected

Special menu items:
- **Disabled items**: Name starts with `-` (shown dimmed, not selectable)
- **Separator**: Empty name `""` with empty key and command

#### Position (-x and -y)

Special position values:

| Value | Flag  | Meaning |
|-------|-------|---------|
| `C`   | Both  | Center of terminal |
| `R`   | `-x`  | Right side of terminal |
| `P`   | Both  | Bottom left of pane |
| `M`   | Both  | Mouse position |
| `W`   | Both  | Window position on status line |
| `S`   | `-y`  | Line above or below status line |

Can also use format expressions with these special variables:
- `#{popup_centre_x}`, `#{popup_centre_y}` - Centered in client
- `#{popup_mouse_x}`, `#{popup_mouse_y}` - Mouse position
- `#{popup_pane_left}`, `#{popup_pane_right}` - Pane edges
- `#{popup_pane_top}`, `#{popup_pane_bottom}` - Pane edges
- `#{popup_height}`, `#{popup_width}` - Menu dimensions

#### Styling Options

- **-b border-lines**: Border style (see [Border Styles](#border-styles))
- **-H selected-style**: Style for selected item (see [STYLES](#styling-options))
- **-s style**: General menu style
- **-S border-style**: Border style
- **-T title**: Menu title (supports format variables)

#### Behavior Options

- **-C starting-choice**: Default selected item index
- **-O**: Keep menu open when releasing mouse without selection
- **-M**: Menu handles mouse events (default only for mouse-opened menus)

### Navigation Keys

| Key   | Function |
|-------|----------|
| Enter | Choose selected item |
| Up    | Select previous item |
| Down  | Select next item |
| q     | Exit menu |
| [0-9a-z] | Direct selection via shortcut key |

### Basic Example

```bash
# Static menu
tmux display-menu -T "Session Management" \
  "New Session" n "new-session" \
  "Kill Session" k "kill-session" \
  "" "" "" \
  "Detach" d "detach-client"
```

---

## display-popup Command

### Overview

The `display-popup` command (alias: `popup`) displays a popup window running a shell command. Popups are rectangular boxes drawn over panes.

### Syntax

```bash
tmux display-popup [-BCEkN] [-b border-lines] [-c target-client] \
  [-d start-directory] [-e environment] [-h height] [-s style] \
  [-S border-style] [-t target-pane] [-T title] [-w width] \
  [-x position] [-y position] [shell-command [argument ...]]
```

### Key Options

#### Size Options

- **-w width**: Width (number or percentage like `80%`)
- **-h height**: Height (number or percentage like `50%`)
- Default: 50% of terminal size if omitted

#### Border Options

- **-B**: No border
- **-b border-lines**: Border style (see [Border Styles](#border-styles))

#### Behavior Options

- **-E**: Close popup automatically when command exits
- **-EE**: Close only if command exits with success
- **-k**: Allow any key to dismiss (not just Escape or Ctrl-c)
- **-N**: Disable -E, -EE, or -k options
- **-C**: Close any existing popup

#### Environment and Directory

- **-d start-directory**: Working directory for command
- **-e VARIABLE=value**: Set environment variable (can use multiple times)

#### Position Options

Same as `display-menu`: `-x` and `-y` support special values like `C`, `M`, `P`, etc.

### Examples

```bash
# Simple popup with fzf
tmux display-popup -E -w 80% -h 60% \
  'tmux list-sessions -F "#S" | fzf | xargs tmux switch-client -t'

# Popup at mouse position
tmux display-popup -x M -y M -E 'ls -la'

# Popup with custom title and no border
tmux display-popup -B -T "Git Status" -E 'git status'
```

---

## Dynamic Menu Generation

### Using Format Loops

tmux supports format loops to dynamically generate content:

- **#{S:format}**: Loop over sessions
- **#{W:format}**: Loop over windows
- **#{P:format}**: Loop over panes
- **#{L:format}**: Loop over clients

### Dynamic Session Menu Example

Using shell to generate menu items:

```bash
# Method 1: Using awk to build menu
tmux display-menu -T "Switch Session" \
  $(tmux list-sessions -F '#S' | awk 'BEGIN {ORS=" "} {print $1, NR, "\"switch-client -t", $1 "\""}')

# Method 2: Using shell loop
menu_items=""
i=1
for session in $(tmux list-sessions -F '#S'); do
  menu_items="$menu_items \"$session\" \"$i\" \"switch-client -t $session\""
  i=$((i + 1))
done
eval "tmux display-menu -T \"Switch Session\" $menu_items"
```

### Dynamic Pane Menu Example

```bash
# Generate menu to switch to any pane
menu_items=""
i=1
while IFS=: read -r session window pane title; do
  menu_items="$menu_items \"$session:$window.$pane - $title\" \"\" \"select-pane -t $session:$window.$pane\""
  i=$((i + 1))
done < <(tmux list-panes -a -F '#{session_name}:#{window_index}:#{pane_index}:#{pane_title}')

eval "tmux display-menu -T \"Switch to Pane\" -x C -y C $menu_items"
```

### Conditional Menu Items

Using format conditionals to show/hide items:

```bash
# Only show "Swap with marked" if marked pane exists
tmux display-menu \
  "#{?#{pane_marked_set},Swap with Marked,}" "" "#{?#{pane_marked_set},swap-pane,}" \
  "Split Horizontal" h "split-window -h" \
  "Split Vertical" v "split-window -v"
```

---

## Listing Sessions and Panes

### list-sessions Command

**Syntax**: `tmux list-sessions [-F format] [-f filter]` (alias: `ls`)

List all sessions with custom format.

**Examples**:

```bash
# Basic session list
tmux list-sessions

# Custom format
tmux list-sessions -F "#{session_name}:#{session_windows}:#{session_attached}"

# Output: session1:3:1

# Filter attached sessions only
tmux list-sessions -f '#{session_attached}'

# Get just session names
tmux list-sessions -F '#S'
```

### list-windows Command

**Syntax**: `tmux list-windows [-a] [-F format] [-f filter] [-t target-session]` (alias: `lsw`)

List windows in session (or all with `-a`).

**Examples**:

```bash
# List windows in current session
tmux list-windows -F "#{window_index}:#{window_name}:#{window_active}"

# List all windows across all sessions
tmux list-windows -a -F "#{session_name}:#{window_index}:#{window_name}"
```

### list-panes Command

**Syntax**: `tmux list-panes [-as] [-F format] [-f filter] [-t target]` (alias: `lsp`)

List panes in window/session/all.

**Examples**:

```bash
# List panes in current window
tmux list-panes

# List all panes on server
tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index} #{pane_title} [#{pane_current_command}]"

# Output: agents:1.1 Ready [node]

# List panes in session
tmux list-panes -s -t mysession

# Get pane IDs only
tmux list-panes -a -F "#{pane_id}"
```

---

## Format Variables

### Session Format Variables

| Variable | Alias | Description |
|----------|-------|-------------|
| `session_name` | `#S` | Session name |
| `session_id` | `$` | Unique session ID |
| `session_windows` | | Number of windows |
| `session_attached` | | Number of attached clients |
| `session_created` | | Creation timestamp |
| `session_activity` | | Last activity timestamp |
| `session_group` | | Session group name |
| `session_format` | | 1 if format is for session |

### Window Format Variables

| Variable | Alias | Description |
|----------|-------|-------------|
| `window_name` | `#W` | Window name |
| `window_id` | `@` | Unique window ID |
| `window_index` | `#I` | Window index |
| `window_active` | | 1 if active window |
| `window_activity` | | Last activity timestamp |
| `window_format` | | 1 if format is for window |
| `window_panes` | | Number of panes |
| `window_width` | | Window width |
| `window_height` | | Window height |

### Pane Format Variables

| Variable | Alias | Description |
|----------|-------|-------------|
| `pane_id` | `#D` | Unique pane ID (e.g., %1) |
| `pane_index` | `#P` | Pane index |
| `pane_title` | `#T` | Pane title |
| `pane_current_command` | | Current command |
| `pane_current_path` | | Current directory |
| `pane_width` | | Pane width |
| `pane_height` | | Pane height |
| `pane_active` | | 1 if active pane |
| `pane_in_mode` | | Number of modes active |
| `pane_mode` | | Mode name (e.g., copy-mode) |
| `pane_marked` | | 1 if marked pane |
| `pane_marked_set` | | 1 if any marked pane exists |

### Format Conditionals

```bash
# If-then-else
#{?variable,true_value,false_value}

# Example: show attached/detached status
#{?session_attached,attached,detached}

# Nested conditionals
#{?#{pane_marked_set},Marked,#{?pane_active,Active,Inactive}}
```

### Format Comparisons

```bash
# Equality
#{==:#{session_name},mysession}

# Inequality
#{!=:#{pane_index},0}

# Greater/less than
#{>:#{session_windows},5}
#{<:#{pane_width},80}

# Logical OR
#{||:#{pane_in_mode},#{pane_marked}}

# Logical AND
#{&&:#{session_attached},#{>:#{session_windows},1}}

# Logical NOT
#{!:#{pane_active}}
```

### Format Loops

```bash
# Loop over sessions
tmux display -p '#{S:#{session_name} }'
# Output: session1 session2 session3

# Loop over windows with format
tmux display -p '#{W:#{window_index}:#{window_name} }'

# Loop over panes
tmux display -p '#{P:#{pane_index}:#{pane_title} }'

# Provide different format for current item
tmux display -p '#{W:#{window_index},*#{window_index}*}'
# Output: 1 *2* 3  (if window 2 is current)
```

### Format Modifiers

```bash
# Length
#{l:session_name}

# Basename
#{b:pane_current_path}

# Dirname
#{d:pane_current_path}

# Substring (first 10 chars)
#{=10:pane_title}

# Substring (last 10 chars)
#{=-10:pane_title}

# Substring with ellipsis
#{=/10/...:pane_title}

# Pad to width (left-pad to 20)
#{p20:session_name}

# Time format
#{t:session_created}

# Custom time format
#{t/f/%%H#:%%M:session_activity}
```

---

## Styling Options

### Border Styles

The `-b` option accepts these border line types:

| Type | Description |
|------|-------------|
| `single` | Single lines using ACS or UTF-8 (default) |
| `rounded` | Single lines with rounded corners (UTF-8) |
| `double` | Double lines (UTF-8) |
| `heavy` | Heavy/thick lines (UTF-8) |
| `simple` | Simple ASCII characters |
| `padded` | Simple ASCII space character |
| `none` | No border |

**Example**:
```bash
tmux display-menu -b rounded -T "Rounded Menu" \
  "Option 1" 1 "command1" \
  "Option 2" 2 "command2"
```

### Style Syntax

Styles use space or comma-separated attributes:

```bash
# Foreground/background colors
fg=colour bg=colour

# Colors can be:
# - Named: black, red, green, yellow, blue, magenta, cyan, white
# - Bright: brightred, brightgreen, etc.
# - Palette: colour0 to colour255
# - Hex: #ffffff
# - Special: default, terminal

# Attributes
bold, dim, underscore, blink, reverse, italics, strikethrough

# Examples
fg=yellow bold underscore
bg=black,fg=white,bold
fg=#00ff00,bg=colour235
```

### Menu Styling Options

```bash
# Style selected item
-H "fg=black,bg=yellow,bold"

# Style menu background
-s "fg=white,bg=colour235"

# Style menu border
-S "fg=cyan"

# Complete example
tmux display-menu \
  -T "Styled Menu" \
  -s "bg=colour235,fg=white" \
  -S "fg=cyan" \
  -H "bg=yellow,fg=black,bold" \
  "Item 1" 1 "command1" \
  "Item 2" 2 "command2"
```

### Popup Styling

```bash
# Popup with styling
tmux display-popup \
  -b rounded \
  -s "bg=colour235,fg=white" \
  -S "fg=green" \
  -T "Styled Popup" \
  -w 60% -h 40% \
  -E 'echo "Hello World"'
```

---

## Key Binding for Menus

### Binding Static Menus

```bash
# In .tmux.conf
bind-key m display-menu -T "Main Menu" \
  "New Window" n "new-window" \
  "Split Horizontal" h "split-window -h" \
  "Split Vertical" v "split-window -v" \
  "" "" "" \
  "Kill Pane" k "kill-pane"
```

### Binding Dynamic Menus

Use `run-shell` to generate menu dynamically:

```bash
# Session switcher
bind-key s run-shell ' \
  menu_items=""; \
  i=1; \
  for session in $(tmux list-sessions -F "#S"); do \
    menu_items="$menu_items \"$session\" \"$i\" \"switch-client -t $session\""; \
    i=$((i + 1)); \
  done; \
  eval "tmux display-menu -T \"Switch Session\" $menu_items"'
```

### Binding Popups

```bash
# Session browser popup
bind-key S display-popup -E -w 50% -h 50% \
  'tmux list-sessions | fzf | cut -d: -f1 | xargs tmux switch-client -t'

# File browser popup
bind-key f display-popup -E -w 80% -h 80% -d "#{pane_current_path}" \
  'find . -type f | fzf | xargs ${EDITOR:-vim}'
```

### Using command-prompt for Input

```bash
# Rename session with prompt
bind-key r command-prompt -I "#S" "rename-session '%%'"

# Create new session with name
bind-key N command-prompt "new-session -s '%%'"
```

### Key Tables for Complex Bindings

```bash
# Create a menu mode
bind-key m switch-client -T menu_mode

bind-key -T menu_mode s display-menu -T "Sessions" \
  $(tmux list-sessions -F '#S #{session_windows}' | awk '{print $1, NR, "\"switch-client -t " $1 "\""}')

bind-key -T menu_mode w display-menu -T "Windows" \
  "New Window" n "new-window" \
  "Kill Window" k "kill-window"

bind-key -T menu_mode p display-menu -T "Panes" \
  "Split H" h "split-window -h" \
  "Split V" v "split-window -v"
```

---

## Practical Examples

### Example 1: Complete Session Switcher

**Bash function**:

```bash
#!/bin/bash
# tmux-session-menu.sh

menu_items=""
index=1

while IFS=: read -r name windows attached; do
  # Format: "session_name (3 windows) [attached]"
  label="$name ($windows windows)"
  if [ "$attached" -gt 0 ]; then
    label="$label [attached]"
  fi

  menu_items="$menu_items \"$label\" \"$index\" \"switch-client -t $name\""
  index=$((index + 1))
done < <(tmux list-sessions -F '#{session_name}:#{session_windows}:#{session_attached}')

eval "tmux display-menu -T \"Switch Session\" -x C -y C $menu_items"
```

**Keybinding**:
```bash
bind-key s run-shell '~/.tmux/scripts/tmux-session-menu.sh'
```

### Example 2: Pane Navigation Menu

```bash
#!/bin/bash
# tmux-pane-menu.sh

current_pane=$(tmux display -p '#{pane_id}')
menu_items=""

while IFS='|' read -r pane_id session window pane_idx title cmd; do
  # Skip current pane
  [ "$pane_id" = "$current_pane" ] && continue

  # Format label
  label="$session:$window.$pane_idx - $title [$cmd]"

  menu_items="$menu_items \"$label\" \"\" \"select-pane -t $pane_id\""
done < <(tmux list-panes -a -F '#{pane_id}|#{session_name}|#{window_index}|#{pane_index}|#{pane_title}|#{pane_current_command}')

if [ -z "$menu_items" ]; then
  tmux display-message "No other panes available"
else
  eval "tmux display-menu -T \"Jump to Pane\" -x C -y C $menu_items"
fi
```

### Example 3: Context Menu for Pane Actions

```bash
# Right-click menu for pane
bind-key -n MouseDown3Pane display-menu -T "Pane Menu" -x M -y M \
  "#{?#{pane_marked},Unmark,Mark}" m "select-pane -#{?#{pane_marked},M,m}" \
  "#{?#{pane_marked_set},Swap with Marked,}" "" "#{?#{pane_marked_set},swap-pane,}" \
  "" "" "" \
  "Split Horizontal" h "split-window -h -c '#{pane_current_path}'" \
  "Split Vertical" v "split-window -v -c '#{pane_current_path}'" \
  "" "" "" \
  "Kill Pane" k "kill-pane" \
  "Break to Window" b "break-pane"
```

### Example 4: Interactive Window Selector Popup

```bash
# Fuzzy window finder
bind-key w display-popup -E -w 60% -h 50% \
  'tmux list-windows -a -F "#{session_name}:#{window_index} #{window_name}" | \
   fzf --preview "tmux capture-pane -t {} -p" | \
   cut -d\" \" -f1 | xargs tmux select-window -t'
```

### Example 5: Agent Research Integration

```bash
#!/bin/bash
# agent-pane-handoff.sh
# Send context from current pane to agent research pane

current_pane=$(tmux display -p '#{pane_id}')
menu_items=""

# Find agent panes
while IFS='|' read -r pane_id title; do
  [ "$pane_id" = "$current_pane" ] && continue

  # Only show panes with "agent" or "research" in title
  if echo "$title" | grep -qi -e agent -e research; then
    menu_items="$menu_items \"$title\" \"\" \"run-shell 'tmux capture-pane -p -S - | tmux load-buffer - && tmux paste-buffer -t $pane_id'\""
  fi
done < <(tmux list-panes -a -F '#{pane_id}|#{pane_title}')

if [ -z "$menu_items" ]; then
  tmux display-message "No agent panes found"
else
  eval "tmux display-menu -T \"Send to Agent\" -x M -y M $menu_items"
fi
```

### Example 6: Styled Main Menu

```bash
# Comprehensive main menu with styling
bind-key Space display-menu -T "#[align=centre]Main Menu" \
  -x C -y C \
  -b rounded \
  -s "bg=colour235,fg=white" \
  -S "fg=cyan,bold" \
  -H "bg=yellow,fg=black,bold" \
  "Sessions" "" "" \
  "  New Session" n "command-prompt \"new-session -s '%%'\"" \
  "  Switch Session" s "run-shell '~/.tmux/scripts/session-menu.sh'" \
  "  Kill Session" k "confirm-before -p \"Kill session #S?\" kill-session" \
  "" "" "" \
  "Windows" "" "" \
  "  New Window" w "new-window -c '#{pane_current_path}'" \
  "  Rename Window" r "command-prompt -I \"#W\" \"rename-window '%%'\"" \
  "" "" "" \
  "Panes" "" "" \
  "  Split Horizontal" h "split-window -h -c '#{pane_current_path}'" \
  "  Split Vertical" v "split-window -v -c '#{pane_current_path}'" \
  "  Jump to Pane" j "run-shell '~/.tmux/scripts/pane-menu.sh'"
```

### Example 7: Dynamic Window List with Format Loops

```bash
# Using format loops (requires tmux 3.2+)
bind-key W display-menu -T "Windows" -x C -y C \
  '#{W:#{window_index}: #{window_name},#{window_index}: #{window_name} (current)}' \
  "" "select-window -t {}"
```

---

## Key Findings for agent-tmux-toolkit

### 1. Dynamic Menu Generation Strategies

**Best approach**: Use shell scripts with `eval` to build dynamic menus:

```bash
# Pattern for dynamic menus
build_menu() {
  local items=""
  while IFS=delimiter read -r fields; do
    items="$items \"$label\" \"$key\" \"$command\""
  done < <(tmux list-command -F format)
  eval "tmux display-menu -T \"Title\" $items"
}
```

### 2. Session/Pane Discovery

Use format strings for efficient querying:

```bash
# Get all sessions with metadata
tmux list-sessions -F '#{session_name}:#{session_windows}:#{session_attached}'

# Get all panes across all sessions
tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index}|#{pane_id}|#{pane_title}'

# Filter specific panes
tmux list-panes -a -F '#{pane_id}' -f '#{m:*agent*,#{pane_title}}'
```

### 3. Context Handoff Pattern

For sending pane content to agent:

```bash
# 1. Capture from source pane
tmux capture-pane -p -t SOURCE_PANE -S -

# 2. Load into buffer
tmux load-buffer -

# 3. Paste to target
tmux paste-buffer -t AGENT_PANE

# Combined with menu
"Send to Agent" "" "run-shell 'tmux capture-pane -p -S - | tmux load-buffer - && tmux paste-buffer -t #{TARGET}'"
```

### 4. Popup vs Menu Trade-offs

**Use display-menu when**:
- Need keyboard shortcuts (1-9, a-z)
- Simple list of commands
- Want native tmux look
- Need mouse click support

**Use display-popup when**:
- Need complex filtering (fzf, grep)
- Want preview panes
- Need external programs
- Want custom UI/colors

### 5. Recommended Keybindings

```bash
# Core navigation
bind-key s <session-menu>      # Session switcher
bind-key w <window-menu>       # Window switcher
bind-key p <pane-menu>         # Pane jumper

# Context handoff
bind-key a <agent-menu>        # Send to agent
bind-key C-a <agent-popup>     # Agent with preview

# Main menu
bind-key Space <main-menu>     # Everything
```

### 6. Format Performance

Format loops are efficient but can be slow with many items:

```bash
# Fast: Direct list commands
tmux list-sessions -F '#S'

# Slower: Format loops (but more flexible)
tmux display -p '#{S:#{session_name} }'

# For large lists, prefer direct list commands piped to shell
```

---

## Capturing Menus and Popups (Screenshots)

### The Challenge

tmux menus and popups are **overlay elements** that float above pane content. Standard `capture-pane` commands cannot capture these overlays—they only capture the underlying pane content. This presents a documentation challenge when trying to preserve visual examples of menus and popups.

### Built-in tmux Capture Commands

#### capture-pane Command

The `capture-pane` command is tmux's built-in mechanism for capturing pane content (textual screenshots), but it **does not capture overlays like menus or popups**.

**Syntax**:
```bash
tmux capture-pane [-aCeJNpPq] [-b buffer-name] [-E end-line] [-S start-line] [-t target-pane]
```

**Key Options**:

| Option | Description |
|--------|-------------|
| `-p` | Print output to stdout (instead of buffer) |
| `-S start-line` | Starting line number (use `-` for beginning of history) |
| `-E end-line` | Ending line number (use `-` for end of visible content) |
| `-e` | Include escape sequences (preserves colors) |
| `-C` | Escape non-printable characters |
| `-N` | Preserve trailing spaces |
| `-J` | Preserve trailing spaces and join wrapped lines |
| `-b buffer-name` | Capture to named buffer |
| `-t target-pane` | Target specific pane |

**Line Number Reference**:
- **Positive numbers**: Lines in visible pane (0 = first visible line)
- **Negative numbers**: Lines in scrollback history
- **`-`**: Special marker:
  - For `-S`: Start of scrollback history
  - For `-E`: End of visible content

**Common Usage Patterns**:

```bash
# Capture only visible content to stdout
tmux capture-pane -p

# Capture entire pane including scrollback
tmux capture-pane -p -S - -E -

# Save to file directly
tmux capture-pane -p -S - > ~/output.txt

# Two-step capture with buffer
tmux capture-pane -S -
tmux save-buffer filename.txt

# Capture last 10000 lines
tmux capture-pane -pS -10000 > ./last-10000-lines.out

# Capture with colors/escape codes preserved
tmux capture-pane -pe -S - -E -

# Capture specific pane to named buffer
tmux capture-pane -b my-capture -t %0 -S -
```

**Important Configuration**:

The `history-limit` setting determines how much scrollback can be captured:

```bash
# In .tmux.conf - set high limit for modern systems
set -g history-limit 50000
```

**Note**: Only lines kept in the scrollback buffer can be captured. Set `history-limit` appropriately for your needs.

#### Key Bindings for Capture

Add to `.tmux.conf`:

```bash
# Quick save entire scrollback
bind-key S capture-pane -b temp-capture-buffer -S - \; \
           save-buffer -b temp-capture-buffer ~/tmux.log \; \
           delete-buffer -b temp-capture-buffer

# Interactive save with prompt
bind-key P command-prompt -p 'save history to filename:' \
           -I '~/tmux.history' \
           'capture-pane -S -32768 ; save-buffer %1 ; delete-buffer'

# Capture to vim for viewing
bind-key V capture-pane -p -S - | vim -
```

### tmux-logging Plugin

**Repository**: [tmux-plugins/tmux-logging](https://github.com/tmux-plugins/tmux-logging)

The standard plugin for screen capture and logging in tmux. Provides convenient key bindings for common capture operations.

#### Features

- Save visible text (textual screenshot)
- Save complete scrollback history
- Record terminal actions (logging)
- Automatic logging
- Configurable save locations

#### Key Bindings

| Key | Action |
|-----|--------|
| `prefix + Alt + p` | Take screenshot (save visible pane content) |
| `prefix + Alt + Shift + p` | Save complete history |
| `prefix + Shift + p` | Toggle logging (start/stop recording) |
| `prefix + Alt + c` | Clear pane history |

#### Installation

```bash
# Add to .tmux.conf
set -g @plugin 'tmux-plugins/tmux-logging'

# Install with TPM
prefix + I
```

#### Configuration

```bash
# Customize save paths
set -g @logging-path "~/tmux-logs"
set -g @screen-capture-path "~/tmux-screenshots"
set -g @save-complete-history-path "~/tmux-history"

# Customize filename format
set -g @logging-filename "tmux-#{session_name}-#{window_index}-#{pane_index}-%Y%m%d-%H%M%S.log"
set -g @screen-capture-filename "screenshot-#{session_name}-#{window_index}-#{pane_index}-%Y%m%d-%H%M%S.txt"
```

### Capturing Menus and Popups Visually

Since `capture-pane` cannot capture overlay elements, you need to use external screenshot tools.

#### 1. Terminal Emulator Screenshots

The most reliable method for visual documentation of menus and popups:

**iTerm2** (macOS):
```bash
# Built-in screenshot
Cmd + Shift + 4    # Selection screenshot
Cmd + Shift + 3    # Full window screenshot

# Or use macOS system screenshot
Cmd + Shift + 4    # Selection
Cmd + Shift + 5    # Screenshot menu with recording
```

**Alacritty**:
```bash
# Use system screenshot tools
# macOS: Cmd + Shift + 4
# Linux: Use gnome-screenshot, scrot, or flameshot
```

**kitty**:
```bash
# kitty has built-in screenshot capability
kitty +kitten icat --print-window-size

# Use system screenshot tools for simpler approach
```

**GNOME Terminal** (Linux):
```bash
PrtScn           # Full screen
Shift + PrtScn   # Selection
Alt + PrtScn     # Current window
```

**Windows Terminal**:
```bash
# Use Windows Snipping Tool
Win + Shift + S

# Or PowerToys Screen Ruler
```

#### 2. Terminal Recording Tools

For animated demonstrations showing menu/popup interactions:

**asciinema** - Record and replay terminal sessions:
```bash
# Record session
asciinema rec demo.cast

# Playback
asciinema play demo.cast

# Upload to share
asciinema upload demo.cast

# Convert to GIF using agg
agg demo.cast demo.gif

# Convert to GIF using asciicast2gif
asciicast2gif -s 2 demo.cast demo.gif
```

**ttyd** - Share terminal via web browser (can screenshot from browser):
```bash
# Start web terminal server
ttyd -p 8080 tmux attach

# Access in browser at http://localhost:8080
# Take screenshots using browser screenshot tools
```

**VHS** - Generate terminal GIFs from scripts:
```bash
# Create a .tape file describing the session
cat > demo.tape <<'EOF'
Output demo.gif
Set Shell bash
Set Width 1200
Set Height 800

Type "tmux"
Enter
Sleep 1s

Type "C-b m"  # Open menu
Sleep 2s

Screenshot demo.png
EOF

# Generate GIF
vhs demo.tape
```

#### 3. Textual Documentation Approach

For non-visual documentation when screenshots aren't practical:

**Capture menu definition**:
```bash
# Extract menu from config
grep -A 20 "display-menu" ~/.tmux.conf > menu-definition.txt

# Document menu structure in markdown
cat > menu-structure.md <<'EOF'
## Main Menu

Press `prefix + Space` to open

### Menu Items:
1. **New Session** (n) - Create new session with name prompt
2. **Switch Session** (s) - Display session picker
---
3. **Split Horizontal** (h) - Split pane horizontally
4. **Split Vertical** (v) - Split pane vertically
---
5. **Quit** (q) - Close menu
EOF
```

**ASCII art representation**:
```bash
cat > menu-ascii.txt <<'EOF'
┌─ Main Menu ────────────────┐
│ New Session           (n)  │
│ Switch Session        (s)  │
│────────────────────────────│
│ Split Horizontal      (h)  │
│ Split Vertical        (v)  │
│────────────────────────────│
│ Quit                  (q)  │
└────────────────────────────┘
EOF
```

#### 4. Automated Documentation Scripts

**Document all menus in config**:
```bash
#!/bin/bash
# document-menus.sh

echo "# Tmux Menus Documentation" > menus.md
echo "" >> menus.md
echo "Generated: $(date)" >> menus.md
echo "" >> menus.md

# Extract all display-menu commands
grep -n "display-menu\|display-popup" ~/.tmux.conf | while IFS=: read -r linenum line; do
    echo "## Command at line $linenum" >> menus.md
    echo '```bash' >> menus.md

    # Extract the full command (handle multi-line)
    sed -n "${linenum},/[^\\]$/p" ~/.tmux.conf >> menus.md

    echo '```' >> menus.md
    echo "" >> menus.md
done

echo "Documentation generated in menus.md"
```

**Capture diagnostic information**:
```bash
#!/bin/bash
# tmux-diagnostic.sh

{
    echo "=== Tmux Version ==="
    tmux -V
    echo ""

    echo "=== Server Info ==="
    tmux info
    echo ""

    echo "=== Current Session ==="
    tmux display-message -p 'Session: #{session_name}'
    tmux display-message -p 'Window: #{window_index}:#{window_name}'
    tmux display-message -p 'Pane: #{pane_index} (#{pane_id})'
    echo ""

    echo "=== All Sessions ==="
    tmux list-sessions
    echo ""

    echo "=== Current Pane Content ==="
    tmux capture-pane -p -S -

} > tmux-diagnostic.txt

echo "Diagnostic saved to tmux-diagnostic.txt"
```

### Best Practices for Documentation

#### Workflow for Documenting Menus/Popups

1. **Define the menu/popup** in your config file
2. **Test interactively** to ensure it works correctly
3. **Screenshot the visual result** using terminal emulator screenshot
4. **Extract config** for textual reference in documentation
5. **Document behavior** in markdown with both:
   - Screenshot image
   - Config code block
   - Description of each menu item
6. **Commit both** the config and documentation together

#### Example Documentation Template

```markdown
## Session Switcher Menu

Press `prefix + s` to open the session switcher menu.

![Session Switcher Screenshot](screenshots/session-switcher.png)

### Configuration

```bash
bind-key s run-shell '~/.tmux/scripts/session-menu.sh'
```

### Menu Items

Dynamic menu showing all available sessions with:
- Session name
- Number of windows
- Attached status indicator

Each session shows: `session-name (3 windows) [attached]`

### Features

- Keyboard navigation with arrow keys
- Direct selection with number keys (1-9)
- Mouse click support
- Auto-dismisses on Escape
- Switches to selected session immediately
```

#### Documentation for Bug Reports

```bash
#!/bin/bash
# Comprehensive diagnostic for bug reports

{
    echo "=== Environment ==="
    echo "tmux version: $(tmux -V)"
    echo "OS: $(uname -a)"
    echo "TERM: $TERM"
    echo "Shell: $SHELL"
    echo ""

    echo "=== Tmux Configuration ==="
    tmux show-options -g
    echo ""

    echo "=== Current State ==="
    tmux display-message -p 'Session: #{session_name}'
    tmux display-message -p 'Panes: #{window_panes}'
    echo ""

    echo "=== Recent Commands ==="
    tmux list-commands | tail -20
    echo ""

    echo "=== Pane Content ==="
    tmux capture-pane -p -S -100

} > bug-report.txt

# Also take a screenshot manually
echo "Bug report saved to bug-report.txt"
echo "Please also take a screenshot of the issue"
```

### Known Limitations

#### What capture-pane Cannot Do

1. **No Overlay Capture**: Cannot capture menus, popups, or any overlay elements
2. **History Dependent**: Can only capture what's in the scrollback buffer (limited by `history-limit`)
3. **Formatting Loss**: Some formatting may be lost without `-e` flag
4. **No Mouse Cursor**: Cannot capture mouse cursor position
5. **No Selection**: Cannot capture copy-mode selections or highlights

#### Workarounds

**For overlays (menus/popups)**:
- Use terminal emulator screenshots
- Use terminal recording tools (asciinema, vhs)
- Document textually with ASCII art or markdown

**For limited history**:
```bash
# Set high history limit in .tmux.conf
set -g history-limit 50000

# Or capture incrementally
tmux capture-pane -p -S -10000 > part1.txt
tmux capture-pane -p -S -20000 -E -10000 > part2.txt
```

**For formatting**:
```bash
# Always use -e flag to preserve escape sequences
tmux capture-pane -pe -S -

# Preserve colors with -e, preserve wrapping with -J
tmux capture-pane -peJ -S -
```

**For interactive elements**:
```bash
# Record the entire session with asciinema
asciinema rec session.cast

# Play it back to see interactions
asciinema play session.cast

# Convert to shareable format
agg session.cast session.gif
```

### Menu Display Limitations

From the research, there's a critical limitation to be aware of:

**Silent Failure**: tmux doesn't provide an error when a menu doesn't fit the screen—it simply refuses to display it. The only indication is that the menu closes immediately.

**Prevention**:
- Keep menu items concise
- Test on minimum supported terminal size (80x24)
- Use popups with scrolling for large content
- Split large menus into sub-menus

**Debugging invisible menus**:
```bash
# Check if menu command is valid
tmux display-menu -T "Test" "Item" 1 "display-message 'works'"

# If it disappears immediately:
# 1. Check terminal size
tmux display-message -p '#{client_width}x#{client_height}'

# 2. Reduce menu items
# 3. Try different position (-x C -y C)
# 4. Check for syntax errors in menu items
```

### Recommended Tools Summary

| Use Case | Recommended Tool | Notes |
|----------|------------------|-------|
| Capture pane text | `tmux capture-pane -p` | Built-in, no overlays |
| Capture with history | `tmux-logging plugin` | Easy key bindings |
| Screenshot menus | Terminal emulator | iTerm2, GNOME, etc. |
| Record interactions | `asciinema` + `agg` | Creates shareable GIFs |
| Live demo | `ttyd` | Web-based terminal |
| Scripted demos | `vhs` | Programmatic GIF creation |
| Bug reports | Script + screenshot | Combine both methods |

### Quick Reference Commands

```bash
# Capture visible pane
tmux capture-pane -p

# Capture full history
tmux capture-pane -p -S -

# Capture with colors
tmux capture-pane -pe -S -

# Save to file
tmux capture-pane -p -S - > output.txt

# Capture specific pane
tmux capture-pane -p -t %1 -S -

# Two-step buffer capture
tmux capture-pane -b mybuffer -S -
tmux save-buffer -b mybuffer ~/file.txt
tmux delete-buffer -b mybuffer

# Record session with asciinema
asciinema rec session.cast

# Convert to GIF
agg session.cast session.gif
```

---

## References

### Official Documentation

- [tmux Manual Page (man7.org)](https://man7.org/linux/man-pages/man1/tmux.1.html)
- [tmux GitHub Wiki - Formats](https://github.com/tmux/tmux/wiki/Formats)
- [tmux GitHub Wiki - Advanced Use](https://github.com/tmux/tmux/wiki/Advanced-Use)
- [tmux GitHub Wiki - Getting Started](https://github.com/tmux/tmux/wiki/Getting-Started)

### Tutorials and Examples

- [Session switching with the tmux menu](https://qmacro.org/blog/posts/2021/08/12/session-switching-with-the-tmux-menu/)
- [GitHub - jaclu/tmux-menus: Tmux plugin, Popup menus](https://github.com/jaclu/tmux-menus)
- [More Tmux little hacks - aliquote.org](https://aliquote.org/post/tmux-little-hacks/)
- [seanh.cc - Binding Keys in tmux](https://www.seanh.cc/2020/12/28/binding-keys-in-tmux/)
- [Popups and Menus | DeepWiki](https://deepwiki.com/tmux/tmux/5.2-popups-and-menus)
- [Tmux pop-up cheat sheet](https://justyn.io/til/til-tmux-popup-cheatsheet/)
- [Floating scratch terminal in tmux](https://blog.meain.io/2020/tmux-flating-scratch-terminal/)
- [How to use popup windows in tmux?](https://tmuxai.dev/tmux-popup/)

### Community Resources

- [Tmux Cheat Sheet & Quick Reference](https://tmuxcheatsheet.com/)
- [A beginner's guide to tmux](https://www.redhat.com/en/blog/introduction-tmux-linux)
- [A step-by-step guide to creating custom Tmux key bindings](https://www.fosslinux.com/106055/create-custom-tmux-key-bindings.htm)

### Screenshot and Capture Resources

- [GitHub - tmux-plugins/tmux-logging: Easy logging and screen capturing](https://github.com/tmux-plugins/tmux-logging)
- [Dump tmux pane history to a file | Mateusz Burnicki](https://burnicki.pl/en/2021/07/04/dump-tmux-pane-history-to-a-file.html)
- [How to capture pane content in tmux?](https://tmuxai.dev/tmux-capture-pane/)
- [How to Capture tmux Pane History – Linux Hint](https://linuxhint.com/capture-tmux-pane-history/)
- [tmux Session Logging and Pane Content Extraction | Baeldung on Linux](https://www.baeldung.com/linux/tmux-logging)
- [2021-08-06 - tmux capture pane](https://xoc3.io/blog/2021-08-06)
- [Saving Tmux Scrollback to a File | Mike Griffin](https://mikegriffin.ie/blog/20220504-saving-tmux-scrollback-to-a-file)

---

## Summary

tmux provides powerful built-in capabilities for creating dynamic, interactive menus and popups:

1. **display-menu**: Native menu system with keyboard shortcuts and mouse support
2. **display-popup**: Run external commands in floating windows with fzf integration
3. **Format variables**: Rich querying system for sessions, windows, and panes
4. **Format loops**: Generate content dynamically from tmux state
5. **Styling**: Full control over colors, borders, and appearance
6. **Key bindings**: Flexible binding system for interactive workflows

For agent-tmux-toolkit, the recommended approach is:
- Use shell scripts to build dynamic menus with `list-sessions`/`list-panes`
- Bind to convenient keys for quick access
- Use popups for fuzzy finding with fzf
- Leverage format variables for context-aware actions
- Style menus consistently with project theme

---

**Generated**: 2026-01-06
**Updated**: 2026-01-07 (Added screenshot/capture documentation)
**tmux Version**: 3.6a
**Project**: agent-tmux-toolkit
**Purpose**: Research for implementing native tmux menu navigation, agent handoff features, and documenting menus/popups
