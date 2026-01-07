# Plan: Expand Sandbox Permissions for Smoother Workflow

## Overview

Your current sandbox configuration is **very restrictive** - only 13 specific operations are allowed. This means Claude will ask permission for nearly every common development task (git, npm, file operations, etc.).

**The Goal:** Stay sandboxed (secure) while reducing permission friction for safe, common operations.

## Current State Analysis

**File:** `.claude/settings.local.json`

```
Currently Allowed (13 items):
├── WebSearch
├── Bash: col, chmod
├── Bash: tmux display-message, list-commands, list-panes, capture-pane
├── Bash: gh pr view
├── MCP: playwright navigate, context7 tools
├── WebFetch: deepwiki.com only
└── Skill: ascii-animation
```

**What Will Trigger Permission Prompts:**
- ❌ `git status`, `git diff`, `git log`, `git add`, `git commit`
- ❌ `npm install`, `npm run`, `npm test`, `npm build`
- ❌ `ls`, `pwd`, `which`, `echo`
- ❌ `mkdir`, `touch`, `cp`, `mv`
- ❌ All other tmux commands (new-session, send-keys, etc.)
- ❌ File edits via Edit tool
- ❌ Most web fetching

## Options

---

### Option A: Minimal Expansion (Conservative)

Add only the most essential read-only commands.

```json
{
  "permissions": {
    "allow": [
      // Existing
      "WebSearch",
      "Bash(col:*)",
      "Bash(chmod:*)",
      "Bash(tmux display-message:*)",
      "Bash(tmux list-commands:*)",
      "Bash(tmux list-panes:*)",
      "Bash(tmux capture-pane:*)",
      "Bash(gh pr view:*)",
      "mcp__playwright__browser_navigate",
      "mcp__plugin_compound-engineering_context7__query-docs",
      "mcp__plugin_compound-engineering_context7__resolve-library-id",
      "Skill(ascii-animation)",
      "WebFetch(domain:deepwiki.com)",

      // NEW: Read-only git
      "Bash(git status:*)",
      "Bash(git diff:*)",
      "Bash(git log:*)",
      "Bash(git branch:*)",
      "Bash(git show:*)",

      // NEW: Basic inspection
      "Bash(ls:*)",
      "Bash(pwd)",
      "Bash(which:*)",
      "Bash(head:*)",
      "Bash(tail:*)",
      "Bash(wc:*)"
    ],
    "deny": [],
    "ask": []
  }
}
```

**Pros:**
- Very safe - only read operations
- Still requires approval for any writes/modifications

**Cons:**
- Still many prompts for npm, file edits, git writes, tmux session management

---

### Option B: Development Workflow (Recommended)

Allow common development operations while blocking dangerous ones.

