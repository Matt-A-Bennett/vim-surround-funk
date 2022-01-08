" Author:       Matthew Bennett
" Version:      0.3.1
"
" The following column indices are found in the current line:
"
"    np.outerfunc(np.innerfunc(arg1), arg2)
"    ^  ^        ^                  ^     ^
"    1a 1b       2                  3     4
"
" Then we delete/yank 1:2, and 3:4

"- setup ----------------------------------------------------------------------
if exists("g:loaded_surround_funk") || &cp || v:version < 700
  finish
endif
let g:loaded_surround_funk = 1

let s:legal_func_name_chars = ['\w', '\d', '\.', '_']
let s:legal_func_name_chars = join(s:legal_func_name_chars, '\|')

"- helper functions -----------------------------------------------------------
function! s:is_greater_or_lesser(v1, v2, greater_or_lesser)
    if a:greater_or_lesser ==# '>'
        return a:v1 > a:v2
    else
        return a:v1 < a:v2
    endif
endfunction

function! s:searchpairpos2(start, middle, end, flag)
    let [_, _, c, _] = getpos('.')
    if a:flag ==# 'b'
        let f1 = 'b'
        let f2 = ''
        let g_or_l = '>'
    else
        let f1 = ''
        let f2 = 'b'
        let g_or_l = '<'
    endif
    call searchpair(a:start, '', a:end, f1)
    let end_c = col(".")
    call searchpair(a:start, '', a:end, f2)
    let [_, c] = searchpos(a:middle, f1, line(".")) 
    if s:is_greater_or_lesser(c, end_c, g_or_l)
        return c
    else
        return 0
    endif
    call cursor('.', c)
endfunction

function! s:searchpair2(start, middle, end, flag)
     let c = s:searchpair2(a:start, a:middle, a:end, a:flag)
     if c > 0
         call cursor('.', c)
     endif
endfunction

function! s:get_char_under_cursor()
     return getline(".")[col(".")-1]
endfunction

function! s:string2list(str)
    let str = a:str
    if str ==# '.'
        let str = getline('.')
    endif
    return split(str, '\zs')
endfunction

"- functions to get marker positions ------------------------------------------
function! s:get_func_open_paren_column()
    let [_, _, c, _] = getpos('.')
    " move forward to one of function's parentheses (unless already on one)
    call search('(\|)', 'c', line('.'))
    " if we're on the closing parenthsis, move to other side
    if s:get_char_under_cursor() ==# ')'
        call searchpair('(','',')', 'b')
    endif
    call cursor('.', c)
    return col('.')
endfunction

function! s:move_to_func_open_paren()
    call cursor('.', s:get_func_open_paren_column())
endfunction

function! s:get_start_of_func_column(word_size)
    let [_, _, c, _] = getpos('.')
    call s:move_to_func_open_paren()
    if a:word_size ==# 'small'
        let [_, c] = searchpos('\<', 'b', line('.'))
    else
        let [_, c] = searchpos('\('.s:legal_func_name_chars.'\)\@<!', 'b', line('.'))
    endif
    call cursor('.', c)
    return c
endfunction

function! s:move_to_start_of_func(word_size)
    call cursor('.', s:get_start_of_func_column(a:word_size))
endfunction

function! s:get_end_of_func_column()
    let [_, _, c, _] = getpos('.')
    call s:move_to_func_open_paren()
    let [_, c] = searchpairpos('(','',')')
    call cursor('.', c)
    return c
endfunction

function! s:move_to_end_of_func()
    call cursor('.', s:get_end_of_func_column())
endfunction

function! s:get_start_of_trailing_args_column()
    let [_, _, c, _] = getpos('.')
    call s:move_to_func_open_paren()
    let c = s:searchpairpos2('(', ')', ')', '')
    call cursor('.', c)
    if c > 0
        return c
    else
        return s:get_end_of_func_column()
    endif
endfunction

function! s:get_substring(str, c1, c2)
    let chars = s:string2list(a:str)
    return join(chars[a:c1-1:a:c2-2], '')
endfunction

function! s:remove_substring(str, c1, c2)
    let chars = s:string2list(a:str)
    call remove(chars, a:c1-1, a:c2)
    return join(chars, '')
endfunction

function! s:is_cursor_on_func()
    let [_, _, c, _] = getpos('.')
    if s:get_char_under_cursor() =~ '(\|)'
        return 1
    endif
    let chars = s:string2list('.')
    let right = chars[col("."):]
    let on_func_name = s:get_char_under_cursor() =~ s:legal_func_name_chars.'\|('
    let open_paren_count = 0
    let close_paren_count = 0
    for char in right
        if on_func_name && char !~ s:legal_func_name_chars.'\|('
            let on_func_name = 0
        endif
        if char ==# '('
            if on_func_name
                call cursor('.', c)
                return 1
            endif
            " I could jump to the matching ')' at this point to speed things up
            let open_paren_count+=1
        elseif char ==# '('
            let close_paren_count+=1
        endif
    endfor
    call cursor('.', c)
    return close_paren_count > open_paren_count
endfunction

function! s:get_func_markers(word_size)
    let fstart = s:get_start_of_func_column(a:word_size)
    let fopen = s:get_func_open_paren_column()
    let ftrail = s:get_start_of_trailing_args_column()
    let fclose = s:get_end_of_func_column()
    return [fstart, fopen, ftrail, fclose]
endfunction

"    np.outerfunc(np.innerfunc(arg1), arg2)
"    ^  ^        ^                  ^     ^
"    1a 1b       2                  3     4
"
" Then we delete/yank 1:2, and 3:4

function! s:delete_surrounding_func(word_size)
    let [fstart, fopen, ftrail, fclose] = s:get_func_markers(a:word_size)
    let str = getline('.')
    let str = s:remove_substring(str, fstart, fopen) 
    call setline('.', str)
    echo 'TEST'
