# Code Quality Remediation Plan

## Overview

Address code review findings to improve maintainability, security, and consistency across the agent-tmux-toolkit codebase.

**Type:** Refactor
**Estimated Effort:** 2-3 hours
**Risk Level:** Low (internal refactoring, no API changes)

---

## Problem Statement

Code review identified several DRY violations, inconsistent patterns, and missing infrastructure that reduce maintainability:

1. Duplicate function definitions across files
2. Missing input validation in some commands
3. Inconsistent error handling patterns
4. No CI linting or automated tests

---

## Implementation Phases

### Phase 1: High Priority (DRY & Security)

#### Task 1.1: Remove duplicate `resolve_pane()` from agent-manage

**File:** `bin/agent-manage:66-86`

**Problem:** `agent-manage` defines its own `resolve_pane()` that shadows the more complete version in `agent-common.sh:206-240`.

**Solution:** Delete the local definition and use the shared library version.

```bash
# DELETE lines 66-86 in agent-manage (the local resolve_pane function)

# The shared library version at agent-common.sh:206-240 already:
# - Handles numeric pane indices
# - Supports role lookup (PLAN, WORK, REVIEW)
# - Falls back to pane title matching
```

**Acceptance Criteria:**
- [ ] Local `resolve_pane()` removed from `agent-manage`
- [ ] All `resolve_pane()` calls in `agent-manage` work with shared version
- [ ] Test: `agent-manage close PLAN`, `agent-manage focus 0`, `agent-manage copy WORK`

---

#### Task 1.2: Add input validation to `cmd_rename()`

**File:** `bin/agent-manage:214-228`

**Problem:** `cmd_rename()` accepts arbitrary pane names without validation, but the menu version (line 569) validates. Inconsistent.

**Solution:** Add `validate_name()` call.

```bash
# bin/agent-manage - cmd_rename() function
cmd_rename() {
    check_session

    local index="$1"
    local name="$2"

    if [[ -z "$index" ]] || [[ -z "$name" ]]; then
        echo -e "${RED}Error: Usage: agent-manage rename <index> <name>${NC}"
        exit 1
    fi

    # ADD THIS: Validate the pane name
    if ! validate_name "$name" "pane name"; then
        exit 1
    fi

    tmux select-pane -t "$SESSION_NAME.$index" -T "$name" 2>/dev/null && \
        echo -e "${GREEN}Renamed pane $index to '$name'${NC}" || \
        echo -e "${RED}Error: Pane $index not found${NC}"
}
```

**Acceptance Criteria:**
- [ ] `agent-manage rename 0 "test;injection"` fails with validation error
- [ ] `agent-manage rename 0 "valid-name"` succeeds
- [ ] `agent-manage rename 0 "PLAN"` succeeds

---

#### Task 1.3: Fix unquoted `$tasks` expansion in agent-manage menu

**File:** `bin/agent-manage:621,624`

**Problem:** Variable expansion without quotes can cause word splitting issues.

```bash
# CURRENT (line 621, 624):
agent-delegate --worktree $tasks
agent-delegate $tasks

# ISSUE: If tasks="task one task two", this breaks
```

**Solution:** The `$tasks` comes from `read -p` which stores input as a single string. Convert to array properly.

```bash
# bin/agent-manage - "Delegate tasks" menu option (around line 614-628)
"🚀 Delegate tasks")
    echo -e "${BLUE}Delegate Tasks to Parallel Agents${NC}"
    echo "Enter task names (space-separated):"
    read -p "> " -a task_array </dev/tty  # Read directly into array
    if [[ ${#task_array[@]} -gt 0 ]]; then
        read -p "Also create git worktrees? [y/N]: " use_wt </dev/tty
        if [[ "$use_wt" =~ ^[Yy]$ ]]; then
            agent-delegate --worktree "${task_array[@]}"
        else
            agent-delegate "${task_array[@]}"
        fi
    fi
    echo ""
    read -p "Press Enter to continue..." </dev/tty
    ;;
```

**Acceptance Criteria:**
- [ ] Menu delegate with "task1 task2 task3" creates 3 sessions
- [ ] No shellcheck warnings on these lines

---

### Phase 2: Medium Priority (Consistency)

