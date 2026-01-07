# Screenshot Regeneration Guide

This document explains how to regenerate the hero screenshot for the README.

## Overview

The hero screenshot (`docs/images/hero-agent-flow.png`) shows the agent-tmux-toolkit's 3-pane layout with the agent-flow menu open. It's created from an HTML mockup that renders in a browser.

## Quick Regeneration

```bash
# 1. Open the mockup in a browser
open docs/screenshot-mockup.html

# 2. Take a screenshot (1600x800 recommended)
# Use browser developer tools to set viewport size
# Or use Playwright MCP tools (see below)
```

## Using Playwright MCP

If you have Playwright MCP configured, you can automate the screenshot:

```
# In Claude Code with Playwright MCP:
1. browser_navigate to file:///path/to/docs/screenshot-mockup.html
2. browser_resize to width=1600, height=800
3. browser_take_screenshot with filename=hero-agent-flow.png
4. Copy from .playwright-mcp/ to docs/images/
```

## Modifying the Screenshot

### Edit Content

Edit `docs/screenshot-mockup.html` to change:
- **Pane content**: Modify the text in `.pane-content` divs
- **Menu items**: Update the `.menu-item` elements
- **Colors**: Adjust the CSS variables/colors
- **Layout**: Modify the flexbox structure

### Color Scheme

The mockup uses GitHub's dark theme colors:
- Background: `#0d1117`
- Borders: `#30363d`
- Text: `#c9d1d9`
- Blue accent: `#58a6ff`
- Green (success): `#7ee787`
- Red (keywords): `#ff7b72`
- Purple (headings): `#d2a8ff`

## Live Demo Alternative

The toolkit also includes `bin/demo-setup.sh` which creates a real tmux session with demo content:

```bash
# Set up demo session
./bin/demo-setup.sh demo-screenshot

# Attach to see it
tmux attach -t demo-screenshot

# Press Option+F to open menu
# Take screenshot manually (Cmd+Shift+4 on macOS)
```

**Note**: tmux menus are overlay widgets that can't be captured programmatically with `tmux capture-pane`. The HTML mockup approach is preferred for consistent, reproducible screenshots.

## Image Specifications

| Property | Value |
|----------|-------|
| Format | PNG |
| Dimensions | 1600×800 |
| File Size | < 500KB |
| Location | `docs/images/hero-agent-flow.png` |

## Files

- `docs/screenshot-mockup.html` - HTML source for screenshot
- `docs/images/hero-agent-flow.png` - Generated screenshot
- `bin/demo-setup.sh` - Creates live demo tmux session
