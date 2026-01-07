---
status: pending
priority: p2
issue_id: "004"
tags: [code-review, agent-native, architecture]
dependencies: ["002"]
---

# No Machine-Readable Output Format

## Problem Statement

All command output is human-readable with colors and formatting, making it difficult for agents to reliably parse status, pane lists, or session information. Agents need structured output to make decisions.

**Why it matters:** AI agents running in the toolkit need to query system state programmatically. Without structured output, agents must use fragile regex parsing or guess at state.

## Findings

**Location:** `bin/agent-manage` (entire file)

**Current output format (cmd_status, lines 61-86):**
```
=== TMUX Agent Status ===

Sessions:
  → agents (2 windows, attached)

Panes in 'agents':
  0: PLAN (80x24) [ACTIVE]
  1: WORK (80x24)
  2: REVIEW (80x24)

Total panes: 3
```

**Problems:**
- ANSI color codes embedded in output
- Variable formatting and whitespace
- No consistent delimiter structure
- Status indicators mixed with data

**Agent needs:**
```json
{
  "sessions": [{"name": "agents", "windows": 2, "attached": true}],
  "panes": [
    {"index": 0, "title": "PLAN", "active": true, "width": 80, "height": 24}
  ]
}
```

## Proposed Solutions

### Option A: Add --format Flag (Recommended)
**Description:** Add `--format json|tsv|plain` flag to all listing commands.

```bash
agent-manage status --format json
agent-manage list --format tsv
agent-manage status --format plain  # no colors
```

**Implementation:**
```bash
cmd_status() {
    local format="${FORMAT:-human}"

    if [[ "$format" == "json" ]]; then
        output_status_json
    elif [[ "$format" == "tsv" ]]; then
        output_status_tsv
    else
        output_status_human  # existing colored output
    fi
}

output_status_json() {
    echo "{"
    echo "  \"session\": \"$SESSION_NAME\","
    echo "  \"panes\": ["
    tmux list-panes -t "$SESSION_NAME" -F '    {"index": #{pane_index}, "title": "#{pane_title}", "active": #{?pane_active,true,false}, "width": #{pane_width}, "height": #{pane_height}}' | paste -sd,
    echo "  ]"
    echo "}"
}
```

**Pros:**
- Clean API for agents
- Preserves human-friendly default
- Industry-standard formats

**Cons:**
- Significant code addition
- Must maintain multiple output paths

**Effort:** Medium-Large
**Risk:** Low

### Option B: Machine-Readable Mode via Environment Variable
**Description:** Use `AGENT_FORMAT=json` environment variable.

**Pros:**
- No CLI changes needed
- Easy to set once for all commands

**Cons:**
- Less discoverable
- Can't mix formats in same script

**Effort:** Medium
**Risk:** Low

## Recommended Action

**Option A** - Add `--format` flag. More explicit and standard.

## Technical Details

**Affected files:**
- `bin/agent-manage` - cmd_status, cmd_list

**Commands to update:**
1. `agent-manage status` - pane list with JSON/TSV
2. `agent-manage list` - session list with JSON/TSV

**JSON schema for status:**
```json
{
  "session": "string",
  "panes": [
    {
      "index": "number",
      "title": "string",
      "active": "boolean",
      "width": "number",
      "height": "number"
    }
  ]
}
```

## Acceptance Criteria

- [ ] `agent-manage status --format json` outputs valid JSON
- [ ] `agent-manage status --format tsv` outputs tab-separated values
- [ ] `agent-manage list --format json` outputs session array
- [ ] Default behavior unchanged (colored human output)
- [ ] Output can be piped to jq/awk without errors
- [ ] Document format options in help text

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-04 | Created finding from agent-native review | Agent-native tools need structured output |

## Resources

- Agent-Native reviewer analysis
- jq documentation for JSON format conventions
