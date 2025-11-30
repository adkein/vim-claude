" Autoload functions for vim-claude

" Script-local state for async processing
let s:claude_state = {
      \ 'output': [],
      \ 'selected_text': '',
      \ 'user_prompt': '',
      \ 'timer': -1,
      \ 'spinner_idx': 0,
      \ 'processing': 0
      \ }

let s:spinner_frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏']

function! claude#ProcessSelection() abort
  " Check if already processing
  if s:claude_state.processing
    echo "Already processing a request. Please wait..."
    return
  endif

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

  " Start the spinner
  call claude#StartSpinner()

  " Call the API asynchronously
  call claude#CallAPIAsync(l:selected_text, l:user_prompt)
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
  let l:full_prompt = a:user_prompt . "\n\nHere is the text/code:\n\n" . a:selected_text

  " Create a temporary file with the prompt
  let l:temp_input = tempname()
  call writefile(split(l:full_prompt, "\n"), l:temp_input)

  " Build command to pipe temp file to claude
  let l:cmd = printf('%s --model %s < %s', g:claude_cli_command, g:claude_model, shellescape(l:temp_input))

  " Start the job
  let l:job = job_start(['/bin/sh', '-c', l:cmd], {
        \ 'out_cb': function('claude#OnOutput'),
        \ 'err_cb': function('claude#OnError'),
        \ 'exit_cb': function('claude#OnExit'),
        \ 'close_cb': function('claude#OnClose'),
        \ 'temp_file': l:temp_input
        \ })

  if job_status(l:job) == 'fail'
    call claude#StopSpinner()
    let s:claude_state.processing = 0
    call delete(l:temp_input)
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
  " Get temp file from job info and clean up
  let l:job_info = job_info(a:job)
  if has_key(l:job_info, 'temp_file')
    call delete(l:job_info.temp_file)
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
    echohl ErrorMsg
    echo "Claude CLI error: " . (empty(l:content) ? "No response received" : l:content)
    echohl None
    return
  endif

  " Ask user what to do with the response
  call inputsave()
  let l:action = input('Action: (r)eplace, (i)nsert below, (s)how in split: ')
  call inputrestore()

  if l:action ==# 'r'
    " Replace the selection
    normal! gvd
    call claude#InsertText(l:content)
  elseif l:action ==# 'i'
    " Insert below the selection
    normal! gv
    execute "normal! o\<Esc>"
    call claude#InsertText(l:content)
  elseif l:action ==# 's'
    " Show in a split
    call claude#ShowInSplit(l:content, s:claude_state.user_prompt)
  else
    echo "\nInvalid action. Cancelled."
  endif
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
  setlocal nowrap

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
