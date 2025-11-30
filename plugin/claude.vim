" vim-claude: Integrate Claude AI into Vim
" Maintainer: Your Name
" Version: 0.2.0

if exists('g:loaded_claude')
  finish
endif
let g:loaded_claude = 1

" Default configuration
if !exists('g:claude_cli_command')
  let g:claude_cli_command = 'claude'
endif

if !exists('g:claude_model')
  let g:claude_model = 'sonnet'
endif

" Main command for visual mode
vnoremap <silent> <Plug>ClaudePrompt :<C-U>call claude#ProcessSelection()<CR>

" Default key mapping (can be overridden by user)
if !exists('g:claude_no_default_mappings')
  vmap <Leader>c <Plug>ClaudePrompt
endif
