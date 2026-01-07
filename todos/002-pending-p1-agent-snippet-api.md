---
status: pending
priority: p1
issue_id: "002"
tags: [code-review, agent-native, architecture]
dependencies: []
---

# Agents Cannot Send Snippets Programmatically

## Problem Statement

The snippet system relies entirely on fzf interactive selection with no programmatic alternative. AI agents running in tmux panes cannot invoke snippets at all, breaking the core use case of the toolkit (parallel AI agents).

**Why it matters:** This is a fundamental architecture gap. The toolkit is designed for AI agents but its signature feature (snippets) is inaccessible to them. Agents are ~40% less capable than human users.

## Findings

**Location:** `bin/snippet-picker:134-196` (entire selection flow)

**Current Flow:**
1. User presses Option+A
2. fzf folder picker appears (requires human interaction)
3. fzf snippet picker appears (requires human interaction)
4. Selected text sent to current pane

**Agent Capability:** Zero - agents cannot:
- List available snippets
- Select a snippet by name
- Send snippet content to a specific pane
- Query snippet folders/categories

**Evidence from agent-native review:**
- 4 of 16 capabilities are completely inaccessible to agents
- Snippet system accounts for 3 of these gaps
- No CLI flags or environment variables to bypass fzf

## Proposed Solutions

### Option A: Add `snippet-send` Command (Recommended)
**Description:** Create a new script that sends snippets by label without fzf.

```bash
#!/bin/bash
# snippet-send - Send snippet to pane (agent-friendly)
# Usage: snippet-send <label> [--to <pane>] [--list] [--format json]

snippet-send "Commit"                    # send to current pane
snippet-send "Plan" --to agents.0        # send to specific pane
snippet-send --list                      # list all snippet labels
snippet-send --list --folder WORK        # list snippets in folder
snippet-send --list --format json        # machine-readable output
```

**Pros:**
- Clean API for agents
- Preserves existing human UX (fzf remains for Option+A)
- Enables automation and scripting
- Machine-readable output modes

**Cons:**
- New script to maintain
- Must keep parsing logic in sync with snippet-picker

**Effort:** Medium (new 50-80 line script)
**Risk:** Low

### Option B: Add CLI Flags to snippet-picker
**Description:** Add flags like `--send <label>` to existing script.

```bash
snippet-picker                       # interactive mode (default)
snippet-picker --send "Commit"       # non-interactive send
snippet-picker --list                # list snippets
```

**Pros:**
- Single script to maintain
- Reuses existing parsing logic

**Cons:**
- Makes snippet-picker more complex
- Mixes interactive and non-interactive concerns

**Effort:** Medium
**Risk:** Medium

### Option C: Parse Snippets File Directly via tmux
**Description:** Document that agents should parse snippets.txt and use `tmux send-keys` directly.

**Pros:**
- No code changes needed

**Cons:**
- Requires agents to understand file format
- Duplicates parsing logic
- No abstraction layer

**Effort:** Small (documentation only)
**Risk:** High (fragile)

## Recommended Action

**Option A** - Create dedicated `snippet-send` command. Clean separation of concerns, best agent UX.

## Technical Details

**New file:** `bin/snippet-send`

**Affected files:**
- `install.sh` (add new script to install)
- `README.md` (document new command)

**API Design:**
```bash
# Core operations
snippet-send <label>                 # send snippet by label
snippet-send <label> --to <pane>     # send to specific pane
snippet-send --list                  # list all snippets
snippet-send --list --folder <name>  # filter by folder
snippet-send --get <label>           # print content without sending

# Output formats
snippet-send --list --format json    # JSON array
snippet-send --list --format tsv     # tab-separated

# Error handling
snippet-send "NotFound"              # exit 1, stderr: ERROR:SNIPPET_NOT_FOUND
```

## Acceptance Criteria

- [ ] `snippet-send <label>` sends snippet to current pane
- [ ] `snippet-send <label> --to <pane>` sends to specific pane
- [ ] `snippet-send --list` outputs all snippet labels
- [ ] `snippet-send --list --format json` outputs structured data
- [ ] `snippet-send --get <label>` prints content without sending
- [ ] Error messages are machine-parseable
- [ ] Script is installed by `install.sh`
- [ ] README documents the new command
- [ ] Agents can successfully use the command

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-04 | Created finding from agent-native review | Interactive-only features break agent accessibility |

## Resources

- Agent-Native reviewer analysis
- Existing snippet-picker parsing logic at lines 26-91
