---
status: pending
priority: p3
issue_id: "015"
tags: [code-review, simplicity, yagni]
dependencies: []
---

# Interactive Menu May Be Over-Engineered

## Problem Statement

The `cmd_menu()` function is 126 lines of TUI code that duplicates functionality already available via direct CLI commands. Users who want the menu can invoke it, but it adds significant complexity.

**Why it matters:** The CLI commands are simple and work well. The menu adds maintenance burden and complexity that may not justify its UX benefit.

## Findings

**Location:** `bin/agent-manage:248-373`

**Menu provides these actions:**
- New session → `agent-manage new [name]`
- Status → `agent-manage status`
- Add panes → `agent-manage add <n>`
- Layout → `agent-manage layout`
- Rename pane → `agent-manage rename <n> <name>`
- Focus pane → `agent-manage focus <n>`
- Close pane → `agent-manage close <n>`
- Kill session → `agent-manage kill <target>`
- Attach session → (click on session name)

**All of these work fine from CLI.**

**Code complexity:**
- 126 lines (27% of agent-manage)
- fzf-specific bindings
- State management for menu loop
- read -p prompts inside menu

## Proposed Solutions

### Option A: Keep Menu, Note Technical Debt
**Description:** Menu provides legitimate UX value for discoverability. Keep it but acknowledge the maintenance cost.

**Pros:**
- Good for new users
- Interactive discovery of features

**Cons:**
- 126 lines to maintain
- Duplicates CLI functionality

**Effort:** None
**Risk:** None

### Option B: Remove Menu, Rely on CLI + Help
**Description:** Delete cmd_menu(), add better help text.

**Pros:**
- -126 lines of code
- Simpler maintenance
- CLI is more scriptable

**Cons:**
- Loss of discoverability for new users
- Some users prefer menu UX

**Effort:** Small (delete code)
**Risk:** Low (feature removal)

### Option C: Extract Menu to Separate Script
**Description:** Move menu to `agent-menu` script, keep agent-manage focused on CLI.

**Pros:**
- Separation of concerns
- Menu is opt-in
- Cleaner main script

**Cons:**
- Another file to maintain
- Users need to know about both

**Effort:** Medium
**Risk:** Low

## Recommended Action

**Option A** - Keep the menu. It provides legitimate UX value and isn't causing bugs. This is a "nice to have" simplification, not a critical fix.

If maintenance becomes burdensome, consider Option C.

## Technical Details

**Lines involved:** `bin/agent-manage:248-373`

## Acceptance Criteria

- [ ] Decision documented (keeping menu)
- [ ] Consider extraction if menu grows more complex

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-04 | Created finding from simplicity review | Not all complexity is bad - weigh UX value |

## Resources

- Code Simplicity Reviewer analysis
