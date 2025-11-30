# vim-claude

A Vim plugin to integrate Claude AI directly into your editor using Claude Code. Select text, ask Claude what to do with it, and get instant AI-powered assistance - all covered by your existing Claude subscription!

## Features

- **Dual Mode Operation**:
  - Visual mode: Work with selected text
  - Normal mode: Send entire file as context
- **Persistent Conversation Sessions**: All requests in the same Vim session maintain context with each other
- **Async Processing with Progress Indicator**: Animated ASCII spinner shows progress while Claude thinks
- **Flexible Output Options**:
  - Replace the selection/file with Claude's response
  - Show the response in a new split window
- **No API Keys Required**: Uses Claude Code CLI, so it's covered by your existing Claude subscription
- **Customizable**: Configure key mappings, CLI path, and model selection
- **Non-blocking**: Continue viewing your code while waiting for responses

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

**Visual Mode (Selection):**
1. Enter visual mode and select some text (`v`, `V`, or `Ctrl-v`)
2. Press `<Leader>c` (default mapping, typically `\c`)
3. Enter your prompt when prompted (e.g., "Explain this code" or "Fix the bug")
4. Wait for Claude to process your request
5. Choose an action:
   - `r` - Replace the selected text
   - `s` - Show in a new split window

**Normal Mode (Whole File):**
1. In normal mode, press `<Leader>c` (no selection needed)
2. Enter your prompt (e.g., "Add error handling throughout" or "Review this code")
3. Wait for Claude to process the entire file
4. Choose an action:
   - `r` - Replace the entire file with Claude's response
   - `s` - Show response in a new split window

**Quick Actions:**
- Visual mode: `<Leader>cr` / `<Leader>cs` - Replace/split selected text
- Normal mode: `<Leader>cr` / `<Leader>cs` - Replace/split entire file

### Example Workflows

**Explaining selected code (visual mode):**
```
1. Select a function in visual mode
2. Press <Leader>cs (show in split)
3. Type: "Explain what this function does"
4. View explanation in split window
```

**Refactoring selected code (visual mode):**
```
1. Select code to refactor
2. Press <Leader>cr (replace)
3. Type: "Refactor this to be more efficient"
4. Selected code is replaced with refactored version
```

**Reviewing entire file (normal mode):**
```
1. In normal mode (no selection)
2. Press <Leader>cs
3. Type: "Review this code for bugs and suggest improvements"
4. See review in split window
```

**Refactoring entire file (normal mode):**
```
1. In normal mode (no selection)
2. Press <Leader>cr
3. Type: "Add comprehensive error handling"
4. Entire file is replaced with improved version
```

**Continuing a conversation:**
```
1. Select code -> \cs -> "Explain this function"
   (Claude explains the function)
2. Select different code -> \cs -> "How does this relate to the function you just explained?"
   (Claude remembers the previous function and compares)
3. Select code -> \cr -> "Now refactor it using the pattern we discussed"
   (Claude refactors based on the full conversation context)
```

All requests in the same Vim session share conversation history automatically!

## Configuration

Add these to your `.vimrc` to customize the plugin:

```vim
" Set Claude model (optional, default: 'sonnet')
" Options: 'sonnet', 'opus', 'haiku'
let g:claude_model = 'sonnet'

" Set custom Claude CLI command path (optional, default: 'claude')
let g:claude_cli_command = '/path/to/claude'

" Disable default key mappings (optional)
let g:claude_no_default_mappings = 1

" Set custom key mappings (if defaults are disabled)
" Visual mode (selection)
vmap <Leader>ai <Plug>ClaudePrompt
vmap <Leader>air <Plug>ClaudePromptReplace
vmap <Leader>ais <Plug>ClaudePromptSplit

" Normal mode (whole file)
nmap <Leader>ai <Plug>ClaudeFilePrompt
nmap <Leader>air <Plug>ClaudeFilePromptReplace
nmap <Leader>ais <Plug>ClaudeFilePromptSplit
```

## Session Management

The plugin automatically maintains conversation context across all requests in the same Vim session. Each Vim session gets a unique conversation ID.

### Multi-File Context

When using normal mode prompts, each file is sent **only once per session**:

```vim
" file1.py (normal mode)
\cs "What does this do?"  → Sends entire file1.py

" file2.py (switch buffers, normal mode)
\cs "What does this do?"  → Sends entire file2.py

" file1.py (back to first file, normal mode)
\cs "How does this relate to file2?"  → Just sends prompt (Claude has both files)

" Edit file1.py then want Claude to see changes
:ClaudeResendFile
\cs "Review my changes"  → Sends updated file1.py
```

This saves tokens and makes responses faster while still allowing Claude to synthesize information across multiple files.

**Commands:**
- `:ClaudeNewSession` - Start a fresh conversation (next request won't use `-c` flag)
- `:ClaudeResendFile` - Mark current buffer to be resent on next normal mode prompt

**Example use case for new session:**
```vim
" Working on feature A across multiple files
" file1.py
\cs "Review this module"

" file2.py
\cs "How does this interact with file1?"

" Now switching to unrelated feature B - start fresh
:ClaudeNewSession

" All files will be sent fresh again
" file3.py
\cs "Explain this code"  → No context from previous session
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

- Vim 8.0+ (with job and timer support)
- Claude Code installed and accessible via CLI
- Active Claude subscription (Pro or Max)

## How It Works

When you invoke the plugin:
1. Select text and press `<Leader>c`
2. Enter your prompt
3. An animated spinner appears showing Claude is processing
4. You cannot start another request until the current one completes
5. When complete, choose how to display the result

The plugin uses Vim's async job system, so Vim remains responsive while Claude processes your request.

**Session persistence:** The plugin uses Claude Code's `-c` (continue) flag to maintain conversation context. The first request in a Vim session starts a new conversation, and all subsequent requests continue that conversation automatically.

## License

MIT

## Contributing

Issues and pull requests are welcome!
