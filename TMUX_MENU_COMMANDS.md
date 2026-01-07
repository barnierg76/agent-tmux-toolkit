# tmux Menu Commands - Quick Reference

Ready-to-use tmux commands for dynamic menus and popups. Copy and test these directly.

---

## Testing Commands

### Basic Menu Test

```bash
# Simple static menu
tmux display-menu -T "Test Menu" -x C -y C \
  "Option 1" 1 "display-message 'You chose option 1'" \
  "Option 2" 2 "display-message 'You chose option 2'" \
  "" "" "" \
  "Cancel" q ""
```

### Basic Popup Test

```bash
# Simple popup with message
tmux display-popup -E -w 50% -h 30% -T "Test Popup" \
  'echo "Hello from popup!"; read -p "Press enter to close..."'
```

---

## Session Management

### List All Sessions

```bash
# Just names
tmux list-sessions -F '#S'

# With details
tmux list-sessions -F '#{session_name}: #{session_windows} windows, #{session_attached} attached'

# As JSON-like format
tmux list-sessions -F '{"name":"#{session_name}","windows":#{session_windows},"attached":#{session_attached}}'
```

### Dynamic Session Switcher Menu

```bash
# Method 1: Using awk
tmux display-menu -T "Switch Session" \
  $(tmux list-sessions -F '#S' | awk 'BEGIN {ORS=" "} {print "\"" $1 "\"", NR, "\"switch-client -t", $1 "\""}')

# Method 2: Using while loop (more readable)
menu_items=""
i=1
for session in $(tmux list-sessions -F '#S'); do
  menu_items="$menu_items \"$session\" \"$i\" \"switch-client -t $session\""
  i=$((i+1))
done
eval "tmux display-menu -T \"Switch Session\" $menu_items"
```

### Session Switcher Popup (with fzf)

```bash
# Interactive fuzzy finder
tmux display-popup -E -w 60% -h 50% -T "Switch Session" \
  'tmux list-sessions -F "#S: #{session_windows} windows" | fzf | cut -d: -f1 | xargs tmux switch-client -t'
```

---

## Pane Navigation

### List All Panes

```bash
# All panes with full details
tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index} "#{pane_title}" [#{pane_current_command}] {#{pane_id}}'

# Just pane IDs and titles
tmux list-panes -a -F '#{pane_id}: #{pane_title}'

# Filter by title pattern
tmux list-panes -a -F '#{pane_id} #{pane_title}' -f '#{m:*agent*,#{pane_title}}'
```

### Dynamic Pane Switcher Menu

```bash
# Jump to any pane
menu_items=""
current_pane=$(tmux display -p '#{pane_id}')

while IFS='|' read -r pane_id session window pane_idx title; do
  [ "$pane_id" = "$current_pane" ] && continue
  label="$session:$window.$pane_idx - $title"
  menu_items="$menu_items \"$label\" \"\" \"select-pane -t $pane_id\""
done < <(tmux list-panes -a -F '#{pane_id}|#{session_name}|#{window_index}|#{pane_index}|#{pane_title}')

eval "tmux display-menu -T \"Jump to Pane\" -x C -y C $menu_items"
```

### Pane Switcher Popup (with fzf)

```bash
# Interactive pane jumper with preview
tmux display-popup -E -w 80% -h 70% -T "Jump to Pane" \
  'tmux list-panes -a -F "#{pane_id}: #{session_name}:#{window_index}.#{pane_index} - #{pane_title} [#{pane_current_command}]" | \
   fzf --preview "tmux capture-pane -t {1} -p" | \
   cut -d: -f1 | xargs tmux select-pane -t'
```

---

## Window Operations

### List Windows

```bash
# Current session windows
tmux list-windows -F '#{window_index}: #{window_name} #{?window_active,(active),}'

# All windows across all sessions
tmux list-windows -a -F '#{session_name}:#{window_index} #{window_name}'
```

### Window Switcher Menu

```bash
# Simple window list
menu_items=""
while IFS='|' read -r idx name active; do
  label="$idx: $name"
  [ "$active" = "1" ] && label="$label (current)"
  menu_items="$menu_items \"$label\" \"$idx\" \"select-window -t :$idx\""
done < <(tmux list-windows -F '#{window_index}|#{window_name}|#{window_active}')

eval "tmux display-menu -T \"Switch Window\" $menu_items"
```

---

## Agent Integration

### Find Agent Panes

```bash
# Find panes with "agent" in title
tmux list-panes -a -F '#{pane_id} #{pane_title}' -f '#{m:*agent*,#{pane_title}}'

# Find panes with specific commands
tmux list-panes -a -F '#{pane_id} #{pane_current_command}' -f '#{m:node,#{pane_current_command}}'
```

