" Author:       Matthew Bennett
" Version:      0.3.1

if exists("g:loaded_surround_funk") || &cp || v:version < 700
  finish
endif
let g:loaded_surround_funk = 1

let s:legal_func_name_chars = ['\w', '\d', '\.', '_']
let s:legal_func_name_chars = join(s:legal_func_name_chars, '\|')

function! s:get_char_under_cursor()
     return getline(".")[col(".")-1]
endfunction

function! s:current_line2list()
    let str = getline(".")
    return split(str, '.\zs\ze.')
endfunction

function! s:searchpair2(start, middle, end, flag)
    if a:flag ==# 'b'
        let f1 = 'b'
        let f2 = ''
    else
        let f1 = ''
        let f2 = 'b'
    endif
    call searchpair(a:start, '', a:end, f1)
    let end_c = col(".")
    call searchpair(a:start, '', a:end, f2)
    if search(a:middle, f1, line(".")) && col('.') < end_c
        return 1
    else
        return 0
    endif
endfunction

function! s:is_cursor_on_function()
    if s:get_char_under_cursor() =~ '(\|)'
        return 1
    endif
    let chars = s:current_line2list()
    let right = chars[col("."):]
    let on_func_name = s:get_char_under_cursor() =~ s:legal_func_name_chars.'\|('
    let open_paren_count = 0
    let close_paren_count = 0
    for char in right
        if on_func_name && char !~ legal_func_name_chars.'\|('
            let on_func_name = 0
        endif
        if char ==# '('
            if on_func_name
                return 1
            endif
            " I could jump to the matching ')' at this point to speed things up
            let open_paren_count+=1
        elseif char ==# '('
            let close_paren_count+=1
        endif
    endfor
    return close_paren_count > open_paren_count
endfunction

function! s:move_to_function_opening_paren()
    " move forward to one of function's parentheses (unless already on one)
    call search('(\|)', 'c', line('.'))
    " if we're on the closing parenthsis, move to other side
    if s:get_char_under_cursor() ==# ')'
        call searchpair('(','',')', 'b')
    endif
endfunction

function! s:move_to_start_of_function(word_size)
    call s:move_to_function_opening_paren()
    " move onto function name 
    if a:word_size ==# 'small'
        call search('\<', 'b', line('.'))
    else
        call search('\('.legal_func_name_chars.'\)\@<!', 'b', line('.'))
    endif
endfunction

function! s:get_start_of_function_column(word_size)
    call s:move_to_start_of_function(a:word_size)
    return = col('.')
endfunction

function! s:get_function_opening_paren_column(word_size)
    cursor('.', s:get_start_of_function_column(a:word_size))
    let [_, c] = searchpos('(')
    return c
endfunction

function! s:get_surrounding_function_name(word_size)
    let chars = s:current_line2list()
    let c1 = s:get_start_of_function_column(a:word_size)
    let c2 = s:get_function_opening_paren_column(a:word_size)
    return [range(c1, c2-2), chars[c1-1:c2-2]]
endfunction

function! s:delete_surrounding_function(word_size)
    " we'll restore the f register later so it isn't clobbered here
    let l:freg = @f
    call s:move_to_start_of_function(a:word_size)
    " delete function name into the f register and mark opening parenthesis 
    silent! execute 'normal! "fdt(mo'
    " yank opening parenthesis into f register
    silent! execute 'normal! "Fyl'
    " mark closing parenthesis
    silent! execute 'normal! %mc'
    " note where the function ends
    let close = col('.')
    " move back to opening paranthesis
    silent! execute 'normal! %'
    " search on the same line for an opening paren before the closing paren 
    if search("(", '', line('.')) && col('.') < close
        " move to matching paren and delete everthing up to the closing paren
        " of the original function (remark closing paren)
        silent! execute 'normal! %l"Fd`cmc'
    endif
    " delete the closing and opening parens (put the closing one into register)
    silent! execute 'normal! `c"Fx`ox'
    " paste the function into unamed register
    let @"=@f
    " restore the f register
    let @f = l:freg
endfunction

function! s:change_surrounding_function(word_size)
    call s:delete_surrounding_function(a:word_size)
    startinsert
endfunction

function! s:yank_surrounding_function(word_size)
    " store the current line
    silent! execute 'normal! "lyy'
    call s:delete_surrounding_function(a:word_size)
    " restore the current line to original state
    silent! execute 'normal! "_dd"lP'
endfunction

function! s:paste_function_around_function(word_size)
    " we'll restore the unnamed register later so it isn't clobbered here
    let l:unnamed_reg = @"
    if s:is_cursor_on_function()
        call s:move_to_start_of_function(a:word_size)
        " paste just behind existing function
        silent! execute 'normal! P'
        " mark closing parenthesis
        silent! execute 'normal! f(%mc'
        " move back onto start of function name
        call s:move_to_start_of_function(a:word_size)
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
        call s:paste_function_around_word(a:word_size)
    endif
endfunction

function! s:paste_function_around_word(word_size)
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
    " move to start of funtion and mark it, paste the word, move back to start
    silent! execute 'normal! %mop`o'
    " restore unnamed register
    let @" = l:unnamed_reg
endfunction

nnoremap <silent> <Plug>DeleteSurroundingFunction :<C-U>call <SID>delete_surrounding_function("small")<CR>
nnoremap <silent> <Plug>DeleteSurroundingFUNCTION :<C-U>call <SID>delete_surrounding_function("big")<CR>
nnoremap <silent> <Plug>ChangeSurroundingFunction :<C-U>call <SID>change_surrounding_function("small")<CR>
nnoremap <silent> <Plug>ChangeSurroundingFUNCTION :<C-U>call <SID>change_surrounding_function("big")<CR>
nnoremap <silent> <Plug>YankSurroundingFunction :<C-U>call <SID>yank_surrounding_function("small")<CR>
nnoremap <silent> <Plug>YankSurroundingFUNCTION :<C-U>call <SID>yank_surrounding_function("big")<CR>
nnoremap <silent> <Plug>PasteFunctionAroundFunction :<C-U>call <SID>paste_function_around_function("small")<CR>
nnoremap <silent> <Plug>PasteFunctionAroundFUNCTION :<C-U>call <SID>paste_function_around_function("big")<CR>
nnoremap <silent> <Plug>PasteFunctionAroundWord :<C-U>call <SID>paste_function_around_word("small")<CR>
nnoremap <silent> <Plug>PasteFunctionAroundWORD :<C-U>call <SID>paste_function_around_word("big")<CR>

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
