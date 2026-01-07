# Framework Documentation Research: Tmux & Clipboard APIs

**Date:** 2026-01-04
**Research Focus:** Programmatic tmux pane capture and clipboard integration for Node.js

---

## Summary

This research covers three key areas for implementing clipboard functionality with tmux:
1. **tmux capture-pane command** - Extracting pane content programmatically
2. **Node.js clipboard libraries** - System clipboard access from Node.js
3. **Browser Clipboard API** - Web-based clipboard access (secondary)

The recommended approach is to use tmux's `capture-pane` command with the `-p` flag to output directly to stdout, combined with the `clipboardy` npm package for cross-platform clipboard access.

---

## 1. tmux capture-pane Command

### Version Information
- Tested on: tmux 3.6a (installed at `/usr/local/bin/tmux`)
- Command alias: `capturep`

### Command Syntax
```bash
tmux capture-pane [-aCeJMNpPqT] [-b buffer-name] [-E end-line] [-S start-line] [-t target-pane]
```

### Key Flags

| Flag | Description | Use Case |
|------|-------------|----------|
| `-p` | Print to stdout instead of buffer | **Critical for piping to other commands** |
| `-S start-line` | Specify starting line | `-S -` starts from history beginning |
| `-E end-line` | Specify ending line | `-E -` ends at visible pane end |
| `-t target-pane` | Target specific pane | `mysession:2.1` (pane 1 of window 2) |
| `-a` | Include alternate screen | Useful for programs like vim |
| `-e` | Include ANSI escape sequences | Preserves colors/formatting |
| `-J` | Join wrapped lines | Preserves trailing spaces, joins wrapped text |
| `-N` | Preserve trailing spaces | Keeps line-end whitespace |
| `-T` | Trim trailing empty positions | Removes empty positions at line end |
| `-C` | Escape non-printable chars | Outputs as octal `\xxx` format |
| `-q` | Quiet mode | Suppresses errors |
| `-M` | Use screen mode | If pane is in a mode |
| `-P` | Capture incomplete sequences | For partial escape sequences |
| `-b buffer-name` | Specify buffer destination | Stores in named buffer |

### Line Number System

**Understanding line positions:**
- `0` = First line of visible pane
- Positive numbers = Lines in visible pane
- Negative numbers = Lines in scrollback history
- `-` (when used with `-S`) = Start of history
- `-` (when used with `-E`) = End of visible pane

### Practical Examples

**Capture entire scrollback to stdout:**
```bash
tmux capture-pane -p -S -
```

**Capture visible pane only:**
```bash
tmux capture-pane -p
```

**Capture with colors/formatting:**
```bash
tmux capture-pane -p -e -S -
```

**Capture specific pane by target:**
```bash
tmux capture-pane -p -t mysession:0.1 -S -
```

**Capture and save to file:**
```bash
tmux capture-pane -p -S - > output.txt
```

**Capture to named buffer:**
```bash
tmux capture-pane -b mybuffer -S -
tmux show-buffer -b mybuffer
```

### Related Buffer Commands

```bash
# List available commands
capture-pane (capturep)    # Extract pane contents
show-buffer (showb)        # Display buffer contents
save-buffer (saveb)        # Save buffer to file
load-buffer (loadb)        # Load file into buffer
set-buffer (setb)          # Set buffer contents
```

**save-buffer usage:**
```bash
tmux save-buffer [-a] [-b buffer-name] path
```
- `-a` = Append to file instead of overwriting
- `-b buffer-name` = Specify which buffer to save

