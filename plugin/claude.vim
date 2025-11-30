" vim-claude: Integrate Claude AI into Vim
" Maintainer: Your Name
" Version: 0.5.1

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

" Commands for visual mode
vnoremap <silent> <Plug>ClaudePrompt :<C-U>call claude#ProcessSelection()<CR>
vnoremap <silent> <Plug>ClaudePromptReplace :<C-U>call claude#ProcessSelectionReplace()<CR>
vnoremap <silent> <Plug>ClaudePromptSplit :<C-U>call claude#ProcessSelectionSplit()<CR>

" Commands for normal mode (whole file)
nnoremap <silent> <Plug>ClaudeFilePrompt :call claude#ProcessFile()<CR>
nnoremap <silent> <Plug>ClaudeFilePromptReplace :call claude#ProcessFileReplace()<CR>
nnoremap <silent> <Plug>ClaudeFilePromptSplit :call claude#ProcessFileSplit()<CR>

" Default key mappings (can be overridden by user)
if !exists('g:claude_no_default_mappings')
  " Visual mode mappings
  vmap <Leader>c <Plug>ClaudePrompt
  vmap <Leader>cr <Plug>ClaudePromptReplace
  vmap <Leader>cs <Plug>ClaudePromptSplit

  " Normal mode mappings (whole file)
  nmap <Leader>c <Plug>ClaudeFilePrompt
  nmap <Leader>cr <Plug>ClaudeFilePromptReplace
  nmap <Leader>cs <Plug>ClaudeFilePromptSplit
endif

" Session management commands
command! ClaudeNewSession call claude#NewSession()
command! ClaudeShowSession call claude#ShowSessionId()
command! ClaudeResendFile call claude#ResendFile()
