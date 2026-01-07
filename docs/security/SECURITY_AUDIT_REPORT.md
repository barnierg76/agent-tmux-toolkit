# Security Audit Report: agent-tmux-toolkit

**Date**: 2026-01-07
**Auditor**: Claude Code Security Analysis
**Scope**: Bash-based tmux toolkit for AI agent workflows

---

## Executive Summary

**Overall Risk Assessment**: MEDIUM-HIGH

This audit identified **23 security findings** across the codebase:
- **5 P1 (Critical)** - Immediate attention required
- **11 P2 (Important)** - Should be fixed before production use
- **7 P3 (Nice-to-have)** - Defense-in-depth improvements

The toolkit has **good validation** in some areas (session names, basic input validation) but suffers from **command injection vulnerabilities** in fzf preview commands, **incomplete input validation** for pane names/titles, and **unsafe variable handling** in several scripts.

---

## P1 - Critical Vulnerabilities

### P1-1: Command Injection via fzf preview in agent-manage
**File**: `bin/agent-manage:310,314`
**Severity**: CRITICAL

```bash
preview_cmd="tmux capture-pane -p -S - -t '$SESSION_NAME.{1}' 2>/dev/null | tail -30"
```

**Issue**: The `$SESSION_NAME` variable is interpolated into the fzf preview command without proper escaping. While `get_session_name()` validates the session name format, an attacker who can control the `AGENT_SESSION` environment variable before validation could inject commands.

**Attack Vector**:
```bash
AGENT_SESSION='test$(rm -rf /)`' agent-manage copy
```

**Impact**: Arbitrary command execution when fzf executes preview commands

**Remediation**:
```bash
# Option 1: Use printf %q for proper shell escaping
preview_cmd="tmux capture-pane -p -S - -t $(printf %q "$SESSION_NAME").{1} 2>/dev/null | tail -30"

# Option 2: Move to static preview and use --bind
--preview-command='tmux capture-pane -p -S - -t {1} 2>/dev/null | tail -30'
```

---

### P1-2: Command Injection via fzf preview in agent-handoff
**File**: `bin/agent-handoff:203`
**Severity**: CRITICAL

```bash
--preview="tmux capture-pane -p -t {1} 2>/dev/null | tail -30"
```

**Issue**: The `{1}` placeholder from fzf is passed directly to a shell command. If the pane ID format contains shell metacharacters (unlikely but theoretically possible with tmux options), this could be exploited.

**Impact**: Potential command execution through crafted pane IDs

**Remediation**:
- Validate pane ID format strictly before passing to fzf
- Use `--preview-window=:wrap` instead of shell pipes in preview

---

### P1-3: Unsafe tmux send-keys in snippet-picker
**File**: `bin/snippet-picker:170`
**Severity**: CRITICAL

```bash
tmux send-keys -t "$TARGET_PANE" "$text"
```

**Issue**: The snippet content is sent directly to a pane without the `-l` (literal) flag. This interprets tmux key bindings and special sequences, allowing snippets to execute arbitrary commands if they contain Enter, C-c, etc.

**Attack Vector**: A malicious snippet containing:
```
rm -rf ~
Enter
```

**Impact**: Arbitrary command execution in the target pane

**Remediation**:
```bash
# Use -l flag for literal strings
tmux send-keys -t "$TARGET_PANE" -l "$text"
```

**Note**: This was marked as "completed" in todo 001, but the fix is **NOT applied** in the current code at line 170.

---

### P1-4: Path Traversal in agent-flow-state
**File**: `bin/agent-flow-state:13`
**Severity**: CRITICAL

```bash
SESSION_NAME=$(get_session_name)
STATE_FILE="$STATE_DIR/${SESSION_NAME}.state"
```

**Issue**: While `get_session_name()` validates alphanumeric characters, it does NOT prevent path traversal with `../` sequences if they contain valid characters. An attacker could write state files outside the intended directory.

**Attack Vector**:
```bash
AGENT_SESSION='../../etc/passwd'
agent-flow-state set PLANNING
# Attempts to write to ~/.cache/../../etc/passwd.state
```

**Impact**: Arbitrary file write (though limited by file extension and validation)

**Remediation**:
```bash
# In agent-common.sh get_session_name(), explicitly reject path components
if [[ "$name" =~ \.\. ]] || [[ "$name" =~ / ]]; then
    echo -e "${RED}Error: Invalid session name (path traversal)${NC}" >&2
    echo "agents"
    return 1
fi
```

---

### P1-5: Race Condition in Worktree Creation
**File**: `bin/agent-worktree:136-167`
**Severity**: HIGH

```bash
if [ -d "$WORKTREE_DIR" ]; then
    # ... check session ...
