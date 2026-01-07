# Research: Compound Engineering Plugin

**Research Date:** 2026-01-04
**Repository:** https://github.com/EveryInc/compound-engineering-plugin
**Version Analyzed:** 2.20.0

## Summary

The compound-engineering plugin is a comprehensive system for building "knowledge that compounds" through systematic engineering workflows. It orchestrates 27 agents, 20 commands, 13 skills, and 2 MCP servers to transform the traditional transactional AI coding pattern (prompt → code → ship → forget) into a compounding cycle where each unit of work makes subsequent work easier.

---

## 1. Core Workflow Commands Structure

### `/workflows:plan` - Feature Planning

**Location:** `plugins/compound-engineering/commands/workflows/plan.md`

**Purpose:** Transform feature descriptions into structured implementation plans

**Workflow Stages:**
1. **Feature Input** - Prompt user if description empty
2. **Parallel Research** - Run 3 agents simultaneously:
   - `repo-research-analyst` - Search codebase for patterns
   - `best-practices-researcher` - Web research for industry standards
   - `framework-docs-researcher` - Context7 MCP for framework docs
3. **Issue Planning** - Develop title, categorization, stakeholder analysis
4. **SpecFlow Analysis** - Validate specification completeness (uses `spec-flow-analyzer` agent)
5. **Detail Level Selection** - User chooses fidelity:
   - **MINIMAL** - Quick issues, bug fixes
   - **MORE** - Standard features, complex bugs
   - **A LOT** - Major features, architectural changes
6. **Issue Creation** - Apply markdown best practices, code examples
7. **Final Review** - Pre-submission quality checklist
8. **Post-Generation Options** - 7 choices including:
   - Open in editor
   - Deepen plan with more research
   - Review the plan
   - Start implementing
   - Create GitHub/Linear issue

**Output:** Plans saved to `plans/<issue_title>.md`

**Critical Constraint:** "NEVER CODE! Just research and write the plan."

**Key Insight:** This enforces the separation between planning and execution phases, preventing premature implementation.

---

### `/workflows:work` - Systematic Execution

**Location:** `plugins/compound-engineering/commands/workflows/work.md`

**Purpose:** Execute work plans efficiently with focus on shipping complete features

**Four Main Phases:**

#### Phase 1: Quick Start
- Read and clarify the plan
- Environment setup:
  - **Live branch** - For small changes
  - **Worktree** - For feature isolation (uses `git-worktree` skill)
- Create TodoWrite task list for tracking

#### Phase 2: Execute (Task Loop)
1. Mark task `in_progress` in TodoWrite
2. Reference similar code patterns from repo
3. Implement changes following existing conventions
4. Write tests continuously (not at end)
5. Track progress with work log updates

**Pattern Matching:** "When implementing, search for similar code first - follow existing patterns rather than inventing new ones"

#### Phase 3: Quality Check
- Run full test suite (unit + E2E)
- Run linting/formatting
- Optional review agents:
  - `code-simplicity-reviewer`
  - `kieran-rails-reviewer` (if Rails project)
  - `performance-oracle`
  - `security-sentinel`
  - `cora-test-reviewer`

**Quality Checklist:**
- All clarifications addressed
- All tasks completed
- Tests passing (unit + E2E)
- Linting clean
- Follows existing patterns
- Matches design (if UI changes)
- Documentation updated

#### Phase 4: Ship It
1. Create commit with conventional format
2. Capture UI screenshots (mandatory for design changes)
3. Create PR with before/after comparisons
4. Notify user with PR link

**Core Principles:**
- "Start fast, execute faster" - Don't seek perfect understanding upfront
- "Test continuously, not at the end"
- "Complete features fully before moving forward"

**Key Insight:** The TodoWrite tool is used for ephemeral session tracking, while the `file-todos` skill provides persistent project-level task management.

---

### `/workflows:review` - Multi-Agent Code Review

**Location:** `plugins/compound-engineering/commands/workflows/review.md`

**Purpose:** Exhaustive code reviews using multi-agent analysis, ultra-thinking, and git worktrees

**Process:**

#### Initial Setup
1. Determine review target (PR number, URL, branch name, or current)
2. Ensure correct branch for analysis
3. Offer git worktree for isolated inspection

#### Parallel Agent Analysis (13+ agents)