endfunction

" function! s:delete_surrounding_func(word_size)
"     " we'll restore the f register later so it isn't clobbered here
"     let l:freg = @f
"     call s:move_to_start_of_func(a:word_size)
"     " delete function name into the f register and mark opening parenthesis 
"     silent! execute 'normal! "fdt(mo'
"     " yank opening parenthesis into f register
"     silent! execute 'normal! "Fyl'
"     " mark closing parenthesis
"     silent! execute 'normal! %mc'
"     " note where the function ends
"     let close = col('.')
"     " move back to opening paranthesis
"     silent! execute 'normal! %'
"     " search on the same line for an opening paren before the closing paren 
"     if search("(", '', line('.')) && col('.') < close
"         " move to matching paren and delete everthing up to the closing paren
"         " of the original function (remark closing paren)
"         silent! execute 'normal! %l"Fd`cmc'
"     endif
"     " delete the closing and opening parens (put the closing one into register)
"     silent! execute 'normal! `c"Fx`ox'
"     " paste the function into unamed register
"     let @"=@f
"     " restore the f register
"     let @f = l:freg
" endfunction

function! s:change_surrounding_func(word_size)
    call s:delete_surrounding_func(a:word_size)
    startinsert
endfunction

function! s:yank_surrounding_func(word_size)
    " store the current line
    silent! execute 'normal! "lyy'
    call s:delete_surrounding_func(a:word_size)
    " restore the current line to original state
    silent! execute 'normal! "_dd"lP'
endfunction

function! s:paste_func_around_func(word_size)
    " we'll restore the unnamed register later so it isn't clobbered here
    let l:unnamed_reg = @"
    if s:is_cursor_on_func()
        call s:move_to_start_of_func(a:word_size)
        " paste just behind existing function
        silent! execute 'normal! P'
        " mark closing parenthesis
        silent! execute 'normal! f(%mc'
        " move back onto start of function name
        call s:move_to_start_of_func(a:word_size)
        " delete the whole function (including last parenthesis)
        silent! execute 'normal! d`c"_x'
        " if we're not already on a last parenthesis, move back to it
        call search(')', 'bc', line('.'))
        " move to opening surrounding paren and paste original function, then add
        " surrounding parenthesis back in
        silent! execute 'normal! %pa)'
        " leave the cursor on the opening parenthesis of the surrounding function
        silent! execute 'normal! `c%'
        " restore unnamed register
        let @" = l:unnamed_reg
    else
        " we're on a word, not a function
        call s:paste_func_around_word(a:word_size)
    endif
endfunction

function! s:paste_func_around_word(word_size)
    " we'll restore the unnamed register later so it isn't clobbered here
    let l:unnamed_reg = @"
    if a:word_size ==# 'small'
        " get onto start of the word
        silent! execute 'normal! lb'
        " paste the function behind and move back to the word
        silent! execute 'normal! Pl'
        " delete the word
        silent! execute 'normal! diw'
    elseif a:word_size ==# 'big'
        " find first boundary before function that we don't want to cross
        call search(' \|,\|;\|(\|^', 'b', line('.'))
        " If we're not at the start of the line, or if we're on whitespace
        if col('.') > 1 || s:get_char_under_cursor() ==# ' '
            silent! execute 'normal! l'
        endif
        " paste the function behind and move back to the word
        silent! execute 'normal! Pl'
        " delete WORD
        silent! execute 'normal! dW'
    endif
    " if we're not already on a last parenthesis, move back to it
    call search(')', 'bc', line('.'))
    " move to start of function and mark it, paste the word, move back to start
    silent! execute 'normal! %mop`o'
    " restore unnamed register
    let @" = l:unnamed_reg
endfunction

nnoremap <silent> <Plug>DeleteSurroundingFunction :<C-U>call <SID>delete_surrounding_func("small")<CR>
nnoremap <silent> <Plug>DeleteSurroundingFUNCTION :<C-U>call <SID>delete_surrounding_func("big")<CR>
nnoremap <silent> <Plug>ChangeSurroundingFunction :<C-U>call <SID>change_surrounding_func("small")<CR>
nnoremap <silent> <Plug>ChangeSurroundingFUNCTION :<C-U>call <SID>change_surrounding_func("big")<CR>
nnoremap <silent> <Plug>YankSurroundingFunction :<C-U>call <SID>yank_surrounding_func("small")<CR>
nnoremap <silent> <Plug>YankSurroundingFUNCTION :<C-U>call <SID>yank_surrounding_func("big")<CR>
nnoremap <silent> <Plug>PasteFunctionAroundFunction :<C-U>call <SID>paste_func_around_func("small")<CR>
nnoremap <silent> <Plug>PasteFunctionAroundFUNCTION :<C-U>call <SID>paste_func_around_func("big")<CR>
nnoremap <silent> <Plug>PasteFunctionAroundWord :<C-U>call <SID>paste_func_around_word("small")<CR>
nnoremap <silent> <Plug>PasteFunctionAroundWORD :<C-U>call <SID>paste_func_around_word("big")<CR>

nmap dsf <Plug>DeleteSurroundingFunction
nmap dsF <Plug>DeleteSurroundingFUNCTION
nmap csf <Plug>ChangeSurroundingFunction
nmap csF <Plug>ChangeSurroundingFUNCTION
nmap ysf <Plug>YankSurroundingFunction
nmap ysF <Plug>YankSurroundingFUNCTION
nmap gsf <Plug>PasteFunctionAroundFunction
nmap gsF <Plug>PasteFunctionAroundFUNCTION
nmap gsw <Plug>PasteFunctionAroundWord
nmap gsW <Plug>PasteFunctionAroundWORD
