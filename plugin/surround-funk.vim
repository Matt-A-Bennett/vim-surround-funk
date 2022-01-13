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

let g:legal_func_name_chars = join(g:surround_funk_legal_func_name_chars, '\|')

"- helper functions -----------------------------------------------------------
function! Is_greater_or_lesser(v1, v2, greater_or_lesser)
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

function! String2list(str)
    " e.g. 'vim' -> ['v', 'i', 'm']
    let str = a:str
    if str ==# '.'
        let str = getline('.')
    endif
    return split(str, '\zs')
endfunction

"- get marker positions -------------------------------------------------------
function! Get_func_open_paren_position()
    let [_, l_orig, c_orig, _] = getpos('.')
    " move forward to one of function's parentheses (unless already on one)
    call search('(\|)', 'c')
    " if we're on the closing parenthesis, move to other side
    if Get_char_under_cursor() ==# ')'
        call searchpair('(','',')', 'b')
    endif
    let [_, l, c, _] = getpos('.')
    call cursor(l_orig, c_orig)
    return [l, c]
endfunction

function! Move_to_func_open_paren()
    let [l, c] = Get_func_open_paren_position()
    call cursor(l, c)
endfunction

function! Get_start_of_func_position(word_size)
    let [_, l_orig, c_orig, _] = getpos('.')
    call Move_to_func_open_paren()
    if a:word_size ==# 'small'
        let [l, c] = searchpos('\<', 'b', line('.'))
    elseif a:word_size ==# 'big'
        let [l, c] = searchpos('\('.g:legal_func_name_chars.'\)\@<!', 'b', line('.'))
    endif
    call cursor(l_orig, c_orig)
    return [l, c]
endfunction

function! Move_to_start_of_func(word_size)
    let [l, c] = Get_start_of_func_position(a:word_size)
    call cursor(l, c)
endfunction

function! Get_end_of_func_position()
    let [_, l_orig, c_orig, _] = getpos('.')
    call Move_to_func_open_paren()
    let [l, c] = searchpairpos('(','',')')
    call cursor(l_orig, c_orig)
    return [l, c]
endfunction

function! Move_to_end_of_func()
    let [l, c] = Get_end_of_func_position()
    call cursor(l, c)
endfunction

function! Get_start_of_trailing_args_position()
    let [_, l_orig, c_orig, _] = getpos('.')
    call Move_to_func_open_paren()
    let [l, c] = Searchpairpos2('(', ')', ')', '')
    call cursor(l_orig, c_orig)
    if l < 0 || c < 0
        return Get_end_of_func_position()
    elseif l == line('.') && c == col('.')
        return Get_end_of_func_position()
    elseif Get_char_at_pos(l, c) ==# ')'
        let [l, c] = [l, c+1]
    endif
    if Get_char_at_pos(l, c) ==# ''
        let [l, c] = [l+1, 1]
    endif
    return [l, c]
endfunction

function! Move_to_start_of_trailing_args()
    let [l, c] = Get_start_of_trailing_args_position()
    call cursor(l, c)
endfunction

function! Extract_substring(str, c1, c2)
    " remove the characters ranging from <c1> to <c2> (inclusive) from <str>
    " returns: the original with characters removed
    "          the removed characters as a string
    let chars = String2list(a:str)
    " index from 1
    let [c1, c2] = [a:c1-1, a:c2-1]
    " unless idexing from the end of the list
    if a:c2 < 0
        let c2 = a:c2
    endif
    let removed = remove(chars, c1, c2)
    return [join(chars, ''), join(removed, '')]
endfunction

function! Get_func_markers(word_size)
    " get a list of lists: each list contains the line and column positions of
    " one of the four key function markers (see top of file for explanation of
    " these function markers)
    let [l_fstart, c_fstart] = Get_start_of_func_position(a:word_size)
    let [l_fopen, c_fopen] = Get_func_open_paren_position()
    let [l_ftrail, c_ftrail] = Get_start_of_trailing_args_position()
    let [l_fclose, c_fclose] = Get_end_of_func_position()
    return [[l_fstart, c_fstart],
           \[l_fopen, c_fopen],
           \[l_ftrail, c_ftrail],
           \[l_fclose, c_fclose]]
endfunction

" maybe need to look at the -1 for big vs small??
function! Get_word_markers(word_size)
    " get list containing the line and column positions of the word - using the
    " <s:legal_func_name_chars> if marking a 'big word'
    if a:word_size ==# 'small'
        let [fstart, fstart] = searchpos('\<', 'b', line('.'))
        let [fclose, fclose] = searchpos('\>', '', line('.'))
    elseif a:word_size ==# 'big'
        let [fstart, fstart] = searchpos('\('.g:legal_func_name_chars.'\)\@<!', 'b', line('.'))
        let [fclose, fclose] = searchpos('\('.g:legal_func_name_chars.'\)\@<!\|$', '', line('.'))
    endif
    return [[fstart, fstart], [fclose, fclose-1]]
