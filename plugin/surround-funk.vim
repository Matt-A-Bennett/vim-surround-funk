" Author:       Matthew Bennett
" Version:      1.0.0
"
" The following 'function markers' are found in the current line:
"      
"    np.outer(os.inner(arg1), arg2)
"    ^  ^    ^              ^     ^
"    1a 1b   2              3     4
"
" Then we can delete/yank 1:2, and 3:4

"- setup ----------------------------------------------------------------------
if exists("g:loaded_surround_funk") || &cp || v:version < 700
    finish
endif
let g:loaded_surround_funk = 1

" use defaults if not defined by user
if ! exists("g:surround_funk_legal_func_name_chars")
    let g:surround_funk_legal_func_name_chars = ['\w', '\.']
endif

let s:legal_func_name_chars = join(g:surround_funk_legal_func_name_chars, '\|')

"- helper functions -----------------------------------------------------------
function! s:is_greater_or_lesser(v1, v2, greater_or_lesser)
    if a:greater_or_lesser ==# '>'
        return a:v1 > a:v2
    else
        return a:v1 < a:v2
    endif
endfunction

function! Searchpairpos2(start, middle, end, flags)
    " like Vim's builtin searchpairpos(), but find the {middle} even when it's
    " in a nested stat-end pair
    let [_, l_orig, c_orig, _] = getpos('.')
    if a:flags =~# 'b'
        let f1 = 'bW'
        let f2 = ''
        let g_or_l = '>'
    else
        let f1 = ''
        let f2 = 'bW'
        let g_or_l = '<'
    endif
    call searchpair(a:start, '', a:end, f1)
    let [_, end_l, end_c, _] = getpos('.')
    call searchpair(a:start, '', a:end, f2)
    let [l, c] = searchpos(a:middle, f1) 
    call cursor(l_orig, c_orig)
    if Is_greater_or_lesser(l, end_l, g_or_l)
        return [l, c]
    elseif l == end_l && Is_greater_or_lesser(c, end_c, g_or_l)
        return [l, c]
    else
        return [-1, -1]
    endif
endfunction

function! Searchpair2(start, middle, end, flag)
    " like Vim's builtin searchpair(), but find the {middle} even when it's in
    " a nested stat-end pair
     let [l, c]  = Searchpairpos2(a:start, a:middle, a:end, a:flag)
     if l > 0 || c > 0
         call cursor(l, c)
     endif
endfunction

function! Get_char_at_pos(l, c)
    let [l, c] = [a:l, a:c]
    if a:l ==# '.'
        let l = line(".")
    endif
    if a:c ==# '.'
        let c = col(".")
    endif
    return getline(l)[c-1]
endfunction

function! Get_char_under_cursor()
     return Get_char_at_pos('.', '.')
endfunction

function! s:string2list(str)
    let str = a:str
    if str ==# '.'
        let str = getline('.')
    endif
    return split(str, '\zs')
endfunction

"- get marker positions -------------------------------------------------------
function! s:get_func_open_paren_column()
    let [_, _, c_orig, _] = getpos('.')
    " move forward to one of function's parentheses (unless already on one)
    call search('(\|)', 'c', line('.'))
    " if we're on the closing parenthsis, move to other side
    if s:get_char_under_cursor() ==# ')'
        call searchpair('(','',')', 'b')
    endif
    let c = col('.')
    call cursor('.', c_orig)
    return c
endfunction

function! s:move_to_func_open_paren()
    call cursor('.', s:get_func_open_paren_column())
endfunction

function! s:get_start_of_func_column(word_size)
    let [_, _, c_orig, _] = getpos('.')
    call s:move_to_func_open_paren()
    if a:word_size ==# 'small'
        let [_, c] = searchpos('\<', 'b', line('.'))
    else
        let [_, c] = searchpos('\('.s:legal_func_name_chars.'\)\@<!', 'b', line('.'))
    endif
    call cursor('.', c_orig)
    return c
endfunction

function! s:move_to_start_of_func(word_size)
    call cursor('.', s:get_start_of_func_column(a:word_size))
endfunction

function! s:get_end_of_func_column()
    let [_, _, c_orig, _] = getpos('.')
    call s:move_to_func_open_paren()
    let [_, c] = searchpairpos('(','',')')
    call cursor('.', c_orig)
    return c
endfunction

function! s:move_to_end_of_func()
    call cursor('.', s:get_end_of_func_column())
endfunction

function! s:get_start_of_trailing_args_column()
    let [_, _, c_orig, _] = getpos('.')
    call s:move_to_func_open_paren()
    let c = s:searchpairpos2('(', ')', ')', '')
    call cursor('.', c_orig)
    if c > 0
        return c+1
    else
        return s:get_end_of_func_column()
    endif
endfunction

function! s:get_substring(str, c1, c2)
    let chars = s:string2list(a:str)
    return join(chars[a:c1-1:a:c2-1], '')
endfunction

function! s:remove_substring(str, c1, c2)
    let chars = s:string2list(a:str)
    let removed = remove(chars, a:c1-1, a:c2-1)
    return [join(chars, ''), join(removed, '')]
endfunction

