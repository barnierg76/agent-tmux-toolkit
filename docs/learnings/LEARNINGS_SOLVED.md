---
title: "Removed agent-notify - Unused Feature Cleanup"
date: 2026-01-06
category: cleanup
tags: [code-simplification, maintenance, refactor, unused-code]
component: agent-tmux-toolkit
severity: low
issue_id: "#6"
solved_in: "c68727e - refactor: extract shared library and simplify codebase"
---

## Problem Solved

GitHub issue #6 requested removal of `agent-notify`, an unused and rarely-employed notification feature that was disabled by default.

## What Was Done

In commit c68727e, the following changes were made:

### Files Removed
- **bin/agent-notify** (44 lines) - Desktop notification script requiring external dependencies (terminal-notifier, notify-send)

### Files Modified
- **config/agent-tmux.conf** - Removed 7 lines of notification hook configuration (lines 103-116)
- **install.sh** - Removed reference to copying agent-notify
- **README.md** - Removed documentation about the notification feature

### Impact
- Net reduction of ~500 lines of duplicated/unused code across the entire refactor
- Simplified tmux configuration
- Removed unnecessary external dependencies

## Root Cause Analysis

The feature existed as "dead code" because:
1. **Disabled by default** - Users had to explicitly enable it
2. **External dependencies** - Required terminal-notifier (macOS) or notify-send (Linux)
3. **Limited use case** - Desktop notifications from terminal are rarely useful when user is actively watching
4. **Maintenance burden** - Code took up space without providing core value to the toolkit

## Learnings

### What Worked
- Systematic code cleanup identified and removed unused features
- Shared library extraction (bin/agent-common.sh) reduced duplication
- Thorough refactor improved overall codebase maintainability

### What to Remember
- **Disabled-by-default features** are candidates for removal if not core to the toolkit
- **External dependency burden** should be weighed against feature value
- **Code simplification compounds** - removing 500 lines of dead code makes the codebase easier to understand and maintain

### Patterns to Reuse
- When reviewing unused features: Ask "Are we maintaining this for anyone?" If the answer is no, remove it
- Extract shared utilities into common libraries to reduce duplication across scripts
- Regularly audit for "dead code" that adds complexity without value

## Status

**COMPLETED** - Issue #6 resolved in commit c68727e (2026-01-05)
**Note:** Todo file `todos/024-pending-p3-remove-agent-notify.md` is now stale and should be archived

## Evidence

```
commit c68727e89af4235ec859a7415521335a2d12429e
Author: barnierg76 <barniergeerling@gmail.com>
Date:   Mon Jan 5 00:52:00 2026 +0100

    refactor: extract shared library and simplify codebase

    - Remove agent-notify (rarely used, adds complexity without clear value)

    Net reduction: ~500 lines of duplicated/unused code
```

### Before
- agent-notify: 44 lines
- agent-tmux.conf: 7 lines of hooks
- README: Confusing "disabled by default" documentation
- install.sh: Extra copy operation

### After
- Feature completely removed
- Config simplified
- Installation faster
- Clearer toolkit scope