**Standard Agents (run simultaneously):**
- Rails specialists (`kieran-rails-reviewer`, `rails-8-upgrader`)
- Security expert (`security-sentinel`)
- Performance analyst (`performance-oracle`)
- Architecture reviewer (`architecture-strategist`)
- Code quality (`code-simplicity-reviewer`)
- Pattern recognition (`pattern-recognition-specialist`)
- Test quality (`cora-test-reviewer`)
- Data integrity (`data-integrity-guardian`)
- UI/UX reviewers
- Error handling (`error-handling-specialist`)

**Conditional Agents (auto-trigger based on PR content):**
- Database migration reviewer (if migrations detected)
- Data transformation validator (if data changes detected)

#### Ultra-Thinking Deep Dive

Structured cognitive phases examining:
- **Stakeholder perspectives:**
  - Developer (maintainability, debuggability)
  - Operations (deployment, monitoring)
  - End-user (UX, performance)
  - Security (threat vectors)
  - Business (value, risk)

- **Scenario exploration:**
  - Edge cases and boundary conditions
  - Concurrent access patterns
  - Scale testing (10x, 100x load)
  - Failure modes and recovery

- **Multi-angle review:**
  - Technical excellence
  - Business value alignment
  - Risk management
  - Team dynamics impact

#### Findings Management

**Critical Feature:** "ALL findings MUST be stored in the todos/ directory using the file-todos skill"

This is different from presenting findings sequentially for approval - it accelerates review-to-action pipeline by creating trackable todos immediately.

**Severity Classification:**
- 🔴 **P1 (Critical)** - Security vulnerabilities, data corruption risks - **BLOCKS MERGE**
- 🟡 **P2 (Important)** - Performance issues, architectural concerns
- 🔵 **P3 (Nice-to-Have)** - Minor improvements, cleanup

#### Optional E2E Testing

Detects project type and offers appropriate testing:
- **Web projects** - Playwright browser tests
- **iOS projects** - Xcode simulator tests
- **Hybrid** - Both test suites

**Key Constraint:** "P1 Findings Block Merge" - Critical issues must be resolved before PR acceptance.

**Key Insight:** The use of `file-todos` skill for findings creates a persistent record that survives the review session, enabling async resolution and tracking.

---

### `/workflows:compound` - Knowledge Capture

**Location:** `plugins/compound-engineering/commands/workflows/compound.md`

**Purpose:** Document recently solved problems to build team knowledge

**Core Function:** "Coordinate multiple subagents working in parallel to document a recently solved problem"

**Output:** Solutions saved to `docs/solutions/` with searchable YAML frontmatter

#### Six Primary Parallel Subagents

All run simultaneously:

1. **Context Analyzer**
   - Extracts conversation history
   - Identifies problem characteristics
   - Determines scope and impact

2. **Solution Extractor**
   - Analyzes investigation steps taken
   - Documents root cause discovery
   - Captures solution approach

3. **Related Docs Finder**
   - Searches existing documentation
   - Identifies cross-references
   - Links related problems/solutions

4. **Prevention Strategist**
   - Develops prevention strategies
   - Creates test cases for regression prevention
   - Suggests monitoring/alerting

5. **Category Classifier**
   - Determines optimal documentation category
   - Generates appropriate filename
   - Assigns searchable tags

6. **Documentation Writer**
   - Assembles final markdown file
   - Validates completeness
   - Ensures YAML frontmatter correctness

#### Auto-Triggering Specialized Agents

Additional agents invoke based on detected problem type:

| Problem Type | Agent Triggered |
|--------------|-----------------|
| Performance issues | `performance-oracle` |
| Security issues | `security-sentinel` |
| Database issues | `data-integrity-guardian` |
| Test failures | `cora-test-reviewer` |
| Code-heavy issues | `kieran-rails-reviewer`, `code-simplicity-reviewer` |

#### Documentation Categories (Auto-detected)

Nine standard categories:
- `build-errors`
- `test-failures`
- `runtime-errors`
- `performance-issues`
- `database-issues`
- `security-issues`
- `ui-bugs`
- `integration-issues`
- `logic-errors`

#### Knowledge Compounding Philosophy

The workflow embodies: "Each unit of engineering work should make subsequent units of work easier—not harder"

**Time Investment Pattern:**
- **First occurrence:** 2 hours investigation + 15 min documentation = 2h15m
- **Future occurrences:** 2 min lookup (99% time savings)

**Key Insight:** The parallel subagent architecture ensures comprehensive documentation without bottlenecking on sequential analysis. Each aspect (context, solution, prevention, categorization) is analyzed simultaneously.

