#!/bin/bash

# triage-issues.sh - Find stale GitHub issues and todo tracking artifacts
# Usage: ./bin/triage-issues.sh
#
# This script identifies:
# - Pending todos with closed GitHub issues
# - Recent commits without issue references
# - Inconsistencies between todo files and actual code state

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

STALE_COUNT=0
MISSING_REF_COUNT=0

echo -e "${BLUE}=== GitHub Issue Triage Report ===${NC}\n"
echo "Generated: $(date)"
echo "Repository: $(git remote get-url origin 2>/dev/null || echo 'local')"
echo ""

# ============================================================================
# Section 1: Check for pending todos with closed GitHub issues
# ============================================================================

echo -e "${BLUE}=== Section 1: Stale Todo Files ===${NC}"
echo "Checking pending todos against GitHub issue status..."
echo ""

has_stale=false

for todo in todos/???-pending-*.md; do
  if [ -f "$todo" ]; then
    issue_id=$(grep "^issue_id:" "$todo" 2>/dev/null | cut -d'"' -f2 || echo "")
    github_issue=$(grep "^github_issue:" "$todo" 2>/dev/null | cut -d: -f2 | xargs || echo "")

    if [ -n "$github_issue" ]; then
      # Try to get issue state using gh CLI
      if command -v gh &> /dev/null; then
        state=$(gh issue view "$github_issue" --json state -q '.state' 2>/dev/null || echo "UNKNOWN")

        if [ "$state" = "CLOSED" ]; then
          has_stale=true
          ((STALE_COUNT++))
          todo_name=$(basename "$todo")
          echo -e "${RED}STALE:${NC} $todo_name"
          echo "  GitHub Issue: #$github_issue (CLOSED)"
          echo "  Todo Status: pending"
          echo "  Action: Mark as complete or update issue status"
          echo ""
        fi
      else
        # gh CLI not available, just list todos without GitHub status
        todo_name=$(basename "$todo")
        echo -e "${YELLOW}TODO:${NC} $todo_name (id: $issue_id, issue: $github_issue)"
      fi
    else
      # No GitHub issue linked
      todo_name=$(basename "$todo")
      echo -e "${YELLOW}UNLINKED:${NC} $todo_name"
      echo "  This pending todo has no github_issue link in frontmatter"
      echo "  Consider adding: github_issue: N"
      echo ""
    fi
  fi
done

if ! $has_stale; then
  echo -e "${GREEN}OK${NC}: No stale todos found"
fi
echo ""

# ============================================================================
# Section 2: Check recent commits for issue references
# ============================================================================

echo -e "${BLUE}=== Section 2: Recent Commits Without Issue References ===${NC}"
echo "Checking last 20 commits for issue closing keywords..."
echo ""

has_missing=false

git log --oneline -20 | while read -r commit_sha commit_msg; do
  if ! echo "$commit_msg" | grep -qiE "(closes|fixes|resolves|#[0-9]+)"; then
    has_missing=true
    ((MISSING_REF_COUNT++))
    echo -e "${YELLOW}NO REFERENCE:${NC} $commit_sha"
    echo "  Message: $commit_msg"
    echo "  Suggestion: Include 'Closes #N' in commit message"
    echo ""
  fi
done

if ! $has_missing; then
  echo -e "${GREEN}OK${NC}: All recent commits reference issues"
fi
echo ""

# ============================================================================
# Section 3: Check for recently closed GitHub issues
# ============================================================================

echo -e "${BLUE}=== Section 3: Recently Closed Issues ===${NC}"
echo "Verifying related todo files are updated..."
echo ""

if command -v gh &> /dev/null; then
  # Get issues closed in the last 30 days
  echo "Issues closed in last 30 days:"

  gh issue list --state closed --limit 20 --json number,title,closedAt \
    --template '{{range .}}#{{.number}}: {{.title}}{{"\n"}}{{end}}' 2>/dev/null | while read -r issue_line; do
    if [ -n "$issue_line" ]; then
      issue_num=$(echo "$issue_line" | cut -d: -f1 | tr -d '#')
      issue_title=$(echo "$issue_line" | cut -d: -f2-)

      # Check if there's a pending todo for this issue
      matching_todo=$(grep -r "github_issue:.*$issue_num" todos/ 2>/dev/null | cut -d: -f1 || echo "")

      if [ -n "$matching_todo" ]; then
        status=$(grep "^status:" "$matching_todo" | cut -d: -f2 | xargs)
        if [ "$status" = "pending" ]; then
          echo -e "${RED}MISMATCH:${NC} $issue_line"
          echo "  Todo file: $matching_todo"
          echo "  Todo status: $status (should be: complete)"
        fi
      else
        echo -e "${GREEN}✓${NC} $issue_line (no related pending todo)"
      fi
    fi
  done
else
  echo "gh CLI not available - install it to check GitHub issue status"
fi
echo ""

# ============================================================================
# Section 4: Summary and Recommendations
# ============================================================================

echo -e "${BLUE}=== Summary ===${NC}"
echo ""

if [ $STALE_COUNT -gt 0 ]; then
  echo -e "${RED}Found $STALE_COUNT stale todo(s)${NC}"
  echo "Action: Update status to 'complete' and add completed_date"
fi

if [ $MISSING_REF_COUNT -gt 0 ]; then
  echo -e "${YELLOW}Found $MISSING_REF_COUNT commit(s) without issue references${NC}"
  echo "Action: Enforce 'Closes #N' in commit messages going forward"
fi

if [ $STALE_COUNT -eq 0 ] && [ $MISSING_REF_COUNT -eq 0 ]; then
  echo -e "${GREEN}All tracking artifacts are in good state!${NC}"
fi

echo ""
echo "Next steps:"
echo "1. Review items marked STALE or MISSING REFERENCE"
echo "2. Update todo files to match actual state"
echo "3. Close any orphaned GitHub issues"
echo "4. Run this script monthly to maintain consistency"
echo ""

# ============================================================================
# Section 5: Detailed Recommendations
# ============================================================================

if [ $STALE_COUNT -gt 0 ]; then
  echo -e "${BLUE}=== Recommended Actions ===${NC}"
  echo ""
  echo "To fix stale todos:"
  echo "1. For each STALE todo:"
  echo "   - Open the todo file"
  echo "   - Change 'status: pending' to 'status: complete'"
  echo "   - Add 'completed_date: $(date +%Y-%m-%d)'"
  echo "   - Add work log entry with completion details"
  echo "   - Commit with 'docs: update completed todos'"
  echo ""
fi

echo -e "${BLUE}=== Git Commit Best Practices ===${NC}"
echo ""
echo "When committing work, include issue references:"
echo ""
echo "  git commit -m \"feat: description of feature"
echo ""
echo "  Closes #123\""
echo ""
echo "This automatically closes the issue when PR is merged."
echo "GitHub closing keywords: Closes, Fixes, Resolves"
echo ""
