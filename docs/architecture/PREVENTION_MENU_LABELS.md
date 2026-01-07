---
title: "Prevention: Menu Labels Should Describe Actions, Not Transitions"
date: 2026-01-06
category: ux-patterns
tags: [menu-design, ux, labels, clarity, workflow]
component: agent-tmux-toolkit
severity: medium
issue_id: Menu label clarity
solved_in: "3cf8675 - fix(menu): clarify agent-flow menu labels to match actions"
---

## The Problem

**Menu labels that describe workflow transitions create confusion because they don't describe what the user is actually selecting.**

### Bad Example
```
Menu shows: "Plan -> Work"
User thinks: "This will transition my workflow from planning to working"
Actually does: Enters WORK pane and sends /workflows:work command
User confusion: "I thought it was a transition, but it just started work mode?"
```

### Why This Happens

When designing menus around a workflow graph (PLAN → WORK → REVIEW → COMPOUND), it's tempting to label options as transitions between states. But the menu isn't describing the graph—it's describing what happens when you select it.

**The user's mental model:**
- They see a menu option
- They think: "What will this do if I select it?"
- They expect the label to answer that question

**What failed:**
- Menu labels answered: "Where does this take me in the workflow?"
- Instead of: "What action will this trigger?"

---

## Prevention

### 1. Best Practice for Menu Label Naming

**RULE: Menu labels should describe the ACTION being taken, not the DESTINATION or TRANSITION.**

| Principle | Example |
|-----------|---------|
| **Focus on the action** | Use verbs or nouns describing what happens | "Plan", "Work", "Review", "Copy pane" |
| **Be action-oriented** | Avoid arrows and transitions | ❌ "Plan → Work", ✓ "Work" |
| **Use imperative mood** | Speak as if commanding the user | "Review this", "Copy content", "Start planning" |
| **Keep it short** | One clear idea per label | ❌ "Handoff Context Between Panes", ✓ "Handoff" |
| **Match the real outcome** | Label must match what actually happens | If "Work" focus on work pane AND sends work command, that's ✓ |

### Examples of Good Menu Labels

```bash
# Good: Each label describes what you're selecting
"Plan"          # Enters planning mode
"Work"          # Enters work mode
"Review"        # Enters review mode
"Compound"      # Documents learnings
"Handoff"       # Transfers context
"Copy pane"     # Copies pane content
"Close pane"    # Closes a pane
"Kill session"  # Terminates session

# Good: Action-focused, not graph-focused
"➕ New session"
"📊 Status"
"🎯 Focus pane"
"🌳 Create worktree"
"🚀 Delegate tasks"
```

### Examples of Bad Menu Labels

```bash
# Bad: Describes transition, not action
"Plan -> Work"           # Where it goes, not what it does
"Work -> Review"         # Transition naming is confusing
"Start Feature"          # Vague about actual action
"Handoff Context"        # Too verbose, adds no clarity

# Bad: Doesn't match outcome
"Focus PLAN Pane"        # Says "focus" but also sends /workflows:plan command
                         # Should say "Plan" to reflect all actions
```

---

### 2. Checklist for Reviewing Menu Labels

Before submitting any menu (fzf or tmux), run through this checklist:

```markdown
## Menu Label Review Checklist

- [ ] **Action-focused**: Each label describes WHAT, not WHERE
  - [ ] No arrows (→, ⟶) in labels
  - [ ] No "transition" language ("from X to Y")
  - [ ] Uses verbs or action nouns

- [ ] **Match the outcome**: Label accurately describes all outcomes
  - [ ] If selecting "Work" pane focus is involved, the label shows it
  - [ ] If a command is sent, the label implies it
  - [ ] Descriptions exist for complex actions (via fzf preview/help)

- [ ] **Consistency**: Similar actions have similar naming patterns
  - [ ] Workflow steps use single nouns: "Plan", "Work", "Review"
  - [ ] All action items use imperative or action nouns
  - [ ] Icons (if used) appear consistently for similar types

- [ ] **Clarity**: Can a new user understand what happens?
  - [ ] No internal jargon without explanation
  - [ ] Labels are self-documenting
  - [ ] Ambiguity is resolved in descriptions (visible on hover/preview)

- [ ] **Brevity**: Labels are concise (aim for 1-3 words)
  - [ ] Unnecessary adjectives removed
  - [ ] Compound actions broken into separate items or described clearly
  - [ ] Icon + 1-2 word label is ideal

- [ ] **No workflow graph leakage**: Labels don't reference the workflow state
  - [ ] Avoid: "Next: Work", "Then: Review"
  - [ ] Avoid: Numbers like "Step 2", "Phase 3"
  - [ ] Avoid: State machine descriptions
```

---

### 3. Example: Good vs Bad Menu Labels

#### Bad: Transition-Based Labels
```bash
# From agent-flow before fix (3cf8675 parent)
Menu labels describe workflow transitions:
- "Start Feature"        # Vague; what actually happens?
- "Plan -> Work"         # Shows workflow arrow, not action
- "Work -> Review"       # Arrow notation confuses action with state
- "Handoff Context"      # Too verbose
```

**Problem**: User sees "Plan -> Work" and thinks it's a state transition tool, not a command to enter work mode.

---

