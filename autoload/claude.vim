" Autoload functions for vim-claude

" Script-local state for async processing
let s:claude_state = {
      \ 'output': [],
      \ 'selected_text': '',
      \ 'user_prompt': '',
      \ 'timer': -1,
      \ 'spinner_idx': 0,
      \ 'processing': 0,
      \ 'temp_file': '',
      \ 'action': '',
      \ 'session_id': '',
      \ 'whole_file': 0
      \ }

" Track which buffers have been sent to Claude this session
let s:buffers_sent = {}

" Generate a UUID v4 for session tracking
function! s:GenerateUUID() abort
  " UUID v4 generation with timestamp for better uniqueness
  let l:chars = '0123456789abcdef'
  let l:uuid = ''

  " Seed random with current time for better entropy
  " Use modulo to keep seed in valid range for srand()
  let l:seed = (localtime() + reltimefloat(reltime()) * 1000000) % 0x7FFFFFFF
  call srand(l:seed)

  for l:i in range(36)
    if l:i == 8 || l:i == 13 || l:i == 18 || l:i == 23
      let l:uuid .= '-'
    elseif l:i == 14
      " Version 4
      let l:uuid .= '4'
    elseif l:i == 19
      " Variant bits (10xx) - should be 8, 9, a, or b
      let l:uuid .= l:chars[8 + (rand() % 4)]
    else
      let l:uuid .= l:chars[rand() % 16]
    endif
  endfor

  return l:uuid
endfunction

" Initialize session ID
let s:claude_state.session_id = s:GenerateUUID()

