---
status: complete
priority: p3
issue_id: "013"
tags: [code-review, security, low-severity]
dependencies: []
---

# Glob Patterns in chmod Could Match Unintended Files

## Problem Statement

The install script uses glob patterns for chmod that could match unintended files if other `agent-*` or `snippet-*` files exist in the target directory.

**Why it matters:** While unlikely to cause harm, explicit file lists are more precise and predictable.

## Findings

**Location:** `install.sh:22-23`

```bash
chmod +x ~/.local/bin/agent-*
chmod +x ~/.local/bin/snippet-*
```

**Potential issue:** If user has other files like `agent-foo` or `snippet-backup`, they would also be made executable.

## Proposed Solutions

### Option A: Explicit File List (Recommended)
**Description:** Name each file explicitly.

```bash
chmod +x ~/.local/bin/agent-session
chmod +x ~/.local/bin/agent-manage
chmod +x ~/.local/bin/snippet-picker
chmod +x ~/.local/bin/snippet-edit
```

**Pros:**
- Precise, no surprises
- Documents exactly what's installed

**Cons:**
- More verbose
- Must update if new scripts added

**Effort:** Small
**Risk:** None

## Recommended Action

**Option A** - Use explicit file list for clarity and precision.

## Technical Details

**Affected file:** `install.sh`

**Lines to change:** 22-23

## Acceptance Criteria

- [ ] chmod uses explicit file names instead of globs
- [ ] All four scripts are made executable
- [ ] No other files affected

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-04 | Created finding from security review | Prefer explicit over glob when list is known |

## Resources

- Security Sentinel analysis