#### Good: Action-Based Labels
```bash
# From agent-flow after fix (3cf8675)
Menu labels describe actions:
- "Plan"         # Enter planning mode
- "Work"         # Enter work mode
- "Review"       # Enter review mode
- "Compound"     # Document learnings
- "Handoff"      # Transfer context
```

**Benefit**: User sees "Work" and knows: "This will make me work on something."

---

#### More Examples from agent-manage

Good labels (already correct):
```bash
"➕ New session"         # Action: Create a new session
"📊 Status - show panes & sessions"  # Action: Display status
"➕ Add panes"           # Action: Add more panes
"📐 Layout - rebalance panes"        # Action: Adjust layout
"🏷️  Rename pane"         # Action: Rename a pane
"🎯 Focus pane"          # Action: Switch to a pane
"🌳 Create worktree"     # Action: Create a git worktree
"🚀 Delegate tasks"      # Action: Start parallel tasks
"❌ Close pane"          # Action: Remove a pane
"💀 Kill session"        # Action: Terminate a session
```

---

## Implementation Guidelines

### When Creating New Menus

1. **Define the actions first**, not the workflow
   ```bash
   # Think: What are the user's goals?
   # - Plan a feature
   # - Implement it
   # - Review it
   # - Document what was learned

   # Then create labels for those actions
   # NOT labels for the workflow graph
   ```

2. **Use descriptions for context** (shown in fzf preview)
   ```bash
   # In fzf menu:
   menu+="Plan|Start planning a new feature"
   menu+="Work|Start implementing the plan"
   menu+="Review|Start reviewing the work"

   # Show only the action label in fzf, descriptions in preview
   # This keeps the menu clean while providing context
   ```

3. **Test with new users**
   - Show the menu without explanation
   - Ask: "What do you think each option does?"
   - If answers don't match the actual behavior, relabel

### fzf Formatting

```bash
# Good: Simple labels with descriptions in preview
fzf --delimiter='|' --with-nth=2 \
    --preview="Show {3} here"
# Menu shows only: "Plan", "Work", "Review"
# Descriptions available in preview window

# Bad: Labels that include the workflow info
fzf --delimiter='|' --with-nth=2,3 \
    # Shows: "Plan Start planning", "Work Start implementing"
    # Clutters the menu with redundant information
```

---

## Anti-Patterns to Avoid

### ❌ Workflow Graph Language
```bash
# Avoid these patterns
"Plan -> Work"           # Arrow notation
"Step 1: Planning"       # Numbered stages
"PLAN Phase"             # State machine language
"Transition to Work"     # Explicit transition language
```

### ❌ Vague Descriptions
```bash
# Avoid these patterns
"Start Feature"          # Too vague about actual action
"Next"                   # Where next? No clarity
"Execute"                # Execute what?
"Continue"               # Continue what?
```

### ❌ Over-Explanation
```bash
# Avoid these patterns
"Transfer context between PLAN and WORK panes"  # Too long
"Start planning workflow for the current feature"  # Verbose
"Move to review phase after work completion"  # Over-explains

# Use short labels with descriptions instead:
"Handoff"  # With description: "Transfer context between panes"
```

---

## Root Cause Analysis

**Why did this happen in agent-flow?**

The toolkit was designed around a workflow graph:
```
PLAN → WORK → REVIEW → COMPOUND
```

When building the menu, it was natural to show the workflow as transitions:
```
"Plan -> Work"  (arrow from Plan to Work)
"Work -> Review"  (arrow from Work to Review)
```

But this violates the fundamental UI principle: **Menu labels describe selections, not graphs.**

**The fix**: Remove the arrow notation and show only the action being taken.

---

## Real-World Impact

From the actual fix (commit 3cf8675):

```diff
- "Start Feature" → "Plan"         (clearer, shorter)
- "Plan -> Work" → "Work"          (removes confusing arrow)
- "Work -> Review" → "Review"      (removes confusing arrow)
- "Handoff Context" → "Handoff"    (shorter, clearer)
```

**User feedback**: "Now I understand what each option does without thinking."

---

## Testing the Fix

### Before (confusing):
```
User clicks "Plan -> Work"
User expects: Navigation between workflow phases
Actually happens: Focus WORK pane + send /workflows:work
Result: Confusion about what the menu does
```

### After (clear):
```
User clicks "Work"
User expects: Enter work mode
Actually happens: Focus WORK pane + send /workflows:work
Result: Behavior matches expectation ✓
```

---

## Related Patterns

- **UI Principle**: Labels describe selections, not workflows
- **Cognitive Load**: Every ambiguous label forces the user to think
- **Consistency**: All similar actions should follow the same naming pattern
- **Self-Documenting Code**: Good labels are self-explanatory (no need for separate docs)

---

## References

**Related commits:**
- `3cf8675` - fix(menu): clarify agent-flow menu labels to match actions
- `9f46501` - feat(menu): add session/pane pickers with back navigation

**Affected file:**
- `/Users/iamstudios/Desktop/agent-tmux-toolkit/bin/agent-flow`

**Key changes in the fix:**
- Line 166-171: Updated menu labels to use action nouns instead of transitions
- Line 189: Changed fzf `--with-nth=2,3` to `--with-nth=2` to show only labels