function! s:get_func_markers(word_size)
    let fstart = s:get_start_of_func_column(a:word_size)
    let fopen = s:get_func_open_paren_column()
    let ftrail = s:get_start_of_trailing_args_column()
    let fclose = s:get_end_of_func_column()
    return [fstart, fopen, ftrail, fclose]
endfunction

function! s:get_word_markers(word_size)
    if a:word_size ==# 'small'
        let [_, wstart] = searchpos('\<', 'b', line('.'))
        let [_, wclose] = searchpos('\>', '', line('.'))
    else
        let [_, wstart] = searchpos('\('.s:legal_func_name_chars.'\)\@<!', 'b', line('.'))
        let [_, wclose] = searchpos('\('.s:legal_func_name_chars.'\)\@<!\|$', '', line('.'))
    endif
    return [wstart, wclose-1]
endfunction

function! s:extract_func_parts(word_size)
    let [fstart, fopen, ftrail, fclose] = s:get_func_markers(a:word_size)
    let str = getline('.')
    let [tmp, rm1] = s:remove_substring(str, fstart, fopen) 
    let offset = fopen-fstart+1
    let [result, rm2] = s:remove_substring(tmp, ftrail-offset, fclose-offset) 
    let s:surroundfunk_func_parts = [fstart, result, rm1, rm2]
    return [fstart, result, rm1, rm2]
endfunction

" this isn't used, but could allow me to switch to from 'dsf' to 'dsw' if 'dsf'
" was called with the cursor not on a function (or to gracfully do nothing
" instead of clobbering the line)...
function! s:is_cursor_on_func()
    let [_, _, c_orig, _] = getpos('.')
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
                call cursor('.', c_orig)
                return 1
            endif
            " maybe jump to the matching ')' at this point to speed things up
            let open_paren_count+=1
        elseif char ==# '('
            let close_paren_count+=1
        endif
    endfor
    call cursor('.', c_orig)
    return close_paren_count > open_paren_count
endfunction

"- perform the operations -----------------------------------------------------
function! s:operate_on_surrounding_func(word_size, operation)
    let [fstart, result, rm1, rm2] = s:extract_func_parts(a:word_size)
    call setreg('"', rm1.rm2)
    call cursor('.', fstart)
    if a:operation =~ 'delete\|change'
        call setline('.', result)
    endif
    if a:operation =~ 'change'
        startinsert
    endif
endfunction

function! s:paste_func_around(word_size, func_or_word)
    if a:func_or_word ==# 'func'
        let [fstart, _, _, fclose] = s:get_func_markers(a:word_size)
    else
        let [fstart, fclose] = s:get_word_markers(a:word_size)
    endif
    let chars = s:string2list('.')
    call extend(chars, [s:surroundfunk_func_parts[2]], fstart-1)
    call extend(chars, [s:surroundfunk_func_parts[3]], fclose+1)
    let chars = join(chars, '')
    call setline('.', chars)
    call cursor('.', fstart)
endfunction

"- make maps repeatable -------------------------------------------------------
function! s:repeatable_delete(word_size, operation, mapname)
    call s:operate_on_surrounding_func(a:word_size, a:operation)
    silent! call repeat#set("\<Plug>".a:mapname, v:count)
endfunction

function! s:repeatable_paste(word_size, func_or_word, mapname)
    call s:paste_func_around(a:word_size, a:func_or_word)
    silent! call repeat#set("\<Plug>".a:mapname, v:count)
endfunction

nnoremap <silent> <Plug>DeleteSurroundingFunction :<C-U>call <SID>repeatable_delete("small", "delete", "DeleteSurroundingFunction")<CR>
nnoremap <silent> <Plug>DeleteSurroundingFUNCTION :<C-U>call <SID>repeatable_delete("big", "delete", "DeleteSurroundingFunction")<CR>
nnoremap <silent> <Plug>ChangeSurroundingFunction :<C-U>call <SID>operate_on_surrounding_func("small", "change")<CR>
nnoremap <silent> <Plug>ChangeSurroundingFUNCTION :<C-U>call <SID>operate_on_surrounding_func("big", "change")<CR>
nnoremap <silent> <Plug>YankSurroundingFunction :<C-U>call <SID>operate_on_surrounding_func("small", "yank")<CR>
nnoremap <silent> <Plug>YankSurroundingFUNCTION :<C-U>call <SID>operate_on_surrounding_func("big", "yank")<CR>
nnoremap <silent> <Plug>PasteFunctionAroundFunction :<C-U>call <SID>repeatable_paste("small", "func", "PasteFunctionAroundFunction")<CR>
nnoremap <silent> <Plug>PasteFunctionAroundFUNCTION :<C-U>call <SID>repeatable_paste("big", "func", "PasteFunctionAroundFUNCTION")<CR>
nnoremap <silent> <Plug>PasteFunctionAroundWord :<C-U>call <SID>repeatable_paste("small", "word", "PasteFunctionAroundWord")<CR>
nnoremap <silent> <Plug>PasteFunctionAroundWORD :<C-U>call <SID>repeatable_paste("big", "word", "PasteFunctionAroundWORD")<CR>

if !exists("g:surround_funk_no_mappings") || g:surround_funk_no_mappings != 0
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
endif
