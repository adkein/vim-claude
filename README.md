# vim-claude

A Vim plugin to integrate Claude AI directly into your editor using Claude Code. Select text, ask Claude what to do with it, and get instant AI-powered assistance - all covered by your existing Claude subscription!

## Features

- **Visual Selection Integration**: Select any text in visual mode and send it to Claude with a custom prompt
- **Flexible Output Options**:
  - Replace the selected text with Claude's response
  - Insert Claude's response below the selection
  - Show the response in a new split window
- **No API Keys Required**: Uses Claude Code CLI, so it's covered by your existing Claude subscription
- **Customizable**: Configure key mappings and CLI path

## Installation

### Prerequisites

1. **Claude Code installed** - You need the `claude` CLI available in your PATH
   - If you have Claude Pro or Claude Max, you already have access
   - Install from: https://docs.claude.com/claude-code

### Using Pathogen

1. Clone this repository into your Vim bundle directory:
   ```bash
   cd ~/.vim/bundle
   git clone https://github.com/yourusername/vim-claude.git
   ```

2. Restart Vim - that's it! No API keys or additional configuration needed.

### Using Other Plugin Managers

- **vim-plug**: Add to your `.vimrc`:
  ```vim
  Plug 'yourusername/vim-claude'
  ```

- **Vundle**: Add to your `.vimrc`:
  ```vim
  Plugin 'yourusername/vim-claude'
  ```

## Usage

### Basic Usage

1. Enter visual mode and select some text (`v`, `V`, or `Ctrl-v`)
2. Press `<Leader>c` (default mapping, typically `\c`)
3. Enter your prompt when prompted (e.g., "Explain this code" or "Fix the bug")
4. Wait for Claude to process your request
5. Choose an action:
   - `r` - Replace the selected text
   - `i` - Insert below the selection
   - `s` - Show in a new split window

### Example Workflows

**Explaining code:**
```
1. Select a function in visual mode
2. Press <Leader>c
3. Type: "Explain what this function does"
4. Press 's' to view the explanation in a split
```

**Refactoring code:**
```
1. Select code to refactor
2. Press <Leader>c
3. Type: "Refactor this to be more efficient"
4. Press 'r' to replace with the refactored version
```

**Adding documentation:**
```
1. Select a function
2. Press <Leader>c
3. Type: "Add detailed docstring"
4. Press 'i' to insert the documentation below
```

## Configuration

Add these to your `.vimrc` to customize the plugin:

```vim
" Set custom Claude CLI command path (optional, default: 'claude')
let g:claude_cli_command = '/path/to/claude'

" Disable default key mapping (optional)
let g:claude_no_default_mappings = 1

" Set custom key mapping (if default is disabled)
vmap <Leader>ai <Plug>ClaudePrompt
```

## Troubleshooting

**Error: "Claude CLI not found"**
- Make sure Claude Code is installed and the `claude` command is in your PATH
- Or set `g:claude_cli_command` to the full path of the Claude CLI

**No response from Claude**
- Check your internet connection
- Make sure you're logged into Claude Code
- Try running `claude "test"` in your terminal to verify it works

**Plugin not loading**
- Make sure Pathogen is set up correctly
- Check that the plugin is in `~/.vim/bundle/vim-claude/`
- Try running `:scriptnames` in Vim to see if the plugin loaded

## Requirements

- Vim 8.0+
- Claude Code installed and accessible via CLI
- Active Claude subscription (Pro or Max)

## License

MIT

## Contributing

Issues and pull requests are welcome!