else
    # ... create worktree ...
fi
```

**Issue**: TOCTOU (Time-of-Check-Time-of-Use) race condition. Between checking if the directory exists and creating it, another process could create a malicious symlink at that location.

**Attack Vector**:
```bash
# Attacker runs in parallel:
while true; do
  ln -s /etc/passwd ../myrepo-feat-auth 2>/dev/null
done
```

**Impact**: Symlink attack allowing write to arbitrary filesystem locations

**Remediation**:
```bash
# Use atomic operations with git worktree
git worktree add -b "$BRANCH_NAME" "$WORKTREE_DIR" "$BASE_BRANCH" 2>/dev/null || {
    echo -e "${RED}Failed to create worktree${NC}"
    exit 1
}
# Git will fail safely if directory exists
```

---

## P2 - Important Vulnerabilities

### P2-1: Incomplete Pane Name Validation
**File**: `bin/agent-manage:138,223`
**Severity**: HIGH

```bash
if validate_name "${names[$i]}" "pane name"; then
    tmux select-pane -t "$SESSION_NAME.$new_pane" -T "${names[$i]}"
```

**Issue**: While `validate_name()` checks alphanumeric characters, tmux pane titles can contain spaces and special characters. Pane titles set by users are later used in grep/awk operations without escaping.

**Impact**: Grep command injection through crafted pane titles

**Remediation**:
- Expand validation to allow only safe pane title characters
- Escape pane titles when used in grep/awk operations

---

### P2-2: Unquoted Variable in Array Assignment
**File**: `bin/agent-session:103`, `bin/agent-delegate:122,146`, `bin/agent-worktree:190`
**Severity**: MEDIUM

```bash
PANE_IDS=($(tmux list-panes -t "$SESSION_NAME:agents" -F "#{pane_id}"))
```

**Issue**: Command substitution in array assignment without proper quoting. If pane IDs contain spaces (theoretically possible), word splitting occurs.

**Impact**: Incorrect pane ID parsing, potential denial of service

**Remediation**:
```bash
# Use mapfile/readarray for safer array population
mapfile -t PANE_IDS < <(tmux list-panes -t "$SESSION_NAME:agents" -F "#{pane_id}")
```

---

### P2-3: Clipboard Content Injection in Paste Operations
**File**: `bin/agent-manage:440`
**Severity**: HIGH

```bash
tmux send-keys -t "$SESSION_NAME.$pane_idx" -l "$content"
```

**Issue**: Uses `-l` flag (good!) but clipboard content is not sanitized. While `-l` prevents key interpretation, malicious clipboard content could still contain control characters (like `\x00`, `\x1b`) that could cause terminal issues.

**Impact**: Terminal escape sequence injection, potential information disclosure

**Remediation**:
```bash
# Strip control characters before pasting
content=$(echo "$content" | tr -cd '[:print:]\n\t')
tmux send-keys -t "$SESSION_NAME.$pane_idx" -l "$content"
```

---

### P2-4: Missing Validation for Task IDs
**File**: `bin/agent-session:73`
**Severity**: MEDIUM

```bash
if [ -n "$TASK_ID" ]; then
    validate_name "$TASK_ID" "task ID" || exit 1
    SESSION_NAME="agent-${TASK_ID}"
fi
```

**Issue**: Good validation! But pane titles set from `$TASK_ID` at lines 113-115 are not similarly validated when used in other contexts.

**Impact**: Potential injection if task IDs are used in shell commands elsewhere

**Remediation**: Ensure all uses of task IDs in commands are properly quoted

---

### P2-5: Shell Injection in agent-flow send-to-pane
**File**: `bin/agent-flow:60`
**Severity**: HIGH

```bash
tmux send-keys -t "$pane_id" -l "$*"
```

**Issue**: Uses `-l` flag (good!) but `$*` concatenates all arguments with spaces. If arguments contain tmux special sequences or control characters, they're still sent.

**Impact**: Limited - using `-l` mitigates most issues, but control characters could cause terminal problems

**Remediation**:
```bash
# Sanitize before sending
local text="$*"
text="${text//[^[:print:][:space:]]/}"  # Remove non-printable chars
tmux send-keys -t "$pane_id" -l "$text"
```

---

### P2-6: Directory Traversal in Worktree Path Construction
**File**: `bin/agent-worktree:133`, `bin/agent-delegate:91`
**Severity**: MEDIUM

```bash
REPO_NAME="${PWD##*/}"
WORKTREE_DIR="../${REPO_NAME}-${BRANCH_NAME}"
```

**Issue**: If `$PWD` is a path like `/tmp/../../etc`, the `PWD##*/` extraction could yield unexpected results. Combined with user-controlled branch names, this could create worktrees in unintended locations.

