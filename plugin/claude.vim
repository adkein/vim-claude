" vim-claude: Integrate Claude AI into Vim
" Maintainer: Your Name
" Version: 0.1.0

if exists('g:loaded_claude')
  finish
endif
let g:loaded_claude = 1

" Default configuration
if !exists('g:claude_api_key')
  let g:claude_api_key = $ANTHROPIC_API_KEY
endif

if !exists('g:claude_model')
  let g:claude_model = 'claude-sonnet-4-20250514'
endif

if !exists('g:claude_max_tokens')
  let g:claude_max_tokens = 4096
endif

" Main command for visual mode
vnoremap <silent> <Plug>ClaudePrompt :<C-U>call claude#ProcessSelection()<CR>

" Default key mapping (can be overridden by user)
if !exists('g:claude_no_default_mappings')
  vmap <Leader>c <Plug>ClaudePrompt
endif

" Command for setting API key
command! -nargs=1 ClaudeSetAPIKey :let g:claude_api_key = <q-args>
