# Prevention Strategies: Stale Issues and Todos

## Problem Summary

Work gets completed but tracking artifacts become stale:
- **Case Study:** Commit c68727e removed `agent-notify` but Issue #6 was never closed
- **Impact:** Todo file `024-pending-p3-remove-agent-notify.md` remained marked "pending" despite completed work
- **Root Cause:** No automated or manual process ensures issue/todo state matches actual code changes

---

## Prevention Strategy 1: Commit Message Hygiene

### Implementation

**Rule:** Every commit that resolves work MUST include a closing keyword.

#### A. Use GitHub's Closing Keywords

When a commit resolves an issue, add closing keywords to commit messages:

```bash
# Format: Include in commit message body
git commit -m "feat: add new feature

Closes #123"

# Multiple issues:
git commit -m "refactor: extract shared library

Closes #6
Fixes #19
Resolves #24"
```

**GitHub Closing Keywords (auto-close issues):**
- `Closes #N` / `Close #N` / `Closed #N`
- `Fixes #N` / `Fixed #N`
- `Resolves #N` / `Resolved #N`
- `Closes github.com/owner/repo/issues/N` (cross-repo)

**Example from the problem case (should have been):**
```bash
git commit -m "refactor: extract shared library and simplify codebase

- Create bin/agent-common.sh with shared utilities
- Remove agent-notify (rarely used, adds complexity)
- Update all scripts to use shared library

Closes #6"
```

#### B. Add Issue Reference to Todo Files

Update todo files with issue/PR numbers before starting work:

```yaml
# todos/024-pending-p3-remove-agent-notify.md
---
status: pending
priority: p3
issue_id: "024"
github_issue: 6          # ADD THIS LINE
pr_number: null
tags: [code-review, simplification, cleanup]
---
```

#### C. Commit Message Template

Create a local git hook to enforce the pattern:

```bash
# .git/hooks/prepare-commit-msg (make executable: chmod +x)
#!/bin/bash

COMMIT_MSG_FILE=$1
COMMIT_SOURCE=$2

if [ "$COMMIT_SOURCE" = "" ]; then
  # Add template only for interactive commits
  if ! grep -q "^Closes\|^Fixes\|^Resolves" "$COMMIT_MSG_FILE"; then
    # Only suggest template for commits touching multiple files
    FILE_COUNT=$(git diff --cached --name-only | wc -l)
    if [ "$FILE_COUNT" -gt 3 ]; then
      echo "" >> "$COMMIT_MSG_FILE"
      echo "# Reference related issues:" >> "$COMMIT_MSG_FILE"
      echo "# Closes #" >> "$COMMIT_MSG_FILE"
    fi
  fi
fi
```

---

## Prevention Strategy 2: Regular Issue/Todo Triage

### Monthly Triage Process

Run this before each release or monthly:

```bash
# Check for stale todos
for todo in todos/*.md; do
  status=$(grep "^status:" "$todo" | cut -d: -f2 | xargs)
  if [ "$status" = "pending" ]; then
    issue_id=$(grep "^issue_id:" "$todo" | cut -d'"' -f2)
    gh issue view "$issue_id" --json state,updatedAt
  fi
done
```

### A. Automated Triage Command

```bash
#!/bin/bash
# bin/triage-issues.sh - Find stale tracking artifacts

echo "=== Checking for completed todos that are still marked pending ==="

for todo in todos/???-pending-*.md; do
  if [ -f "$todo" ]; then
    issue_id=$(grep "^issue_id:" "$todo" | cut -d'"' -f2)
    github_issue=$(grep "^github_issue:" "$todo" | cut -d: -f2 | xargs)

    if [ -n "$github_issue" ]; then
      state=$(gh issue view "$github_issue" --json state -q '.state')

      if [ "$state" = "CLOSED" ]; then
        echo "STALE: $todo (Issue #$github_issue is closed but todo is pending)"
      fi
    fi
  fi
done

echo ""
echo "=== Checking for recent commits without issue references ==="
git log --oneline --all -20 | while read commit msg; do
  if ! echo "$msg" | grep -qE "(closes|fixes|resolves|#[0-9]+)"; then
    echo "MISSING REF: $commit $msg"
  fi
done
```

### B. Triage Checklist (Monthly)