**Impact**: Worktree creation in arbitrary directories

**Remediation**:
```bash
# Canonicalize the path first
REPO_PATH="$(cd "$PWD" && pwd -P)"
REPO_NAME="${REPO_PATH##*/}"
# Ensure parent directory is safe
PARENT_DIR="$(cd .. && pwd -P)"
WORKTREE_DIR="${PARENT_DIR}/${REPO_NAME}-${BRANCH_NAME}"
```

---

### P2-7: Unsafe grep with User-Controlled Folder Names
**File**: `bin/snippet-picker:138`
**Severity**: MEDIUM

```bash
snippets=$(echo "$PARSED_SNIPPETS" | grep "^${selected_folder}/")
```

**Issue**: `$selected_folder` comes from parsing the snippets file, which could contain regex metacharacters. If a folder is named with regex patterns like `.*` or `[PLAN]`, the grep could match unintended lines.

**Impact**: Information disclosure - user sees snippets from wrong folders

**Remediation**:
```bash
# Use -F for fixed string matching
snippets=$(echo "$PARSED_SNIPPETS" | grep -F "^${selected_folder}/")
```

---

### P2-8: Session Name Injection in grep Filter
**File**: `bin/agent-status:67`
**Severity**: MEDIUM

```bash
sessions=$(tmux list-sessions ... | grep "$filter" || true)
```

**Issue**: `$filter` is set to `"^agent"` (hardcoded), so this is safe. However, if future code allows user-controlled filters, this would be vulnerable to regex injection.

**Impact**: Currently NONE (hardcoded), but fragile design

**Remediation**:
```bash
# Use -F for literal string matching
sessions=$(tmux list-sessions ... | grep -F "$filter" || true)
```

---

### P2-9: Unvalidated Branch Names in Git Commands
**File**: `bin/agent-worktree:153-166`
**Severity**: MEDIUM

```bash
if git show-ref --verify --quiet "refs/heads/${BRANCH_NAME}"; then
    git worktree add "$WORKTREE_DIR" "$BRANCH_NAME"
```

**Issue**: While branch name is validated with alphanumeric check, Git allows many special characters in branch names that could cause command confusion or injection in shell contexts.

**Impact**: Potential command injection if Git commands are later used in unsafe ways

**Remediation**:
- Restrict branch name validation to `[a-zA-Z0-9_-]` only (already done at line 127)
- Always quote branch names in git commands (already done)

---

### P2-10: Missing Input Validation in agent-flow-state
**File**: `bin/agent-flow-state:49-61`
**Severity**: LOW-MEDIUM

```bash
cmd_set() {
    local state="$1"
    case "$state" in
        IDLE|PLANNING|WORKING|REVIEWING|COMPOUND|DONE)
            echo "$state" > "$STATE_FILE"
```

**Issue**: Good validation! But no check for special characters or length limits. While the case statement prevents most issues, extremely long state strings could cause problems.

**Impact**: Minimal - case statement provides good protection

**Remediation**: Add length check:
```bash
if [[ ${#state} -gt 20 ]]; then
    echo "State too long" >&2
    exit 1
fi
```

---

### P2-11: Potential Command Injection in install.sh
**File**: `install.sh:30-32`
**Severity**: MEDIUM

```bash
for script in agent-common agent-session ...; do
    backup_if_exists ~/.local/bin/$script
done
```

**Issue**: If the script names in the for loop contained spaces or special characters, this would fail. Currently safe because names are hardcoded, but fragile.

**Impact**: Installation failure, potential security issue if script names are ever sourced from external input

**Remediation**:
```bash
# Quote the variable
backup_if_exists ~/.local/bin/"$script"
```

---

## P3 - Defense-in-Depth Improvements

### P3-1: Missing File Permissions Check
**File**: `bin/agent-flow-state:10`
**Severity**: LOW

```bash
mkdir -p -m 700 "$STATE_DIR"
```

**Issue**: Good practice! But doesn't check if directory already exists with wrong permissions.

**Remediation**:
```bash
mkdir -p -m 700 "$STATE_DIR"
chmod 700 "$STATE_DIR"  # Ensure permissions even if dir exists
```

---

### P3-2: Information Disclosure in Status Dashboard
**File**: `bin/agent-status:120`
**Severity**: LOW

```bash
last_output=$(tmux capture-pane -t "$name:0.0" -p 2>/dev/null | grep -v '^$' | tail -1 | cut -c1-33)
```

