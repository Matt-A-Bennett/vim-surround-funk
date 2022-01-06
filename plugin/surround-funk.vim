" Author:       Matthew Bennett
" Version:      0.1.0

if exists("g:loaded_surround_funk") || &cp || v:version < 700
  finish
endif
let g:loaded_surround_funk = 1

function! s:get_char_under_cursor()
     return getline(".")[col(".")-1]
endfunction

function! s:move_to_start_of_function(word_size, pasting)
    " move forward to one of function's parentheses (unless already on one)
    call search('(\|)', 'c', line('.'))
    " if we're on the closing parenthsis, move to other side
    if s:get_char_under_cursor() ==# ')'
        silent! execute 'normal! %'
    endif
    " move onto function name 
    silent! execute 'normal! b'
    if a:word_size ==# 'big'
        " if we've pasted in a function, then there will be a ')' right before
        " the one we need to move inside - so we can go to the start easily
        if a:pasting
            silent! execute 'normal! F)l'
        else
            " find first boundary before function that we don't want to cross
            call search(' \|,\|;\|(\|^', 'b', line('.'))
            " If we're not at the start of the line, or if we're on whitespace
            if col('.') > 1 || s:get_char_under_cursor() ==# ' '
                silent! execute 'normal! l'
            endif
        endif
    endif
endfunction

function! s:delete_surrounding_function(word_size)
    " we'll restore the f register later so it isn't clobbered here
    let l:freg = @f
    call s:move_to_start_of_function(a:word_size, 0)
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
    end
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
    call s:move_to_start_of_function(a:word_size, 0)
    " paste just behind existing function
    silent! execute 'normal! P'
    " mark closing parenthesis
    silent! execute 'normal! f(%mc'
    " move back onto start of function name
    call s:move_to_start_of_function(a:word_size, 1)
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
nnoremap <silent> <Plug>PasteFunctionAroundWord :<C-U>call <SID>paste_function_aroundWord("small")<CR>
nnoremap <silent> <Plug>PasteFunctionAroundWORD :<C-U>call <SID>paste_function_aroundWord("big")<CR>

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