---

## 2. Workflow Orchestration Structure

### Plugin Architecture

**Configuration:** `.claude-plugin/plugin.json`

```json
{
  "name": "compound-engineering",
  "version": "2.20.0",
  "description": "AI-powered development tools. 27 agents, 20 commands, 13 skills, 2 MCP servers",
  "author": "Kieran Klaassen (kieran@every.to)",
  "license": "MIT",
  "mcp_servers": {
    "pw": {
      "type": "stdio",
      "command": "npx -y @playwright/mcp@latest"
    },
    "context7": {
      "type": "http",
      "url": "https://mcp.context7.com/mcp"
    }
  }
}
```

### Three-Layer System

#### Layer 1: Agents (27 total)

**Organization:** `plugins/compound-engineering/agents/`

Five categories:

1. **review/** (14 agents)
   - Code quality, security, performance, architecture validation
   - Examples: `security-sentinel`, `performance-oracle`, `code-simplicity-reviewer`

2. **research/** (4 agents)
   - Documentation and pattern analysis
   - Examples: `repo-research-analyst`, `best-practices-researcher`, `framework-docs-researcher`

3. **design/** (3 agents)
   - UI/design implementation verification

4. **workflow/** (5 agents)
   - Bug handling and content management
   - Examples: `spec-flow-analyzer`, `bug-reproduction-validator`, `pr-comment-resolver`

5. **docs/** (1 agent)
   - Documentation generation

**Agent Structure Pattern (from `spec-flow-analyzer.md`):**

```markdown
## Core Purpose
[What the agent does]

## Activation Triggers
- User presents [trigger condition 1]
- User requests [trigger condition 2]
- Before [event] begins

## Analysis Phases
1. [Phase 1 name] ([specific activities])
2. [Phase 2 name] ([specific activities])
3. [Phase 3 name] ([specific activities])

## Output Organization
- [Section 1] with [specific format]
- [Section 2] with [specific format]
- [Section 3] organized by [category]

## Design Philosophy
The agent operates as [adjective], thinking like [perspective],
prioritizing [focus area], asking [question type], and providing
[output type] to [achieve goal].
```

**Key Pattern:** Each agent has:
- Clear activation triggers
- Structured analysis phases
- Standardized output format
- Explicit design philosophy

#### Layer 2: Commands (20 total)

**Organization:** `plugins/compound-engineering/commands/`

Two types:

1. **Workflow Commands** (`commands/workflows/`)
   - `plan.md` - Planning workflow
   - `work.md` - Execution workflow
   - `review.md` - Review workflow
   - `compound.md` - Knowledge capture workflow

2. **Utility Commands** (`commands/`)
   - `deepen-plan.md` - Enhance plans with parallel research
   - `plan_review.md` - Multi-agent plan review
   - `resolve_parallel.md` - Parallel TODO resolution
   - `resolve_pr_parallel.md` - Parallel PR comment resolution
   - `resolve_todo_parallel.md` - Parallel CLI todo resolution
   - `playwright-test.md` - Browser testing
   - `xcode-test.md` - iOS testing
   - `changelog.md` - Generate changelogs
   - `triage.md` - Categorize findings
   - Others...

**Command Structure Pattern:**

Commands are markdown files that expand into prompts when invoked. They:
- Define clear objectives
- Specify which agents to run (often in parallel)
- Provide step-by-step workflows
- Include quality checklists
- Define output formats and locations

#### Layer 3: Skills (13 total)

**Organization:** `plugins/compound-engineering/skills/`

Each skill is a directory with `SKILL.md`:

**Framework/Language Skills:**
- `dhh-rails-style/` - Rails development patterns
- `dhh-ruby-style/` - Ruby coding style
- `andrew-kane-gem-writer/` - Ruby gem patterns
- `dspy-ruby/` - LLM application framework

**Workflow Skills:**
- `file-todos/` - Persistent todo management
- `git-worktree/` - Branch isolation
- `compound-docs/` - Solution documentation

**Domain Skills:**
- `frontend-design/` - UI implementation
- `agent-native-architecture/` - Prompt-native systems
- `create-agent-skills/` - Skill creation guidance
- `skill-creator/` - Skill scaffolding
- `every-style-editor/` - Writing style guide

**Infrastructure Skills:**
- `gemini-imagegen/` - Image generation via Gemini API

**Skill Structure Pattern (from `file-todos/SKILL.md`):**

```markdown
## Core Structure
[File naming patterns, directory organization]

## Key Components
[Required sections, YAML frontmatter format]

## Workflow Integration
| Trigger | Outcome |
|---------|---------|
| [Event 1] | [Result 1] |
| [Event 2] | [Result 2] |

## Key Practices
[Critical usage patterns]
```

**Key Pattern:** Skills embed domain expertise that can be:
- Invoked via Skill tool
- Referenced by agents
- Applied automatically by commands

### MCP Server Integration

**Playwright (pw):**
- Provides browser automation
- Used by `playwright-test` command
- Enables E2E testing in review workflow

**Context7:**
- Provides framework documentation lookup
- Used by `framework-docs-researcher` agent
- Supports 100+ frameworks (Rails, React, Next.js, Vue, Django, Laravel, etc.)

**Auto-start:** "MCP Servers start automatically when the plugin is enabled"

---

## 3. Handoff Patterns Between Phases

### Research → Planning Handoff

**Pattern:** Parallel research with standardized output structure

**Example from `/workflows:plan`:**

```markdown
# Step 1: Run Research Agents (Parallel)
- repo-research-analyst
- best-practices-researcher
- framework-docs-researcher

# Step 2: Synthesize into Plan
[Use standardized research outputs to inform plan sections]
```

**Standardized Research Output (from `repo-research-analyst.md`):**

```markdown
## Architecture & Structure
[Organization, decisions, tech stack]

## Issue Conventions
[Formats, labels, common types]

## Documentation Insights
[Guidelines, standards, requirements]

## Templates Found
[Locations, fields, usage]

## Implementation Patterns
[Code patterns, naming, practices]

## Recommendations
[Alignment strategies, next steps]
```

**Key Insight:** Each research agent outputs to standardized sections that can be directly integrated into planning documents.

### Planning → Execution Handoff

**Pattern:** TodoWrite for session tracking + file-todos for persistent tracking

**From `/workflows:work` Phase 1:**

```markdown
1. Read the plan
2. Create TodoWrite task list (ephemeral session tracking)
3. Set up environment (branch or worktree)
4. Start execution loop
```

**Task Loop Pattern:**

```markdown
For each task:
1. Mark in_progress in TodoWrite
2. Reference similar code patterns
3. Implement
4. Test continuously
5. Update work log in file-todos (if using persistent tracking)
6. Mark complete in TodoWrite
```

**Key Insight:** Dual tracking system:
- **TodoWrite** - Temporary, in-session progress tracking
- **file-todos** - Permanent, cross-session task management

### Execution → Review Handoff

**Pattern:** Git state + automated test results + quality checklist

**From `/workflows:work` Phase 3:**

```markdown
Quality Checklist:
- [ ] All clarifications addressed
- [ ] All tasks completed
- [ ] Tests passing (unit + E2E)
- [ ] Linting clean
- [ ] Follows existing patterns
- [ ] Matches design
- [ ] Documentation updated
```

**Then `/workflows:review` consumes:**
- Branch/PR to review
- Test results from execution
- Code changes in git

**Review Output → file-todos:**

```markdown
# All findings stored as todos in todos/ directory
# Format: {issue_id}-{status}-{priority}-{description}.md

Example:
todos/123-pending-p1-fix-sql-injection-in-search.md
```

**Key Insight:** The review workflow doesn't wait for human approval on each finding - it immediately creates trackable todos that can be triaged and resolved asynchronously.

### Review → Knowledge Capture Handoff

**Pattern:** Conversation context + git history + solution artifacts

**From `/workflows:compound`:**

```markdown
# Context Analyzer reads:
- Conversation history
- Problem characteristics
- Investigation steps taken

# Solution Extractor reads:
- Git commits from fix
- Code changes made
- Test cases added

# Related Docs Finder reads:
- Existing docs/solutions/
- YAML frontmatter for similar problems

# Output: docs/solutions/{category}/{descriptive-name}.md
```

**Solution File Structure:**

```yaml
---
title: "Descriptive problem title"
category: "runtime-errors"
tags: ["tag1", "tag2", "tag3"]
date: "2026-01-04"
severity: "high"
time_to_resolve: "2h"
---

## Problem
[What went wrong]

## Root Cause
[Why it happened]

## Solution
[How it was fixed]

## Prevention
[How to avoid in future]

## Related
- [Link to similar solution 1]
- [Link to similar solution 2]
```

**Key Insight:** The YAML frontmatter makes solutions searchable by category, tags, and severity, enabling rapid lookup in future similar situations.

---

## 4. Automation Patterns for the Compound Loop

### Pattern 1: Parallel Agent Execution

**Used in:** `/workflows:plan`, `/workflows:review`, `/workflows:compound`, `deepen-plan`

**Implementation Pattern:**

```markdown
# Launch all agents simultaneously
Run in parallel:
- agent-1
- agent-2
- agent-3
- agent-N

# Collect outputs
Wait for all agents to complete

# Synthesize
Merge agent outputs into final deliverable
```

**Example from `deepen-plan`:**

```markdown
## Parallel Research Coordination

1. **Extract plan sections** → section manifest
2. **Discover all skills** (project + user + plugins)
3. **Spawn skill sub-agents** (one per skill, all parallel)
4. **Spawn explore agents** (one per section, all parallel)
5. **Run all review agents** (explicitly: "Do NOT filter - run them ALL")
6. **Collect and synthesize** → enhanced plan
```

**Key Features:**
- No limit on parallelization
- No relevance filtering ("run them ALL")
- Synthesis happens after all agents complete

### Pattern 2: Dependency-Aware Sequential Execution

**Used in:** `resolve_parallel`

**Implementation Pattern:**

```markdown
# Stage 1: Analysis
Identify all work items

# Stage 2: Planning
Create mermaid flow diagram showing dependencies

# Stage 3: Parallel Implementation
For independent items:
  Spawn resolver agent in parallel

For dependent items:
  Execute sequentially respecting dependency order

# Stage 4: Finalization
Commit and push
```

**Key Insight:** Planning phase identifies dependencies to enable maximum parallelization while respecting constraints.

### Pattern 3: Auto-Triggered Conditional Agents

**Used in:** `/workflows:review`, `/workflows:compound`

**Implementation Pattern:**

```markdown
# Always run base agents
Run standard agent set

# Conditionally trigger specialists
IF PR contains database migrations THEN
  Run database-migration-reviewer

IF PR contains data transformations THEN
  Run data-transformation-validator

IF problem is performance-related THEN
  Run performance-oracle
```

**Key Features:**
- Context-aware agent selection
- Automatic specialization based on content
- No manual agent selection required

### Pattern 4: Progressive Enhancement

**Used in:** `deepen-plan`

**Implementation Pattern:**

```markdown
# Base plan exists
Read existing plan structure

# Layer 1: Skill Application
Apply all available skills to relevant sections

# Layer 2: Institutional Knowledge
Integrate past learnings from docs/solutions/

# Layer 3: External Research
Add best practices from web + framework docs

# Layer 4: Review Perspective
Run all review agents for critique

# Synthesis
Merge all layers into enhanced plan
```

**Key Insight:** Each layer adds depth without replacing previous layers - knowledge compounds through addition, not replacement.

### Pattern 5: Persistent State Management

**Used in:** `file-todos` skill, `compound-docs` skill

**Implementation Pattern:**

**file-todos:**
```markdown
# File-based state (survives sessions)
todos/{issue_id}-{status}-{priority}-{description}.md

# Status transitions
pending → ready → complete

# Work log accumulation
Each work session appends to log chronologically

# Cross-reference tracking
Dependencies stored in YAML frontmatter
```

**compound-docs:**
```markdown
# Solution library (grows over time)
docs/solutions/{category}/{problem-name}.md

# Searchable metadata
YAML frontmatter with tags, category, severity

# Cross-linking
Related solutions linked in metadata
```

**Key Features:**
- Survives session boundaries
- Searchable via filesystem and YAML
- Accumulates rather than replaces
- Git-trackable for team sharing

### Pattern 6: Quality Gates with Checklists

**Used in:** `/workflows:plan`, `/workflows:work`, `/workflows:review`

**Implementation Pattern:**

```markdown
# Before proceeding to next phase
Quality Checklist:
- [ ] Criterion 1 met
- [ ] Criterion 2 verified
- [ ] Criterion 3 validated

# Block progression if criteria not met
IF any criterion fails THEN
  Address failure before proceeding
```

**Examples:**

**Plan Quality Gate:**
- [ ] Research complete
- [ ] SpecFlow analysis done
- [ ] Acceptance criteria defined
- [ ] Implementation approach clear

**Work Quality Gate:**
- [ ] All tasks completed
- [ ] Tests passing
- [ ] Linting clean
- [ ] Patterns followed

**Review Quality Gate:**
- [ ] All P1 findings resolved
- [ ] P2 findings triaged
- [ ] Tests passing
- [ ] Documentation updated

**Key Insight:** Explicit quality gates prevent premature phase transitions and ensure completeness.

---

## 5. Key Takeaways for Agent-Tmux-Toolkit

### Architectural Patterns to Adopt

1. **Separation of Concerns**
   - Planning never codes
   - Execution follows plans
   - Review creates trackable todos
   - Compound documents learnings

2. **Parallel-First Execution**
   - Default to parallel agent execution
   - Use dependency analysis for sequencing
   - "Run them ALL" approach for comprehensive coverage

3. **Standardized Output Formats**
   - Research agents → structured sections
   - Review agents → severity-classified findings
   - Solutions → YAML frontmatter + markdown

4. **Persistent Knowledge Layer**
   - `file-todos/` for trackable work
   - `docs/solutions/` for institutional knowledge
   - Git-tracked for team sharing

5. **Progressive Enhancement**
   - Base → Skills → Learnings → Research → Review
   - Each layer adds without replacing

6. **Quality Gates**
   - Explicit checklists between phases
   - Blocking P1 findings
   - Pre-submission validation

### Workflow Orchestration to Implement

1. **Command Structure**
   - Markdown files that expand to prompts
   - Clear phase definitions
   - Explicit agent invocations
   - Standardized output locations

2. **Agent Coordination**
   - Parallel execution where possible
   - Auto-triggering based on context
   - Standardized input/output contracts

3. **Handoff Mechanisms**
   - File-based state for persistence
   - TodoWrite for ephemeral tracking
   - Git for version control
   - YAML for metadata/search

4. **Automation Hooks**
   - Conditional agent triggering
   - Dependency-aware scheduling
   - Progressive enhancement loops

### Tmux Integration Opportunities

1. **Multi-Pane Agent Execution**
   - One tmux pane per parallel agent
   - Visual progress monitoring
   - Session persistence across disconnects

2. **Phase-Based Window Management**
   - Window 1: Planning agents
   - Window 2: Execution loop
   - Window 3: Review agents
   - Window 4: Knowledge capture

3. **Persistent State via Tmux Sessions**
   - Named sessions per workflow phase
   - Session groups for related work
   - Resurrection for crash recovery

4. **Status Bar Integration**
   - Active phase indicator
   - Agent completion count
   - Quality gate status

---

## 6. Implementation Recommendations

### For Agent-Tmux-Toolkit

1. **Adopt the 4-Phase Workflow Structure**
   ```
   /plan → /work → /review → /compound
   ```

2. **Implement Parallel Agent Execution in Tmux**
   - Use tmux panes for visual agent monitoring
   - Collect outputs via shared state files
   - Synthesize in main pane

3. **Create Persistent State System**
   - `todos/` directory for trackable work
   - `docs/solutions/` for knowledge base
   - YAML frontmatter for searchability

4. **Standardize Agent Output Formats**
   - Define sections per agent type
   - Require structured outputs
   - Enable programmatic synthesis

5. **Build Quality Gate System**
   - Pre-phase checklists
   - Blocking criteria (P1 findings)
   - Automated validation where possible

6. **Enable Progressive Enhancement**
   - Base plan → enhanced plan loop
   - Layer skills, learnings, research
   - Preserve rather than replace

---

## Sources

- [GitHub Repository](https://github.com/EveryInc/compound-engineering-plugin)
- [Plugin README](https://github.com/EveryInc/compound-engineering-plugin/blob/main/README.md)
- [CLAUDE.md](https://github.com/EveryInc/compound-engineering-plugin/blob/main/CLAUDE.md)
- [Compound Engineering Article](https://every.to/chain-of-thought/compound-engineering-how-every-codes-with-agents)
- [Plugin Components](https://github.com/EveryInc/compound-engineering-plugin/tree/main/plugins/compound-engineering)
- [Workflow Commands](https://github.com/EveryInc/compound-engineering-plugin/tree/main/plugins/compound-engineering/commands/workflows)
- [Agents Directory](https://github.com/EveryInc/compound-engineering-plugin/tree/main/plugins/compound-engineering/agents)
- [Skills Directory](https://github.com/EveryInc/compound-engineering-plugin/tree/main/plugins/compound-engineering/skills)
