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

let g:legal_func_name_chars = ['\w', '\d', '\.', '_']
let g:legal_func_name_chars = join(g:legal_func_name_chars, '\|')

"- helper functions -----------------------------------------------------------
function! Is_greater_or_lesser(v1, v2, greater_or_lesser)
    if a:greater_or_lesser ==# '>'
        return a:v1 > a:v2
    else
        return a:v1 < a:v2
    endif
endfunction

function! Searchpairpos2(start, middle, end, flag)
    let [_, _, c_orig, _] = getpos('.')
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
    call cursor('.', c_orig)
    if Is_greater_or_lesser(c, end_c, g_or_l)
        return c
    else
        return 0
    endif
endfunction

function! Searchpair2(start, middle, end, flag)
     let c = Searchpairpos2(a:start, a:middle, a:end, a:flag)
     if c > 0
         call cursor('.', c)
     endif
endfunction

function! Get_char_under_cursor()
     return getline(".")[col(".")-1]
endfunction

function! String2list(str)
    let str = a:str
    if str ==# '.'
        let str = getline('.')
    endif
    return split(str, '\zs')
endfunction

"- functions to get marker positions ------------------------------------------
function! Get_func_open_paren_column()
    let [_, _, c_orig, _] = getpos('.')
    " move forward to one of function's parentheses (unless already on one)
    call search('(\|)', 'c', line('.'))
    " if we're on the closing parenthsis, move to other side
    if Get_char_under_cursor() ==# ')'
        call searchpair('(','',')', 'b')
    endif
    let c = col('.')
    call cursor('.', c_orig)
    return c
endfunction

function! Move_to_func_open_paren()
    call cursor('.', Get_func_open_paren_column())
endfunction

function! Get_start_of_func_column(word_size)
    let [_, _, c_orig, _] = getpos('.')
    call Move_to_func_open_paren()
    if a:word_size ==# 'small'
        let [_, c] = searchpos('\<', 'b', line('.'))
    else
        let [_, c] = searchpos('\('.g:legal_func_name_chars.'\)\@<!', 'b', line('.'))
    endif
    call cursor('.', c_orig)
    return c
endfunction

function! Move_to_start_of_func(word_size)
    call cursor('.', Get_start_of_func_column(a:word_size))
endfunction

function! Get_end_of_func_column()
    let [_, _, c_orig, _] = getpos('.')
    call Move_to_func_open_paren()
    let [_, c] = searchpairpos('(','',')')
    call cursor('.', c_orig)
    return c
endfunction

function! Move_to_end_of_func()
    call cursor('.', Get_end_of_func_column())
endfunction

function! Get_start_of_trailing_args_column()
    let [_, _, c_orig, _] = getpos('.')
    call Move_to_func_open_paren()
    let c = Searchpairpos2('(', ')', ')', '')
    call cursor('.', c_orig)
    if c > 0
        return c+1
    else
        return Get_end_of_func_column()
    endif
endfunction

function! Get_substring(str, c1, c2)
    let chars = String2list(a:str)
    return join(chars[a:c1-1:a:c2-1], '')
endfunction

function! Remove_substring(str, c1, c2)
    let chars = String2list(a:str)
    let removed = remove(chars, a:c1-1, a:c2-1)
    return [join(chars, ''), join(removed, '')]
endfunction

function! Is_cursor_on_func()
    T [_, _, c, _] = getpos('.')
    if Get_char_under_cursor() =~ '(\|)'
        return 1
    endif
    let chars = String2list('.')
    let right = chars[col("."):]
    let on_func_name = Get_char_under_cursor() =~ g:legal_func_name_chars.'\|('
    let open_paren_count = 0
    let close_paren_count = 0
    for char in right
        if on_func_name && char !~ g:legal_func_name_chars.'\|('
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

function! Get_func_markers(word_size)
    let fstart = Get_start_of_func_column(a:word_size)
    let fopen = Get_func_open_paren_column()
    let ftrail = Get_start_of_trailing_args_column()
    let fclose = Get_end_of_func_column()
    return [fstart, fopen, ftrail, fclose]
endfunction

function! Operate_on_surrounding_func(word_size, operation)
    let [fstart, fopen, ftrail, fclose] = Get_func_markers(a:word_size)
    let str = getline('.')
    let offset = fopen-fstart+1
    let [str1, rm1] = Remove_substring(str, fstart, fopen) 
    let [str2, rm2] = Remove_substring(str1, ftrail-offset, fclose-offset) 
    call setreg('"', rm1.rm2)
    call cursor('.', fstart)
    if a:operation =~ 'delete\|change'
        call setline('.', str2)
    endif
    if a:operation =~ 'change'
        startinsert
    endif
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