**Issue**: Displays last output from panes, which could contain sensitive information (passwords, API keys, etc.)

**Impact**: Information disclosure to users who can run agent-status

**Remediation**:
- Add option to disable last output display
- Redact common sensitive patterns (password=, api_key=, token=)

---

### P3-3: No Timeout on User Input
**File**: `bin/agent-manage:514,530,543,555` (multiple read commands)
**Severity**: LOW

```bash
read -p "Session name [agents]: " session_name </dev/tty
```

**Issue**: No timeout on read commands. If script is run in automated context, it could hang indefinitely.

**Impact**: Denial of service through script hanging

**Remediation**:
```bash
read -t 30 -p "Session name [agents]: " session_name </dev/tty || {
    echo "Timeout"
    exit 1
}
```

---

### P3-4: Weak Backup Naming in install.sh
**File**: `install.sh:14`
**Severity**: LOW

```bash
local backup="${file}.backup.$(date +%Y%m%d%H%M%S)"
```

**Issue**: Backup filenames are predictable. An attacker could pre-create files with these names to prevent backups or cause confusion.

**Impact**: Backup bypass, potential data loss

**Remediation**:
```bash
local backup="${file}.backup.$(date +%Y%m%d%H%M%S).$$"  # Add PID for uniqueness
```

---

### P3-5: No Verification of Clipboard Commands
**File**: `bin/agent-common.sh:73-87`
**Severity**: LOW

```bash
if command -v pbcopy &>/dev/null; then
    echo -n "$content" | pbcopy
```

**Issue**: No verification that clipboard tools are legitimate. An attacker could replace `pbcopy` with a malicious script.

**Impact**: Clipboard content interception

**Remediation**:
- Verify clipboard tool paths are in trusted directories
- Use absolute paths: `/usr/bin/pbcopy`

---

### P3-6: Missing Error Handling for State File Operations
**File**: `bin/agent-flow-state:54`
**Severity**: LOW

```bash
echo "$state" > "$STATE_FILE"
```

**Issue**: No error checking if write fails (disk full, permissions, etc.)

**Impact**: Silent failure of state tracking

**Remediation**:
```bash
if ! echo "$state" > "$STATE_FILE"; then
    echo "Failed to save state" >&2
    exit 1
fi
```

---

### P3-7: No Sanitization of Pane Content in Handoff
**File**: `bin/agent-handoff:222-225`
**Severity**: LOW

```bash
local content=$(tmux capture-pane -p -t "$source_id" 2>/dev/null | \
    sed 's/\x1b\[[0-9;]*m//g' | \
    grep -v '^[[:space:]]*$' | \
    tail -50)
```

**Issue**: Strips ANSI codes (good!) but doesn't remove other control characters or null bytes that could cause issues.

**Impact**: Terminal corruption, potential injection if content is later used unsafely

**Remediation**:
```bash
# Add control character stripping
local content=$(tmux capture-pane -p -t "$source_id" 2>/dev/null | \
    sed 's/\x1b\[[0-9;]*m//g' | \
    tr -cd '[:print:]\n\t' | \
    grep -v '^[[:space:]]*$' | \
    tail -50)
```

---

## Risk Matrix

| Priority | Count | Risk Level | Action Required |
|----------|-------|------------|-----------------|
| P1       | 5     | CRITICAL   | Fix immediately before use |
| P2       | 11    | HIGH       | Fix before production |
| P3       | 7     | MEDIUM     | Consider for hardening |

---

## Remediation Roadmap

### Immediate (Week 1)
1. **P1-3**: Fix snippet-picker to use `-l` flag (marked as done but not applied)
2. **P1-1**: Escape SESSION_NAME in fzf preview commands
3. **P1-4**: Add path traversal checks to get_session_name()
4. **P2-3**: Sanitize clipboard content before pasting
5. **P2-7**: Use grep -F for folder name matching

### Short-term (Week 2-3)
6. **P1-2**: Validate pane ID format before fzf
7. **P1-5**: Fix worktree race condition with atomic operations
8. **P2-1**: Expand pane name validation and escaping
9. **P2-2**: Use mapfile for array assignments
10. **P2-5**: Sanitize control characters in agent-flow
11. **P2-6**: Canonicalize worktree directory paths

### Medium-term (Month 1)
12. **P2-8** through **P2-11**: Complete all P2 items
13. **P3** items: Implement defense-in-depth improvements
14. Add comprehensive test suite for security validation
15. Implement input fuzzing for all user-facing functions

