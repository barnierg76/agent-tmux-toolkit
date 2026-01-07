# tmux Documentation: Copy Mode, Buffers, and Selection Operations

Comprehensive research on tmux text selection, buffer operations, and copy mode commands for the agent-tmux-toolkit project.

---

## Table of Contents

1. [Copy-Mode Commands](#copy-mode-commands)
2. [Buffer Operations](#buffer-operations)
3. [Capture Pane](#capture-pane)
4. [Format Variables](#format-variables)
5. [Keybinding with Selection](#keybinding-with-selection)
6. [Practical Examples](#practical-examples)
7. [References](#references)

---

## Copy-Mode Commands

### Overview

Copy mode is a special operating mode in tmux that allows you to navigate, search, and select content from a pane's history buffer for copying. It transforms the pane into a navigable viewport with its own set of commands and key bindings, similar to vi or emacs.

### Entering Copy Mode

- **Default keybinding**: `prefix + [` (e.g., `Ctrl+b [`)
- **Command**: `tmux copy-mode`

### Mode Tables

There are two key tables for copy mode:
- **`copy-mode`** - For emacs-style key bindings
- **`copy-mode-vi`** - For vi-style key bindings

Set your preference in `.tmux.conf`:
```bash
set-window-option -g mode-keys vi
```

### send-keys -X Commands

Commands are sent to copy mode using the `-X` flag to the `send-keys` command.

#### Selection Commands

```bash
# Begin selection
send-keys -X begin-selection

# Clear selection
send-keys -X clear-selection

# Copy selection
send-keys -X copy-selection

# Copy and exit copy mode
send-keys -X copy-selection-and-cancel

# Copy without clearing selection
send-keys -X copy-selection-no-clear

# Select entire line
send-keys -X select-line

# Toggle rectangle selection mode
send-keys -X rectangle-toggle
```

#### Navigation Commands

```bash
# Cursor movement
send-keys -X cursor-down
send-keys -X cursor-up
send-keys -X cursor-left
send-keys -X cursor-right

# Line movement
send-keys -X start-of-line
send-keys -X end-of-line
send-keys -X goto-line <line>

# Word movement
send-keys -X next-word
send-keys -X previous-word

# Page/history scrolling
send-keys -X page-up
send-keys -X page-down
send-keys -X halfpage-up
send-keys -X halfpage-down
send-keys -X history-top
send-keys -X history-bottom
```

#### Search Commands

```bash
# Search forward
send-keys -X search-forward <text>

# Search backward
send-keys -X search-backward <text>

# Repeat last search
send-keys -X search-again

# Reverse direction of search
send-keys -X search-reverse
```

#### Copy with External Commands

```bash
# Copy to system clipboard (Linux)
send-keys -X copy-pipe-and-cancel "xclip -in -selection clipboard"

# Copy to system clipboard (macOS)
send-keys -X copy-pipe-and-cancel "pbcopy"

# Copy but stay in copy mode
send-keys -X copy-pipe "xclip -in -selection clipboard"
```

---

## Buffer Operations

### Overview

tmux maintains a set of named paste buffers that store text data. Buffers can be created automatically via copy mode selections or explicitly created by the user.

### Buffer Naming

- **Automatic buffers**: Named `buffer0`, `buffer1`, etc. (up to 50 buffers)
- **Named buffers**: Explicitly named buffers that are never automatically deleted
- **Default prefix**: `buffer` (can be customized with buffer prefix argument)

### Commands

#### list-buffers (alias: lsb)

Display all available buffers with name, size, and content preview.

```bash
tmux list-buffers
```

#### show-buffer (alias: showb)

Display the contents of a specific buffer.

```bash
# Show default buffer
tmux show-buffer

# Show named buffer
tmux show-buffer -b buffer_name
```

#### save-buffer (alias: saveb)

Save buffer contents to a file.

```bash
# Save default buffer
tmux save-buffer /path/to/file.txt

# Save named buffer
tmux save-buffer -b buffer_name /path/to/file.txt

# Append to file instead of overwriting
tmux save-buffer -a /path/to/file.txt
```

#### load-buffer (alias: loadb)

Load a file into a paste buffer.

```bash
# Load file into new buffer
tmux load-buffer /path/to/file.txt

# Load into named buffer
tmux load-buffer -b buffer_name /path/to/file.txt

# Load from stdin
echo "text content" | tmux load-buffer -
```

#### paste-buffer (alias: pasteb)

Paste buffer contents into a pane.

```bash
# Paste default buffer
tmux paste-buffer

# Paste named buffer
tmux paste-buffer -b buffer_name

# Paste to specific pane
tmux paste-buffer -t target-pane

# Paste with custom separator
tmux paste-buffer -s "separator_string"

# Delete buffer after pasting
tmux paste-buffer -d
```

#### set-buffer (alias: setb)

Create or modify a buffer with a string.

```bash
# Create buffer with content
tmux set-buffer "text content"

# Create named buffer
tmux set-buffer -b buffer_name "text content"

# Set buffer and update client terminal selection (OSC 52)
tmux set-buffer -w "text content"

# Rename buffer
tmux set-buffer -n new_name
```

#### delete-buffer (alias: deleteb)

Remove a buffer.

```bash
# Delete default buffer
tmux delete-buffer

# Delete named buffer
tmux delete-buffer -b buffer_name
```

---

## Capture Pane

### Overview

The `capture-pane` command captures pane content to a buffer or stdout. This is useful for logging, saving history, or processing pane output.

### Command Syntax

```bash
tmux capture-pane [-aepPqCJMN] [-b buffer-name] [-E end-line] [-S start-line] [-t target-pane]
```

### Key Options

#### Output Control

- **`-p`** - Print to stdout instead of buffer
- **`-b <buffer-name>`** - Specify buffer name (default: automatic buffer)

#### Content Selection

- **`-S <start-line>`** - Starting line number
  - `0` = first visible line
  - Negative numbers = lines in history (e.g., `-100` = 100 lines back)
  - Special value `-` = start of history

- **`-E <end-line>`** - Ending line number
  - `0` = first visible line
  - Special value `-` = end of visible content

#### Screen Selection

- **`-a`** - Use alternate screen (not history)
- **`-M`** - Use mode screen if pane is in a mode
- **`-q`** - Suppress errors if alternate screen unavailable

#### Formatting Options

- **`-e`** - Include ANSI escape sequences for colors/formatting
- **`-C`** - Escape non-printable characters as octal `\xxx`
- **`-J`** - Join wrapped lines and preserve trailing spaces
- **`-N`** - Preserve trailing spaces at each line's end
- **`-T`** - Trim trailing positions with no characters (requires tmux 3.4+)
- **`-P`** - Only capture what is actually on screen, not what tmux thinks is there

### Examples

```bash
# Capture entire scrollback history to stdout
tmux capture-pane -p -S -

# Capture last 100 lines to buffer
tmux capture-pane -S -100

# Capture with colors preserved
tmux capture-pane -p -e -S -

# Capture and save to file
tmux capture-pane -p -S - > /path/to/file.txt

# Capture visible pane only
tmux capture-pane -p

# Capture with wrapped lines joined
tmux capture-pane -p -J -S -

# Capture to specific buffer
tmux capture-pane -b my_capture -S -

# Pipe to vim for viewing
tmux capture-pane -p -S - | vim -

# Save scrollback to file (two-step)
tmux capture-pane -S -
tmux save-buffer ~/capture.txt
```

---

## Format Variables

### Overview

Formats are strings containing special directives in `#{}` which tmux will expand. Each `#{}` can reference named variables with information about the server, session, client, window, or pane.

### Discovering Format Variables

```bash
# List all available format variables
tmux display-message -a

# Search for specific variables
tmux display-message -a | grep pane

# Verbose evaluation (debugging)
tmux display-message -vp '#{pane_width}'

# Show specific format
tmux display-message -p '#{session_name}:#{window_index}.#{pane_index}'
```

### Copy-Mode Related Variables

Based on tmux documentation, these format variables relate to copy mode:

#### Pane Mode Variables

- **`pane_in_mode`** - Boolean indicating if pane is in a mode
  - `0` = normal mode
  - `1` = copy mode or other mode

- **`pane_mode`** - String describing the current mode (e.g., "copy-mode")

#### Copy Mode Specific

- **`copy_cursor_x`** - X position of cursor in copy mode
- **`copy_cursor_y`** - Y position of cursor in copy mode
- **`copy_cursor_line`** - Line content at cursor in copy mode
- **`copy_cursor_word`** - Word under cursor in copy mode
- **`copy_cursor_hyperlink`** - Hyperlink under cursor in copy mode
- **`selection_active`** - Boolean for active selection (may vary by version)
- **`selection_present`** - Boolean indicating if selection exists
- **`search_match`** - Current search match text
- **`search_count`** - Number of search matches
- **`search_count_partial`** - Partial search match count

#### Mouse-Related (in copy mode)

- **`mouse_word`** - Word under mouse cursor
- **`mouse_line`** - Line under mouse cursor
- **`mouse_utf8_flag`** - UTF-8 mouse flag
- **`mouse_sgr_flag`** - SGR mouse flag

#### General Pane Variables

- **`pane_id`** - Unique pane identifier
- **`pane_width`** - Width of pane
- **`pane_height`** - Height of pane
- **`pane_current_path`** - Current working directory
- **`cursor_x`** - Normal mode cursor X position
- **`cursor_y`** - Normal mode cursor Y position
- **`cursor_flag`** - Cursor visibility flag
- **`alternate_on`** - If pane is in alternate screen
- **`pane_title`** - Pane title

### Conditional Formats

```bash
# Use conditionals in formats
tmux display-message -p '#{?pane_in_mode,IN MODE,NORMAL}'

# Check for specific mode
tmux display-message -p '#{?#{==:#{pane_mode},copy-mode},COPY,NORMAL}'
```

### Format Modifiers

```bash
# Length
#{l:variable}

# Basename
#{b:variable}

# Dirname
#{d:variable}

# Conditional
#{?condition,true_value,false_value}

# Equality
#{==:#{var1},#{var2}}
```

---

## Keybinding with Selection

### Overview

Keybindings for copy mode must specify the appropriate key table (`copy-mode` or `copy-mode-vi`) using the `-T` flag.

### Basic Syntax

```bash
bind-key -T <table> <key> send-keys -X <command>
```

### Vi-Style Copy Mode Configuration

Complete example for `.tmux.conf`:

```bash
# Enable vi mode
set-window-option -g mode-keys vi

# Enter copy mode
bind-key [ copy-mode

# Navigation in copy mode
bind-key -T copy-mode-vi 'v' send-keys -X begin-selection
bind-key -T copy-mode-vi 'V' send-keys -X select-line
bind-key -T copy-mode-vi 'r' send-keys -X rectangle-toggle

# Copy commands (Linux with xclip)
bind-key -T copy-mode-vi 'y' send-keys -X copy-pipe-and-cancel "xclip -in -selection clipboard"
bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "xclip -in -selection clipboard"

# Copy commands (macOS)
# bind-key -T copy-mode-vi 'y' send-keys -X copy-pipe-and-cancel "pbcopy"
# bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "pbcopy"

# Mouse drag to copy
bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "xclip -in -selection clipboard"

# Search
bind-key -T copy-mode-vi '/' send-keys -X search-forward
bind-key -T copy-mode-vi '?' send-keys -X search-backward
bind-key -T copy-mode-vi 'n' send-keys -X search-again
bind-key -T copy-mode-vi 'N' send-keys -X search-reverse

# Movement
bind-key -T copy-mode-vi 'h' send-keys -X cursor-left
bind-key -T copy-mode-vi 'j' send-keys -X cursor-down
bind-key -T copy-mode-vi 'k' send-keys -X cursor-up
bind-key -T copy-mode-vi 'l' send-keys -X cursor-right
bind-key -T copy-mode-vi 'w' send-keys -X next-word
bind-key -T copy-mode-vi 'b' send-keys -X previous-word
bind-key -T copy-mode-vi '0' send-keys -X start-of-line
bind-key -T copy-mode-vi '$' send-keys -X end-of-line
bind-key -T copy-mode-vi 'g' send-keys -X history-top
bind-key -T copy-mode-vi 'G' send-keys -X history-bottom

# Page movement
bind-key -T copy-mode-vi 'C-f' send-keys -X page-down
bind-key -T copy-mode-vi 'C-b' send-keys -X page-up
bind-key -T copy-mode-vi 'C-d' send-keys -X halfpage-down
bind-key -T copy-mode-vi 'C-u' send-keys -X halfpage-up
```

### Emacs-Style Configuration

```bash
# Enable emacs mode
set-window-option -g mode-keys emacs

# Copy mode bindings
bind-key -T copy-mode C-Space send-keys -X begin-selection
bind-key -T copy-mode M-w send-keys -X copy-pipe-and-cancel "xclip -in -selection clipboard"
bind-key -T copy-mode C-w send-keys -X copy-pipe-and-cancel "xclip -in -selection clipboard"
```

### Normal Mode Bindings

You can also bind keys in normal mode to interact with copy mode:

```bash
# Quick copy last command output (example)
bind-key P run-shell "tmux capture-pane -p -S -100 | tail -n 20"

# Save entire history
bind-key S run-shell "tmux capture-pane -p -S - > ~/tmux-history-$(date +%Y%m%d-%H%M%S).txt"

# Copy pane to clipboard
bind-key C run-shell "tmux capture-pane -p | xclip -selection clipboard"
```

### Detecting Copy Mode in Scripts

```bash
#!/bin/bash

# Check if current pane is in copy mode
is_copy_mode=$(tmux display-message -p '#{pane_in_mode}')

if [ "$is_copy_mode" = "1" ]; then
    echo "Pane is in copy mode"

    # Get copy mode details
    mode=$(tmux display-message -p '#{pane_mode}')
    echo "Mode: $mode"
else
    echo "Pane is in normal mode"
fi
```

---

## Practical Examples

### Example 1: Save Selection to Variable

```bash
#!/bin/bash

# Enter copy mode, select text, then run this
# Get the buffer content
selection=$(tmux show-buffer)

# Use the selection
echo "You copied: $selection"

# Or save to file
echo "$selection" > /tmp/my-selection.txt
```

### Example 2: Programmatic Selection and Copy

```bash
#!/bin/bash

# Capture last command output (assuming prompt is on new line)
tmux copy-mode
tmux send-keys -X start-of-line
tmux send-keys -X cursor-up
tmux send-keys -X start-of-line
tmux send-keys -X begin-selection
tmux send-keys -X end-of-line
tmux send-keys -X copy-selection-and-cancel

# Get the copied text
command_output=$(tmux show-buffer)
echo "Last command: $command_output"
```

### Example 3: Send Selection to Another Pane

```bash
#!/bin/bash

target_pane="$1"

# Ensure we have a selection in buffer
if [ -z "$(tmux show-buffer 2>/dev/null)" ]; then
    echo "No buffer content available"
    exit 1
fi

# Send buffer content to target pane
tmux paste-buffer -t "$target_pane"
```

### Example 4: Interactive Text Selection Script

```bash
#!/bin/bash

# Enter copy mode
tmux copy-mode

# Wait for user to make selection
# (user manually selects and presses Enter/y)

# After selection is made, get it
selected_text=$(tmux show-buffer)

# Do something with selected text
if [ -n "$selected_text" ]; then
    # Send to another command
    echo "$selected_text" | some_processing_command

    # Or save for later
    echo "$selected_text" > /tmp/user-selection.txt
fi
```

### Example 5: Copy Mode Detection and Auto-Actions

```bash
#!/bin/bash

# Monitor if pane enters copy mode
while true; do
    in_mode=$(tmux display-message -p '#{pane_in_mode}')

    if [ "$in_mode" = "1" ]; then
        mode_type=$(tmux display-message -p '#{pane_mode}')

        if [ "$mode_type" = "copy-mode" ]; then
            echo "Copy mode active - watching for selection..."

            # Could trigger notifications or logging here
        fi
    fi

    sleep 1
done
```

### Example 6: Capture and Search

```bash
#!/bin/bash

search_term="$1"

# Capture entire pane history
tmux capture-pane -p -S - > /tmp/pane-capture.txt

# Search in captured content
if grep -q "$search_term" /tmp/pane-capture.txt; then
    echo "Found '$search_term' in pane history"
    grep -n "$search_term" /tmp/pane-capture.txt
else
    echo "Term not found"
fi
```

### Example 7: Smart Buffer Management

```bash
#!/bin/bash

# Create named buffer from selection
save_to_named_buffer() {
    local name="$1"

    # Copy current buffer to named buffer
    local content=$(tmux show-buffer)
    tmux set-buffer -b "$name" "$content"

    echo "Saved to buffer: $name"
}

# Restore from named buffer
restore_from_named_buffer() {
    local name="$1"

    # Show named buffer
    tmux show-buffer -b "$name"
}

# List all named buffers
list_buffers() {
    tmux list-buffers
}
```

### Example 8: Copy Pane Content to Agent

```bash
#!/bin/bash

# Capture visible pane content
pane_content=$(tmux capture-pane -p)

# Send to specific target pane (e.g., pane running agent)
agent_pane="agent-research"

# Load into buffer and paste
echo "$pane_content" | tmux load-buffer -
tmux paste-buffer -t "$agent_pane"
```

---

## References

### Official Documentation

- [tmux Manual Page (man7.org)](https://man7.org/linux/man-pages/man1/tmux.1.html)
- [tmux GitHub Wiki - Formats](https://github.com/tmux/tmux/wiki/Formats)
- [tmux GitHub Wiki - Getting Started](https://github.com/tmux/tmux/wiki/Getting-Started)
- [tmux GitHub Wiki - Advanced Use](https://github.com/tmux/tmux/wiki/Advanced-Use)
- [tmux GitHub Wiki - Clipboard](https://github.com/tmux/tmux/wiki/Clipboard)

### Tutorials and Guides

- [The Easy Way to Copy Text in Tmux - DEV Community](https://dev.to/iggredible/the-easy-way-to-copy-text-in-tmux-319g)
- [Copy Mode | tmux/tmux | DeepWiki](https://deepwiki.com/tmux/tmux/6.1-copy-mode)
- [Buffer Management | tmux/tmux | DeepWiki](https://deepwiki.com/tmux/tmux/6.2-buffer-management)
- [Copy and Paste in Tmux | rockyourcode](https://www.rockyourcode.com/copy-and-paste-in-tmux/)
- [How to copy and paste with a clipboard in Tmux | FOSS Linux](https://www.fosslinux.com/80608/how-to-copy-and-paste-with-a-clipboard-in-tmux.htm)
- [The Modes of tmux - DEV Community](https://dev.to/jbranchaud/the-modes-of-tmux-3d86)
- [How to configure tmux, from scratch](https://ianthehenry.com/posts/how-to-configure-tmux/)
- [tmux Copy and Paste Methods | Baeldung on Linux](https://www.baeldung.com/linux/tmux-copy-paste-keyboard-mouse)
- [How to capture pane content in tmux?](https://tmuxai.dev/tmux-capture-pane/)
- [tmux Session Logging and Pane Content Extraction | Baeldung on Linux](https://www.baeldung.com/linux/tmux-logging)
- [seanh.cc - Binding Keys in tmux](https://www.seanh.cc/2020/12/28/binding-keys-in-tmux/)
- [seanh.cc - Copy and Paste in tmux](https://www.seanh.cc/2020/12/27/copy-and-paste-in-tmux/)

### Community Resources

- [Tmux Cheat Sheet & Quick Reference](https://tmuxcheatsheet.com/)
- [tmux cheatsheet · GitHub](https://gist.github.com/russelldb/06873e0ad4f5ba1c4eec1b673ff4d4cd)
- [Clean tmux cheat-sheet · GitHub](https://gist.github.com/Bekbolatov/6840069e51382965fdad)
- [Mastering Tmux Buffers: A Guide to Efficient Navigation](https://www.fosslinux.com/106189/how-to-jump-between-tmux-buffers-like-a-pro.htm)

### Advanced Topics

- [tmux GitHub - cmd-save-buffer.c source](https://github.com/tmux/tmux/blob/master/cmd-save-buffer.c)
- [Can't get copy-mode cursor position in shell script · Issue #1949](https://github.com/tmux/tmux/issues/1949)
- [Custom Vim Bindings in tmux 2.4 | George Ornbo](https://shapeshed.com/custom-vim-bindings-in-tmux-2-4/)
- [replacement for "bind-key -t vi-copy 'y' copy-selection" ? · Issue #910](https://github.com/tmux/tmux/issues/910)

---

## Notes for agent-tmux-toolkit

### Key Findings for Implementation

1. **Buffer Operations are Synchronous**: `tmux show-buffer` immediately returns buffer content, making it suitable for capturing selections in real-time.

2. **Copy Mode Detection**: Use `#{pane_in_mode}` format variable to detect if a pane is in copy mode.

3. **Selection Workflow**:
   - User enters copy mode (`prefix + [`)
   - User makes selection (vi: `v` for begin, navigate, `y` or `Enter` to copy)
   - Script retrieves with `tmux show-buffer`
   - Send to target with `tmux paste-buffer -t <target>`

4. **Clipboard Integration**: The `copy-pipe-and-cancel` command allows integration with system clipboard while also storing in tmux buffer.

5. **Format Variable Discovery**: Run `tmux display-message -a | grep -i copy` to discover all copy-mode related format variables in your tmux version.

### Recommended Approach for Agent Integration

```bash
# 1. Monitor for copy mode and selection
is_in_copy_mode=$(tmux display-message -p '#{pane_in_mode}')

# 2. When user makes selection and exits copy mode, capture it
if [ "$is_in_copy_mode" = "0" ]; then
    # Just exited copy mode, check for buffer
    selection=$(tmux show-buffer 2>/dev/null)

    if [ -n "$selection" ]; then
        # Send to agent pane
        echo "$selection" | tmux load-buffer -
        tmux paste-buffer -t "agent-research"
    fi
fi
```

### Alternative: Direct Capture Without Copy Mode

For automated capture without requiring user to enter copy mode:

```bash
# Capture last N lines
tmux capture-pane -p -S -50 > /tmp/context.txt

# Send to agent
tmux send-keys -t "agent-research" "$(cat /tmp/context.txt)" Enter
```

---

**Generated**: 2026-01-04
**Project**: agent-tmux-toolkit
**Purpose**: Research documentation for implementing copy/paste functionality between tmux panes and AI research agents
