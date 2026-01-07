# Add Vibeship Mind & Spawner Snippets

## Overview

Add snippets to the agent-tmux-toolkit for quickly starting and using Vibeship's Mind (persistent memory) and Spawner (expert skills MCP) tools. Both CLI and interactive menu (Meta+S) will have access to these snippets.

## Problem Statement

Users of agent-tmux-toolkit who also use Vibeship's tools need quick access to:
1. **Mind** - Persistent memory system that maintains context across Claude sessions
2. **Spawner** - MCP server that equips Claude with stack-aware expert skills

Currently, users must remember installation commands and usage patterns manually.

## Proposed Solution

Add a new `VIBESHIP` folder to `config/snippets.txt` containing snippets for both tools.

## Acceptance Criteria

- [ ] New `# ═══ VIBESHIP ═══` folder in snippets.txt
- [ ] Snippets for Mind initialization and usage
- [ ] Snippets for Spawner installation and usage
- [ ] Each snippet includes a brief example after the command
- [ ] Snippets work in both interactive (Meta+S) and CLI modes

## MVP

### config/snippets.txt (additions)

```
# ═══ VIBESHIP ═══
Mind: Init
pip install vibeship-mind && python -m mind init

Then tell Claude: "Add Mind MCP server to my config. Use command 'python' with args ['-m', 'mind', 'mcp']"
---
Mind: Recall
Use mind_recall() to load my session context and previous learnings.
---
Mind: Log Learning
Use mind_log() to record this to my persistent memory for future sessions.
---
Mind: Set Reminder
Use mind_remind() to set a reminder - can be time-based ("tomorrow", "in 3 days") or context-triggered ("when I mention auth").
---
Mind: Check Edges
Use mind_edges() to check for potential gotchas before we start coding this feature.
---
Spawner: Install
claude mcp add spawner -- npx -y mcp-remote https://mcp.vibeship.co

Verify with /mcp in Claude Code.
---
Spawner: Plan New Project
I want to build [describe your idea]. Use spawner_plan to help me get started with the right stack and approach.
---
Spawner: Analyze Codebase
Analyze this codebase with spawner_analyze and load the right skills for my tech stack.
---
Spawner: Load Skills
Use spawner to load skills for [Next.js/Supabase/Stripe/etc]. Check for any sharp edges or anti-patterns.
---
```

## Implementation Tasks

1. **Edit `config/snippets.txt`** - Add new VIBESHIP folder with 9 snippets
2. **Test interactive mode** - Press Meta+S, navigate to VIBESHIP folder, verify snippets display correctly
3. **Test CLI mode** - Run `snippet-send --list | grep -i vibeship` to verify snippets are parsed

## References

- Vibeship Mind: https://mind.vibeship.co/#get-started
- Vibeship Spawner: https://spawner.vibeship.co/
- Snippet format: `config/snippets.txt:1-9`
- Snippet picker: `bin/snippet-picker`
- Snippet CLI: `bin/snippet-send`