endfunction

function! Extract_func_name_and_open_paren(word_size)
    let [start_pos, open_pos, _, _] = Get_func_markers(a:word_size)
    let str = getline(start_pos[0])
    return Extract_substring(str, start_pos[1], open_pos[1]) 
endfunction

" function! Extract_func_name_and_open_paren_and_first_trail(word_size)
"     let [start_pos, open_pos, trail_pos, _] = Get_func_markers(a:word_size)
"     let [tmp, rm1] = Extract_func_name_and_open_paren(a:word_size)
"     let offset = open_pos[1]-start_pos[1]+1
"     let [result, rm2] = Extract_substring(tmp, trail_pos[1]-offset, -1) 
"     return [result, rm1.rm2]
" endfunction

function! Extract_func_name_and_open_paren_and_first_trail(word_size)
    let [start_pos, open_pos, trail_pos, _] = Get_func_markers(a:word_size)
    let [tmp, rm1] = Extract_func_name_and_open_paren(a:word_size)
    let offset = open_pos[1]-start_pos[1]+1
    let [result, rm2] = Extract_substring(tmp, trail_pos[1]-offset, -1) 
    return [result, rm1, rm2]
endfunction

" function! Extract_first_trail_arg(word_size)
"     let [_, _, trail_pos, close_pos] = Get_func_markers(a:word_size)
"         let str = getline('.')
"         return [result, rm2] = Extract_substring(str, trail_pos[1], -1) 
" endfunction

function! Extract_intervening_trailing_args(word_size)
    let [_, open_pos, trail_pos, close_pos] = Get_func_markers(a:word_size)
    let results = []
    let intervening = []
    if open_pos[0] == trail_pos[0]
        let trail_pos[1] = 1
        let skip = 1
    else 
        let skip = 0
    endif
    " this loop will only happen if close_pos[0] != trail_pos[0]
    for l in range(trail_pos[0]+skip, close_pos[0]-1)
        let str = getline(l)
        if len(str) == 0
            let [result, rm2] = ['', '']
        else
            let [result, rm2] = Extract_substring(str, trail_pos[1], -1) 
        endif
        call add(results, result)
        call add(intervening, rm2)
        let trail_pos[1] = 1
    endfor
    return [results, intervening]
endfunction

function! Extract_last_line_with_closing_paren(word_size)
    let [_, _,  trail_pos, close_pos] = Get_func_markers(a:word_size)
    " grab from start of line to close
    if trail_pos[0] != close_pos[0]
        let trail_pos[1] = 1
    endif
    let str = getline(close_pos[0])
    let last = Extract_substring(str, trail_pos[1], close_pos[1]) 
    return last
endfunction

function! Extract_func_single_line(word_size)
    let [start_pos, open_pos, trail_pos, close_pos] = Get_func_markers(a:word_size)
    let str = getline('.')
    let [tmp, rm1] = Extract_substring(str, start_pos[1], open_pos[1]) 
    let offset = open_pos[1]-start_pos[1]+1
    let [result, rm2] = Extract_substring(tmp, trail_pos[1]-offset, close_pos[1]-offset) 
    return [result, rm1, rm2] " **
endfunction

function! Extract_func_parts(word_size)
    let [start_pos, open_pos, trail_pos, close_pos] = Get_func_markers(a:word_size)
    let parts = {'start_pos':start_pos}
    if open_pos[0] == trail_pos[0] && trail_pos[0] == close_pos[0]
        let parts['func_name'] = Extract_func_single_line(a:word_size) " **
        let parts['args'] = [['', ''], ['', '']]
        let parts['last'] = ['', '']
    else
        if open_pos[0] == trail_pos[0]
            let [result, func_name, trail_arg] = Extract_func_name_and_open_paren_and_first_trail(a:word_size)
            let parts['func_name'] = func_name
            let [results, intervening] = Extract_intervening_trailing_args(a:word_size)
            call insert(intervening, trail_arg, 0)
            let parts['args'] = [results, intervening]
        else
            let parts['func_name'] = Extract_func_name_and_open_paren(a:word_size)
            let parts['args'] = Extract_intervening_trailing_args(a:word_size)
        endif
        let parts['last'] = Extract_last_line_with_closing_paren(a:word_size)
    endif
    let g:surroundfunk_func_parts = parts
    return parts
endfunction