let s:spinner_frames = ['|', '/', '-', '\']

function! claude#ProcessSelection(...) abort
  " Check if already processing
  if s:claude_state.processing
    echo "Already processing a request. Please wait..."
    return
  endif

  " Get optional action parameter ('r' for replace, 's' for split, '' for prompt)
  let l:action = a:0 > 0 ? a:1 : ''

  " Save the current selection
  let l:save_reg = @"
  normal! gvy
  let l:selected_text = @"
  let @" = l:save_reg

  " Get the prompt from the user
  call inputsave()
  let l:user_prompt = input('Claude prompt: ')
  call inputrestore()

  if empty(l:user_prompt)
    echo "\nCancelled."
    return
  endif

  " Store state for async callback
  let s:claude_state.selected_text = l:selected_text
  let s:claude_state.user_prompt = l:user_prompt
  let s:claude_state.processing = 1
  let s:claude_state.output = []
  let s:claude_state.action = l:action

  " Start the spinner
  call claude#StartSpinner()

  " Call the API asynchronously
  call claude#CallAPIAsync(l:selected_text, l:user_prompt)
endfunction

function! claude#ProcessSelectionReplace() abort
  call claude#ProcessSelection('r')
endfunction

function! claude#ProcessSelectionSplit() abort
  call claude#ProcessSelection('s')
endfunction

function! claude#ProcessFile(...) abort
  " Check if already processing
  if s:claude_state.processing
    echo "Already processing a request. Please wait..."
    return
  endif

  " Get optional action parameter ('r' for replace, 's' for split, '' for prompt)
  let l:action = a:0 > 0 ? a:1 : ''

  " Check if this buffer has been sent before
  let l:bufnr = bufnr('%')
  let l:file_content = ''
  let l:prompt_suffix = ''

  if !has_key(s:buffers_sent, l:bufnr)
    " First time for this buffer - send whole file
    let l:file_content = join(getline(1, '$'), "\n")
    let s:buffers_sent[l:bufnr] = 1
    let l:prompt_suffix = ' (whole file)'
  else
    " Already sent this buffer - just send prompt
    let l:file_content = ''
    let l:prompt_suffix = ''
  endif

  " Get the prompt from the user
  call inputsave()
  let l:user_prompt = input('Claude prompt' . l:prompt_suffix . ': ')
  call inputrestore()

  if empty(l:user_prompt)
    echo "\nCancelled."
    return
  endif

  " Store state for async callback
  let s:claude_state.selected_text = l:file_content
  let s:claude_state.user_prompt = l:user_prompt
  let s:claude_state.processing = 1
  let s:claude_state.output = []
  let s:claude_state.action = l:action
  let s:claude_state.whole_file = 1

  " Start the spinner
  call claude#StartSpinner()

  " Call the API asynchronously
  call claude#CallAPIAsync(l:file_content, l:user_prompt)
endfunction

function! claude#ProcessFileReplace() abort
  call claude#ProcessFile('r')
endfunction

function! claude#ProcessFileSplit() abort
  call claude#ProcessFile('s')
endfunction

function! claude#NewSession() abort
  if s:claude_state.processing
    echo "Cannot start new session while processing. Please wait..."
    return
  endif

  let s:claude_state.session_id = s:GenerateUUID()
  let s:buffers_sent = {}
  echo "New Claude session started: " . s:claude_state.session_id
endfunction

function! claude#ShowSessionId() abort
  echo "Current Claude session ID: " . s:claude_state.session_id
endfunction

function! claude#ResendFile() abort
  if s:claude_state.processing
    echo "Cannot resend file while processing. Please wait..."
    return
  endif

  " Clear this buffer from sent tracking
  let l:bufnr = bufnr('%')
  if has_key(s:buffers_sent, l:bufnr)
    unlet s:buffers_sent[l:bufnr]
    echo "Buffer marked to resend on next normal mode prompt"
  else
    echo "Buffer hasn't been sent yet"
  endif
endfunction

function! claude#StartSpinner() abort
  let s:claude_state.spinner_idx = 0
  let s:claude_state.timer = timer_start(100, function('claude#UpdateSpinner'), {'repeat': -1})
endfunction

function! claude#UpdateSpinner(timer) abort
  let l:frame = s:spinner_frames[s:claude_state.spinner_idx % len(s:spinner_frames)]
  let l:model_display = toupper(g:claude_model[0]) . g:claude_model[1:]
  echon "\r" . l:frame . " Processing with Claude (" . l:model_display . ")... "
  redraw
  let s:claude_state.spinner_idx += 1
endfunction

function! claude#StopSpinner() abort
  if s:claude_state.timer != -1
    call timer_stop(s:claude_state.timer)
    let s:claude_state.timer = -1
  endif
  echon "\r"
  echo " "
  redraw
endfunction

function! claude#CallAPIAsync(selected_text, user_prompt) abort
  " Check if claude CLI is available
  if !executable(g:claude_cli_command)
    call claude#StopSpinner()
    let s:claude_state.processing = 0
    echohl ErrorMsg
    echo "Claude CLI not found. Please install Claude Code or set g:claude_cli_command to the correct path."
    echohl None
    return
  endif

  " Build the full prompt
  if !empty(a:selected_text)
    let l:full_prompt = a:user_prompt . "\n\nHere is the text/code:\n\n" . a:selected_text
  else
    " No text/code to send (already sent in session context)
    let l:full_prompt = a:user_prompt
  endif

  " Create a temporary file with the prompt
  let l:temp_input = tempname()
  call writefile(split(l:full_prompt, "\n"), l:temp_input)

  " Store temp file path in state for cleanup later
  let s:claude_state.temp_file = l:temp_input

  " Build command to pipe temp file to claude with session ID
  let l:cmd = printf('%s --model %s --session-id %s < %s',
        \ g:claude_cli_command,
        \ g:claude_model,
        \ s:claude_state.session_id,
        \ shellescape(l:temp_input))

  " Start the job
  let l:job = job_start(['/bin/sh', '-c', l:cmd], {
        \ 'out_cb': function('claude#OnOutput'),
        \ 'err_cb': function('claude#OnError'),
        \ 'exit_cb': function('claude#OnExit'),
        \ 'close_cb': function('claude#OnClose')
        \ })

  if job_status(l:job) == 'fail'
    call claude#StopSpinner()
    let s:claude_state.processing = 0
    call delete(l:temp_input)
    let s:claude_state.temp_file = ''
    echohl ErrorMsg
    echo "Failed to start Claude CLI job"
    echohl None
  endif
endfunction

function! claude#OnOutput(channel, msg) abort
  call add(s:claude_state.output, a:msg)
endfunction

function! claude#OnError(channel, msg) abort
  call add(s:claude_state.output, a:msg)
endfunction

function! claude#OnExit(job, exit_status) abort
  " Clean up temp file
  if !empty(s:claude_state.temp_file) && filereadable(s:claude_state.temp_file)
    call delete(s:claude_state.temp_file)
    let s:claude_state.temp_file = ''
  endif
endfunction

function! claude#OnClose(channel) abort
  " Stop the spinner
  call claude#StopSpinner()

  " Get the job info
  let l:job = ch_getjob(a:channel)
  let l:exit_status = job_info(l:job).exitval

  " Process the response
  let l:content = join(s:claude_state.output, "\n")

  " Reset processing state
  let s:claude_state.processing = 0

  if l:exit_status != 0 || empty(l:content)
    " Check if session ID conflict
    if l:content =~# 'Session ID.*is already in use'
      " Generate new session ID and inform user
      let s:claude_state.session_id = s:GenerateUUID()
      let s:buffers_sent = {}
      echohl WarningMsg
      echo "Session ID conflict detected. Generated new session ID. Please retry your request."
      echohl None
    else
      echohl ErrorMsg
      echo "Claude CLI error: " . (empty(l:content) ? "No response received" : l:content)
      echohl None
    endif
    return
  endif

  " Determine action (use pre-selected or prompt user)
  let l:action = s:claude_state.action
  if empty(l:action)
    call inputsave()
    let l:action = input('Action: (r)eplace, (s)how in split: ')
    call inputrestore()
  endif

  if l:action ==# 'r'
    if s:claude_state.whole_file
      " Replace entire buffer
      call claude#ReplaceBuffer(l:content)
    else
      " Replace the selection
      normal! gvd
      call claude#InsertText(l:content)
    endif
  elseif l:action ==# 's'
    " Show in a split
    call claude#ShowInSplit(l:content, s:claude_state.user_prompt)
  else
    echo "\nInvalid action. Cancelled."
  endif

  " Reset whole_file flag
  let s:claude_state.whole_file = 0
endfunction

function! claude#ReplaceBuffer(text) abort
  " Replace entire buffer with new content
  " Save cursor position
  let l:save_cursor = getcurpos()

  " Delete all lines
  silent! %delete _

  " Insert new content
  let l:lines = split(a:text, "\n", 1)
  call setline(1, l:lines)

  " Try to restore cursor position (may be out of range now)
  try
    call setpos('.', l:save_cursor)
  catch
    " If position is invalid, go to first line
    normal! gg
  endtry

  echo "Buffer replaced with Claude's response"
endfunction

function! claude#InsertText(text) abort
  " Insert the text at the cursor position
  let l:lines = split(a:text, "\n", 1)

  if len(l:lines) == 1
    execute "normal! i" . l:lines[0]
  else
    " Insert first line
    execute "normal! i" . l:lines[0]

    " Insert remaining lines
    for l:line in l:lines[1:]
      execute "normal! o" . l:line
    endfor
  endif
endfunction

function! claude#ShowInSplit(content, prompt) abort
  " Create a new split window
  new

  " Set buffer options
  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal noswapfile
  setlocal wrap

  " Set buffer name
  execute 'file Claude:\ ' . escape(a:prompt, ' ')

  " Insert the content
  call setline(1, split(a:content, "\n"))

  " Set read-only
  setlocal nomodifiable

  " Set syntax highlighting based on detected filetype
  execute 'setlocal filetype=' . &filetype

  " Move cursor to the top
  normal! gg
endfunction
