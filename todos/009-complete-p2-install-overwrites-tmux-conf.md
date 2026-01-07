---
status: complete
priority: p2
issue_id: "009"
tags: [code-review, security, data-integrity]
dependencies: []
---

# Install Script Overwrites tmux.conf Without Backup

## Problem Statement

The install script overwrites `~/.tmux.conf` without creating a backup, and line 45 completely replaces the file if it doesn't contain the source line. Users could lose their existing tmux configuration.

**Why it matters:** Data loss during installation is a serious UX issue. Users trust install scripts not to destroy their configurations.

## Findings

**Location:** `install.sh:38-47`

```bash
# Check if tmux.conf sources our config
if [[ -f ~/.tmux.conf ]]; then
    if ! grep -q "agent-tmux.conf" ~/.tmux.conf; then
        echo ""
        echo -e "${YELLOW}Add this line to your ~/.tmux.conf:${NC}"
        echo "  source-file ~/.config/agent-tmux.conf"
    fi
else
    echo "source-file ~/.config/agent-tmux.conf" > ~/.tmux.conf  # OVERWRITES!
    echo "Created ~/.tmux.conf"
fi
```

**Problems:**
1. Line 45: `>` overwrites entire file (should append or create new)
2. No backup of existing scripts in `~/.local/bin`
3. Silent replacement of user's scripts

**Additional issue at lines 18-23:**
```bash
cp bin/agent-session ~/.local/bin/
cp bin/agent-manage ~/.local/bin/
# ... etc - no backup of existing files
```

## Proposed Solutions

### Option A: Safe Installation with Backups (Recommended)
**Description:** Create backups before overwriting anything.

```bash
# Backup existing scripts
backup_if_exists() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup="${file}.backup.$(date +%Y%m%d%H%M%S)"
        cp "$file" "$backup"
        echo -e "${YELLOW}Backed up $file to $backup${NC}"
    fi
}

# Before copying scripts
for script in agent-session agent-manage snippet-picker snippet-edit; do
    backup_if_exists ~/.local/bin/$script
done

# For tmux.conf - append instead of overwrite
if [[ ! -f ~/.tmux.conf ]]; then
    echo "source-file ~/.config/agent-tmux.conf" > ~/.tmux.conf
    echo "Created ~/.tmux.conf"
elif ! grep -q "agent-tmux.conf" ~/.tmux.conf; then
    echo "" >> ~/.tmux.conf
    echo "# Agent Tmux Toolkit" >> ~/.tmux.conf
    echo "source-file ~/.config/agent-tmux.conf" >> ~/.tmux.conf
    echo "Added source line to existing ~/.tmux.conf"
fi
```

**Pros:**
- No data loss
- Recoverable if something goes wrong
- Clearer user feedback

**Cons:**
- Creates backup files (minor clutter)

**Effort:** Small
**Risk:** Low

### Option B: Interactive Confirmation
**Description:** Ask before overwriting.

**Pros:**
- User control

**Cons:**
- Breaks non-interactive installation

**Effort:** Small
**Risk:** Low

## Recommended Action

**Option A** - Safe installation with automatic backups.

## Technical Details

**Affected file:** `install.sh`

**Changes:**
1. Add `backup_if_exists()` helper function
2. Call it before each `cp` of scripts
3. Change tmux.conf handling from overwrite to append

## Acceptance Criteria

- [ ] Existing scripts are backed up before overwriting
- [ ] tmux.conf is appended to, not overwritten
- [ ] Backup files have timestamp in name
- [ ] User is informed of backups created
- [ ] Installation still works on fresh system
- [ ] Add uninstall.sh that preserves user snippets

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-04 | Created finding from security review | Always backup before overwriting user files |

## Resources

- Security Sentinel analysis
- Data Integrity Guardian analysis
