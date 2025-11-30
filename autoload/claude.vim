" Autoload functions for vim-claude

function! claude#ProcessSelection() abort
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

  " Show processing message
  echo "\nProcessing with Claude..."
  redraw

  " Call the API
  let l:response = claude#CallAPI(l:selected_text, l:user_prompt)

  if l:response.success
    " Ask user what to do with the response
    call inputsave()
    let l:action = input('Action: (r)eplace, (i)nsert below, (s)how in split: ')
    call inputrestore()

    if l:action ==# 'r'
      " Replace the selection
      normal! gvd
      call claude#InsertText(l:response.content)
    elseif l:action ==# 'i'
      " Insert below the selection
      normal! gv
      execute "normal! o\<Esc>"
      call claude#InsertText(l:response.content)
    elseif l:action ==# 's'
      " Show in a split
      call claude#ShowInSplit(l:response.content, l:user_prompt)
    else
      echo "\nInvalid action. Cancelled."
    endif
  else
    echohl ErrorMsg
    echo "\nError: " . l:response.error
    echohl None
  endif
endfunction

function! claude#CallAPI(selected_text, user_prompt) abort
  " Check if claude CLI is available
  if !executable(g:claude_cli_command)
    return {'success': 0, 'error': 'Claude CLI not found. Please install Claude Code or set g:claude_cli_command to the correct path.'}
  endif

  " Create a temporary file with the selected text
  let l:temp_input = tempname()
  call writefile(split(a:selected_text, "\n"), l:temp_input)

  " Build the full prompt
  let l:full_prompt = a:user_prompt . "\n\nHere is the text/code:\n\n" . a:selected_text

  " Escape single quotes in the prompt for shell
  let l:prompt_escaped = substitute(l:full_prompt, "'", "'\\\\''", 'g')

  " Call Claude Code CLI with model selection
  " Using echo to pipe the prompt to claude
  let l:cmd = printf("printf '%%s' '%s' | %s --model %s 2>&1", l:prompt_escaped, g:claude_cli_command, g:claude_model)

  let l:output = system(l:cmd)
  let l:exit_code = v:shell_error

  " Clean up temp file
  call delete(l:temp_input)

  if l:exit_code != 0
    return {'success': 0, 'error': 'Claude CLI error: ' . l:output}
  endif

  " Claude Code returns the response directly
  return {'success': 1, 'content': l:output}
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
