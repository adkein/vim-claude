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
  " Check if API key is set
  if empty(g:claude_api_key)
    return {'success': 0, 'error': 'API key not set. Set g:claude_api_key or ANTHROPIC_API_KEY environment variable.'}
  endif

  " Create the Python script
  let l:python_script = claude#GetPythonScript()

  " Escape the text for passing to Python
  let l:selected_escaped = substitute(a:selected_text, "'", "'\\\\''", 'g')
  let l:prompt_escaped = substitute(a:user_prompt, "'", "'\\\\''", 'g')
  let l:api_key_escaped = substitute(g:claude_api_key, "'", "'\\\\''", 'g')

  " Create temporary file for the Python script
  let l:temp_script = tempname() . '.py'
  call writefile(split(l:python_script, "\n"), l:temp_script)

  " Call Python script
  let l:cmd = printf("python3 '%s' '%s' '%s' '%s' '%s' '%d'",
        \ l:temp_script,
        \ l:api_key_escaped,
        \ l:selected_escaped,
        \ l:prompt_escaped,
        \ g:claude_model,
        \ g:claude_max_tokens)

  let l:output = system(l:cmd)
  let l:exit_code = v:shell_error

  " Clean up temp file
  call delete(l:temp_script)

  if l:exit_code != 0
    return {'success': 0, 'error': l:output}
  endif

  " Parse the response
  try
    let l:result = json_decode(l:output)
    if has_key(l:result, 'error')
      return {'success': 0, 'error': l:result.error}
    else
      return {'success': 1, 'content': l:result.content}
    endif
  catch
    return {'success': 0, 'error': 'Failed to parse API response: ' . l:output}
  endtry
endfunction

function! claude#GetPythonScript() abort
  return join([
        \ 'import sys',
        \ 'import json',
        \ 'try:',
        \ '    import anthropic',
        \ 'except ImportError:',
        \ '    print(json.dumps({"error": "anthropic package not installed. Run: pip install anthropic"}))',
        \ '    sys.exit(1)',
        \ '',
        \ 'def main():',
        \ '    api_key = sys.argv[1]',
        \ '    selected_text = sys.argv[2]',
        \ '    user_prompt = sys.argv[3]',
        \ '    model = sys.argv[4]',
        \ '    max_tokens = int(sys.argv[5])',
        \ '',
        \ '    client = anthropic.Anthropic(api_key=api_key)',
        \ '',
        \ '    try:',
        \ '        message = client.messages.create(',
        \ '            model=model,',
        \ '            max_tokens=max_tokens,',
        \ '            messages=[{',
        \ '                "role": "user",',
        \ '                "content": f"{user_prompt}\n\n{selected_text}"',
        \ '            }]',
        \ '        )',
        \ '        content = message.content[0].text',
        \ '        print(json.dumps({"content": content}))',
        \ '    except Exception as e:',
        \ '        print(json.dumps({"error": str(e)}))',
        \ '        sys.exit(1)',
        \ '',
        \ 'if __name__ == "__main__":',
        \ '    main()',
        \ ], "\n")
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