```markdown
## Monthly Triage Checklist

- [ ] Run `bin/triage-issues.sh` to find stale artifacts
- [ ] Review pending todos against actual code state
- [ ] Update todo status files to match code
- [ ] Close issues with completed work
- [ ] Check recent commits for missing issue references
- [ ] Document any pattern changes in LEARNINGS.md
```

### C. Add to GitHub Project Board

Use GitHub Projects to track state more visually:

```yaml
# Link todos to GitHub Issues
# For each todo file, create/link a corresponding GitHub issue:
- Todo file: todos/024-pending-p3-remove-agent-notify.md
- GitHub Issue: #6 (Remove agent-notify)
- Status: Should match between todo file and GitHub issue
```

---

## Prevention Strategy 3: Automation (GitHub Actions)

### A. Auto-Close Issues When Code is Removed

Create a workflow that detects deletions and closes related issues:

```yaml
# .github/workflows/auto-close-issues.yml
name: Auto-close Issues on Code Removal

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  check-deletions:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Detect deletions and find related issues
        run: |
          # Get list of deleted files
          DELETED=$(git diff ${{ github.event.pull_request.base.sha }} HEAD --name-only --diff-filter=D)

          if [ -n "$DELETED" ]; then
            echo "Deleted files: $DELETED"

            # Search for related issue references in PR description
            if grep -E "(Closes|Fixes|Resolves) #[0-9]+" <<< "${{ github.event.pull_request.body }}"; then
              echo "PR references issues - good!"
            else
              echo "WARNING: PR deletes files but doesn't reference closing any issues"
              exit 1
            fi
          fi

      - name: Validate PR references issues
        if: failure()
        run: |
          echo "NOTICE: When deleting code, include 'Closes #N' in your PR description"
          exit 0  # Don't fail, just warn
```

### B. Check Todo Status Against Code

```yaml
# .github/workflows/validate-todos.yml
name: Validate Todo Consistency

on:
  push:
    branches: [main]
    paths:
      - 'todos/**'
      - 'bin/**'
      - '.github/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Check for stale completed todos
        run: |
          for todo in todos/???-complete-*.md; do
            if [ -f "$todo" ]; then
              # Verify the todo file still exists (should always be true)
              echo "Verified completed: $(basename $todo)"
            fi
          done

      - name: Report pending todos without code
        run: |
          for todo in todos/???-pending-*.md; do
            if [ -f "$todo" ]; then
              issue_id=$(grep "^issue_id:" "$todo" | cut -d'"' -f2)
              echo "Still pending (ID: $issue_id): $(basename $todo)"
            fi
          done
```

### C. Weekly Triage Reminder

```yaml
# .github/workflows/weekly-triage.yml
name: Weekly Issue Triage Reminder

on:
  schedule:
    - cron: '0 9 * * 1'  # Every Monday at 9 AM UTC

jobs:
  triage-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Check for stale issues
        run: |
          # Find closed issues with pending todos
          ISSUES=$(gh issue list --state closed --limit 50 --json number)
          echo "Closed issues in last week: Check if todos are updated"
          echo "$ISSUES" | head -10

      - name: Post comment reminder
        if: github.event_name == 'schedule'
        run: |
          echo "Weekly triage complete. Check PREVENTION_STRATEGIES.md for guidelines."
```

---

## Prevention Strategy 4: Post-Refactor Checklist

### Mandatory Refactor Checklist

When doing refactors like commit c68727e (multi-file changes, removals):

```markdown
## Post-Refactor Verification Checklist

### Before Opening PR:

- [ ] Identify all features removed or changed
- [ ] Find related GitHub issues for each removed feature
  - [ ] Issue #6 for agent-notify removal
  - [ ] Issue #___ for feature B removal

- [ ] Update issue references
  - [ ] Add issue numbers to commit message as "Closes #N"
  - [ ] Update related PR description with all closing keywords

- [ ] Verify todo consistency
  - [ ] Find todos for removed features (todos/024-* for agent-notify)
  - [ ] Mark as complete or link to PR
  - [ ] Verify status in todo file matches GitHub issue

- [ ] Test the changes
  - [ ] Run `./install.sh`
  - [ ] Verify removed feature no longer accessible
  - [ ] Check no broken references remain

- [ ] Documentation updates
  - [ ] README updated (e.g., remove notification section)
  - [ ] Help text updated if applicable
  - [ ] CHANGELOG entry created

### During Code Review:

Reviewer should check:
- [ ] Commit message includes issue closing keywords
- [ ] All related todos are updated
- [ ] No orphaned todo files remain
- [ ] Related GitHub issues will auto-close on merge

### After Merge:

- [ ] Verify related issues auto-closed
- [ ] Update closed todo files: `status: complete`
- [ ] Add work log entry to closed todo files
```