### Sources
- [tmux capture-pane documentation](https://tmuxai.dev/tmux-capture-pane/)
- [tmux man page](https://man7.org/linux/man-pages/man1/tmux.1.html)
- [Baeldung: tmux logging guide](https://www.baeldung.com/linux/tmux-logging)
- [libtmux panes documentation](https://libtmux.git-pull.com/api/panes.html)

---

## 2. Node.js Clipboard Libraries

### Recommended: clipboardy

**Version:** 5.0.2 (latest as of December 2025)
**License:** MIT
**Weekly Downloads:** 4,275,528
**Popularity:** Classified as "popular"

#### Installation
```bash
npm install clipboardy
```

#### API Documentation

**Module Type:** Pure ESM (requires `import`, not `require`)

**Asynchronous Methods (Recommended):**
```javascript
import clipboard from 'clipboardy';

// Write to clipboard
await clipboard.write('🦄');

// Read from clipboard
const text = await clipboard.read();
// => '🦄'
```

**Synchronous Methods:**
```javascript
// Write synchronously (doesn't work in browsers)
clipboard.writeSync('text');

// Read synchronously (doesn't work in browsers)
const text = clipboard.readSync();
```

#### Platform Support

| Platform | Implementation | Notes |
|----------|---------------|-------|
| **macOS** | Native pbcopy/pbpaste | Built-in system tools |
| **Windows** | PowerShell cmdlets | Set-Clipboard/Get-Clipboard, falls back to bundled binary |
| **Linux X11** | xsel (bundled) | Fallback for non-Wayland systems |
| **Linux Wayland** | wl-clipboard | Auto-detected, preferred on Wayland |
| **WSLg** | wl-clipboard | Windows Subsystem for Linux GUI support |
| **Browsers** | Requires HTTPS | Secure context required, sync methods unavailable |

#### Key Features
- Cross-platform consistency
- Automatic Wayland detection on Linux
- Graceful fallbacks (PowerShell → binary on Windows, Wayland → X11 on Linux)
- ESM-first design
- Zero configuration required

#### Browser Considerations
- Requires secure context (HTTPS)
- Synchronous methods (`writeSync`, `readSync`) not available
- Must be called in response to user gesture (click, keypress)

### Alternative: copy-paste (node-copy-paste)

**Version:** 2.2.0
**Last Updated:** 3 months ago

#### Installation
```bash
npm install copy-paste
```

#### API

**Callback-based API:**
```javascript
const ncp = require('copy-paste');

// Copy
ncp.copy('text', (err) => {
  if (err) console.error(err);
});

// Paste
ncp.paste((err, data) => {
  console.log(data);
});
```

**Promise-based API:**
```javascript
const { copy, paste } = require('copy-paste/promises');

await copy('text');
const data = await paste();
```

#### Platform Implementation
- **macOS:** pbcopy/pbpaste
- **Linux/BSD:** xclip
- **Windows:** clip

**Pros:**
- Supports both callbacks and promises
- Simpler API for basic use cases

**Cons:**
- Older CommonJS module
- Less active maintenance
- No Wayland auto-detection

### Comparison Matrix

| Feature | clipboardy | copy-paste |
|---------|-----------|------------|
| **Module System** | ESM | CommonJS |
| **Async/Sync** | Both | Callbacks + Promises |
| **Wayland Support** | Auto-detect | No |
| **Weekly Downloads** | 4.2M | Lower |
| **Last Updated** | Dec 2025 | 3 months ago |
| **Browser Support** | Yes (HTTPS) | No |

**Recommendation:** Use `clipboardy` for modern projects. It's more actively maintained, has better platform support, and follows current Node.js best practices (ESM).

### Sources
- [clipboardy npm package](https://www.npmjs.com/package/clipboardy)
- [clipboardy GitHub repository](https://github.com/sindresorhus/clipboardy)
- [copy-paste npm package](https://www.npmjs.com/package/copy-paste)
- [Nesin.io: System Clipboard in Node.js](https://nesin.io/blog/system-clipboard-nodejs)

---

## 3. Browser Clipboard API

### navigator.clipboard

**Specification:** Web APIs
**Status:** Widely supported in modern browsers
**Security Requirement:** Secure context (HTTPS) + user gesture

#### API Overview

```javascript
// Write text to clipboard
await navigator.clipboard.writeText('text to copy');

// Read text from clipboard
const text = await navigator.clipboard.readText();

// Write arbitrary data
const blob = new Blob(['data'], { type: 'text/plain' });
await navigator.clipboard.write([
  new ClipboardItem({ 'text/plain': blob })
]);

// Read arbitrary data
const items = await navigator.clipboard.read();
for (const item of items) {
  for (const type of item.types) {
    const blob = await item.getType(type);
    console.log(await blob.text());
  }
}
```

#### Security Model

**Write Access:**
- Requires `clipboard-write` permission (usually auto-granted)
- May require transient user activation (click/keypress)

**Read Access:**
- Requires `clipboard-read` permission
- Usually prompts user for permission
- Must be in response to user gesture

#### Browser Compatibility
- Chrome/Edge: Full support
- Firefox: Full support
- Safari: Full support (with quirks)
- Opera: Full support

**Note:** Implementation details vary by browser. Test thoroughly across target browsers.

### Deprecated Alternative: document.execCommand()

**Status:** Deprecated, avoid in new code

```javascript
// Old approach (deprecated)
const textarea = document.createElement('textarea');
textarea.value = 'text';
document.body.appendChild(textarea);
textarea.select();
document.execCommand('copy');
document.body.removeChild(textarea);
```

**Why deprecated:**
- Synchronous (blocks UI)
- Limited functionality
- Poor security model
- Being removed from standards

### Sources
- [MDN: Navigator.clipboard](https://developer.mozilla.org/en-US/docs/Web/API/Navigator/clipboard)
- [MDN: Clipboard API](https://developer.mozilla.org/en-US/docs/Web/API/Clipboard_API)
- [Can I Use: Navigator.clipboard](https://caniuse.com/mdn-api_navigator_clipboard)

---

## 4. tmux Node.js Bindings

### node-tmux

**Version:** 1.0.2
**License:** ISC
**Last Updated:** 7 years ago (minimal maintenance)

#### Installation
```bash
npm install --save node-tmux
```

#### API Documentation

**Initialization:**
```javascript
import { tmux } from 'node-tmux';

tmux().then(tm => {
  // Use tm instance
}).catch(() => {
  // tmux not found
});
```

**Available Methods:**

```javascript
// Create new session
await tm.newSession('session-name', 'optional-command');

// List all sessions
const sessions = await tm.listSessions();
// => ['session1', 'session2']

// Check if session exists
const exists = await tm.hasSession('session-name');
// => true/false

// Kill session
await tm.killSession('session-name');

// Rename session
await tm.renameSession('old-name', 'new-name');

// Send input to session
await tm.writeInput('session-name', 'command to run', true);
// Third parameter: newline (true = execute command)
```

#### Limitations
- **No capture-pane support** - Missing the key method we need
- **Session-level only** - No pane-specific operations
- **Minimal maintenance** - Last updated 7 years ago
- **Basic functionality** - Only covers session management

**Recommendation:** For capture-pane functionality, use direct `child_process.exec()` or `child_process.spawn()` to call tmux commands rather than relying on this library.

### Alternative Approach: Direct tmux Command Execution

**Using child_process:**
```javascript
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

// Capture pane content
async function capturePaneContent(target = null) {
  const cmd = target
    ? `tmux capture-pane -p -S - -t ${target}`
    : `tmux capture-pane -p -S -`;

  const { stdout, stderr } = await execAsync(cmd);
  if (stderr) throw new Error(stderr);
  return stdout;
}

// Usage
const content = await capturePaneContent();
console.log(content);
```

**Using child_process.spawn:**
```javascript
import { spawn } from 'child_process';

function capturePaneStream(target = null) {
  const args = ['capture-pane', '-p', '-S', '-'];
  if (target) args.push('-t', target);

  return spawn('tmux', args);
}

// Usage
const proc = capturePaneStream();
let data = '';
proc.stdout.on('data', chunk => data += chunk);
proc.on('close', code => {
  if (code === 0) console.log(data);
});
```

### Sources
- [node-tmux npm package](https://www.npmjs.com/package/node-tmux)
- [node-tmux GitHub repository](https://github.com/StarlaneStudios/node-tmux)

---

## 5. Implementation Recommendations

### Recommended Architecture

For the Agent Tmux Toolkit project, implement clipboard functionality using:

1. **Direct tmux command execution** via `child_process`
2. **clipboardy** for cross-platform clipboard access
3. **Shell script wrapper** for quick prototyping

### Example Implementation

**Option A: Pure Node.js Script**

```javascript
#!/usr/bin/env node
import { exec } from 'child_process';
import { promisify } from 'util';
import clipboard from 'clipboardy';

const execAsync = promisify(exec);

async function copyPaneToClipboard(target = null) {
  try {
    // Capture pane content
    const cmd = target
      ? `tmux capture-pane -p -S - -t ${target}`
      : `tmux capture-pane -p -S -`;

    const { stdout, stderr } = await execAsync(cmd);

    if (stderr) {
      throw new Error(`tmux error: ${stderr}`);
    }

    // Copy to clipboard
    await clipboard.write(stdout);

    console.log('Pane content copied to clipboard!');
    return stdout;
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

// Run
const targetPane = process.argv[2]; // Optional pane target
copyPaneToClipboard(targetPane);
```

**Option B: Shell Script (Simpler)**

```bash
#!/bin/bash
# copy-pane-to-clipboard.sh

PANE="${1:-}"

if [ -n "$PANE" ]; then
  tmux capture-pane -p -S - -t "$PANE" | pbcopy  # macOS
  # tmux capture-pane -p -S - -t "$PANE" | xclip -selection clipboard  # Linux
else
  tmux capture-pane -p -S - | pbcopy  # macOS
  # tmux capture-pane -p -S - | xclip -selection clipboard  # Linux
fi

echo "Pane content copied to clipboard!"
```

**Option C: Hybrid (Shell + Node.js for cross-platform)**

Use shell script for quick access, Node.js script for cross-platform reliability:

```bash
#!/bin/bash
# Detect platform and use appropriate tool
if command -v pbcopy &> /dev/null; then
  # macOS
  tmux capture-pane -p -S - | pbcopy
elif command -v xclip &> /dev/null; then
  # Linux X11
  tmux capture-pane -p -S - | xclip -selection clipboard
elif command -v wl-copy &> /dev/null; then
  # Linux Wayland
  tmux capture-pane -p -S - | wl-copy
else
  # Fall back to Node.js
  node /path/to/clipboard-copy.js
fi
```

### Integration Points for Agent Tmux Toolkit

**Add to tmux.conf:**
```tmux
# Copy current pane to clipboard
bind-key C-y run-shell "tmux capture-pane -p -S - | pbcopy"

# Copy specific pane to clipboard (prompts for pane number)
bind-key Y command-prompt -p "Pane:" "run-shell 'tmux capture-pane -p -S - -t %%:. | pbcopy'"
```

**Add to bin/agent-manage:**
```bash
# New command: copy pane content
if [ "$1" = "copy" ]; then
  PANE="${2:-}"
  if [ -n "$PANE" ]; then
    tmux capture-pane -p -S - -t "$PANE" | pbcopy
  else
    # Interactive pane selection with fzf
    SELECTED=$(tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index} #{pane_title}" | fzf)
    if [ -n "$SELECTED" ]; then
      TARGET=$(echo "$SELECTED" | awk '{print $1}')
      tmux capture-pane -p -S - -t "$TARGET" | pbcopy
    fi
  fi
  echo "Content copied to clipboard!"
fi
```

---

## 6. Best Practices & Patterns

### tmux capture-pane Best Practices

1. **Always use `-p` for piping** - Outputs to stdout instead of buffer
2. **Use `-S -` for full history** - Captures entire scrollback
3. **Consider `-J` for wrapped lines** - Joins wrapped text naturally
4. **Use `-e` carefully** - Only when you need ANSI escape sequences
5. **Target panes explicitly** - Use `-t` to avoid capturing wrong pane

### Clipboard Access Best Practices

1. **Prefer async methods** - Better for Node.js event loop
2. **Handle errors gracefully** - Clipboard access can fail
3. **Test across platforms** - Different OS behaviors
4. **Respect user permissions** - Browser clipboard requires gestures
5. **Validate content** - Large clipboard content can cause issues

### Error Handling

```javascript
async function safeCopyToClipboard(text) {
  try {
    // Check text size
    if (text.length > 1_000_000) {
      throw new Error('Content too large for clipboard');
    }

    await clipboard.write(text);
    return { success: true };
  } catch (error) {
    console.error('Clipboard error:', error.message);

    // Fallback: save to file
    const fs = await import('fs/promises');
    const filename = `/tmp/clipboard-fallback-${Date.now()}.txt`;
    await fs.writeFile(filename, text);

    return {
      success: false,
      fallback: filename,
      error: error.message
    };
  }
}
```

### Performance Considerations

**Large pane content:**
- tmux capture can be slow for very long history
- Consider using `-S -1000` to limit to last 1000 lines
- Stream processing for very large buffers

**Clipboard size limits:**
- macOS: ~100MB practical limit
- Linux: Varies by display server
- Windows: ~64KB for CF_TEXT, larger for CF_UNICODETEXT

---

## 7. Testing Checklist

### tmux capture-pane Testing

- [ ] Capture visible pane only
- [ ] Capture with full history (-S -)
- [ ] Capture specific pane by target
- [ ] Capture with colors/escape sequences (-e)
- [ ] Capture with joined wrapped lines (-J)
- [ ] Test with empty pane
- [ ] Test with very long history (10k+ lines)
- [ ] Test with alternate screen (vim, less, etc.)

### Clipboard Integration Testing

- [ ] Copy small text (< 1KB)
- [ ] Copy medium text (1KB - 100KB)
- [ ] Copy large text (100KB - 1MB)
- [ ] Copy unicode/emoji content
- [ ] Copy ANSI escape sequences
- [ ] Test on macOS
- [ ] Test on Linux (X11)
- [ ] Test on Linux (Wayland)
- [ ] Test error handling (clipboard unavailable)
- [ ] Test fallback mechanisms

---

## 8. Key Takeaways

### What Worked

1. **Direct tmux command execution** is more reliable than node-tmux library
2. **clipboardy** provides excellent cross-platform clipboard support
3. **tmux capture-pane -p -S -** is the optimal command for full history capture
4. **Shell scripts** are simpler for quick tmux integrations

### What Didn't Work

1. **node-tmux library** lacks pane capture functionality
2. **Browser Clipboard API** not suitable for terminal/tmux workflows
3. **Synchronous clipboard methods** can block in some scenarios

### Patterns to Reuse

**Pattern 1: Capture and Copy Pipeline**
```bash
tmux capture-pane -p -S - | clipboard-tool
```

**Pattern 2: Node.js Wrapper for Cross-Platform**
```javascript
import { exec } from 'child_process';
import clipboard from 'clipboardy';

const { stdout } = await exec('tmux capture-pane -p -S -');
await clipboard.write(stdout);
```

**Pattern 3: Interactive Pane Selection**
```bash
tmux list-panes -a -F "format" | fzf | xargs tmux capture-pane -p -t
```

### Things to Remember

1. **tmux pane targets** use format `session:window.pane` (e.g., `agents:0.1`)
2. **Line numbers** in tmux: 0 = visible start, negative = history, `-` = history start
3. **clipboardy requires ESM** - use `import`, not `require`
4. **Wayland auto-detection** in clipboardy handles Linux clipboard differences
5. **Always validate** clipboard content size before copying

---

## 9. Related Resources

### Official Documentation
- [tmux manual page](https://man7.org/linux/man-pages/man1/tmux.1.html)
- [tmux GitHub wiki](https://github.com/tmux/tmux/wiki)
- [MDN Clipboard API](https://developer.mozilla.org/en-US/docs/Web/API/Clipboard_API)

### Library Documentation
- [clipboardy on npm](https://www.npmjs.com/package/clipboardy)
- [clipboardy on GitHub](https://github.com/sindresorhus/clipboardy)
- [node-tmux on GitHub](https://github.com/StarlaneStudios/node-tmux)

### Community Resources
- [tmux Cheat Sheet](https://tmuxcheatsheet.com/)
- [libtmux Python library docs](https://libtmux.git-pull.com/)
- [Baeldung: tmux Logging Guide](https://www.baeldung.com/linux/tmux-logging)

### Related Projects
- [tmuxinator](https://github.com/tmuxinator/tmuxinator) - tmux session manager
- [tmuxp](https://github.com/tmux-python/tmuxp) - Python tmux session manager
- [clipboard-cli](https://github.com/sindresorhus/clipboard-cli) - CLI for clipboardy

---

## 10. Next Steps

### Immediate Implementation
1. Install clipboardy: `npm install clipboardy`
2. Create Node.js script for pane-to-clipboard copy
3. Add keybinding to tmux.conf
4. Test across platforms

### Future Enhancements
1. Add pane selection UI with fzf
2. Support copying multiple panes
3. Add history range selection
4. Implement clipboard history/cache
5. Create tmux plugin for easier distribution

---

**Research Completed:** 2026-01-04
**Next Review:** When implementing clipboard feature or updating dependencies