### Long-term (Ongoing)
16. Regular security audits
17. Dependency scanning (though minimal for bash)
18. User training on secure usage patterns
19. Implement logging for security-relevant events

---

## Testing Recommendations

### Manual Testing Checklist
```bash
# Test 1: Command injection in session names
export AGENT_SESSION='test$(whoami)'
agent-session

# Test 2: Path traversal in state files
export AGENT_SESSION='../../tmp/evil'
agent-flow-state set PLANNING

# Test 3: Malicious snippet content
# Create snippet with: evil-command\nEnter
# Verify it doesn't execute

# Test 4: Clipboard injection
echo -e '\x1b[31mRED\x00NULL' | pbcopy
agent-manage paste 0

# Test 5: Race condition in worktree
# Run in parallel: agent-worktree feat-test
# And: ln -s /etc/passwd ../repo-feat-test
```

### Automated Testing
```bash
# Install shellcheck
brew install shellcheck

# Run on all scripts
find bin -type f -exec shellcheck {} \;

# Look for specific patterns
grep -r 'send-keys.*-t.*\$' bin/  # Missing -l flag
grep -r '\$(' bin/ | grep -v '"'   # Unquoted command substitution
```

---

## Security Best Practices for Future Development

1. **Input Validation**: Always validate and sanitize user input
   - Use allowlist validation (regex `^[a-zA-Z0-9_-]+$`)
   - Reject rather than sanitize when possible
   - Validate length, format, and content

2. **Command Execution**: Minimize shell command execution
   - Use tmux commands with explicit arguments
   - Always quote variables: `"$var"` not `$var`
   - Use `-l` flag for `tmux send-keys` for literal strings
   - Prefer `printf %q` for shell escaping

3. **File Operations**: Prevent path traversal
   - Reject paths containing `..`, `/`, or null bytes
   - Use absolute paths when possible
   - Check file permissions after creation
   - Use atomic operations (git's built-in safety)

4. **fzf Integration**: Secure preview commands
   - Never interpolate user input into preview commands
   - Use static preview commands where possible
   - Validate all data before passing to fzf

5. **Clipboard Operations**: Sanitize content
   - Strip control characters
   - Limit size to prevent DoS
   - Use `-l` flag for literal paste

6. **Error Handling**: Fail securely
   - Check return codes
   - Provide minimal error information to users
   - Log security events
   - Use `set -e` to exit on errors

---

## Comparison with Existing Security Work

### Completed TODOs (Good!)
- ✅ **TODO-001**: Command injection prevention in snippet-picker
  - **STATUS**: Marked complete but FIX NOT APPLIED (see P1-3)
- ✅ **TODO-003**: Input validation for session names
  - **STATUS**: Good validation in place
- ✅ **TODO-020**: Session name validation
  - **STATUS**: Properly implemented in agent-common.sh

### Still Needed
- ❌ Pane name/title validation
- ❌ fzf preview command hardening
- ❌ Clipboard content sanitization
- ❌ Path traversal prevention in state files
- ❌ Race condition fixes in worktree operations

---

## Conclusion

The agent-tmux-toolkit has **good security foundations** with input validation for session names and structured error handling. However, several **critical vulnerabilities** remain, particularly around:

1. Command injection in fzf preview commands
2. Missing literal flag in snippet-picker (regression from TODO-001)
3. Path traversal in state file operations
4. Race conditions in worktree creation

**Recommendation**: Address all P1 issues before using in any security-sensitive environment. P2 issues should be fixed before production deployment. P3 issues provide additional defense-in-depth.

The codebase is well-structured and maintainable, making security improvements straightforward to implement.

---

## Appendix: Secure Coding Patterns for Bash

### Pattern 1: Safe Variable Quoting
```bash
# ❌ BAD
tmux send-keys -t $pane $text

# ✅ GOOD
tmux send-keys -t "$pane" -l "$text"
```

### Pattern 2: Input Validation
```bash
# ✅ GOOD
if ! [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Invalid input" >&2
    return 1
fi
```

### Pattern 3: Safe Array Population
```bash
# ❌ BAD
PANES=($(tmux list-panes ...))

# ✅ GOOD
mapfile -t PANES < <(tmux list-panes ...)
```

### Pattern 4: Secure Temporary Files
```bash
# ✅ GOOD
tmpfile=$(mktemp) || exit 1
chmod 600 "$tmpfile"
trap 'rm -f "$tmpfile"' EXIT
```

### Pattern 5: Safe grep with User Input
```bash
# ❌ BAD
grep "$user_input" file

# ✅ GOOD
grep -F "$user_input" file  # -F = fixed string, no regex
```

---

**End of Security Audit Report**
