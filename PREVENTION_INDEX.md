# Prevention System - Complete Index

## Overview

This directory contains a comprehensive prevention system for stale GitHub issues and todo files.

**Problem:** Work completed but tracking artifacts remained stale (e.g., commit c68727e removed agent-notify but Issue #6 was never closed)

**Solution:** Six prevention strategies with documentation and automation

---

## Documentation (Read in This Order)

### 1. Start Here: Executive Summary
**File:** `PREVENTION_EXECUTIVE_SUMMARY.md`
**Time:** 10 minutes
**Content:**
- Problem diagnosis
- Six prevention strategies overview
- Implementation status and costs
- Success metrics

### 2. Daily Reference
**File:** `PREVENTION_QUICK_REFERENCE.md`
**Time:** 5-10 minutes
**Content:**
- Quick command reference
- Decision trees for common scenarios
- Troubleshooting
- Prevention principles

### 3. Comprehensive Strategy Guide
**File:** `PREVENTION_STRATEGIES.md`
**Time:** 20 minutes
**Content:**
- Detailed implementation for each strategy
- Code examples and use cases
- Automation setup
- Success metrics

### 4. Implementation Guide
**File:** `PREVENTION_IMPLEMENTATION_GUIDE.md`
**Time:** 30 minutes
**Content:**
- Phase-by-phase setup instructions
- Testing procedures
- Troubleshooting guide
- Success criteria

---

## Scripts & Tools

### Triage Detection
**File:** `bin/triage-issues.sh`
**Purpose:** Detect stale artifacts and report issues
**Usage:**
```bash
./bin/triage-issues.sh
```
**Output:** Identifies:
- Pending todos with closed issues (STALE)
- Recent commits without issue references
- Todos not linked to GitHub issues

### Todo Management
**File:** `bin/fix-stale-todos.sh`
**Purpose:** Update todo file status and metadata
**Usage:**
```bash
# Interactive mode
./bin/fix-stale-todos.sh

# Direct mode
./bin/fix-stale-todos.sh 024 complete 6
```
**Features:**
- Updates frontmatter metadata
- Adds completed_date
- Links to GitHub issues
- Interactive prompts

---

## GitHub Actions Workflows

### PR & Push Validation
**File:** `.github/workflows/validate-todos.yml`
**Trigger:** Every PR and push to main
**Actions:**
- Validates todo file structure
- Checks for required fields
- Warns about missing GitHub issue links
- Enforces consistency

### Weekly Triage
**File:** `.github/workflows/weekly-triage.yml`
**Trigger:** Every Monday 9 AM UTC (or manual)
**Actions:**
- Generates triage summary
- Reports stale items
- Identifies pending todos without issues
- No failures - informational only

---

## Updated Templates

### Pull Request Template
**File:** `.github/PULL_REQUEST_TEMPLATE.md`
**Changes:**
- Emphasizes "Closes #N" format
- Added todo update checklist
- Explicit GitHub issue reference prompt
- PR review instructions

---

## The Six Prevention Strategies

### 1. Commit Message Hygiene
Use closing keywords in every commit that resolves an issue:
```bash
git commit -m "refactor: remove agent-notify

Closes #6"
```
**Keywords:** Closes, Fixes, Resolves
**Benefit:** GitHub auto-closes issues on merge

### 2. Regular Triage
Run `./bin/triage-issues.sh` monthly to detect drift
**Benefit:** Catches problems before they accumulate

### 3. Automation (GitHub Actions)
Two workflows automatically validate and report
**Benefit:** Continuous monitoring with zero effort

### 4. Post-Refactor Checklist
Mandatory checklist for multi-file changes
**Benefit:** Nothing forgotten in large refactors

### 5. Enhanced Todo Structure
Link todos directly to GitHub issues via metadata
**Benefit:** Machine-readable, enables automation

### 6. Process Documentation
Team guidelines and best practices documented
**Benefit:** Knowledge preserved and shared

---

## Quick Start (5 Minutes)

1. **Read:** PREVENTION_QUICK_REFERENCE.md
2. **Run:** `./bin/triage-issues.sh`
3. **Review:** Output to see current state
4. **Fix:** `./bin/fix-stale-todos.sh 024 complete 6`
5. **Commit:** Changes with prevention workflow

---

## Implementation Timeline

### Week 1: Understand & Establish Baseline
- Read PREVENTION_QUICK_REFERENCE.md
- Run triage script
- Mark known stale todo (024) as complete

### Week 2-4: Link Todos & Process Update
- Link pending todos to GitHub issues
- Update team guidelines
- Enable GitHub Actions (already done)

### Ongoing: Monthly Triage
- Run `./bin/triage-issues.sh` monthly
- Address any stale items found
- Quarterly retrospectives

---

## Success Metrics

Track these to verify prevention is working:

| Metric | Target | Check |
|--------|--------|-------|
| Stale todos/month | 0 | `./bin/triage-issues.sh` |
| Unlinked todos | 0 | triage output |
| Commits with refs | 100% | git log review |
| Issue close rate | 100% | GitHub issue timeline |

**Monthly Report:** `./bin/triage-issues.sh` should show all clear

---

## File Structure

```
agent-tmux-toolkit/
├── PREVENTION_EXECUTIVE_SUMMARY.md    # High-level overview (start here)
├── PREVENTION_QUICK_REFERENCE.md      # Daily reference guide
├── PREVENTION_STRATEGIES.md            # Comprehensive strategy details
├── PREVENTION_IMPLEMENTATION_GUIDE.md  # Step-by-step setup
├── PREVENTION_INDEX.md                 # This file
│
├── bin/
│   ├── triage-issues.sh               # Detect stale artifacts
│   └── fix-stale-todos.sh             # Update todo status
│
├── .github/
│   ├── workflows/
│   │   ├── validate-todos.yml         # PR/push validation
│   │   └── weekly-triage.yml          # Weekly triage report
│   └── PULL_REQUEST_TEMPLATE.md       # Enhanced with issue refs
│
└── todos/
    └── [todo files linked to GitHub issues]
```

---

## Common Use Cases

### I completed some work
1. Add "Closes #N" to commit message
2. Update todo status to "complete" if applicable
3. Done - GitHub issue auto-closes on merge

### I found something that seems stale
1. Run: `./bin/triage-issues.sh`
2. Review output
3. Fix stale items: `./bin/fix-stale-todos.sh`

### I'm starting a new feature
1. Create GitHub issue (if needed)
2. Note issue number
3. Link to todo file: `github_issue: N`
4. Commit with: "Closes #N"

### Monthly maintenance
1. Run: `./bin/triage-issues.sh`
2. Review results
3. Address any issues found
4. Document in PREVENTION_LEARNINGS.md (optional)

---

## Troubleshooting

### "triage-issues.sh needs gh CLI"
```bash
brew install gh          # macOS
# or apt-get install gh  # Linux
gh auth login
```

### "I forgot Closes #N in commit"
- Can amend if not pushed: `git commit --amend`
- Otherwise note for next time
- Future commits will follow the pattern

### "GitHub Actions aren't running"
- Files exist: `ls .github/workflows/`
- Check syntax: `gh workflow list`
- Manually trigger: `gh workflow run validate-todos.yml`

### "I don't know if something is stale"
- Always run: `./bin/triage-issues.sh`
- Or: `gh issue view N --json state`

---

## Prevention Principles

1. **Automate what you can**
   - GitHub Actions handle validation
   - Scripts detect problems

2. **Make it easy**
   - One line per commit ("Closes #N")
   - Scripts are simple and helpful

3. **Check regularly**
   - Monthly triage (5 min)
   - Prevents drift

4. **Document changes**
   - Good commit messages create history
   - Helps future developers

5. **Link everything**
   - Todos ↔ GitHub issues ↔ commits
   - Machine-readable metadata

---

## Team Communication

### For Project Managers
- Expect: 100% of merged PRs close related issues
- Monitor: Monthly triage reports
- Result: Always-accurate project status

### For Developers
- New pattern: Add "Closes #N" to commits
- New tools: Scripts to help manage todos
- Time: No additional burden
- Benefit: Never wonder what's actually done

### For New Team Members
- Read: PREVENTION_QUICK_REFERENCE.md
- Understand: The six strategies
- Follow: The commit message pattern
- Questions: See troubleshooting section

---

## References

### GitHub Documentation
- [Linking PRs to issues](https://docs.github.com/en/issues/tracking-your-work-with-issues/linking-a-pull-request-to-an-issue)
- [Closing issues with keywords](https://docs.github.com/en/issues/tracking-your-work-with-issues/linking-a-pull-request-to-an-issue#linking-a-pull-request-to-an-issue-using-a-keyword)

### This Project
- Repository: https://github.com/barnierg76/agent-tmux-toolkit
- Issue #6: Remove agent-notify (case study example)
- Todo 024: remove-agent-notify.md (tracking artifact)

---

## Status

- **Created:** 2026-01-06
- **Status:** Ready for implementation
- **Testing:** All scripts validated and working
- **Workflows:** Configured and ready to run
- **Documentation:** Complete with examples

## Next Steps

1. **Today:** Read PREVENTION_EXECUTIVE_SUMMARY.md
2. **Tomorrow:** Run `./bin/triage-issues.sh`
3. **This week:** Follow PREVENTION_IMPLEMENTATION_GUIDE.md Phase 1
4. **This month:** Complete Phase 2 (link todos)
5. **Ongoing:** Monthly triage + quarterly review

---

**Questions?** See PREVENTION_QUICK_REFERENCE.md for troubleshooting

**Want details?** See PREVENTION_STRATEGIES.md for comprehensive guide

**Ready to start?** See PREVENTION_IMPLEMENTATION_GUIDE.md for step-by-step

