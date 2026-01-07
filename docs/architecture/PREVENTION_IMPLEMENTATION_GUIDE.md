# Prevention Implementation Guide

A step-by-step guide to implementing the stale issue/todo prevention strategies.

---

## Quick Start (5 minutes)

### For Today

1. **Read the prevention document:**
   ```bash
   cat PREVENTION_STRATEGIES.md
   ```

2. **Run the triage script to see current state:**
   ```bash
   ./bin/triage-issues.sh
   ```

3. **Mark the known stale todo as complete:**
   ```bash
   ./bin/fix-stale-todos.sh 024 complete 6
   ```

4. **Commit this improvement:**
   ```bash
   git add todos/024-*.md PREVENTION_STRATEGIES.md bin/triage-issues.sh
   git commit -m "docs: add prevention strategies for stale issues/todos

   - Add comprehensive prevention strategy document
   - Create triage-issues.sh script to detect stale artifacts
   - Create fix-stale-todos.sh helper for updating todo status
   - Add GitHub Actions workflows for validation
   - Update PR template to emphasize issue references

   Closes #6"
   ```

---

## Implementation Phases

### Phase 1: Document and Tools (Already Done)

**Status:** Complete

Files created:
- `PREVENTION_STRATEGIES.md` - Comprehensive prevention guide
- `bin/triage-issues.sh` - Automated triage detection
- `bin/fix-stale-todos.sh` - Interactive todo updating
- `.github/workflows/validate-todos.yml` - CI validation
- `.github/workflows/weekly-triage.yml` - Scheduled triage
- `.github/PULL_REQUEST_TEMPLATE.md` - Enhanced PR template

### Phase 2: Initial Cleanup (Do Now)

**Goal:** Fix existing stale artifacts and establish baseline

#### Step 2.1: Audit Current State

```bash
# Run full triage analysis
./bin/triage-issues.sh

# Document findings
cat > /tmp/triage-audit.txt << 'EOF'
=== Current State ===
- Stale todos: [count from triage output]
- Unlinked todos: [count from triage output]
- Commits without issue refs: [count from triage output]
EOF
```

#### Step 2.2: Fix Known Stale Items

For todo 024 (agent-notify removal, commit c68727e):

```bash
# Mark as complete with GitHub issue reference
./bin/fix-stale-todos.sh 024 complete 6

# Verify the update
cat todos/024-*.md | head -20
```

#### Step 2.3: Link Todos to Issues

For each pending todo that has a GitHub issue, update it:

```bash
# Interactive: Guide through updating each todo
./bin/fix-stale-todos.sh

# Or directly (if you know the issue number)
# ./bin/fix-stale-todos.sh TODONUM complete ISSUENUM
```

#### Step 2.4: Commit Cleanup

```bash
git add todos/
git commit -m "docs: update todo status to match actual work state

- Mark todo 024 (remove agent-notify) as complete
- Link pending todos to their GitHub issues where applicable
- Add completed_date and pr_number metadata

Addressing stale tracking artifacts as described in PREVENTION_STRATEGIES.md"
```

### Phase 3: Process Integration (Next Week)

**Goal:** Ensure prevention patterns are followed going forward

#### Step 3.1: Update Team Guidelines

Add to `CONTRIBUTING.md` or README:

```markdown
## Issue and Todo Management

### When Starting Work
1. Create or find related GitHub issue
2. Note the issue number (e.g., #6)
3. Check if a todo file exists for this work

### When Committing
Always include closing keywords for issues resolved:

```bash
git commit -m "feat: add new feature

Closes #123"
```

### When Merging a PR
1. Verify PR description includes "Closes #N"
2. GitHub automatically closes referenced issues
3. Verify related todo files are updated to 'complete'

### When Doing Refactors
Follow the post-refactor checklist in PREVENTION_STRATEGIES.md
```

#### Step 3.2: Update Developer Practices

Create a pre-commit hook to remind developers:

