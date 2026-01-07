#!/bin/bash

# fix-stale-todos.sh - Update completed todos with proper metadata
# Usage: ./bin/fix-stale-todos.sh [todo-number]
#
# Examples:
#   ./bin/fix-stale-todos.sh 024          # Mark todo 024 as complete
#   ./bin/fix-stale-todos.sh               # Interactive mode

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Find a todo file by number
find_todo() {
  local num=$1
  local found=$(ls todos/${num}-*.md 2>/dev/null | head -1)
  if [ -n "$found" ]; then
    echo "$found"
  else
    return 1
  fi
}

# Update todo file
update_todo() {
  local todo_file=$1
  local status=$2
  local github_issue=$3
  local pr_number=${4:-}

  if [ ! -f "$todo_file" ]; then
    echo -e "${RED}Error: $todo_file not found${NC}"
    return 1
  fi

  echo "Updating $todo_file..."

  # Extract frontmatter
  local title=$(head -1 "$todo_file" | sed 's/^# //')
  local priority=$(grep "^priority:" "$todo_file" | cut -d: -f2 | xargs)
  local issue_id=$(grep "^issue_id:" "$todo_file" | cut -d'"' -f2)
  local tags=$(grep "^tags:" "$todo_file" || echo "tags: []")

  # Get current PR/issue info if not provided
  if [ -z "$github_issue" ]; then
    github_issue=$(grep "^github_issue:" "$todo_file" | cut -d: -f2 | xargs || echo "")
  fi

  if [ -z "$pr_number" ]; then
    pr_number=$(grep "^pr_number:" "$todo_file" | cut -d: -f2 | xargs || echo "null")
  fi

  # Create new frontmatter
  local completed_date=""
  if [ "$status" = "complete" ]; then
    completed_date=$(date +%Y-%m-%d)
  fi

  # Create temporary file with updated frontmatter
  local temp_file="${todo_file}.tmp"

  cat > "$temp_file" << EOF
---
status: $status
priority: $priority
issue_id: "$issue_id"
github_issue: $github_issue
pr_number: $pr_number
tags: $(grep "^tags:" "$todo_file" | cut -d: -f2-)
$([ -n "$completed_date" ] && echo "completed_date: $completed_date" || true)
dependencies: $(grep "^dependencies:" "$todo_file" | cut -d: -f2-)
---
EOF

  # Get content after frontmatter (skip first 5 lines: ---, status, priority, issue_id, ---)
  tail -n +7 "$todo_file" >> "$temp_file"

  # Replace original
  mv "$temp_file" "$todo_file"

  echo -e "${GREEN}✓ Updated:${NC} $todo_file"
  echo "  Status: $status"
  echo "  GitHub Issue: ${github_issue:-'not set'}"
  echo "  Completed: ${completed_date:-'N/A'}"
}

# Interactive mode
interactive_mode() {
  echo -e "${BLUE}=== Todo Fix Helper ===${NC}"
  echo ""

  # List pending todos
  echo "Pending todos:"
  ls -1 todos/???-pending-*.md 2>/dev/null | while read -r todo; do
    issue_id=$(grep "^issue_id:" "$todo" | cut -d'"' -f2)
    github_issue=$(grep "^github_issue:" "$todo" | cut -d: -f2 | xargs || echo "not set")
    title=$(sed -n '7p' "$todo" | sed 's/^# //')
    echo "  $(basename $todo | cut -d- -f1): $title (GitHub: #$github_issue)"
  done
  echo ""

  # Prompt for todo number
  read -p "Enter todo number to update (or 'q' to quit): " todo_num

  if [ "$todo_num" = "q" ]; then
    echo "Cancelled."
    return 0
  fi

  # Find the todo
  todo_file=$(find_todo "$todo_num") || {
    echo -e "${RED}Error: Todo $todo_num not found${NC}"
    return 1
  }

  # Confirm current status
  current_status=$(grep "^status:" "$todo_file" | cut -d: -f2 | xargs)
  echo ""
  echo "Current todo: $todo_file"
  echo "Current status: $current_status"
  echo ""

  # Prompt for new status
  read -p "New status (pending/in_progress/complete/blocked) [${current_status}]: " new_status
  new_status=${new_status:-$current_status}

  # Prompt for GitHub issue
  current_issue=$(grep "^github_issue:" "$todo_file" | cut -d: -f2 | xargs || echo "")
  read -p "GitHub issue number [${current_issue}]: " github_issue
  github_issue=${github_issue:-$current_issue}

  # Prompt for PR number
  current_pr=$(grep "^pr_number:" "$todo_file" | cut -d: -f2 | xargs || echo "null")
  read -p "PR number [${current_pr}]: " pr_number
  pr_number=${pr_number:-$current_pr}

  # Confirm
  echo ""
  echo -e "${YELLOW}Review changes:${NC}"
  echo "  Status: $current_status → $new_status"
  [ -n "$github_issue" ] && echo "  GitHub Issue: #$github_issue"
  [ "$pr_number" != "null" ] && echo "  PR Number: #$pr_number"
  echo ""

  read -p "Apply changes? (y/n): " confirm
  if [ "$confirm" = "y" ]; then
    update_todo "$todo_file" "$new_status" "$github_issue" "$pr_number"
  else
    echo "Cancelled."
    return 0
  fi
}

# Main
if [ $# -eq 0 ]; then
  # Interactive mode
  interactive_mode
else
  # Direct mode
  todo_num=$1
  todo_file=$(find_todo "$todo_num") || {
    echo -e "${RED}Error: Todo $todo_num not found${NC}"
    exit 1
  }

  status=${2:-complete}
  github_issue=${3:-}
  pr_number=${4:-}

  update_todo "$todo_file" "$status" "$github_issue" "$pr_number"
fi

echo ""
echo "Done!"
