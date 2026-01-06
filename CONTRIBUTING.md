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

- macOS or Linux (WSL2 on Windows may work but is untested)
- tmux 3.0+ (tested with 3.2+)
- Bash 4.0+
- fzf for interactive pickers
- git for worktree features
- iTerm2 recommended for Option key support on macOS

## Ways to Contribute

### Report Bugs

Open an issue using the [bug report template](https://github.com/barnierg76/agent-tmux-toolkit/issues/new?template=bug_report.yml).

### Suggest Features

Open an issue using the [feature request template](https://github.com/barnierg76/agent-tmux-toolkit/issues/new?template=feature_request.yml).

### Submit Code

1. Check [existing issues](../../issues) for something to work on
2. Look for issues labeled [`good first issue`](../../labels/good%20first%20issue) if you're new
3. Comment "I'd like to work on this" to claim it
4. Fork, branch, implement, test
5. Submit PR with clear description

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

## Testing

There's no automated test suite yet (contributions welcome!). Please test manually:

```bash
# Test session creation
agent-session test-session

# Test snippet picker
# Press Option+S in tmux

# Test workflow orchestration
# Press Option+F in tmux

# Clean up
tmux kill-session -t test-session
```

## Getting Help

- Open a [GitHub Discussion](https://github.com/barnierg76/agent-tmux-toolkit/discussions) for questions
- Check existing issues for similar problems
- Read the README and LEARNINGS.md for context

## Review Timeline

This is a volunteer project. We aim to review PRs within 7 days, but it may take longer.

## Code of Conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). Please be respectful and constructive in all interactions.
