---
status: pending
priority: p3
issue_id: "024"
tags: [code-review, simplification, cleanup]
dependencies: []
---

# Remove agent-notify (Rarely Used)

## Problem Statement

`agent-notify` is 44 lines of code that is:
- Disabled by default (per README)
- Requires external tools (terminal-notifier, notify-send)
- Adds tmux config complexity
- Not part of core workflow

Most developers don't want desktop notifications from their terminal.

## Findings

### Code Analysis
- **Lines:** 44
- **Default state:** Disabled
- **Evidence:** README says "disabled by default"
- **tmux.conf entries:** 7 lines of hook configuration

### Usage Pattern
The feature would notify when:
- Agent sessions need attention
- Sessions are idle for 30+ seconds

This is rarely useful since users are typically watching the terminal.

## Proposed Solutions

### Option A: Remove Entirely (Recommended)
Delete agent-notify and related tmux.conf entries.

**Pros:**
- 44 fewer lines to maintain
- Simpler tmux config
- No confusing "disabled by default" feature

**Cons:**
- Feature loss for anyone using it

**Effort:** Very Low (15 min)
**Risk:** Very Low

### Option B: Move to Optional Plugin
Keep code but move to separate repository/plugin.

**Pros:**
- Feature preserved for interested users
- Core toolkit simplified

**Cons:**
- Maintenance overhead for separate repo

**Effort:** Low (30 min)
**Risk:** Low

### Option C: Keep but Document Better
Keep agent-notify but improve documentation.

**Pros:**
- No code changes
- Feature available

**Cons:**
- Still maintaining unused code

**Effort:** Very Low (10 min)
**Risk:** Low

## Recommended Action

Option A - Remove entirely. Add note in README about using terminal-notifier directly if users want notifications.

## Technical Details

### Files to Remove
- `bin/agent-notify` (44 lines)

### Config to Update
Remove from `config/agent-tmux.conf`:
```
# Lines 103-116 - notification settings
```

### README Update
Add note:
```markdown
## Notifications (Optional)
For desktop notifications, use terminal-notifier directly:
`terminal-notifier -title "Agent" -message "Task complete"`
```

## Acceptance Criteria

- [ ] bin/agent-notify removed
- [ ] Notification config removed from agent-tmux.conf
- [ ] README updated with alternative
- [ ] install.sh updated to not copy agent-notify

## Work Log

| Date | Action | Notes |
|------|--------|-------|
| 2026-01-05 | Created | From simplicity review |

## Resources

- Code Simplicity Review: Feature analysis
