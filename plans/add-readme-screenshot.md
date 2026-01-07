# feat: Add Hero Screenshot to README

## Overview

Create a compelling hero screenshot for the GitHub README that showcases the agent-tmux-toolkit's key value proposition: a 3-pane tmux layout with interactive workflow menus for parallel AI agent development.

**Fidelity Level**: 2 (Multi-file, clear scope, non-obvious implementation)

## Problem Statement

The repository currently has no visual documentation. Users landing on the README cannot immediately understand what the tool looks like or how it works. A well-crafted screenshot showing the interactive menus would:

- Increase repository engagement (repos with screenshots get ~42% more stars)
- Reduce time-to-understanding for potential users
- Demonstrate the key value prop: 3-pane AI agent workflow

## Proposed Solution

Create a **single hero screenshot** showing:
1. The 3-pane layout (PLAN | WORK | REVIEW) with realistic content
2. The **agent-flow menu** (Option+F) open as an overlay
3. Clean, professional terminal appearance

### Why agent-flow Menu?

| Menu | What it Shows | Why/Why Not |
|------|---------------|-------------|
| **agent-flow** | Workflow orchestration (Plan/Work/Review/Compound) | **Best choice** - Shows the core workflow concept |
| agent-manage | Session/pane management | Good but more "administrative" |
| snippet-picker | Code snippets | Useful but secondary feature |
| agent-handoff | Cross-pane context transfer | Advanced feature, less immediately understandable |

## Technical Approach

### Challenge: tmux Menus Can't Be Captured Programmatically

tmux `capture-pane` cannot capture overlay menus - they float above pane content. We need a **hybrid approach**:

1. **VHS tape** to automate setup (start session, populate panes with content)
2. **Manual capture** of the screenshot when menu is open (using macOS screenshot or iTerm2)

### Recommended Capture Method

**Primary**: macOS native screenshot (`Cmd+Shift+4`) or iTerm2's capture feature
**Terminal**: iTerm2 (best font rendering, most common among developers)
**Format**: PNG (lossless, sharp text)

## Pane Content Strategy

Each pane needs realistic content that demonstrates value:

```
┌────────────────────┬────────────────────┬────────────────────┐
│       PLAN         │       WORK         │      REVIEW        │
├────────────────────┼────────────────────┼────────────────────┤
│                    │                    │                    │
│ $ claude          │ $ claude          │ $ claude          │
│                    │                    │                    │
│ > Planning auth    │ > Implementing     │ > Reviewing        │
│   feature...       │   login flow...    │   changes...       │
│                    │                    │                    │
│ Tasks:             │ Writing code:      │ Test results:      │
│ - Research OAuth   │ app/auth/login.ts  │ ✓ 12 tests pass    │
│ - Design API       │                    │ ✓ No lint errors   │
│ - Create plan      │ [code visible]     │ ✓ Types valid      │
│                    │                    │                    │
└────────────────────┴────────────────────┴────────────────────┘
                      ┌─────────────────────┐
                      │ Agent Flow [WORKING]│
                      ├─────────────────────┤
                      │ Plan    Focus PLAN  │
                      │ Work  ▶ Focus WORK  │  ← Menu overlay
                      │ Review  Focus REVIEW│
                      │ Compound  Record    │
                      │ Handoff   Transfer  │
                      │ Status    Dashboard │
                      └─────────────────────┘
```

### Content Options

**Option A: Synthetic Demo Content** (Recommended)
- Curated, clean examples showing idealized workflow
- Easy to reproduce and update
- Pros: Professional appearance, consistent
- Cons: Not "real" usage

**Option B: Live Session Recording**
- Capture during actual development
- Pros: Authentic
- Cons: Hard to reproduce, may contain sensitive/messy content

**Recommendation**: Option A - Create a demo script that populates each pane with clean, representative content.

## Implementation Tasks

### Phase 1: Setup Demo Environment

- [ ] **Create demo content script** (`bin/demo-setup.sh`)
  - Starts agent-tmux session
  - Populates PLAN pane with planning content
  - Populates WORK pane with code/implementation content
  - Populates REVIEW pane with test/review output

- [ ] **Create VHS tape file** (`tapes/hero-screenshot.tape`)
  - Automates terminal setup
  - Executes demo script
  - Pauses for manual menu trigger + screenshot

### Phase 2: Capture Screenshot