" function! Extract_func_parts(word_size)
"     let [start_pos, open_pos, trail_pos, close_pos] = Get_func_markers(a:word_size)
"     let parts = {'start_pos':start_pos}
"     if open_pos[0] == trail_pos[0] && trail_pos[0] == close_pos[0]
"         let parts['func_name'] = Extract_func_single_line(a:word_size) " **
"         let parts['args'] = [['', ''], ['', '']]
"         let parts['last'] = ['', '']
"     else
"         if open_pos[0] == trail_pos[0]
"             let parts['func_name'] = Extract_func_name_and_open_paren_and_first_trail(a:word_size)
"         else
"             let parts['func_name'] = Extract_func_name_and_open_paren(a:word_size)
"         endif
"         let parts['args'] = Extract_intervening_trailing_args(a:word_size)
"         let parts['last'] = Extract_last_line_with_closing_paren(a:word_size)
"     endif
"     let g:surroundfunk_func_parts = parts
"     return parts
" endfunction

" " this isn't used, but could allow me to switch to from 'dsf' to 'dsw' if 'dsf'
" " was called with the cursor not on a function (or to gracfully do nothing
" " instead of clobbering the line)...
" function! s:is_cursor_on_func()
"     let [_, _, c_orig, _] = getpos('.')
"     if s:get_char_under_cursor() =~ '(\|)'
"         return 1
"     endif
"     let chars = s:string2list('.')
"     let right = chars[col("."):]
"     let on_func_name = s:get_char_under_cursor() =~ s:legal_func_name_chars.'\|('
"     let open_paren_count = 0
"     let close_paren_count = 0
"     for char in right
"         if on_func_name && char !~ s:legal_func_name_chars.'\|('
"             let on_func_name = 0
"         endif
"         if char ==# '('
"             if on_func_name
"                 call cursor('.', c_orig)
"                 return 1
"             endif
"             " maybe jump to the matching ')' at this point to speed things up
"             let open_paren_count+=1
"         elseif char ==# '('
"             let close_paren_count+=1
"         endif
"     endfor
"     call cursor('.', c_orig)
"     return close_paren_count > open_paren_count
" endfunction

function! Insert_into_string(str, insertion_list)
    " insert a set of new strings into <str>
    " <insertion_list> is a list of lists where the first element is the string to
    " be insterted, and the second element is the index of where to insert into
    " <str>
    let chars = String2list(a:str)
    let offset = -1
    for insertion in a:insertion_list
        let insertion[0] = String2list(insertion[0])
        call extend(chars, insertion[0], insertion[1]+offset)
        let offset += len(insertion[0])
    endfor
    return join(chars, '')
endfunction

"- perform the operations -----------------------------------------------------
function! Operate_on_surrounding_func(word_size, operation)
    let [start_pos, open_pos, trail_pos, close_pos] = Get_func_markers(a:word_size)
    let parts = Extract_func_parts(a:word_size)
    if open_pos[0] == trail_pos[0] && trail_pos[0] == close_pos[0]
        let result = [parts['func_name'][0]]
        let rm = [parts['func_name'][1]]
    else
        let result = [parts['func_name'][0]] + parts['args'][0] + [parts['last'][0]]
        let rm = [parts['func_name'][1]] + parts['args'][1] + [parts['last'][1]]
    end
    call join(rm, '\n')
    call setreg('"', rm)
    call cursor(parts['start_pos'][0], parts['start_pos'][1])
    if a:operation =~ 'delete\|change'
        call join(result, '\n')
        call setline('.', result)
    endif
    if a:operation =~ 'change'
        startinsert
    endif
endfunction

function! Paste_func_around(word_size, func_or_word)
    if a:func_or_word ==# 'func'
        let [open_pos, _, _, close_pos] = Get_func_markers(a:word_size)
    else
        let [fstart, fclose] = Get_word_markers(a:word_size)
    endif
    let chars = String2list('.')
    let rm = g:surroundfunk_func_parts['args'][1] + [g:surroundfunk_func_parts['last'][1]]
    call join(rm, '\n')
    call extend(chars, [g:surroundfunk_func_parts['func_name'][1]], open_pos[1]-1)
    " call extend(chars, rm, close_pos[1]+1) 
    let chars = join(chars, '')
    call setline('.', chars)
    call cursor(open_pos[0], open_pos[1])
endfunction

" function! s:paste_func_around(word_size, func_or_word)
"     if a:func_or_word ==# 'func'
"         let [fstart, _, _, fclose] = s:get_func_markers(a:word_size)
"     else
"         let [fstart, fclose] = s:get_word_markers(a:word_size)
"     endif
"     let chars = s:string2list('.')
"     call extend(chars, [s:surroundfunk_func_parts[2]], fstart-1)
"     call extend(chars, [s:surroundfunk_func_parts[3]], fclose+1) 
"     let chars = join(chars, '')
"     call setline('.', chars)
"     call cursor('.', fstart)
" endfunction

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
