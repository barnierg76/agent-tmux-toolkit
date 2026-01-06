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

## What to Report

- Command injection vulnerabilities
- Unvalidated input handling
- Privilege escalation issues
- Information disclosure

## Out of Scope

- Issues in tmux itself (report to tmux maintainers)
- Issues in fzf (report to fzf maintainers)
- Social engineering attacks
- Physical access attacks
