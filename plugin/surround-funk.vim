" Author:       Matthew Bennett
" Version:      0.0.1

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

nnoremap dsf1 :call s:delete_surrounding_function("small")<CR>
nnoremap dsf2 s:delete_surrounding_function("small")<CR>
nnoremap dsf3 s:delete_surrounding_function("small")
nnoremap dsf4 <SID>delete_surrounding_function("small")
nnoremap dsf5 <SID>delete_surrounding_function("small")<CR>
