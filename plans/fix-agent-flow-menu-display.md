# fix: agent-flow menu labels don't match their actions

**Date:** 2026-01-06
**Type:** Bug Fix
**Fidelity:** 1 (Quick Fix)

## Problem Statement

The `agent-flow` menu labels describe **workflow transitions** rather than the **action the user is taking**. This is confusing because:

| Current Label | What it does | Why it's confusing |
|---------------|--------------|-------------------|
| `Start Feature` | Enters PLAN mode | Sounds like starting work, not planning |
| `Plan -> Work` | Enters WORK mode | Describes flow direction, not an action |
| `Work -> Review` | Enters REVIEW mode | Same - describes transition, not action |

When you select "Plan -> Work", you expect it to mean "go from plan to work" but it's actually "start working". The labels describe the workflow graph, not what you're selecting.

## Solution

Rename labels to clearly describe the **action/mode being entered**:

| Current | New Label | Description |
|---------|-----------|-------------|
| `Start Feature` | `Plan` | Enter planning mode |
| `Plan -> Work` | `Work` | Enter work mode |
| `Work -> Review` | `Review` | Enter review mode |
| `Compound` | `Compound` | (unchanged - already clear) |

## Acceptance Criteria

- [ ] Menu labels clearly indicate the mode being entered
- [ ] Labels are action-oriented, not transition-oriented
- [ ] Descriptions provide additional context about what happens

## Implementation

### bin/agent-flow (lines 164-174)

```bash
# Change from:
cat << EOF
COMPOUND WORKFLOW [$state]
start|Start Feature|Focus PLAN pane, run /workflows:plan
work|Plan -> Work|Focus WORK pane, run /workflows:work
review|Work -> Review|Focus REVIEW pane, run /workflows:review
compound|Compound|Document learnings with /workflows:compound
---
handoff|Handoff Context|Transfer context between panes
status|Status|Show workflow state
reset|Reset|Clear workflow state
EOF

# To:
cat << EOF
COMPOUND WORKFLOW [$state]
start|Plan|Start planning a new feature
work|Work|Start implementing the plan
review|Review|Start reviewing the work
compound|Compound|Document learnings
---
handoff|Handoff|Transfer context between panes
status|Status|Show workflow state
reset|Reset|Clear workflow state
EOF
```

### Secondary fix: Display formatting (line 189)

Also change `--with-nth=2,3` to `--with-nth=2` so only labels display (not label+description concatenated):

```bash
--with-nth=2 \
```

## References

- **Issue location:** `bin/agent-flow:164-174` (menu definitions)
- **Display issue:** `bin/agent-flow:189` (`--with-nth=2,3` should be `--with-nth=2`)