### Example: agent-notify Case (How It Should Have Been)

```markdown
## Refactor: Extract shared library and remove agent-notify

Checklist completion:

- [ ] Identify removed features
  - agent-notify script (44 lines, disabled by default)
  - Related tmux.conf entries (7 lines)

- [x] GitHub issues
  - Issue #6: "Remove agent-notify (unused, disabled by default)"

- [x] Commit message
  ```
  refactor: extract shared library and simplify codebase

  - Create bin/agent-common.sh with shared utilities
  - Remove agent-notify (rarely used, adds complexity)
  - Update all scripts to use shared library

  Closes #6
  ```

- [x] Todo consistency
  - Found: todos/024-pending-p3-remove-agent-notify.md
  - Update: Add github_issue: 6 to frontmatter
  - Update: After merge, change status to complete

- [x] Documentation
  - README.md: Removed notification section
  - Added: Alternative using terminal-notifier directly
```

---

## Prevention Strategy 5: Enhanced Todo File Structure

### Improved Todo Format

```yaml
# todos/024-complete-p3-remove-agent-notify.md
---
status: complete           # pending | in_progress | complete | blocked
priority: p3
issue_id: "024"
github_issue: 6           # NEW: Link to GitHub issue
related_pr: 12            # NEW: Link to PR that resolved this
tags: [code-review, simplification, cleanup]
dependencies: []
completed_date: 2026-01-05  # NEW: When actually completed
---

# Remove agent-notify (Rarely Used)

## Problem Statement
...

## Work Log

| Date | Status | Notes |
|------|--------|-------|
| 2026-01-05 | Created | From simplicity review |
| 2026-01-05 | In Progress | Started refactoring |
| 2026-01-05 | Complete | Merged in commit c68727e |
| | | Closes GitHub Issue #6 |
| | | PR #12 merged with closing keyword |

## Verification Checklist

- [x] Code removed
- [x] Tests pass
- [x] Documentation updated
- [x] GitHub issue closed
- [x] PR merged with closing keyword
```

### Todo File Validation Script

```bash
#!/bin/bash
# scripts/validate-todos.sh

validate_todo_file() {
  local file=$1
  local errors=0

  # Check frontmatter consistency
  status=$(grep "^status:" "$file" | cut -d: -f2 | xargs)
  github_issue=$(grep "^github_issue:" "$file" | cut -d: -f2 | xargs)

  if [ "$status" = "complete" ] || [ "$status" = "in_progress" ]; then
    if [ -z "$github_issue" ]; then
      echo "WARNING: $file has status=$status but no github_issue link"
      ((errors++))
    fi
  fi

  # If complete, should have completed_date
  if [ "$status" = "complete" ]; then
    if ! grep -q "^completed_date:" "$file"; then
      echo "WARNING: $file is complete but missing completed_date"
      ((errors++))
    fi
  fi

  return $errors
}

echo "Validating todo files..."
for todo in todos/*.md; do
  validate_todo_file "$todo"
done
```

---

## Prevention Strategy 6: Process Documentation

### Add to README

```markdown
## Contributing

### Issue/Todo Workflow

When work is completed:

1. **Include closing keywords** in commit messages:
   ```
   git commit -m "fix: resolve issue

   Closes #123"
   ```

2. **Update todo status** when work is done:
   - Move todo file from `pending` to `complete`
   - Add `completed_date` and work log entry
   - Link to PR that resolved it

3. **Verify during code review:**
   - PR description includes "Closes #N"
   - Related todo files are updated
   - No stale artifacts remain

### Triage Schedule

- **Monthly:** Run `bin/triage-issues.sh` to find stale items
- **Before release:** Full audit of pending vs. completed status
- **On PR review:** Check issue/todo consistency
```

