# Prevention Quick Reference

## The Problem (What We're Fixing)

GitHub issues and todo files became stale when work was completed but tracking artifacts weren't updated.

**Example:** Commit c68727e removed `agent-notify` but Issue #6 was never closed and todo 024 remained "pending".

## The Six Prevention Strategies

### 1. Commit Message Hygiene
**When:** Every commit that resolves an issue
**How:** Add closing keywords to commit messages
**Example:**
```bash
git commit -m "refactor: remove agent-notify

Closes #6"
```

**Why:** GitHub auto-closes issues on merge, creating an audit trail

---

### 2. Regular Triage
**When:** Monthly (or weekly if using automation)
**How:** Run the triage script
**Example:**
```bash
./bin/triage-issues.sh
```

**Why:** Detects drift between todo status and actual code state

---

### 3. Automation (GitHub Actions)
**When:** Automatic on every push/PR
**How:** Two workflows validate and report automatically
**Runs:**
- On every PR: validates issue references
- Weekly Monday: generates triage summary

**Why:** Catches problems without manual effort

---

### 4. Post-Refactor Checklist
**When:** Before merging multi-file changes
**How:** Use the mandatory checklist from PREVENTION_STRATEGIES.md
**Steps:**
1. Identify all removed/changed features
2. Find related GitHub issues
3. Include "Closes #N" in commit message
4. Verify todo status matches

**Why:** Ensures nothing is forgotten in large refactors

---

### 5. Enhanced Todo Structure
**When:** When creating new todos
**How:** Add metadata fields to todo frontmatter
**Fields:**
```yaml
---
github_issue: 6
pr_number: 12
completed_date: 2026-01-05
---
```

**Why:** Links todos directly to GitHub, enables automation

---

### 6. Process Documentation
**When:** Ongoing team communication
**How:** Update guidelines, share best practices
**Where:** CONTRIBUTING.md, CLAUDE.md, README
**Content:** Issue/todo workflow guidelines

**Why:** Teaches team the prevention patterns

---

## Quick Commands

### Check for Stale Items
```bash
./bin/triage-issues.sh
```

### Mark Work as Complete
```bash
./bin/fix-stale-todos.sh 024 complete 6
```

### Start a Feature (with tracking)
```bash
# 1. Create GitHub issue (if needed)
gh issue create --title "Feature X" --body "Description"

# 2. Note issue number (e.g., #10)
# 3. Create/find related todo file
# 4. Add: github_issue: 10 to frontmatter
# 5. Do work...
# 6. Commit with "Closes #10"
git commit -m "feat: implement feature X

Closes #10"
```

### Close Related Work
```bash
git commit -m "fix: resolve issue

This fixes the bug where X happened.

Closes #6"
```

---

## Decision Tree: Am I Doing This Right?

### Starting New Work

```
Starting new feature or bug fix?
├─ Has GitHub issue?
│  ├─ No → Create one: gh issue create --title "..."
│  └─ Yes → Note the issue number
├─ Create/find related todo file
├─ Add: github_issue: N to frontmatter
└─ Start work on feature branch
```

### Committing Work

```
Committing changes?
├─ Does this resolve an issue?
│  ├─ No → Commit normally: git commit -m "..."
│  └─ Yes → Include closing keyword:
│           git commit -m "...
│                        Closes #N"
├─ Is this multi-file change?
│  ├─ No → Continue
│  └─ Yes → Check post-refactor checklist
└─ Commit complete ✓
```

### Merging a PR

```
PR ready to merge?
├─ Check: Does PR description include "Closes #N"?
│  ├─ No → Request changes
│  └─ Yes → Continue
├─ Check: Are related todos marked complete?
│  ├─ No → Update todos before merge
│  └─ Yes → Continue
├─ Check: GitHub Actions pass?
│  ├─ No → Fix issues
│  └─ Yes → Merge ✓
└─ GitHub auto-closes issue #N
```

### Finding Stale Items

```
Is something feeling out of sync?
├─ Run: ./bin/triage-issues.sh
├─ Review output:
│  ├─ STALE items → Update to complete
│  ├─ UNLINKED items → Add github_issue link
│  └─ NO REFERENCE commits → Note for future
└─ Commit cleanup: git commit -m "docs: update todos"
```

---

## Prevention Metrics