```bash
# Create hook
cat > .git/hooks/prepare-commit-msg << 'EOF'
#!/bin/bash

COMMIT_MSG_FILE=$1
COMMIT_SOURCE=$2

# Only add hints for interactive commits
if [ "$COMMIT_SOURCE" = "" ]; then
  FILE_COUNT=$(git diff --cached --name-only | wc -l)

  # For multi-file changes, suggest issue reference
  if [ "$FILE_COUNT" -gt 2 ]; then
    if ! grep -q "^Closes\|^Fixes\|^Resolves" "$COMMIT_MSG_FILE"; then
      echo "" >> "$COMMIT_MSG_FILE"
      echo "# Remember: Include 'Closes #N' for resolved issues" >> "$COMMIT_MSG_FILE"
    fi
  fi
fi
EOF

chmod +x .git/hooks/prepare-commit-msg
```

#### Step 3.3: Enable GitHub Actions

The workflows are already created. They run automatically on:
- **Every PR:** Validates issue references
- **Every push to main:** Checks todo consistency
- **Weekly (Monday 9 AM UTC):** Triage summary

No additional setup needed if `.github/workflows/` files exist.

### Phase 4: Monitoring and Refinement (Ongoing)

**Goal:** Maintain the system and improve based on experience

#### Monthly Checklist

```markdown
## Monthly Prevention Review

First Monday of each month:

- [ ] Run `./bin/triage-issues.sh`
- [ ] Review any STALE or UNLINKED items found
- [ ] Fix any orphaned todos or issues
- [ ] Check GitHub Actions workflow logs for any issues
- [ ] Document lessons learned in PREVENTION_LEARNINGS.md
- [ ] Update PREVENTION_STRATEGIES.md if patterns change
```

#### Quarterly Retrospective

```markdown
## Quarterly Prevention Retrospective

Every 3 months:

- [ ] Review all closed todos and issues
- [ ] Identify any patterns in what went stale
- [ ] Assess whether current prevention is working
- [ ] Update team guidelines based on findings
- [ ] Consider any automation improvements
```

---

## Testing the Prevention System

### Test Case 1: Verify Triage Detection

```bash
# Manually create a stale scenario
cp todos/024-pending-p3-remove-agent-notify.md todos/999-pending-p0-test.md
echo "github_issue: 999" >> todos/999-pending-p0-test.md

# Run triage (should detect if issue #999 is closed)
./bin/triage-issues.sh | grep -i "stale\|999"

# Clean up
rm todos/999-pending-p0-test.md
```

### Test Case 2: Verify PR Validation

```bash
# Create test branch
git checkout -b test/issue-reference

# Make a dummy change
echo "test" >> README.md

# Create draft PR without issue reference
gh pr create \
  --title "test: without issue reference" \
  --body "Just a test change" \
  --draft

# Check workflow output - should note missing reference
# Then close the PR and delete branch

git checkout -
git branch -D test/issue-reference
```

### Test Case 3: Verify Auto-Close

```bash
# When a real PR is merged with "Closes #N"
# Verify the linked GitHub issue auto-closes

# Example:
git log --oneline -1 | grep -i "closes"
# Should show the issue number

# Check GitHub to confirm issue is closed
gh issue view NUMBER --json state
```

---

## Troubleshooting

### Issue: Triage script says "gh CLI not available"

**Solution:**
```bash
# Install GitHub CLI
brew install gh  # macOS
# or
apt-get install gh  # Linux
# or visit https://github.com/cli/cli

# Authenticate
gh auth login
```

### Issue: Triage shows todos but says "UNKNOWN" state

**Solution:**
```bash
# Ensure GitHub CLI is authenticated
gh auth status

# Verify issue number is correct
gh issue view 6  # Should show details if issue exists
```

### Issue: GitHub Actions workflows not triggering

**Solution:**
```bash
# Verify workflow files exist
ls -la .github/workflows/

# Check workflow syntax
gh workflow view validate-todos.yml

# Manually trigger for testing
gh workflow run validate-todos.yml
```