### Send Content to Agent Menu

```bash
# Menu to select which agent to send to
current_pane=$(tmux display -p '#{pane_id}')
menu_items=""

while IFS='|' read -r pane_id title; do
  [ "$pane_id" = "$current_pane" ] && continue
  if echo "$title" | grep -qi -e agent -e research; then
    # Command to capture current pane and send to selected pane
    cmd="run-shell 'tmux capture-pane -p -S - | tmux load-buffer - && tmux paste-buffer -t $pane_id'"
    menu_items="$menu_items \"Send to: $title\" \"\" \"$cmd\""
  fi
done < <(tmux list-panes -a -F '#{pane_id}|#{pane_title}')

if [ -z "$menu_items" ]; then
  tmux display-message "No agent panes found"
else
  eval "tmux display-menu -T \"Send to Agent\" -x M -y M $menu_items"
fi
```

### Capture and Send to Specific Pane

```bash
# Capture current pane history and send to pane %2
tmux capture-pane -p -S - | tmux load-buffer - && tmux paste-buffer -t '%2'

# Capture last 50 lines
tmux capture-pane -p -S -50 | tmux load-buffer - && tmux paste-buffer -t '%2'

# Capture visible screen only
tmux capture-pane -p | tmux load-buffer - && tmux paste-buffer -t '%2'
```

---

## Styled Menus

### Styled Menu Example

```bash
tmux display-menu \
  -T "#[align=centre]Styled Menu" \
  -x C -y C \
  -b rounded \
  -s "bg=colour235,fg=white" \
  -S "fg=cyan,bold" \
  -H "bg=yellow,fg=black,bold" \
  "Option 1" 1 "display-message 'Option 1'" \
  "Option 2" 2 "display-message 'Option 2'" \
  "" "" "" \
  "Disabled" "" "" \
  "-Disabled" d "" \
  "" "" "" \
  "Cancel" q ""
```

### Styled Popup Example

```bash
tmux display-popup \
  -E \
  -b double \
  -s "bg=colour235,fg=white" \
  -S "fg=green,bold" \
  -T "#[fg=yellow,bold]Styled Popup" \
  -w 60% -h 40% \
  -x C -y C \
  'ls -la --color=always'
```

---

## Context Menus

### Right-Click Pane Menu

```bash
# Bind to right-click on pane
bind-key -n MouseDown3Pane display-menu -T "Pane Actions" -x M -y M \
  "Split Horizontal" h "split-window -h -c '#{pane_current_path}'" \
  "Split Vertical" v "split-window -v -c '#{pane_current_path}'" \
  "" "" "" \
  "#{?#{pane_marked},Unmark,Mark}" m "select-pane -#{?#{pane_marked},M,m}" \
  "#{?#{pane_marked_set},Swap with Marked,}" "" "#{?#{pane_marked_set},swap-pane,}" \
  "" "" "" \
  "Kill Pane" k "kill-pane" \
  "Break to Window" b "break-pane"
```

### Status Line Menu

```bash
# Bind to click on status line
bind-key -n MouseDown3Status display-menu -T "Session Menu" -x W -y S \
  "New Session" n "command-prompt -p 'New session name:' 'new-session -s %%'" \
  "Rename Session" r "command-prompt -I '#S' 'rename-session %%'" \
  "" "" "" \
  "List Sessions" l "choose-tree -s" \
  "" "" "" \
  "Kill Session" k "confirm-before -p 'Kill session #S?' kill-session"
```

---

## Format Testing

### Display All Format Variables

```bash
# Show all available format variables and their values
tmux display-message -a | less

# Filter for specific type
tmux display-message -a | grep pane
tmux display-message -a | grep session
tmux display-message -a | grep window
```

### Test Format Expressions

```bash
# Simple variable
tmux display -p '#{session_name}'

# Conditional
tmux display -p '#{?session_attached,Attached,Detached}'

# Comparison
tmux display -p '#{==:#{session_name},mysession}'

# Loop
tmux display -p '#{S:#{session_name} }'

# Complex example
tmux display -p 'Session: #{session_name}, Windows: #{session_windows}, Attached: #{?session_attached,Yes,No}'
```

---

## Useful One-Liners

### Get Current Pane ID

```bash
tmux display -p '#{pane_id}'
```

### Get Current Session Name

```bash
tmux display -p '#{session_name}'
```

### Count Total Panes

```bash
tmux list-panes -a | wc -l
```

### Find Pane by Title

```bash
tmux list-panes -a -F '#{pane_id}' -f '#{==:#{pane_title},MyTitle}'
```

### Switch to Pane by Title