Track these to know if prevention is working:

| Metric | Target | How to Check |
|--------|--------|--------------|
| **Stale todos/month** | 0 | `./bin/triage-issues.sh` |
| **Issue close rate** | 100% merged = closed | Check GitHub issue timeline |
| **Commit refs** | All multi-file have "Closes #N" | `git log` review |
| **Todo accuracy** | 100% match code state | Monthly triage |

---

## Common Scenarios

### Scenario 1: Completed Work with Stale Issue
**Problem:** Todo 024 says "pending" but work was done in commit c68727e

**Solution:**
1. Run: `./bin/fix-stale-todos.sh 024 complete 6`
2. Commit: `git commit -m "docs: mark todo 024 complete"`

### Scenario 2: Multi-file Refactor
**Problem:** Removing 3 features, need to close related issues

**Solution:**
1. Identify removed features: X, Y, Z
2. Find GitHub issues: #6, #10, #15
3. Use post-refactor checklist from PREVENTION_STRATEGIES.md
4. Include in PR: "Closes #6, #10, #15"

### Scenario 3: New Feature with No Issue
**Problem:** Added feature but didn't link to tracking

**Solution:**
1. Create issue: `gh issue create --title "Feature added"`
2. Note issue number
3. Update todo file: add `github_issue: N`
4. Update commit message if possible

### Scenario 4: Someone Else Closed Issue Without Updating Todo
**Problem:** Issue closed but todo still pending

**Solution:**
1. Monthly triage catches this: `./bin/triage-issues.sh`
2. Interactive fix: `./bin/fix-stale-todos.sh`
3. Update and commit

---

## Prevention Culture

### What Good Looks Like
- Closing keywords in every merge commit
- Todos linked to GitHub issues
- Monthly triage shows 0 stale items
- New developers understand the pattern

### What Bad Looks Like
- Issues and todos drift apart
- Can't find related work
- Stale tracking artifacts
- New developers confused by process

---

## Key Files Reference

| File | Purpose | When to Use |
|------|---------|------------|
| **PREVENTION_STRATEGIES.md** | Full strategy guide | Read first, reference for details |
| **PREVENTION_IMPLEMENTATION_GUIDE.md** | Step-by-step setup | Implementation and testing |
| **PREVENTION_QUICK_REFERENCE.md** | This file | Daily workflow reference |
| **bin/triage-issues.sh** | Detect stale items | Monthly check or when something feels off |
| **bin/fix-stale-todos.sh** | Update todo status | Marking work as complete |
| **validate-todos.yml** | CI validation | Auto-runs on every PR |
| **weekly-triage.yml** | Scheduled reports | Auto-runs every Monday |

---

## Need Help?

### Troubleshooting

**"triage-issues.sh says 'gh CLI not available'"**
- Install: `brew install gh` (macOS) or `apt-get install gh` (Linux)
- Authenticate: `gh auth login`

**"I don't know if an issue is stale"**
- Run: `./bin/triage-issues.sh` (it will detect)
- Or check manually: `gh issue view 6 --json state`

**"I forgot to include 'Closes #N' in my commit"**
- For recent commit: Use `git commit --amend` (if not pushed yet)
- For old commits: Note for next time, create separate doc commit
- Future: Use `.git/hooks/prepare-commit-msg` for hints

**"GitHub Actions aren't running"**
- Verify files exist: `ls .github/workflows/`
- Check syntax: `gh workflow list`
- Manually trigger: `gh workflow run validate-todos.yml`

### Getting Started

1. **Day 1:** Read PREVENTION_STRATEGIES.md overview
2. **Day 2:** Run `./bin/triage-issues.sh` to see current state
3. **Day 3:** Follow PREVENTION_IMPLEMENTATION_GUIDE.md
4. **Week 1:** Set up monthly triage reminder
5. **Ongoing:** Use quick commands above in daily workflow

---

## Prevention Principles

1. **Automate what you can** - GitHub Actions do the work
2. **Make it easy** - Scripts like `fix-stale-todos.sh` are simple
3. **Check regularly** - Monthly triage prevents drift
4. **Document changes** - Good commit messages create history
5. **Link everything** - todos ↔ GitHub issues ↔ commits

---

**Last Updated:** 2026-01-06
**Current Status:** Ready for use
**Success Metric:** 0 stale items per month
