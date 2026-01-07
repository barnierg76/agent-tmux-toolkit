# Research: CLI Help Systems Best Practices

**Research Date:** 2026-01-04
**Topic:** Implementing help systems in CLI tools - conventions, patterns, and UX best practices

---

## Table of Contents
1. [CLI Help Conventions](#cli-help-conventions)
2. [Terminal Menu UX Patterns](#terminal-menu-ux-patterns)
3. [Contextual Help in TUI Applications](#contextual-help-in-tui-applications)
4. [Real-World Examples](#real-world-examples)
5. [Implementation Recommendations](#implementation-recommendations)

---

## CLI Help Conventions

### Standard Help Options

**All CLI programs should support these standard options:**
- `--help` - Long form, most common
- `-h` - Short form, traditional Unix style
- `help` command - For git-like tools with subcommands

**Key Principles:**
- Help flags should **always print to stdout**, not stderr
- Help should **ignore other flags** - users should be able to add `-h` anywhere without side effects
- Support multiple invocation methods: `myapp --help`, `myapp -h`, `myapp help`, `myapp help subcommand`

**Source:** [Command Line Interface Guidelines](https://clig.dev/), [GNU Coding Standards](https://www.gnu.org/prep/standards/html_node/Command_002dLine-Interfaces.html)

### Two Levels of Help

#### 1. Concise Default Help (No Arguments)
When a command requiring arguments runs with no input, show **brief help**:
- Program description (one-liner)
- 1-2 example invocations
- Brief flag descriptions (if not too many)
- Pointer to `--help` for full information

**Example from jq:**
```
jq - commandline JSON processor [version 1.6]

Usage:    jq [options] <jq filter> [file...]
          jq [options] --args <jq filter> [strings...]
          jq [options] --jsonargs <jq filter> [JSON_TEXTS...]

For more options, see jq --help
```

#### 2. Extensive Help (--help flag)
Display comprehensive help including:
- Detailed flag descriptions
- Usage examples with expected output
- Subcommand documentation
- Links to web documentation
- Environment variables
- Configuration file paths

**Source:** [BetterCLI.org Help Pages](https://bettercli.org/design/cli-help-page/)

### Help Text Structure

Follow man page conventions with these sections (in order):

```
NAME
    Brief name and one-line description

SYNOPSIS
    Command syntax showing:
    - Bold for literal text (command name, options)
    - Italics for replaceable arguments
    - [brackets] for optional arguments
    - vertical bars | for choices
    - ... for repeatable items

DESCRIPTION
    Detailed explanation of what the program does

OPTIONS
    Each option with description, formatted as:
    -h, --help          Display this help and exit
    -v, --verbose       Enable verbose output
    -o, --output FILE   Write output to FILE

EXAMPLES
    Practical examples showing common usage:
    $ myapp --input file.txt --output result.txt
    Processing file.txt...
    Output written to result.txt

ENVIRONMENT
    Environment variables that affect behavior

FILES
    Configuration files and their locations

SEE ALSO
    Related commands, links to web documentation
```

**Sources:**
- [BetterCLI.org](https://bettercli.org/design/cli-help-page/)
- [How to Write a Man Page](https://babbage.cs.qc.cuny.edu/courses/cs701/Handouts/man_pages.html)
- [Ubuntu Man Page Conventions](https://manpages.ubuntu.com/manpages/jammy/man7/man-pages.7.html)

### Formatting Best Practices

**Text Styling:**
- **Bold** for command names and literal options
- *Italics* for replaceable arguments
- Indentation for option descriptions (4 spaces after first line)

**Line Length:**
- Limit to ~75 characters to prevent line-wrapping in email/patches
- Break long lines before hyphens, underscores, or quotes
- Indent continuation lines by 4 spaces

**Examples Section:**
- Use `.RS` (relative margin indent) to visually distinguish examples
- Show actual command output when helpful
- Keep examples short (<50 lines ideal, <100 max)
- Only include examples that demonstrate something non-obvious

**Source:** [Google Developer Documentation Style Guide](https://developers.google.com/style/code-syntax)

### Auto-Generation vs Manual

**Best Practice:** Generate help from code

- Use CLI frameworks that generate help from option definitions
- Ensures help never goes out of sync with implementation
- Keep **reference material** (options, flags) generated
- Create **documentation** (guides, tutorials) manually

**Source:** [BetterCLI.org](https://bettercli.org/design/cli-help-page/)

### Example-First Approach

**Lead with examples, not abstract descriptions:**

❌ Bad:
```
OPTIONS
  -r, --recursive    Process directories recursively
  -v, --verbose      Increase verbosity level
```

✅ Good:
```
EXAMPLES
  # Search all files in current directory and subdirectories
  $ myapp search "pattern" -r

  # Show detailed progress while processing
  $ myapp process file.txt -v

OPTIONS
  -r, --recursive    Process directories recursively
  -v, --verbose      Show detailed progress information
```

**Source:** [Command Line Interface Guidelines](https://clig.dev/)

### Error Messages with Helpful Suggestions

When users make mistakes, be helpful:

```bash
$ git sttaus
git: 'sttaus' is not a git command. See 'git --help'.

The most similar command is
    status
```

**Principles:**
- Clearly indicate the error
- Suggest correct alternatives
- Don't auto-correct for state-changing operations (dangerous)
- Guide toward correct syntax

**Source:** [BetterCLI.org](https://bettercli.org/design/cli-help-page/)

---

## Terminal Menu UX Patterns

### Common Keyboard Shortcut Patterns

Popular CLI tools use these conventions:

| Pattern | Tools Using It | Purpose |
|---------|---------------|---------|
| `?` | vim, less, many | Show help/keyboard shortcuts |
| `h` | vim, some TUIs | Help or navigate left |
| `Ctrl+R` | bash, fzf | Search history |
| `Ctrl+T` | fzf | File finder |
| `Ctrl+J/K` | fzf, vim | Navigate down/up |
| `Ctrl+N/P` | fzf, emacs | Next/previous (alternative to J/K) |
| `Esc` | Universal | Cancel/exit mode |
| `q` | less, vim, htop | Quit |
| `F1-F10` | htop, mc | Function menu |

**Sources:**
- [fzf GitHub](https://github.com/junegunn/fzf)
- [A Practical Guide to fzf](https://thevaluable.dev/fzf-shell-integration/)

### fzf - The Gold Standard for Minimal UX

**Key Bindings:**
- `Ctrl+K` / `Ctrl+J` - Move up/down
- `Ctrl+N` / `Ctrl+P` - Alternative navigation (emacs-style)
- `Ctrl+T` - Fuzzy file finder
- `Alt+C` - Change directory
- `Ctrl+R` - History search
- `Enter` - Select
- `Tab` - Multi-select toggle
- `Esc` - Cancel

**Design Philosophy:**
- No visible help by default (clean interface)
- Use `fzf --help` for documentation
- Rely on muscle memory from vim/emacs conventions
- Progressive disclosure: basic keys work, power users discover more

**tmux Integration:**
- `-p` flag creates popup/floating panes instead of splits
- Export `FZF_TMUX_OPTS="-p"` for consistent popup behavior

**Sources:**
- [fzf GitHub](https://github.com/junegunn/fzf)
- [Josh Medeski's tmux+fzf Guide](https://www.joshmedeski.com/posts/popup-history-with-tmux-and-fzf/)

---

## Contextual Help in TUI Applications

### Bottom Bar / Status Line Pattern

The most common pattern for displaying keyboard shortcuts in TUI applications is a **bottom status bar** showing available keys.

**Implementation Approach:**
1. Reserve bottom line(s) of terminal
2. Use VT100 escape sequences to position text
3. Configure scroll region to exclude bottom line
4. Update bar based on current context/focus

**Source:** [bottombar Python Library](https://github.com/evalf/bottombar)

### ncurses/TUI Help Display Patterns

**Three Common Approaches:**

#### 1. **Bottom Bar (htop, Midnight Commander style)**

Always visible, shows F1-F10 or common shortcuts:

```
F1Help F2Setup F3Search F4Filter F5Tree F6Sort F9Kill F10Quit
```

**Characteristics:**
- Takes 1-2 lines at bottom
- Always visible (persistent)
- Shows only most important shortcuts
- Context-sensitive (changes based on active screen)

**Example - htop:**
- Shows F1-F10 functions with color coding
- Mouse-clickable labels
- Alternative character shortcuts (S for Setup, K for Kill)

**Sources:**
- [htop Guide](https://spin.atomicobject.com/htop-guide/)
- [How to Use htop](https://www.howtogeek.com/how-to-use-linux-htop-command/)

#### 2. **F1/? Toggles Help Screen**

Dedicated help screen, toggled with F1 or `?`:

```
[Press F1 to return to main screen]

KEYBOARD SHORTCUTS

  Navigation:
    Up, k       - Move cursor up
    Down, j     - Move cursor down
    Home        - Jump to first item
    End         - Jump to last item

  Actions:
    Enter       - Select item
    Space       - Toggle selection
    d           - Delete item
    q, Esc      - Quit

[Press any key to continue]
```

**Characteristics:**
- Full-screen overlay
- Shows all available shortcuts with descriptions
- Organized by category
- Easy to dismiss (any key, Esc, or F1 again)

**Example - Midnight Commander:**
- F1 invokes hypertext help viewer
- Tab selects next link, Enter follows link
- Space/Backspace navigate pages
- F1 again shows full key list

**Sources:**
- [Midnight Commander Tutorial](http://www.trembath.co.za/mctutorial.html)
- [Linux Command Adventure: MC](https://linuxcommand.org/lc3_adv_mc.php)

#### 3. **In-Context Hints (Progressive Disclosure)**

Minimal hints that appear based on context:

```
> Select an option (? for help):
```

Then when `?` is pressed:

```
AVAILABLE COMMANDS:
  ?  - Show this help
  q  - Quit
  /  - Search
  n  - Next result
  p  - Previous result

Press any key to continue...
```

**Characteristics:**
- No permanent UI overhead
- Help appears only when requested
- Returns to original screen after dismissal
- Doesn't break flow for expert users

### GDB TUI as Reference Implementation

The GDB Text User Interface demonstrates professional TUI design:

**Features:**
- Multiple windows (source, assembly, registers, commands)
- Status line shows current process info
- Status line updates automatically when data changes
- SingleKey keymap for direct command access
- Readline keymaps for editing

**Key Insights:**
- Status line positioned with VT100 escape sequences
- Scroll region excludes status line
- Context-sensitive window management
- Separate keymaps for different modes

**Source:** [GDB TUI Documentation](https://developer.apple.com/library/archive/documentation/DeveloperTools/gdb/gdb/gdb_23.html)

---

## Real-World Examples

### htop - Bottom Bar with Function Keys

```
1[|||||||||||3.2%]  Tasks: 45, 123 thr; 1 running
2[|         0.7%]   Load average: 1.23 0.95 0.78
Mem[||||||1.2G/8.0G] Uptime: 2 days, 03:45:12
Swp[          0K/2G]

  PID USER      PRI  NI  VIRT   RES   SHR S CPU% MEM%   TIME+  Command
  123 user       20   0 1234M  123M  45M R  3.2  1.5  12:34.5 some-process

F1Help F2Setup F3Search F4Filter F5Tree F6SortBy F7Nice F8Nice+ F9Kill F10Quit
```

**Design Lessons:**
- Color-coded function keys (blue background)
- Compact single-line display
- Mouse-clickable
- Essential functions only (10 max)
- Consistent position (always bottom)

**Alternative Character Shortcuts:**
- Press `S` instead of F2 for Setup
- Press `k` instead of F9 for Kill
- Press `<` or `>` instead of F6 for Sort

**Source:** [htop Command Guide](https://spin.atomicobject.com/htop-guide/)

### Midnight Commander - Keybar + F1 Help

**Bottom Keybar (always visible):**
```
1Help 2Menu 3View 4Edit 5Copy 6Move 7Mkdir 8Delete 9PullDn 10Quit
```

**F1 Help Screen (on demand):**
- Built-in hypertext help viewer
- Tab to select next link
- Enter to follow link
- Space/Backspace for page navigation
- Press F1 again for full key list

**Terminal Compatibility:**
- ESC+number as alternative to function keys (ESC+1 = F1, ESC+0 = F10)
- Works around terminal emulators that intercept F-keys

**Source:** [Midnight Commander Manual](https://source.midnight-commander.org/man/mc.html)

### vim - Question Mark Help

```
:help [topic]       - Open help for topic
?                   - Search backward (in normal mode)
:help quickref      - Quick reference of all commands
:help index         - Complete index
```

**In vim, contextual help is built into the editor:**
- `:help` command with extensive documentation
- Tab completion for help topics
- Hyperlinked help navigation (Ctrl+] to follow, Ctrl+T to go back)

### Bash Select Menus - Simple PS3 Prompt

```bash
select option in "Option 1" "Option 2" "Quit"; do
  case $option in
    "Option 1") echo "You selected 1";;
    "Option 2") echo "You selected 2";;
    "Quit") break;;
  esac
done
```

**Default output:**
```
1) Option 1
2) Option 2
3) Quit
#?
```

The `#?` prompt is the default PS3 prompt. Customize with:
```bash
PS3="Select an option (or 'q' to quit): "
```

**Limitations:**
- No arrow key navigation (number selection only)
- No visual highlighting
- No built-in help display
- Fixed formatting

**Source:** [How to Create Selection Menu in Bash](https://linuxconfig.org/how-to-create-a-selection-menu-using-the-select-statement-in-bash-shell)

### Pure Bash Interactive Menus with Help

More advanced bash menus can include:
- Arrow key navigation
- Visual highlighting
- Help display on `?` or `h` key press
- Vim keybinds (j/k navigation)
- Multi-select with checkboxes

**Example pattern:**
```bash
# Show help when 'h' or '?' is pressed
case "$key" in
  h|"?")
    echo "HELP:"
    echo "  ↑/k  - Move up"
    echo "  ↓/j  - Move down"
    echo "  Enter - Select"
    echo "  Space - Toggle (multi-select)"
    echo "  q/Esc - Quit"
    echo ""
    echo "Press any key to continue..."
    read -n 1
    ;;
esac
```

**Sources:**
- [Pure BASH Interactive Menu Gist](https://gist.github.com/blurayne/f63c5a8521c0eeab8e9afd8baa45c65e)
- [Bash Script Graphical Menus](https://www.codegenes.net/blog/bash-script-with-graphical-menus/)

---

## Implementation Recommendations

Based on the research, here are concrete recommendations for implementing help in CLI tools:

### For Simple CLI Tools (No TUI)

**Implement both help levels:**

```bash
# Short help (when run with no args)
if [ $# -eq 0 ]; then
  cat <<EOF
myapp - Do something useful

Usage: myapp [OPTIONS] FILE

Common options:
  -h, --help     Show detailed help
  -v, --verbose  Enable verbose output

Example:
  myapp --verbose input.txt

See 'myapp --help' for more information.
EOF
  exit 0
fi

# Full help (when --help is passed)
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  cat <<EOF
NAME
    myapp - Do something useful with files

SYNOPSIS
    myapp [OPTIONS] FILE

DESCRIPTION
    Detailed explanation of what this tool does...

OPTIONS
    -h, --help
        Display this help message and exit

    -v, --verbose
        Enable verbose output, showing detailed progress
        information during processing

    -o, --output FILE
        Write results to FILE instead of stdout

EXAMPLES
    Process a file with verbose output:
        $ myapp -v input.txt
        Processing input.txt...
        Completed in 1.23s

    Save output to a file:
        $ myapp input.txt -o result.txt

ENVIRONMENT
    MYAPP_CONFIG    Path to config file (default: ~/.myapprc)

SEE ALSO
    https://github.com/user/myapp
EOF
  exit 0
fi
```

### For Interactive Bash Menus

**Pattern 1: Inline hint with toggle help**

```bash
show_menu() {
  clear
  echo "=== Main Menu ==="
  echo
  echo "1) Option One"
  echo "2) Option Two"
  echo "3) Option Three"
  echo "q) Quit"
  echo
  echo "Enter selection (? for help): "
}

show_help() {
  cat <<EOF

KEYBOARD SHORTCUTS:
  1-9    - Select numbered option
  ?      - Show this help
  q      - Quit

Press any key to continue...
EOF
  read -n 1
}

while true; do
  show_menu
  read -n 1 choice

  case $choice in
    "?") show_help ;;
    q) break ;;
    1) do_option_1 ;;
    2) do_option_2 ;;
    3) do_option_3 ;;
  esac
done
```

**Pattern 2: Bottom status line (ncurses-style)**

```bash
# For bash scripts that use arrow key navigation
print_menu_with_status() {
  clear

  # Print menu items
  for i in "${!options[@]}"; do
    if [ $i -eq $selected ]; then
      echo "> ${options[$i]}"  # Highlight selected
    else
      echo "  ${options[$i]}"
    fi
  done

  # Move cursor to bottom of screen
  tput cup $LINES 0

  # Print status line in reverse video
  tput rev
  printf "%-${COLUMNS}s" "↑/↓:Navigate Enter:Select ?:Help q:Quit"
  tput sgr0
}
```

### For TUI Applications (ncurses)

**Use the bottom bar pattern from htop/mc:**

```
┌─────────────────────────────────────────────┐
│                                             │
│  [Application content area]                │
│                                             │
│                                             │
├─────────────────────────────────────────────┤
│ F1Help F2Edit F3View F9Menu F10Quit         │
└─────────────────────────────────────────────┘
```

**Plus F1 detailed help screen:**

```
┌─────────────────────────────────────────────┐
│ HELP - Press F1 to close                    │
├─────────────────────────────────────────────┤
│                                             │
│ NAVIGATION:                                 │
│   ↑, k        Move up                       │
│   ↓, j        Move down                     │
│   Home        Jump to top                   │
│   End         Jump to bottom                │
│                                             │
│ ACTIONS:                                    │
│   Enter       Select/Open                   │
│   Space       Toggle                        │
│   d           Delete                        │
│                                             │
│ OTHER:                                      │
│   ?           Show this help                │
│   q, F10      Quit                          │
│                                             │
│ Press any key to continue...                │
└─────────────────────────────────────────────┘
```

### Design Decision Matrix

| Scenario | Recommended Pattern | Rationale |
|----------|-------------------|-----------|
| Simple CLI (no menu) | `--help` flag + auto-help on error | Standard convention, widely expected |
| One-time menu choice | `?` key shows help overlay | Doesn't clutter display, available when needed |
| Persistent TUI app | Bottom bar + F1 detailed help | Always visible essentials, details on demand |
| Complex TUI app | Multiple help modes (context-sensitive) | Different screens need different shortcuts |
| Arrow-key navigation menu | Bottom status line with hints | Guides new users without cluttering interface |

### Progressive Disclosure Strategy

**Level 1: Minimal (always visible)**
- Single line at bottom: `?:Help q:Quit`
- Or concise prompt: `Select (? for help):`

**Level 2: Essential (on ? or F1)**
- One-screen overview of key shortcuts
- Organized by category (Navigation, Actions, Other)
- "Press any key to continue"

**Level 3: Comprehensive (--help or dedicated help command)**
- Full documentation
- Examples with expected output
- Configuration options
- Links to web resources

**Example progression:**
```
Minimal:    ?:Help q:Quit
            ↓
Essential:  Full-screen shortcuts overlay
            ↓
Complete:   Man page / --help output
```

### Key Bindings Priority

**Standard keys that should be consistent across tools:**

1. `?` or `F1` - Show help (highest priority)
2. `q` or `F10` or `Esc` - Quit/Cancel
3. `Enter` - Select/Confirm
4. Arrow keys / `hjkl` / `Ctrl+N/P/J/K` - Navigate
5. `Space` - Toggle (in multi-select contexts)
6. `/` - Search (if applicable)
7. `n` / `p` - Next/Previous (if applicable)

**Do NOT override these without very good reason** - they're muscle memory for many users.

---

## Summary: Best Practices Checklist

### CLI Help System Checklist

- [ ] Support `-h` and `--help` flags
- [ ] Print help to stdout (not stderr)
- [ ] Ignore other flags when help is requested
- [ ] Show brief help when run with no args (if args are required)
- [ ] Include program description, examples, and options
- [ ] Format help text for 75-80 character width
- [ ] Use bold for commands/options, italics for arguments
- [ ] Lead with examples, not abstract descriptions
- [ ] Include link to web documentation
- [ ] Provide helpful error messages with suggestions

### Interactive Menu Checklist

- [ ] Display available shortcuts clearly
- [ ] Use `?` or `F1` for help (standard convention)
- [ ] Support `q` or `Esc` to quit/cancel
- [ ] Show context-sensitive help when possible
- [ ] Don't clutter interface - use progressive disclosure
- [ ] Provide escape hatch from help screen (any key)
- [ ] Consider terminal compatibility (ESC+number for F-keys)
- [ ] Use consistent navigation keys (arrows or vim-style)

### TUI Application Checklist

- [ ] Reserve bottom line(s) for status/shortcuts
- [ ] Configure scroll region to exclude status line
- [ ] Update status line based on active context
- [ ] Provide F1/? detailed help overlay
- [ ] Organize help by category (Navigation, Actions, etc.)
- [ ] Use color/reverse video to distinguish status bar
- [ ] Make function keys mouse-clickable (if possible)
- [ ] Provide character alternatives to function keys
- [ ] Test with different terminal sizes
- [ ] Handle terminal resize (SIGWINCH)

---

## Additional Resources

### Authoritative Sources
- [Command Line Interface Guidelines (clig.dev)](https://clig.dev/) - Comprehensive modern CLI design guide
- [GNU Coding Standards - CLI](https://www.gnu.org/prep/standards/html_node/Command_002dLine-Interfaces.html) - Traditional Unix standards
- [BetterCLI.org](https://bettercli.org/design/cli-help-page/) - Focused CLI design patterns
- [Google Developer Docs Style Guide](https://developers.google.com/style/code-syntax) - Code/CLI syntax documentation

### Example Code & Tools
- [fzf](https://github.com/junegunn/fzf) - Fuzzy finder with excellent minimal UX
- [Pure Bash Interactive Menu](https://gist.github.com/blurayne/f63c5a8521c0eeab8e9afd8baa45c65e) - Arrow key navigation
- [writing-a-tui-in-bash](https://github.com/dylanaraps/writing-a-tui-in-bash) - Pure bash TUI techniques
- [htop](https://github.com/htop-dev/htop) - Reference TUI with bottom bar
- [Midnight Commander](https://midnight-commander.org/) - F-key based TUI

### Libraries & Frameworks
- ncurses - Standard TUI library for C/C++
- [notcurses](https://github.com/dankamongmen/notcurses) - Modern TUI library
- dialog / whiptail - Ready-made TUI widgets for bash
- [bottombar](https://github.com/evalf/bottombar) - Python bottom status bar
- [tty-prompt](https://github.com/piotrmurach/tty-prompt) - Ruby interactive prompts

---

**Document Metadata:**
- **Created:** 2026-01-04
- **Research Method:** Web search across authoritative CLI design guides, tool documentation, and community best practices
- **Total Sources:** 40+ articles, documentation pages, and example repositories
- **Confidence Level:** High - Research based on established standards (GNU, clig.dev) and widely-used tools (vim, tmux, fzf, htop)
