# feat: Add Open Source Community Documentation

## Overview

Add community engagement documentation to make it easy for open source contributors to discover, understand, and contribute to the Agent Tmux Toolkit project.

**Current State:** The project has excellent technical documentation (README, LEARNINGS.md, research files) but **zero community/contribution infrastructure** - no templates, guidelines, or onboarding documentation despite being an MIT-licensed open source project.

## Problem Statement

Contributors currently face these barriers:
1. No guidance on how to contribute (no CONTRIBUTING.md)
2. No issue templates to report bugs or request features
3. No PR template to guide submissions
4. No code of conduct establishing community standards
5. No security policy for vulnerability reporting
6. README lacks a "Contributing" section with calls-to-action
7. 14 pending todos that could be labeled as "good first issues" but aren't discoverable

## Proposed Solution

Create a complete community documentation suite following GitHub best practices:

```
.github/
├── ISSUE_TEMPLATE/
│   ├── bug_report.yml
│   ├── feature_request.yml
│   └── config.yml
├── PULL_REQUEST_TEMPLATE.md
└── FUNDING.yml (optional)
CONTRIBUTING.md
CODE_OF_CONDUCT.md
SECURITY.md
README.md (add Contributing section)
```

## Technical Approach

### Phase 1: Core Documentation

#### 1.1 CONTRIBUTING.md

```markdown
# Contributing to Agent Tmux Toolkit

Thank you for your interest in contributing! We welcome contributions of all types.

## Quick Start

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/agent-tmux-toolkit.git`
3. Run `./install.sh` to set up
4. Make your changes
5. Test manually with `agent-session`
6. Submit a pull request

## Development Requirements

- macOS or Linux (WSL2 on Windows)
- tmux 3.0+
- Bash 4.0+
- fzf
- git

## Ways to Contribute

### Report Bugs
Open an issue using the bug report template.

### Suggest Features
Open an issue using the feature request template.

### Submit Code
1. Check existing issues for something to work on
2. Comment "I'd like to work on this" to claim it
3. Fork, branch, implement, test
4. Submit PR with clear description

### Improve Documentation
- Fix typos, clarify explanations
- Add examples or use cases
- No issue needed - just submit a PR

## Coding Conventions

### Shell Scripts
- Use `#!/usr/bin/env bash` shebang
- Run `shellcheck` before submitting
- Use meaningful variable names
- Comment complex logic
- Follow existing patterns in `bin/agent-common.sh`

### Git Commits
- Present tense: "Add feature" not "Added feature"
- Reference issues: "Fix pane selection (#123)"
- Keep commits focused and atomic

## Getting Help

- Open a GitHub Discussion for questions
- Check existing issues for similar problems
- Read the README and LEARNINGS.md for context
```

#### 1.2 CODE_OF_CONDUCT.md

Use Contributor Covenant v2.1 (industry standard).

#### 1.3 SECURITY.md

```markdown
# Security Policy

## Reporting a Vulnerability

Please report security vulnerabilities via GitHub Security Advisories:
https://github.com/barnierg76/agent-tmux-toolkit/security/advisories/new

**Do not open public issues for security vulnerabilities.**

## Response Timeline

- Acknowledgment: Within 72 hours
- Initial assessment: Within 7 days
- Fix timeline: Depends on severity

## Scope

This policy covers:
- The shell scripts in `bin/`
- The tmux configuration in `config/`
- The installation script
```

### Phase 2: Issue & PR Templates

#### 2.1 Bug Report Template (.github/ISSUE_TEMPLATE/bug_report.yml)

```yaml
name: Bug Report
description: Report something that isn't working
labels: ["bug"]
body:
  - type: textarea
    id: description
    attributes:
      label: What happened?
      placeholder: Describe the bug
    validations:
      required: true
  - type: textarea
    id: expected
    attributes:
      label: What did you expect?
  - type: textarea
    id: reproduce
    attributes:
      label: Steps to reproduce
      placeholder: |
        1. Run `agent-session`
        2. Press Option+S
        3. See error
  - type: input
    id: tmux-version
    attributes:
      label: tmux version
      placeholder: "tmux -V output"
  - type: dropdown
    id: os
    attributes:
      label: Operating System
      options:
        - macOS
        - Linux
        - WSL2
```

#### 2.2 Feature Request Template (.github/ISSUE_TEMPLATE/feature_request.yml)

```yaml
name: Feature Request
description: Suggest an improvement
labels: ["enhancement"]
body:
  - type: textarea
    id: problem
    attributes:
      label: What problem does this solve?
    validations:
      required: true
  - type: textarea
    id: solution
    attributes:
      label: Proposed solution
  - type: textarea
    id: alternatives
    attributes:
      label: Alternatives considered