- [ ] **Configure terminal** for optimal capture
  - Font: 16-18pt monospace (SF Mono, JetBrains Mono, or Menlo)
  - Window size: 1600x1000 or similar 16:10 ratio
  - Theme: Dark (matches most developers' preference)
  - Disable window chrome/title bar for clean capture

- [ ] **Execute capture workflow**
  1. Run VHS tape or demo script
  2. Wait for panes to populate
  3. Press Option+F to open agent-flow menu
  4. Take screenshot (Cmd+Shift+4 → select area)
  5. Save to `docs/images/hero-agent-flow.png`

- [ ] **Optimize image**
  - Crop to content (remove extra terminal padding)
  - Compress with pngquant or ImageOptim
  - Target: < 500KB file size
  - Verify text is readable at 50% zoom

### Phase 3: Integrate into README

- [ ] **Create image directory structure**
  ```
  docs/
  └── images/
      └── hero-agent-flow.png
  ```

- [ ] **Update README.md**
  - Add screenshot after title/badges, before installation
  - Include descriptive alt text
  - Add brief caption explaining what's shown

  ```markdown
  ## What it looks like

  ![agent-tmux-toolkit showing 3-pane layout with PLAN, WORK, and REVIEW panes,
  and the agent-flow menu open for workflow orchestration](docs/images/hero-agent-flow.png)

  *The agent-flow menu (Option+F) orchestrating work across PLAN, WORK, and REVIEW panes*
  ```

### Phase 4: Documentation

- [ ] **Create screenshot regeneration docs** (`docs/screenshots.md`)
  - How to set up demo environment
  - VHS tape usage instructions
  - Manual capture steps
  - Image optimization commands

- [ ] **Store VHS tape** (if created) in `tapes/` directory

## Image Specifications

| Property | Value |
|----------|-------|
| Format | PNG |
| Dimensions | 1600×1000 (or 1280×800 minimum) |
| Aspect Ratio | 16:10 or 16:9 |
| File Size | < 500KB |
| Color Mode | sRGB |
| Font Size | 16-18pt minimum |
| Theme | Dark terminal background |
| DPI | 72 (for web) or 144 (retina) |

## Acceptance Criteria

### Must Have
- [ ] Screenshot clearly shows the 3-pane layout (PLAN | WORK | REVIEW labels visible)
- [ ] agent-flow menu is fully visible and readable
- [ ] All menu items are visible and legible
- [ ] Content in each pane demonstrates realistic usage
- [ ] Image loads quickly on GitHub (file size < 500KB)
- [ ] Alt text accurately describes the screenshot
- [ ] Screenshot is added to README.md in prominent position

### Should Have
- [ ] Text is readable at GitHub's default rendering size (~800px wide)
- [ ] Colors have sufficient contrast
- [ ] VHS tape or demo script exists for regeneration
- [ ] Documentation explains how to update the screenshot

### Nice to Have
- [ ] Retina (2x) version available
- [ ] Animated GIF showing menu interaction
- [ ] Multiple screenshots showing different menus

## File Changes Summary

| File | Action |
|------|--------|
| `docs/images/hero-agent-flow.png` | Create - hero screenshot |
| `README.md` | Edit - add screenshot section |
| `bin/demo-setup.sh` | Create - demo environment script |
| `tapes/hero-screenshot.tape` | Create - VHS automation (optional) |
| `docs/screenshots.md` | Create - regeneration instructions |

## Quick Reference Commands

```bash
# Install VHS (optional, for automation)
brew install vhs

# Set up demo environment
./bin/demo-setup.sh

# Capture with VHS (sets up environment)
vhs tapes/hero-screenshot.tape

# Optimize PNG after capture
pngquant --quality=65-80 docs/images/hero-agent-flow.png

# Alternative: ImageOptim (GUI on macOS)
open -a ImageOptim docs/images/hero-agent-flow.png
```

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| VHS can't trigger tmux menus | Medium | Use VHS for setup only, manual menu trigger |
| Menu doesn't fit terminal | High | Test dimensions before capture, use 120+ column width |
| Screenshot becomes outdated | Low | Document regeneration process, store VHS tape |
| Large file size | Medium | Use pngquant compression, verify < 500KB |

## References

- Research: `RESEARCH_TERMINAL_SCREENSHOTS.md` (screenshot best practices)
- Research: `RESEARCH_TMUX_MENUS_POPUPS.md` (tmux capture limitations)
- VHS documentation: https://github.com/charmbracelet/vhs
- agent-flow menu: `bin/agent-flow`
- tmux config: `config/agent-tmux.conf`