```json
{
  "permissions": {
    "allow": [
      // === WEB & MCP ===
      "WebSearch",
      "WebFetch(domain:deepwiki.com)",
      "WebFetch(domain:github.com)",
      "WebFetch(domain:npmjs.com)",
      "WebFetch(domain:docs.anthropic.com)",
      "mcp__playwright__browser_navigate",
      "mcp__plugin_compound-engineering_context7__query-docs",
      "mcp__plugin_compound-engineering_context7__resolve-library-id",
      "Skill(ascii-animation)",

      // === GIT (all common operations) ===
      "Bash(git status:*)",
      "Bash(git diff:*)",
      "Bash(git log:*)",
      "Bash(git branch:*)",
      "Bash(git show:*)",
      "Bash(git add:*)",
      "Bash(git commit:*)",
      "Bash(git stash:*)",
      "Bash(git checkout:*)",
      "Bash(git switch:*)",
      "Bash(git fetch:*)",
      "Bash(git pull:*)",
      "Bash(git merge:*)",
      "Bash(git rebase:*)",
      "Bash(git worktree:*)",

      // === NPM/NODE ===
      "Bash(npm run:*)",
      "Bash(npm test:*)",
      "Bash(npm install:*)",
      "Bash(npm ci:*)",
      "Bash(npm build:*)",
      "Bash(npx:*)",
      "Bash(node:*)",

      // === TMUX (full control for this project) ===
      "Bash(tmux:*)",

      // === FILE INSPECTION ===
      "Bash(ls:*)",
      "Bash(pwd)",
      "Bash(which:*)",
      "Bash(head:*)",
      "Bash(tail:*)",
      "Bash(wc:*)",
      "Bash(file:*)",
      "Bash(stat:*)",
      "Bash(tree:*)",

      // === SAFE FILE OPS ===
      "Bash(mkdir:*)",
      "Bash(touch:*)",
      "Bash(cp:*)",
      "Bash(mv:*)",
      "Bash(chmod:*)",
      "Bash(col:*)",

      // === GITHUB CLI ===
      "Bash(gh:*)",

      // === FILE EDITING ===
      "Edit(./bin/**)",
      "Edit(./config/**)",
      "Edit(./docs/**)",
      "Edit(./.claude/**)",
      "Edit(./plans/**)",
      "Edit(./todos/**)",
      "Edit(./README.md)",
      "Edit(./CLAUDE.md)"
    ],
    "deny": [
      // Block dangerous operations
      "Bash(rm -rf:*)",
      "Bash(sudo:*)",
      "Bash(curl:*)",
      "Bash(wget:*)",
      "Bash(git push --force:*)",
      "Bash(git reset --hard:*)",
      "Read(./.env*)",
      "Read(./secrets/**)",
      "Read(~/.ssh/**)",
      "Read(~/.aws/**)"
    ],
    "ask": [
      // Require confirmation for these
      "Bash(git push:*)",
      "Bash(rm:*)"
    ]
  }
}
```

**Pros:**
- Smooth development workflow - most tasks just work
- Explicit deny list blocks dangerous operations
- Push and delete require confirmation (safety net)
- File edits scoped to project directories

**Cons:**
- More permissive - relies on deny list for safety
- Full tmux access (but this is your project's purpose)

---

### Option C: Maximum Productivity (Trust Mode)

Allow almost everything, deny only the dangerous.

```json
{
  "permissions": {
    "allow": [
      "WebSearch",
      "WebFetch(domain:*)",
      "Bash(*)",
      "Edit(./**)",
      "Read(./**)",
      "mcp__*"
    ],
    "deny": [
      "Bash(rm -rf:*)",
      "Bash(sudo:*)",
      "Bash(curl -X POST:*)",
      "Bash(wget:*)",
      "Bash(git push --force:*)",
      "Bash(git reset --hard:*)",
      "Read(./.env*)",
      "Read(~/.ssh/**)",
      "Read(~/.aws/**)",
      "Read(~/.config/gh/**)"
    ],
    "ask": [
      "Bash(git push:*)",
      "Bash(rm:*)",
      "Bash(npm publish:*)"
    ]
  }
}
```

**Pros:**
- Near-zero permission prompts
- Deny list still protects critical operations

**Cons:**
- Very permissive - mistakes have consequences
- Relies heavily on deny list being comprehensive

---

## Recommendation

**Option B (Development Workflow)** strikes the best balance:

1. ✅ Allows all common dev tasks without prompts
2. ✅ Full tmux control (essential for this project)
3. ✅ Git operations flow smoothly (but push needs confirmation)
4. ✅ Explicit deny list blocks dangerous commands
5. ✅ File edits scoped to project directories only

## Acceptance Criteria

- [ ] Update `.claude/settings.local.json` with chosen option
- [ ] Test common workflows work without prompts:
  - [ ] `git status`, `git diff`, `git add`, `git commit`
  - [ ] `npm run`, `npm test`
  - [ ] tmux session creation and management
  - [ ] File editing in project directories
- [ ] Verify blocked operations actually block:
  - [ ] `rm -rf` denied
  - [ ] `.env` file access denied
  - [ ] `git push` asks for confirmation

## References

- Current config: `.claude/settings.local.json:1-21`
- Claude Code permissions docs: https://docs.anthropic.com/claude-code/permissions
- Claude Code sandbox docs: https://docs.anthropic.com/claude-code/sandboxing