```

#### 2.3 PR Template (.github/PULL_REQUEST_TEMPLATE.md)

```markdown
## What does this PR do?

<!-- Brief description -->

## Related Issue

<!-- Closes #123 -->

## How to Test

<!-- Steps to verify the changes work -->

## Checklist

- [ ] I've run `shellcheck` on modified scripts
- [ ] I've tested manually with `agent-session`
- [ ] I've updated README if needed
```

### Phase 3: README Updates

Add a new section after "License":

```markdown
## Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Quick Ways to Help

- **Found a bug?** [Open an issue](https://github.com/barnierg76/agent-tmux-toolkit/issues/new?template=bug_report.yml)
- **Have an idea?** [Request a feature](https://github.com/barnierg76/agent-tmux-toolkit/issues/new?template=feature_request.yml)
- **Want to code?** Check issues labeled [`good first issue`](https://github.com/barnierg76/agent-tmux-toolkit/labels/good%20first%20issue)

### Priority Areas

- Improving error handling and validation
- Adding test coverage
- Documentation and examples
- Cross-platform compatibility (Linux/WSL2)

## Contributors

<!-- ALL-CONTRIBUTORS-LIST:START -->
<!-- ALL-CONTRIBUTORS-LIST:END -->

Thanks to everyone who has contributed!
```

### Phase 4: Labels

Create these labels in GitHub:
- `good first issue` (green) - Good for newcomers
- `help wanted` (yellow) - Extra attention needed
- `bug` (red) - Something isn't working
- `enhancement` (blue) - New feature or improvement
- `documentation` (purple) - Documentation improvements
- `question` (cyan) - Further information requested

## Acceptance Criteria

- [ ] CONTRIBUTING.md exists with setup instructions and guidelines
- [ ] CODE_OF_CONDUCT.md exists (Contributor Covenant)
- [ ] SECURITY.md exists with reporting instructions
- [ ] `.github/ISSUE_TEMPLATE/bug_report.yml` exists
- [ ] `.github/ISSUE_TEMPLATE/feature_request.yml` exists
- [ ] `.github/PULL_REQUEST_TEMPLATE.md` exists
- [ ] README has "Contributing" section with links
- [ ] GitHub labels are configured
- [ ] At least 3 existing todos labeled as `good first issue`

## Files to Create/Modify

### New Files
- `CONTRIBUTING.md`
- `CODE_OF_CONDUCT.md`
- `SECURITY.md`
- `.github/ISSUE_TEMPLATE/bug_report.yml`
- `.github/ISSUE_TEMPLATE/feature_request.yml`
- `.github/ISSUE_TEMPLATE/config.yml`
- `.github/PULL_REQUEST_TEMPLATE.md`

### Modified Files
- `README.md` - Add Contributing section

## Implementation Notes

### System Requirements to Document
- macOS or Linux (WSL2 on Windows may work but untested)
- tmux 3.0+ (tested with 3.2+)
- Bash 4.0+
- fzf for interactive pickers
- git for worktree features
- iTerm2 recommended for Option key support

### Good First Issue Candidates from Existing Todos
Review `/todos/` for P3 items that could be marked:
- Documentation improvements
- Simple validation additions
- Config enhancements

### Recognition System
Start with manual acknowledgment in release notes. Consider all-contributors bot later if community grows.

### Review SLA
Document as "best effort within 7 days" - this is a volunteer project.

## References

### Internal
- Current README structure: `README.md:1-269`
- Existing todos: `/todos/` (14 pending items)
- Learnings: `LEARNINGS.md`
- License: MIT

### External
- [GitHub Community Health Files](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions)
- [Contributor Covenant](https://www.contributor-covenant.org/version/2/1/code_of_conduct/)
- [All-Contributors Specification](https://allcontributors.org/)
- [Good First Issues Algorithm](https://github.blog/2020-01-22-how-we-built-good-first-issues/)

## Research Summary

Research from 3 parallel agents identified:
1. **No community infrastructure exists** - biggest gap in otherwise well-documented project
2. **Response time matters** - non-returning contributors correlate with no/poor responses
3. **Recognition is key** - 31% lower turnover with recognition programs
4. **Lower barriers** - every question a newcomer has to ask is friction
5. **Mentorship multiplies** - 46% productivity increase with mentorship programs