```bash
pane_id=$(tmux list-panes -a -F '#{pane_id}' -f '#{m:*agent*,#{pane_title}}' | head -1)
[ -n "$pane_id" ] && tmux select-pane -t "$pane_id"
```

### Create Session If Not Exists

```bash
tmux has-session -t mysession 2>/dev/null || tmux new-session -d -s mysession
```

---

## Complete Example: Main Menu System

Save this as `~/.tmux/scripts/main-menu.sh`:

```bash
#!/bin/bash
# Complete main menu with submenus

show_session_menu() {
  menu_items=""
  i=1
  for session in $(tmux list-sessions -F '#S'); do
    menu_items="$menu_items \"$session\" \"$i\" \"switch-client -t $session\""
    i=$((i+1))
  done
  menu_items="$menu_items \"\" \"\" \"\" \"New Session\" n \"command-prompt 'new-session -s %%'\""
  eval "tmux display-menu -T \"Sessions\" -x C -y C $menu_items"
}

show_window_menu() {
  menu_items=""
  while IFS='|' read -r idx name; do
    menu_items="$menu_items \"$idx: $name\" \"$idx\" \"select-window -t :$idx\""
  done < <(tmux list-windows -F '#{window_index}|#{window_name}')
  menu_items="$menu_items \"\" \"\" \"\" \"New Window\" n \"new-window\""
  eval "tmux display-menu -T \"Windows\" -x C -y C $menu_items"
}

show_pane_menu() {
  menu_items=""
  current_pane=$(tmux display -p '#{pane_id}')
  while IFS='|' read -r pane_id title; do
    [ "$pane_id" = "$current_pane" ] && continue
    menu_items="$menu_items \"$title\" \"\" \"select-pane -t $pane_id\""
  done < <(tmux list-panes -F '#{pane_id}|#{pane_title}')
  eval "tmux display-menu -T \"Panes\" -x C -y C $menu_items"
}

# Main menu
tmux display-menu -T "Main Menu" -x C -y C \
  "Sessions..." s "run-shell '$0 sessions'" \
  "Windows..." w "run-shell '$0 windows'" \
  "Panes..." p "run-shell '$0 panes'" \
  "" "" "" \
  "Split Horizontal" h "split-window -h" \
  "Split Vertical" v "split-window -v" \
  "" "" "" \
  "Reload Config" r "source ~/.tmux.conf" \
  "Detach" d "detach-client"

# Handle submenu calls
case "${1:-}" in
  sessions) show_session_menu ;;
  windows) show_window_menu ;;
  panes) show_pane_menu ;;
esac
```

Add to `.tmux.conf`:
```bash
bind-key Space run-shell '~/.tmux/scripts/main-menu.sh'
```

---

## Testing Workflow

1. **Start tmux**:
   ```bash
   tmux new -s test
   ```

2. **Test basic menu**:
   ```bash
   tmux display-menu -T "Test" "Hello" 1 "display-message 'Hi'" "Bye" 2 ""
   ```

3. **Create multiple sessions**:
   ```bash
   tmux new-session -d -s session1
   tmux new-session -d -s session2
   tmux new-session -d -s session3
   ```

4. **Test dynamic session menu**:
   ```bash
   tmux display-menu $(tmux list-sessions -F '#S' | awk 'BEGIN {ORS=" "} {print "\"" $1 "\"", NR, "\"switch-client -t", $1 "\""}')
   ```

5. **Test popup**:
   ```bash
   tmux display-popup -E 'tmux list-sessions'
   ```

6. **Test agent detection**:
   ```bash
   # Create agent pane
   tmux split-window -h
   tmux select-pane -T "agent-research"

   # List agent panes
   tmux list-panes -a -F '#{pane_id} #{pane_title}' -f '#{m:*agent*,#{pane_title}}'
   ```

---

**Quick Reference Card**:

```bash
# Session menu
tmux display-menu $(tmux list-sessions -F '#S' | awk 'BEGIN {ORS=" "} {print "\"" $1 "\"", NR, "\"switch-client -t", $1 "\""}')

# Popup session switcher
tmux display-popup -E 'tmux list-sessions | fzf | cut -d: -f1 | xargs tmux switch-client -t'

# Send to agent
tmux capture-pane -p -S - | tmux load-buffer - && tmux paste-buffer -t AGENT_PANE_ID

# Current pane info
tmux display -p '#{pane_id}: #{pane_title} [#{pane_current_command}]'

# Find agent panes
tmux list-panes -a -F '#{pane_id}' -f '#{m:*agent*,#{pane_title}}'
```

---

**Generated**: 2026-01-06
**Purpose**: Quick command reference for testing and implementing tmux menus in agent-tmux-toolkit
