# tmux Text Selection & Inter-Pane Communication Best Practices

**Research Date:** 2026-01-04
**Purpose:** Guide implementation of text selection → action → target pane workflow

---

## Table of Contents

1. [tmux Copy Mode Fundamentals](#1-tmux-copy-mode-fundamentals)
2. [Buffer Management](#2-buffer-management)
3. [Selection Detection & State Preservation](#3-selection-detection--state-preservation)
4. [Text Transfer Methods: send-keys vs load-buffer](#4-text-transfer-methods-send-keys-vs-load-buffer)
5. [Workflow Patterns](#5-workflow-patterns)
6. [Implementation Recommendations](#6-implementation-recommendations)
7. [Code Examples](#7-code-examples)

---

## 1. tmux Copy Mode Fundamentals

### What is Copy Mode?

Copy mode is a special operating mode in tmux that allows users to navigate, search, and select content from a pane's history buffer for copying. It transforms the pane into a navigable viewport with its own set of commands and key bindings.

**Sources:**
- [tmux Manual Page](https://man7.org/linux/man-pages/man1/tmux.1.html)
- [Copy Mode | DeepWiki](https://deepwiki.com/tmux/tmux/6.1-copy-mode)

### Entering and Exiting Copy Mode

```bash
# Default bindings
Prefix + [      # Enter copy mode
Prefix + ]      # Paste most recent buffer
Prefix + #      # List all paste buffers
Prefix + =      # Choose buffer to paste interactively
```

**Command form:**
```bash
tmux copy-mode              # Enter copy mode
tmux paste-buffer           # Paste from default buffer
tmux choose-buffer          # Interactive buffer selection
```

### Key Binding Evolution (tmux 2.4+)

**IMPORTANT:** tmux 2.4 fundamentally changed how copy mode bindings work.

**Old way (pre-2.4):**
```bash
bind-key -t vi-copy 'v' begin-selection
bind-key -t vi-copy 'y' copy-selection
```

**Modern way (2.4+):**
```bash
bind-key -T copy-mode-vi 'v' send-keys -X begin-selection
bind-key -T copy-mode-vi 'y' send-keys -X copy-selection
```

The `-X` flag sends commands **to** copy mode rather than binding within it.

**Source:** [GitHub: Fundamental change to copy mode](https://github.com/tmux/tmux/commit/76d6d3641f271be1756e41494960d96714e7ee58)

---

## 2. Buffer Management

### Understanding tmux Paste Buffers

tmux maintains **internal paste buffers** that are separate from the system clipboard. Buffers are automatically named (`buffer0`, `buffer1`, etc.) unless explicitly named.

**Key Commands:**
```bash
tmux save-buffer <PATH>           # Write buffer to file
tmux load-buffer <PATH>           # Load file into buffer
tmux set-buffer "text"            # Set buffer content directly
tmux show-buffer                  # Display buffer content
tmux delete-buffer [-b <name>]    # Delete buffer
tmux paste-buffer [-t <pane>]     # Paste to target pane
```

**Buffer Limit:**
- Controlled by `buffer-limit` option
- Oldest automatic buffers are removed when limit is reached
- Default limit varies by tmux version

**Sources:**
- [Buffer Management | DeepWiki](https://deepwiki.com/tmux/tmux/6.2-buffer-management)
- [Copy and Paste in tmux](https://www.seanh.cc/2020/12/27/copy-and-paste-in-tmux/)

### Buffer vs System Clipboard

**Critical distinction:**
- tmux buffers are **internal** to tmux
- System clipboard is **external** (OS-level)
- They do NOT sync automatically

**Integration approaches:**

1. **copy-pipe** (recommended for most use cases)
2. **OSC 52** (for remote/SSH scenarios)
3. **set-clipboard** option (automatic but security concerns)

---

## 3. Selection Detection & State Preservation

### Can you detect if text is selected?

**Short answer:** Not directly, but you can work around it.

tmux copy mode doesn't expose a "is text selected" state that external scripts can query. However, you can:

1. **Use copy-mode commands that preserve state**
2. **Bind keys to execute scripts when selection is made**
3. **Capture selection on-demand when triggered**

### Preserving Selection State

Three copy commands with different behaviors:

```bash
# 1. Copy and exit copy mode (default behavior)
send-keys -X copy-selection-and-cancel

# 2. Copy but stay in copy mode
send-keys -X copy-selection

# 3. Copy, stay in copy mode, preserve selection highlight
send-keys -X copy-selection-no-clear
```

**For "select text → trigger action" workflows**, use `copy-pipe-no-clear`:

```bash
bind-key -T copy-mode-vi y send-keys -X copy-pipe-no-clear "pbcopy"
# Copies to clipboard, stays in copy mode, keeps selection visible
```

**Sources:**
- [GitHub: Clipboard Wiki](https://github.com/tmux/tmux/wiki/Clipboard)
- [Copy Mode | DeepWiki](https://deepwiki.com/tmux/tmux/6.1-copy-mode)

### Selection State Management

The selection can be manipulated with the `cursordrag` variable (internal):
- `CURSORDRAG_NONE`: Selection independent of cursor
- `CURSORDRAG_ENDSEL`: End of selection follows cursor
- `CURSORDRAG_SEL`: Start of selection follows cursor

**Practical implication:** You can't query this directly, so design workflows that **trigger on selection completion** rather than checking if selection exists.

---

## 4. Text Transfer Methods: send-keys vs load-buffer

### Method Comparison

| Method | Use Case | Pros | Cons |
|--------|----------|------|------|
| **send-keys** | Sending keystrokes to panes | Simulates typing, triggers input handlers | Can be interpreted by shell, escaping issues |
| **load-buffer + paste-buffer** | Transferring clipboard content | Clean, preserves formatting | Requires buffer management |
| **copy-pipe** | Selection → external command | Integrates with system clipboard | Requires external tool (pbcopy, xclip) |

### send-keys Approach

**Purpose:** Send literal keystrokes to a pane as if typed by user.

```bash
# Send literal text (doesn't interpret as keys)
tmux send-keys -t <target-pane> -l "text to send"

# Send text + Enter to execute
tmux send-keys -t <target-pane> -l "command" C-m

# Send special keys
tmux send-keys -t <target-pane> C-c    # Ctrl+C
tmux send-keys -t <target-pane> Enter  # Enter key
```

**Flags:**
- `-l`: Literal mode (doesn't look for key names)
- `-t <target>`: Target pane
- No `-l`: Interprets arguments as key names

**Example from vim-tmux-send:**
```bash
# Send current line to next pane
tmux send-keys -t "{next}" "$(current_line)" C-m
```

**Sources:**
- [GitHub: vim-tmux-send](https://github.com/slarwise/vim-tmux-send)
- [tmux Manual Page](https://man7.org/linux/man-pages/man1/tmux.1.html)

### load-buffer + paste-buffer Approach

**Purpose:** Transfer text via tmux's internal buffer system.

```bash
# Load text into buffer from stdin
echo "text" | tmux load-buffer -

# Paste buffer to target pane
tmux paste-buffer -t <target-pane>

# Combined: pipe to buffer, then paste
echo "text" | tmux load-buffer - && tmux paste-buffer -t <target-pane>
```

**Flags:**
- `-`: Read from stdin
- `-t <target>`: Target pane
- `-b <buffer-name>`: Use named buffer

**Example from agent-handoff (lines 192-193):**
```bash
echo "$handoff" | tmux load-buffer -
tmux paste-buffer -t "$target_id"
```

**Sources:**
- [seanh.cc: Copy and Paste in tmux](https://www.seanh.cc/2020/12/27/copy-and-paste-in-tmux/)
- [Everything you need to know about tmux copy paste](https://www.rushiagr.com/blog/2016/06/16/everything-you-need-to-know-about-tmux-copy-pasting-ubuntu/)

### copy-pipe Approach

**Purpose:** Copy selection AND pipe to external command (e.g., system clipboard).

```bash
# Modern binding (tmux 2.4+)
bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"

# Stays in copy mode
bind-key -T copy-mode-vi y send-keys -X copy-pipe "pbcopy"

# Stays in copy mode, preserves selection
bind-key -T copy-mode-vi y send-keys -X copy-pipe-no-clear "pbcopy"
```

**tmux 3.2+ alternative:**
```bash
# Set global copy command
set-option -g copy-command "pbcopy"

# Now any copy-pipe with no args uses it
bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel
```

**Platform-specific clipboard tools:**
- **macOS:** `pbcopy`, `pbpaste`
- **Linux (X11):** `xclip -sel clip -i`, `xsel --clipboard`
- **Linux (Wayland):** `wl-copy`, `wl-paste`
- **WSL:** `clip.exe`, `powershell.exe -command "Get-Clipboard"`

**Sources:**
- [GitHub: Clipboard Wiki](https://github.com/tmux/tmux/wiki/Clipboard)
- [tmux in practice: system clipboard integration](https://www.freecodecamp.org/news/tmux-in-practice-integration-with-system-clipboard-bcd72c62ff7b/)

### Recommendation: load-buffer for Inter-Pane Transfer

**For "select text → send to another pane" workflows:**

Use **load-buffer + paste-buffer** because:

1. ✅ **No escaping issues** - text is transferred verbatim
2. ✅ **Preserves formatting** - multi-line content works cleanly
3. ✅ **Predictable** - doesn't trigger shell interpretation
4. ✅ **No external dependencies** - pure tmux
5. ✅ **Works with multiline** - handles complex content

**Use send-keys when:**
- You want to execute a command (append `C-m` for Enter)
- You're sending keyboard shortcuts (like `C-c`)
- You need interactive shell behavior

**Example: Current agent-handoff implementation (lines 176-193):**
```bash
# Capture source content
content=$(tmux capture-pane -p -t "$source_id" 2>/dev/null | \
    sed 's/\x1b\[[0-9;]*m//g' | \
    grep -v '^[[:space:]]*$' | \
    tail -50)

# Format with template
handoff=$(printf "%s\n\n---\n%s\n---\n" "$template" "$content")

# Load into buffer and paste
echo "$handoff" | tmux load-buffer -
tmux paste-buffer -t "$target_id"
```

This is **excellent** because it:
- Transfers formatted text cleanly
- Preserves line breaks
- Doesn't trigger shell interpretation
- Works reliably across different pane states

---

## 5. Workflow Patterns

### Pattern 1: Copy Mode Selection → Action

**Goal:** User selects text in copy mode, presses key to trigger action.

**Implementation:**
```bash
# In .tmux.conf
bind-key -T copy-mode-vi C-s \
    send-keys -X copy-pipe-no-clear \
    "tmux run-shell 'snippet-send-selection.sh'"
```

**Flow:**
1. User enters copy mode (`Prefix + [`)
2. User selects text (`v` to start, move cursor)
3. User presses `Ctrl+S`
4. Selection is copied to buffer AND piped to script
5. Script uses `tmux show-buffer` to get selection
6. User remains in copy mode with selection visible

### Pattern 2: Capture Visible Content → Action

**Goal:** Extract current pane content without entering copy mode.

**Implementation:**
```bash
# Capture visible portion
tmux capture-pane -p -t <pane>

# Capture with history (last 100 lines)
tmux capture-pane -p -S -100 -t <pane>

# Capture entire scrollback
tmux capture-pane -p -S - -t <pane>
```

**Flags:**
- `-p`: Print to stdout (don't save to buffer)
- `-S <start>`: Start line (negative = lines back, `-` = beginning)
- `-E <end>`: End line
- `-t <target>`: Target pane

**Example: agent-manage copy (lines 452-455):**
```bash
content=$(tmux capture-pane -p -t "$SESSION_NAME.$pane_idx" 2>/dev/null | \
    sed 's/\x1b\[[0-9;]*m//g')  # Strip ANSI codes
```

### Pattern 3: Interactive Target Selection

**Goal:** Show menu of panes, preview content, select target.

**Implementation with fzf:**
```bash
# Get pane list
panes=$(tmux list-panes -t "$SESSION_NAME" \
    -F "#{pane_id}|#{pane_index}|#{pane_title}")

# Interactive picker with preview
selected=$(echo "$panes" | fzf \
    --preview="tmux capture-pane -p -t {1} | tail -30" \
    --preview-window=right:50%:wrap)
```

**Example: agent-handoff (lines 151-159):**
```bash
local selected=$(echo "$formatted" | fzf \
    --height=50% \
    --layout=reverse \
    --border=rounded \
    --prompt="$prompt › " \
    --delimiter='|' \
    --with-nth=2 \
    --preview="tmux capture-pane -p -t {1} 2>/dev/null | tail -30" \
    --preview-window=right:50%:wrap)
```

**Sources:**
- [GitHub: vim-tmux-send](https://github.com/slarwise/vim-tmux-send)
- [Advanced Use | tmux Wiki](https://github.com/tmux/tmux/wiki/Advanced-Use)

### Pattern 4: Menu-Triggered Transfer

**Goal:** Press key → show pane menu → select → transfer.

**Current agent-handoff workflow:**
1. User presses `Option+H` (bound to `agent-handoff`)
2. Script shows source pane selector (with content preview)
3. User selects source
4. Script shows target pane selector
5. User selects target
6. Script captures source, applies template, pastes to target

**This pattern is EXCELLENT** because:
- No copy mode needed
- Visual feedback (previews)
- Clean UX (two-step selection)
- Preserves current pane state

---

## 6. Implementation Recommendations

### For "Select Text in Copy Mode → Choose Target Pane"

**Challenge:** tmux doesn't allow showing menus (like fzf) while in copy mode.

**Recommended approach:**

1. **Bind key in copy mode to trigger external script**
2. **Script captures the selection from buffer**
3. **Script exits copy mode (or leaves it active)**
4. **Script shows target picker**
5. **Script transfers to target**

**Example implementation:**

```bash
# .tmux.conf binding
bind-key -T copy-mode-vi S \
    send-keys -X copy-pipe-and-cancel \
    "~/.local/bin/send-selection-to-pane"

# send-selection-to-pane script
#!/bin/bash
selection=$(cat)  # Read from stdin (copy-pipe sends here)

# Show pane picker
target=$(tmux list-panes -F "#{pane_index}|#{pane_title}" | \
    fzf --prompt="Send to pane: ")
[ -z "$target" ] && exit 0

target_idx=$(echo "$target" | cut -d'|' -f1)

# Load selection into buffer and paste
echo "$selection" | tmux load-buffer -
tmux paste-buffer -t ".$target_idx"
```

**Why this works:**
- `copy-pipe-and-cancel` exits copy mode BEFORE running script
- Script receives selection via stdin
- Script can now show fzf menu (no conflict with copy mode)
- Clean, predictable flow

### Alternative: Don't Use Copy Mode

**Pattern:** Capture pane content on-demand (like current agent-handoff).

**Pros:**
- Simpler UX (no mode switching)
- Works from any pane state
- Can capture more than visible screen

**Cons:**
- User can't precisely select text
- Captures everything (or last N lines)

**Best for:** Transferring entire contexts (like task handoffs)

**Best against:** Precise text snippets

### For Snippet Integration

**Goal:** User selects text → trigger snippet that includes selection.

**Recommended approach:**

```bash
# .tmux.conf
bind-key -T copy-mode-vi C-s \
    send-keys -X copy-pipe \
    "~/.local/bin/snippet-with-selection"

# snippet-with-selection
#!/bin/bash
selection=$(cat)  # Get selection from stdin

# Now show snippet picker with selection available
export SNIPPET_CONTEXT="$selection"
exec snippet-picker
```

Inside `snippet-picker`, check for `$SNIPPET_CONTEXT` and prepend/append it to selected snippet.

**Flow:**
1. User selects text in copy mode
2. Presses `Ctrl+S`
3. Selection captured, snippet picker opens
4. User picks snippet
5. Snippet + selection sent to target pane

---

## 7. Code Examples

### Example 1: Copy Selection to Buffer (No External Tool)

```bash
# Binding in .tmux.conf (vi mode)
bind-key -T copy-mode-vi Enter send-keys -X copy-selection-and-cancel

# Or with explicit buffer name
bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
```

### Example 2: Copy Selection to System Clipboard

```bash
# macOS
bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"

# Linux (X11)
bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "xclip -sel clip -i"

# Linux (Wayland)
bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "wl-copy"

# WSL
bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "clip.exe"
```

### Example 3: Get Current Selection in Script

```bash
#!/bin/bash
# After copy-pipe, selection is in stdin
selection=$(cat)

# Or from tmux buffer
selection=$(tmux show-buffer)

echo "You selected: $selection"
```

### Example 4: Capture Pane Content (No Selection Needed)

```bash
# Visible portion only
visible=$(tmux capture-pane -p -t <pane>)

# Last 50 lines (including scrollback)
context=$(tmux capture-pane -p -S -50 -t <pane>)

# Entire history
full=$(tmux capture-pane -p -S - -t <pane>)

# Strip ANSI color codes
clean=$(tmux capture-pane -p -t <pane> | sed 's/\x1b\[[0-9;]*m//g')
```

### Example 5: Send Text to Target Pane (Best Practice)

```bash
#!/bin/bash
target_pane="$1"
text_to_send="$2"

# Method 1: load-buffer + paste-buffer (RECOMMENDED for text)
echo "$text_to_send" | tmux load-buffer -
tmux paste-buffer -t "$target_pane"

# Method 2: send-keys literal (alternative)
tmux send-keys -t "$target_pane" -l "$text_to_send"

# Method 3: send-keys + execute (for commands)
tmux send-keys -t "$target_pane" -l "$text_to_send" C-m
```

### Example 6: Interactive Pane Picker with Preview

```bash
#!/bin/bash
SESSION_NAME="agents"

# Get panes
panes=$(tmux list-panes -t "$SESSION_NAME" \
    -F "#{pane_id}|#{pane_index}|#{pane_title}")

# Pick with fzf, show content preview
selected=$(echo "$panes" | fzf \
    --height=50% \
    --layout=reverse \
    --border=rounded \
    --prompt="Select pane: " \
    --delimiter='|' \
    --with-nth=2,3 \
    --preview="tmux capture-pane -p -t {1} 2>/dev/null | tail -30" \
    --preview-window=right:50%:wrap)

[ -z "$selected" ] && exit 0

pane_id=$(echo "$selected" | cut -d'|' -f1)
echo "Selected pane: $pane_id"
```

### Example 7: Copy Mode → External Script

```bash
# .tmux.conf
bind-key -T copy-mode-vi C-x \
    send-keys -X copy-pipe-no-clear \
    "~/.local/bin/process-selection"

# ~/.local/bin/process-selection
#!/bin/bash
selection=$(cat)  # Read from stdin

# Do something with selection
echo "Processing: $selection"

# Selection remains visible in copy mode
# User can continue editing selection or cancel
```

### Example 8: Full Workflow - Select → Pick Target → Send

```bash
#!/bin/bash
# .tmux.conf binding:
# bind-key -T copy-mode-vi S send-keys -X copy-pipe-and-cancel \
#     "~/.local/bin/send-to-pane"

SESSION_NAME="${AGENT_SESSION:-agents}"
selection=$(cat)  # Get selection from copy-pipe

# Exit if empty
[ -z "$selection" ] && exit 0

# Get panes (exclude current)
current_pane=$(tmux display-message -p '#{pane_id}')
panes=$(tmux list-panes -t "$SESSION_NAME" \
    -F "#{pane_id}|#{pane_index}|#{pane_title}" | \
    grep -v "^$current_pane|")

# Pick target
target=$(echo "$panes" | fzf \
    --height=40% \
    --border=rounded \
    --prompt="Send to: " \
    --delimiter='|' \
    --with-nth=2,3 \
    --preview="echo 'Selected text:'; echo '---'; echo '$selection' | head -10")

[ -z "$target" ] && exit 0

target_id=$(echo "$target" | cut -d'|' -f1)

# Send to target
echo "$selection" | tmux load-buffer -
tmux paste-buffer -t "$target_id"

# Notify
tmux display-message "Sent to pane $(echo "$target" | cut -d'|' -f2,3 | tr '|' ': ')"
```

---

## Summary of Best Practices

### ✅ DO

1. **Use `load-buffer + paste-buffer`** for inter-pane text transfer
2. **Use `copy-pipe-no-clear`** to preserve selection after copy
3. **Strip ANSI codes** with `sed 's/\x1b\[[0-9;]*m//g'`
4. **Use `capture-pane -p`** to avoid polluting buffer list
5. **Bind copy mode keys with `-T copy-mode-vi`** (modern syntax)
6. **Exit copy mode before showing menus** (use `copy-pipe-and-cancel`)
7. **Preview pane content in fzf** for better UX

### ❌ DON'T

1. **Don't use `send-keys` for multiline text** (escaping issues)
2. **Don't assume copy mode and menus can coexist** (they can't)
3. **Don't forget `-l` flag** when using `send-keys` for literal text
4. **Don't use old syntax** (`-t vi-copy` is deprecated)
5. **Don't pipe to external clipboard without user consent** (privacy)

---

## Recommended Implementation for Agent Tmux Toolkit

### Option A: Copy Mode Selection → Target Picker

**User flow:**
1. Enter copy mode (`Prefix + [`)
2. Select text (`v` to start selection)
3. Press `S` (custom binding)
4. Selection copied, copy mode exits
5. Pane picker appears (fzf)
6. User selects target
7. Text sent to target pane

**Implementation:**
```bash
# .tmux.conf
bind-key -T copy-mode-vi S \
    send-keys -X copy-pipe-and-cancel \
    "~/.local/bin/agent-send-selection"
```

### Option B: Keybinding → Capture Current Pane → Pick Target

**User flow:**
1. Press `Option+T` (or similar)
2. Script captures last N lines of current pane
3. Pane picker appears
4. User selects target
5. Text sent to target pane

**Implementation:**
```bash
# .tmux.conf
bind-key -n M-t run-shell "~/.local/bin/agent-quick-send"
```

**Recommendation:** Implement **Option A** for precise selection, **Option B** for quick context sharing. Both complement existing `agent-handoff`.

---

## References

### Official Documentation
- [tmux Manual Page](https://man7.org/linux/man-pages/man1/tmux.1.html)
- [GitHub: tmux/tmux Wiki - Clipboard](https://github.com/tmux/tmux/wiki/Clipboard)
- [GitHub: tmux/tmux Wiki - Getting Started](https://github.com/tmux/tmux/wiki/Getting-Started)
- [GitHub: tmux/tmux Wiki - Advanced Use](https://github.com/tmux/tmux/wiki/Advanced-Use)

### Tutorials & Guides
- [The Easy Way to Copy Text in Tmux - DEV Community](https://dev.to/iggredible/the-easy-way-to-copy-text-in-tmux-319g)
- [tmux Copy and Paste Methods - Baeldung](https://www.baeldung.com/linux/tmux-copy-paste-keyboard-mouse)
- [Copy and Paste in tmux - seanh.cc](https://www.seanh.cc/2020/12/27/copy-and-paste-in-tmux/)
- [tmux in practice: system clipboard - freeCodeCamp](https://www.freecodecamp.org/news/tmux-in-practice-integration-with-system-clipboard-bcd72c62ff7b/)
- [Everything you need to know about tmux copy paste - rushiagr](https://www.rushiagr.com/blog/2016/06/16/everything-you-need-to-know-about-tmux-copy-pasting-ubuntu/)

### Reference Documentation
- [Copy Mode | tmux/tmux | DeepWiki](https://deepwiki.com/tmux/tmux/6.1-copy-mode)
- [Buffer Management | tmux/tmux | DeepWiki](https://deepwiki.com/tmux/tmux/6.2-buffer-management)
- [User Interaction Commands | DeepWiki](https://deepwiki.com/tmux/tmux/5.4-user-interaction-commands)

### Community Resources
- [GitHub: tmux-plugins/tmux-yank](https://github.com/tmux-plugins/tmux-yank)
- [GitHub: slarwise/vim-tmux-send](https://github.com/slarwise/vim-tmux-send)
- [The power of tmux hooks - devel.tech](https://devel.tech/tips/n/tMuXz2lj/the-power-of-tmux-hooks/)

### Workflow Examples
- [My tmux workflow - Carlos Becker](https://carlosbecker.com/posts/tmux-sessionizer/)
- [My tmux workflow - Miro Sval](https://mirosval.sk/blog/2023/tmux-workflow/)
- [Faster command-line workflow with tmux - Medium](https://medium.com/@lamdbui/faster-command-line-workflow-with-tmux-a6539c8eae2c)

---

**End of Research Document**