### Issue: Todo file update script won't run

**Solution:**
```bash
# Check permissions
ls -la bin/fix-stale-todos.sh

# Make executable
chmod +x bin/fix-stale-todos.sh

# Try again
./bin/fix-stale-todos.sh
```

---

## Success Criteria

Track these metrics to verify the prevention system is working:

| Metric | Target | Check Method |
|--------|--------|--------------|
| **Stale todos per month** | 0 | Run `./bin/triage-issues.sh` |
| **Commits with issue refs** | 100% of multi-file changes | `git log --grep="Closes\|Fixes"` |
| **PR closing keywords** | 100% of merged PRs | Check PR merge commit messages |
| **Triage accuracy** | 100% match between todo status and GitHub | Monthly audit |
| **Workflow failures** | 0 | Check GitHub Actions logs |

### Monthly Report Template

```markdown
## Prevention System - Monthly Report

**Period:** [Month] [Year]

### Metrics
- Stale todos found: [number]
- Unlinked todos: [number]
- Commits without issue refs: [number]

### Actions Taken
- [Fixed X stale todos]
- [Linked Y new todos to GitHub]
- [Updated Z commit messages]

### Observations
- [What went well]
- [What didn't work]
- [Suggestions for improvement]

### Next Month's Focus
- [Priority 1]
- [Priority 2]
```

---

## Examples

### Example 1: Proper Refactor Commit (After Implementation)

```bash
# Scenario: Removing feature X that had todo 024 and GitHub issue #6

# 1. Work on feature branch
git checkout -b refactor/remove-feature-x

# 2. Make changes
rm bin/feature-x
# ... other changes ...

# 3. Before committing, update todo 024
./bin/fix-stale-todos.sh 024 complete 6

# 4. Commit with issue reference
git commit -m "refactor: remove feature X (rarely used)

- Remove bin/feature-x (44 lines)
- Update config to remove feature-x section
- Simplify documentation

Closes #6"

# 5. Create PR
gh pr create \
  --title "refactor: remove feature X" \
  --body "Closes #6"

# 6. When merged, GitHub auto-closes #6
# 7. Todo 024 was already marked complete
# 8. Everything synchronized!
```

### Example 2: Adding New Feature with Proper Tracking

```bash
# Scenario: Adding new feature Y

# 1. Create GitHub issue (or find existing)
gh issue create \
  --title "Feature: Add feature Y" \
  --body "Description of feature Y"
# Note the issue number returned

# 2. Create todo file linked to issue
cat > todos/025-pending-p1-add-feature-y.md << 'EOF'
---
status: pending
priority: p1
issue_id: "025"
github_issue: 10        # Link to GitHub issue
pr_number: null
tags: [feature, enhancement]
dependencies: []
---

# Add Feature Y

## Problem Statement
[Description]

## Work Log
| Date | Action | Notes |
|------|--------|-------|
| 2026-01-06 | Created | From feature request #10 |
EOF

# 3. Start work on feature branch
git checkout -b feat/add-feature-y

# 4. Implement feature...

# 5. Commit with issue reference
git commit -m "feat: add feature Y

Implements feature Y as described in issue #10.
Allows users to [benefit].

Closes #10"

# 6. When merged:
# - GitHub issue #10 auto-closes
# - Todo 025 should be updated to complete
git commit -m "docs: mark todo 025 as complete

Feature Y implemented in PR #11"

# Now everything is in sync!
```

---

## Next Steps

1. **Immediate:** Run Phase 2 cleanup (fix stale todos)
2. **This week:** Commit changes and test triage script
3. **Next week:** Update team guidelines with new process
4. **Ongoing:** Monthly triage and quarterly retrospectives

## Questions?

Refer to:
- `PREVENTION_STRATEGIES.md` - Full strategy document
- `.github/PULL_REQUEST_TEMPLATE.md` - PR guidelines
- `./bin/triage-issues.sh` - Check current state anytime
- `./bin/fix-stale-todos.sh` - Update todos as needed