#### Task 2.1: Standardize error handling

**Problem:** Mixed patterns: some functions exit silently, others print errors.

**Solution:** Add standardized `die()` function to `agent-common.sh`.

```bash
# ADD to bin/agent-common.sh after colors section (~line 21)

# ═══════════════════════════════════════════════════════════════════════════════
# ERROR HANDLING
# ═══════════════════════════════════════════════════════════════════════════════

# Print error message and exit
# Usage: die "Error message" [exit_code]
die() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit "${2:-1}"
}

# Print warning message (doesn't exit)
# Usage: warn "Warning message"
warn() {
    echo -e "${YELLOW}Warning: $1${NC}" >&2
}
```

**Then update scripts to use consistently:**

```bash
# Example replacements:

# BEFORE (agent-worktree:121-124):
if ! git rev-parse --git-dir &>/dev/null; then
    echo -e "${RED}Error: Not a git repository${NC}"
    exit 1
fi

# AFTER:
git rev-parse --git-dir &>/dev/null || die "Not a git repository"
```

**Acceptance Criteria:**
- [ ] `die()` and `warn()` added to `agent-common.sh`
- [ ] At least 5 error cases converted to use `die()`
- [ ] No functionality changes (just cleaner code)

---

#### Task 2.2: Remove duplicate `check_fzf()` from agent-handoff

**File:** `bin/agent-handoff:86-93`

**Problem:** Redefines `check_fzf()` that already exists in `agent-common.sh:247-253`.

**Solution:** Delete local definition.

```bash
# DELETE lines 86-93 in agent-handoff:
check_fzf() {
    if ! command -v fzf &> /dev/null; then
        echo -e "${RED}Error: fzf is required for interactive mode${NC}"
        echo "Install with: brew install fzf"
        exit 1
    fi
}
```

**Acceptance Criteria:**
- [ ] Local `check_fzf()` removed from `agent-handoff`
- [ ] `agent-handoff` still works (uses shared version)
- [ ] Run without fzf installed to verify error message

---

#### Task 2.3: Add shellcheck to CI

**File:** `.github/workflows/shellcheck.yml` (new)

```yaml
name: ShellCheck

on:
  push:
    branches: [main]
    paths:
      - 'bin/**'
      - 'install.sh'
      - '*.sh'
  pull_request:
    paths:
      - 'bin/**'
      - 'install.sh'
      - '*.sh'

jobs:
  shellcheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run ShellCheck
        uses: ludeeus/action-shellcheck@v2
        env:
          SHELLCHECK_OPTS: --severity=warning --shell=bash
        with:
          scandir: './bin'
          additional_files: 'install.sh'
```

**Acceptance Criteria:**
- [ ] Workflow file created
- [ ] PR with shell changes triggers shellcheck
- [ ] Any existing warnings documented or fixed

---

### Phase 3: Low Priority (Infrastructure)

#### Task 3.1: Make paths configurable

**Files:** Multiple scripts with hardcoded paths

**Solution:** Add configuration variables to `agent-common.sh`.

```bash
# ADD to bin/agent-common.sh after error handling section

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

# Configurable paths (can be overridden via environment)
AGENT_CONFIG_DIR="${AGENT_CONFIG_DIR:-$HOME/.config/agent-snippets}"
AGENT_CACHE_DIR="${AGENT_CACHE_DIR:-$HOME/.cache/agent-tmux}"
AGENT_HELP_CMD="${AGENT_HELP_CMD:-$HOME/.local/bin/agent-help}"
SNIPPETS_FILE="${SNIPPETS_FILE:-$AGENT_CONFIG_DIR/snippets.txt}"
```

**Then update scripts:**

```bash
# snippet-picker:11 - BEFORE:
SNIPPETS_FILE="${HOME}/.config/agent-snippets/snippets.txt"

# AFTER (already defined in agent-common.sh):
# Just use $SNIPPETS_FILE directly
```

**Acceptance Criteria:**
- [ ] Configuration variables added to `agent-common.sh`
- [ ] At least `snippet-picker` updated to use shared config
- [ ] `SNIPPETS_FILE=/custom/path snippet-picker` works

---

#### Task 3.2: Add basic tests for critical functions

