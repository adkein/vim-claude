# vim-claude

A Vim plugin to integrate Claude AI directly into your editor. Select text, ask Claude what to do with it, and get instant AI-powered assistance.

## Features

- **Visual Selection Integration**: Select any text in visual mode and send it to Claude with a custom prompt
- **Flexible Output Options**:
  - Replace the selected text with Claude's response
  - Insert Claude's response below the selection
  - Show the response in a new split window
- **Customizable**: Configure your preferred Claude model, API key, and key mappings

## Installation

### Prerequisites

1. Python 3 installed on your system
2. Anthropic Python SDK:
   ```bash
   pip install anthropic
   ```

3. An Anthropic API key (get one at https://console.anthropic.com/)

### Using Pathogen

1. Clone this repository into your Vim bundle directory:
   ```bash
   cd ~/.vim/bundle
   git clone https://github.com/yourusername/vim-claude.git
   ```

2. Set your API key in your `.vimrc`:
   ```vim
   let g:claude_api_key = 'your-api-key-here'
   ```

   Or set the `ANTHROPIC_API_KEY` environment variable:
   ```bash
   export ANTHROPIC_API_KEY='your-api-key-here'
   ```

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
" Set API key (required if not using environment variable)
let g:claude_api_key = 'your-api-key-here'

" Set Claude model (optional, default: claude-sonnet-4-20250514)
let g:claude_model = 'claude-sonnet-4-20250514'

" Set max tokens (optional, default: 4096)
let g:claude_max_tokens = 8192

" Disable default key mapping (optional)
let g:claude_no_default_mappings = 1

" Set custom key mapping (if default is disabled)
vmap <Leader>ai <Plug>ClaudePrompt
```

## Commands

- `:ClaudeSetAPIKey <key>` - Set the API key from within Vim

## Troubleshooting

**Error: "anthropic package not installed"**
- Run: `pip install anthropic`

**Error: "API key not set"**
- Set `g:claude_api_key` in your `.vimrc` or set the `ANTHROPIC_API_KEY` environment variable

**No response from Claude**
- Check your internet connection
- Verify your API key is valid
- Check if you have API credits remaining

## Requirements

- Vim 8.0+ (with Python 3 support)
- Python 3.6+
- `anthropic` Python package
- Valid Anthropic API key

## License

MIT

## Contributing

Issues and pull requests are welcome!