### Add to CLAUDE.md (Project Instructions)

```markdown
## Issue and Todo Hygiene

### Mandatory Pattern
Every meaningful commit resolves at least one tracking item:
- Include "Closes #N" in commit message for GitHub issues
- Update related todo files with completion status
- Link GitHub issues to todo files in frontmatter

### Why This Matters
- Prevents orphaned tracking artifacts
- Makes issue history accurate for future reference
- Supports automated workflows and reports
- Reduces time finding related work

### Example: Good Commit
```
refactor: extract shared library (Closes #6, resolves todos/024)

- Create agent-common.sh with shared utilities
- Remove agent-notify (rarely used)
- Update all scripts to use shared library

Closes #6
```

### What Not To Do
```
# BAD: Deletes code but doesn't reference issue
git commit -m "refactor: clean up code"

# GOOD: References related work
git commit -m "refactor: clean up code

Closes #6"
```

### Triage Workflow
When reviewing stale artifacts:
1. Check if related code actually exists
2. Check if GitHub issue is open or closed
3. Align todo/issue status with actual state
4. Add "stale artifact cleanup" PR if needed
```

---

## Implementation Roadmap

### Phase 1: Immediate (This Week)
- [ ] Set up `.git/hooks/prepare-commit-msg` template
- [ ] Add `PREVENTION_STRATEGIES.md` to repo
- [ ] Create `bin/triage-issues.sh` script
- [ ] Update PR template with issue reference example

### Phase 2: Short-term (This Month)
- [ ] Run first triage audit:
  - [ ] Check all pending todos against GitHub issues
  - [ ] Close any stale issues
  - [ ] Update todo file statuses to match reality
  - [ ] Mark todos/024 as complete

- [ ] Create GitHub Action workflows:
  - [ ] Auto-close validation (from PR description)
  - [ ] Weekly triage reminder
  - [ ] Validate todo consistency

### Phase 3: Long-term (Ongoing)
- [ ] Add todo frontmatter with GitHub issue links
- [ ] Monthly automated triage runs
- [ ] Update CLAUDE.md with issue hygiene rules
- [ ] Document in contributing guide

---

## Validation and Testing

### Manual Validation

Test the triage script locally:

```bash
# Run triage on current repo
./bin/triage-issues.sh

# Expected output:
# - Lists any pending todos with closed GitHub issues
# - Lists any recent commits without issue references
# - Should show 024 as stale (pending but #6 is closed)
```

### Automated Testing

For GitHub Actions:

```bash
# Simulate PR with issue reference
gh pr create --title "refactor" \
  --body "Closes #6" \
  --draft

# Should pass validation workflow

# Simulate PR without issue reference
gh pr create --title "refactor" \
  --body "Made some changes" \
  --draft

# Should warn about missing issue reference
```

---

## Success Metrics

Track improvement over time:

| Metric | Target | How to Measure |
|--------|--------|----------------|
| **Orphaned Todos** | 0 per month | Run triage, count stale todos |
| **Issue Closing Rate** | 100% of merged PRs reference issues | `git log --grep="Closes\|Fixes" \| wc -l` |
| **Todo Accuracy** | 100% match with GitHub | Monthly triage audit |
| **Review Time** | Reduced | Track PR review cycle time |

---

## Lessons Learned

From this incident (agent-notify case):

1. **Commit messages matter.** "Closes #N" keywords auto-close issues and create audit trail.

2. **Multi-file refactors need explicit tracking.** When removing multiple features, reference each related issue.

3. **Triage is not a one-time activity.** Need regular scheduled reviews to catch drift.

4. **Automation helps but doesn't replace process.** GitHub Actions can warn, but humans must decide.

5. **Todo files are useful but need linking.** Standalone todo files become stale unless linked to GitHub issues.

---

## References

- [GitHub: Linking a pull request to an issue](https://docs.github.com/en/issues/tracking-your-work-with-issues/linking-a-pull-request-to-an-issue)
- [GitHub: Closing issues using keywords](https://docs.github.com/en/issues/tracking-your-work-with-issues/linking-a-pull-request-to-an-issue#linking-a-pull-request-to-an-issue-using-a-keyword)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Git Hooks Documentation](https://git-scm.com/docs/githooks)