**Files:** `test/` directory (new)

**Solution:** Create bats tests for validation functions.

```bash
# test/validation.bats
#!/usr/bin/env bats

setup() {
    source "${BATS_TEST_DIRNAME}/../bin/agent-common.sh"
}

@test "validate_name accepts alphanumeric" {
    run validate_name "test123"
    [ "$status" -eq 0 ]
}

@test "validate_name accepts dashes" {
    run validate_name "my-session"
    [ "$status" -eq 0 ]
}

@test "validate_name accepts underscores" {
    run validate_name "my_session"
    [ "$status" -eq 0 ]
}

@test "validate_name rejects semicolons" {
    run validate_name "test;injection"
    [ "$status" -eq 1 ]
}

@test "validate_name rejects pipes" {
    run validate_name "test|cmd"
    [ "$status" -eq 1 ]
}

@test "validate_name rejects spaces" {
    run validate_name "test space"
    [ "$status" -eq 1 ]
}

@test "validate_name rejects empty string" {
    run validate_name ""
    [ "$status" -eq 1 ]
}
```

**Acceptance Criteria:**
- [ ] `test/` directory created
- [ ] `test/validation.bats` with 7+ test cases
- [ ] Tests pass: `bats test/`
- [ ] README updated with test instructions

---

#### Task 3.3: Document paste-buffer vs send-keys tradeoff

**File:** `docs/internals.md` (new) or add to `LEARNINGS.md`

```markdown
## Tmux Content Injection Methods

### send-keys -l (Literal)

Used in: `snippet-picker`, `agent-manage paste`

```bash
tmux send-keys -t "$pane" -l "$content"
```

**Pros:**
- `-l` flag prevents interpretation of special keys (Enter, Tab, etc.)
- Content appears exactly as typed
- Safe for code snippets

**Cons:**
- Very long content may be slow
- Some terminal escape sequences may still be interpreted

### load-buffer + paste-buffer

Used in: `agent-handoff`

```bash
echo "$content" | tmux load-buffer -
tmux paste-buffer -t "$pane"
```

**Pros:**
- Better for large content blocks
- Faster for multi-line content
- Native tmux paste behavior

**Cons:**
- Bypasses `-l` literal protection
- May interpret bracket paste sequences
- Content goes through tmux buffer (can be captured)

### Recommendation

- **Short snippets (< 100 lines):** Use `send-keys -l`
- **Large content / handoffs:** Use `load-buffer` + `paste-buffer`
- **Security-sensitive content:** Always use `send-keys -l`
```

**Acceptance Criteria:**
- [ ] Documentation added to `LEARNINGS.md` or new doc file
- [ ] Explains when to use each method
- [ ] References actual usage in codebase

---

## File Changes Summary

| File | Changes |
|------|---------|
| `bin/agent-common.sh` | Add `die()`, `warn()`, config vars |
| `bin/agent-manage` | Remove duplicate `resolve_pane()`, fix validation, fix array expansion |
| `bin/agent-handoff` | Remove duplicate `check_fzf()` |
| `.github/workflows/shellcheck.yml` | New file |
| `test/validation.bats` | New file |
| `LEARNINGS.md` | Add send-keys documentation |

---

## Testing Checklist

### After Phase 1
- [ ] `agent-manage close PLAN` works
- [ ] `agent-manage rename 0 "bad;name"` fails
- [ ] Menu delegate creates correct number of sessions

### After Phase 2
- [ ] All scripts still function
- [ ] ShellCheck CI runs on PR
- [ ] No new shellcheck warnings

### After Phase 3
- [ ] `bats test/` passes
- [ ] Custom `SNIPPETS_FILE` path works

---

## References

### Internal
- `bin/agent-common.sh:206-240` - Shared `resolve_pane()` implementation
- `bin/agent-common.sh:247-253` - Shared `check_fzf()` implementation
- `bin/agent-common.sh:28-36` - `validate_name()` function
- `CONTRIBUTING.md:65-79` - Testing guidelines

### External
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [ShellCheck GitHub Action](https://github.com/ludeeus/action-shellcheck)
- [Bats-core Testing Framework](https://github.com/bats-core/bats-core)
- [Safer Bash with set -euo pipefail](https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/)
