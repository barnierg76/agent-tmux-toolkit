---
title: "Agent-flow menu labels described transitions instead of actions"
category: "ui-bugs"
tags:
  - menu
  - ux
  - fzf
  - tmux
  - workflow
component: "agent-flow"
symptoms:
  - "Menu options show workflow transitions (Plan -> Work) rather than actions"
  - "Selecting 'Plan -> Work' actually enters work mode, not transitions"
  - "Labels describe workflow graph, not what user is selecting"
severity: "medium"
date_documented: "2026-01-06"
---

# Menu Labels Described Transitions Instead of Actions

## Problem

The `agent-flow` interactive menu had confusing labels that described **workflow transitions** rather than the **action being taken**:

| Label | What it actually does | Why confusing |
|-------|----------------------|---------------|
| `Start Feature` | Enters PLAN mode | Sounds like starting work |
| `Plan -> Work` | Enters WORK mode | Arrow implies transition, not selection |
| `Work -> Review` | Enters REVIEW mode | Same - workflow graph notation |

When selecting "Plan -> Work", users expected it to mean "go from plan to work". But it actually just starts work mode.

## Root Cause

Labels were designed from a **workflow diagram perspective** (showing state transitions) rather than a **user action perspective** (what mode am I entering).

Additionally, `--with-nth=2,3` in fzf showed both label AND description concatenated, making the display cluttered.

## Solution

### 1. Renamed labels to be action-oriented

**File:** `bin/agent-flow` (lines 164-174)

```bash
# Before:
start|Start Feature|Focus PLAN pane, run /workflows:plan
work|Plan -> Work|Focus WORK pane, run /workflows:work
review|Work -> Review|Focus REVIEW pane, run /workflows:review
handoff|Handoff Context|Transfer context between panes

# After:
start|Plan|Start planning a new feature
work|Work|Start implementing the plan
review|Review|Start reviewing the work
handoff|Handoff|Transfer context between panes
```

### 2. Fixed fzf display

**File:** `bin/agent-flow` (line 189)

```bash
# Before: showed label AND description
--with-nth=2,3

# After: shows only label
--with-nth=2
```

## Prevention

### Best Practice

**Menu labels should describe the ACTION being taken, not the TRANSITION or DESTINATION.**

### Checklist for Menu Labels

- [ ] Labels describe WHAT you're selecting, not WHERE you're going
- [ ] No arrows (→, ->) in labels
- [ ] No "transition" language ("from X to Y")
- [ ] New users can understand what happens without context
- [ ] Labels are concise (1-3 words)

### Good vs Bad Examples

| Bad (Transition-Based) | Good (Action-Based) |
|------------------------|---------------------|
| `Start Feature` | `Plan` |
| `Plan -> Work` | `Work` |
| `Work -> Review` | `Review` |
| `Handoff Context` | `Handoff` |

## Related

- **Commit:** `3cf8675` - fix(menu): clarify agent-flow menu labels to match actions
- **File:** `bin/agent-flow`
