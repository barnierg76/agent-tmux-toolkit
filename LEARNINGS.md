# Learnings

Lessons learned while building and maintaining this toolkit.

---

## 2026-01-04 - Tmux Pane Indexing Off-by-One Bug

### What Happened
Keybindings `Option+1/2/3` weren't selecting the correct panes. Option+1 failed entirely, Option+2 selected pane 1, etc.

### Root Cause
Tmux has **two separate indexing systems** that must stay in sync:

1. **Display indexing** (what users see): controlled by `base-index` and `pane-base-index`
2. **Command targets**: `-t N` uses the display index, not internal 0-based index

We had:
```bash
setw -g pane-base-index 1    # Panes display as 1, 2, 3
bind -n M-1 select-pane -t 0  # WRONG: tries to select non-existent pane 0
```

### The Fix
Match command targets to display indices:
```bash
setw -g pane-base-index 1    # Panes display as 1, 2, 3
bind -n M-1 select-pane -t 1  # CORRECT: selects pane 1
bind -n M-2 select-pane -t 2
bind -n M-3 select-pane -t 3
```

For session:window.pane format:
```bash
# With base-index 1 and pane-base-index 1:
tmux select-pane -t "session:1.1"  # First pane of first window
tmux select-pane -t "session:1.2"  # Second pane of first window
```

### Pattern to Remember
> When using `pane-base-index 1` (or any non-zero base), ALL pane references in keybindings, scripts, and commands must use the same 1-based indices.

### Files Affected
- `config/agent-tmux.conf` - keybindings
- `bin/agent-flow` - fallback pane selection

### How to Avoid
1. Always check `pane-base-index` setting before writing pane-targeting code
2. Test keybindings with actual pane selection, not just "does it error"
3. Use `tmux display -p '#{pane_index}'` to verify which pane is selected

---

## 2026-01-04 - Tmux Copy-Paste Spans Multiple Panes

### What Happened
When selecting text in pane 2 or 3, the selection included text from other panes on the same horizontal lines.

### Root Cause
**Terminal emulators don't know about tmux panes.** When you click-drag to select text, your terminal (iTerm2, etc.) sees the entire tmux window as one continuous text buffer. Pane borders are just rendered characters - the terminal doesn't distinguish "content" from "tmux UI."

### The Fix
Use tmux's pane-aware copy mode bindings with `copy-pipe-and-cancel`:

```bash
# Mouse drag: select within pane only, copy to clipboard
bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel "pbcopy"

# Double-click: select word and copy to clipboard
bind -T copy-mode-vi DoubleClick1Pane select-pane \; send -X select-word \; send -X copy-pipe-and-cancel "pbcopy"

# Triple-click: select line and copy to clipboard
bind -T copy-mode-vi TripleClick1Pane select-pane \; send -X select-line \; send -X copy-pipe-and-cancel "pbcopy"
```

### Pattern to Remember
> Terminal-native selection (Shift+drag) bypasses tmux and will always span panes. Use tmux's copy mode for pane-aware selection.

### How to Use
1. Click in a pane to enter copy mode automatically
2. Drag to select - selection stays within pane boundaries
3. Release mouse - text is copied to system clipboard (Cmd+V to paste)

Or keyboard workflow:
1. `Prefix + v` to enter copy mode
2. `v` to start selection, move cursor
3. `y` to yank (copy)
4. `Prefix + p` to paste

### Files Affected
- `config/agent-tmux.conf` - added MouseDragEnd1Pane, DoubleClick1Pane, TripleClick1Pane bindings
