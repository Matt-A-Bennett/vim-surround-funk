"==============================================================================
"    _______ __ ____  ____   ___  __ __ ____  ___       _____ __ __ ____  __  _ 
"  / ___/  |  |    \|    \ /   \|  |  |    \|   \     |     |  |  |    \|  |/ ]
" (   \_|  |  |  D  )  D  )     |  |  |  _  |    \ ___|   __|  |  |  _  |  ' / 
"  \__  |  |  |    /|    /|  O  |  |  |  |  |  D  |   |  |_ |  |  |  |  |    \ 
"  /  \ |  :  |    \|    \|     |  :  |  |  |     |___|   _]|  :  |  |  |     \
"  \    |     |  .  \  .  \     |     |  |  |     |   |  |  |     |  |  |  .  |
"   \___|\__,_|__|\_|__|\_|\___/ \__,_|__|__|_____|   |__|   \__,_|__|__|__|\_|
"
"
" Author:       Matthew Bennett
" Version:      2.2.0
" License:      Same as Vim's (see :help license)
"
"
"======================== EXPLANATION OF THE APPROACH =========================

"{{{---------------------------------------------------------------------------
" The following 'function markers' are found:
"      
"    np.outer(os.inner(arg1    <----- 1a, 1b, 2
"                  arg2, arg3),  <--- 3
"    ^  ^    ^     argB,       
"    |  |    |     argC,      ^
"    |  |    |     argD,      |
"    |  |    |     argE) <----|------ 4
"    |  |    |                |    
"    |  |    |         ^      |
"    |  |    |         |      |
"    |  |    |         |      |

"    1a 1b   2         4      3   
"
" Then we can use them to define text objects, delete/yank bewteen them, and
" store the pieces for later gripping of any text object or motion.
"}}}---------------------------------------------------------------------------

"================================== SETUP =====================================

"{{{---------------------------------------------------------------------------
if exists("g:loaded_surround_funk") || &cp || v:version < 700
    finish
endif
let g:loaded_surround_funk = 1

" use defaults if not defined by user

if ! exists("g:surround_funk_legal_func_name_chars")
    let s:legal_func_name_chars = join(['\w', '\.'], '\|')
else
    let s:legal_func_name_chars = join(g:surround_funk_legal_func_name_chars, '\|')
endif

if ! exists("g:surround_funk_default_parens") || g:surround_funk_default_parens ==# '('
    let s:default_parens = ['(', ')']
elseif g:surround_funk_default_parens ==# '{'
    let s:default_parens = ['{', '}']
elseif g:surround_funk_default_parens ==# '['
    let s:default_parens = ['\[', ']']
endif

let s:orig_default_parens = s:default_parens

"}}}---------------------------------------------------------------------------

"=============================== FOUNDATIONS ==================================

"----------------------------- Helper functions -------------------------------
"{{{---------------------------------------------------------------------------
"{{{- is_greater_or_lesser ----------------------------------------------------
function! s:is_greater_or_lesser(v1, v2, greater_or_lesser)
    if a:greater_or_lesser ==# '>'
        return a:v1 > a:v2
    else
        return a:v1 < a:v2
    endif
endfunction
"}}}---------------------------------------------------------------------------

"{{{- searchpairpos2 ----------------------------------------------------------
function! s:searchpairpos2(start, middle, end, flags)
    " like vim's builtin searchpairpos(), but find the {middle} even when it's
    " in a nested start-end pair
    let [_, l_orig, c_orig, _] = getpos('.')
    if a:flags =~# 'b'
        let f1 = 'bw'
        let f2 = ''
        let g_or_l = '>'
    else
        let f1 = ''
        let f2 = 'bw'
        let g_or_l = '<'
    endif
    call searchpair(a:start, '', a:end, f1)
    let [_, end_l, end_c, _] = getpos('.')
    call searchpair(a:start, '', a:end, f2)
    let [l, c] = searchpos(a:middle, f1) 
    call cursor(l_orig, c_orig)
    if s:is_greater_or_lesser(l, end_l, g_or_l)
        return [l, c]
    elseif l == end_l && s:is_greater_or_lesser(c, end_c, g_or_l)
        return [l, c]
    else
        return [-1, -1]
    endif
endfunction
"}}}---------------------------------------------------------------------------

"{{{- searchpair2 -------------------------------------------------------------
function! s:searchpair2(start, middle, end, flag)
    " like vim's builtin searchpair(), but find the {middle} even when it's in
    " a nested start-end pair
     let [l, c]  = s:searchpairpos2(a:start, a:middle, a:end, a:flag)
     if l > 0 || c > 0
         call cursor(l, c)
     endif
endfunction
"}}}---------------------------------------------------------------------------

"{{{- get_char_at_pos ---------------------------------------------------------
function! s:get_char_at_pos(l, c)
    let [l, c] = [a:l, a:c]
    if a:l ==# '.'
        let l = line(".")
    endif
    if a:c ==# '.'
        let c = col(".")
    endif
    return getline(l)[c-1]
endfunction
"}}}---------------------------------------------------------------------------

"{{{- get_char_under_cursor ---------------------------------------------------
function! s:get_char_under_cursor()
     return s:get_char_at_pos('.', '.')
endfunction
"}}}---------------------------------------------------------------------------

"{{{- string2list -------------------------------------------------------------
function! s:string2list(str)
    " e.g. 'vim' -> ['v', 'i', 'm']
    let str = a:str
    if str ==# '.'
        let str = getline('.')
    endif
    return split(str, '\zs')
endfunction
"}}}---------------------------------------------------------------------------

"{{{- is_cursor_on_func -------------------------------------------------------
" this isn't used (and hasn't been updated for multiline functions), but could
" allow me to switch to from 'dsf' to 'dsw' if 'dsf' was called with the cursor
" not on a function (or to gracfully do nothing instead of clobbering the
" line)...
function! s:is_cursor_on_func()
    let [_, _, c_orig, _] = getpos('.')
    if index(s:default_parens, s:get_char_under_cursor()) >= 0
        return 1
    endif
    let chars = s:string2list('.')
    let right = chars[col("."):]
    let on_func_name = s:get_char_under_cursor() =~ s:legal_func_name_chars.'\|'.s:default_parens[0]
    let open_paren_count = 0
    let close_paren_count = 0
    for char in right
        if on_func_name && char !~ s:legal_func_name_chars.'\|'.s:default_parens[0]
            let on_func_name = 0
        endif
        if char ==# s:default_parens[0]
            if on_func_name
                call cursor('.', c_orig)
                return 1
            endif
            " maybe jump to the matching ')' at this point to speed things up
            let open_paren_count+=1
        elseif char ==# s:default_parens[0]
            let close_paren_count+=1
        endif
    endfor
    call cursor('.', c_orig)
    return close_paren_count > open_paren_count
endfunction
"}}}---------------------------------------------------------------------------

"{{{- get_motion --------------------------------------------------------------
function! s:get_motion(type)
    " after an operator pending command, the line and column coordinates of the
    " start and end positions of whatever text object or motion is given is
    " found
    if a:type ==? 'v' || a:type ==# "\<C-V>"
        let [_, l_start, c_start, _] = getpos("'<")
        let [_, l_end, c_end, _] = getpos("'>")
    else
        let [_, l_start, c_start, _] = getpos("'[")
        let [_, l_end, c_end, _] = getpos("']")
    endif
    if a:type ==# 'V' || a:type ==# 'line'
        let c_start = 1
        let c_end = len(getline(l_end))
    endif
    return [[l_start, c_start], [l_end, c_end]]
endfunction
"}}}---------------------------------------------------------------------------

"{{{- switch_default_parens ---------------------------------------------------
function! s:switch_default_parens(paren)
    if a:paren =~ '('
        let s:default_parens = ['(', ')']
    elseif a:paren =~ '{'
        let s:default_parens = ['{', '}']
    elseif a:paren =~ '\['
        let s:default_parens = ['\[', ']']
    endif
endfunction
"}}}---------------------------------------------------------------------------

"{{{- hot_switch --------------------------------------------------------------
function! s:hot_switch()
    if exists("g:surround_funk_default_hot_switch") && g:surround_funk_default_hot_switch == 1
        let s:default_parens = s:orig_default_parens
    endif
endfunction
"}}}---------------------------------------------------------------------------
"}}}---------------------------------------------------------------------------

"------------------------------- Get Markers ----------------------------------
"{{{---------------------------------------------------------------------------
"{{{- get_func_open_paren_position (marker 2) ---------------------------------
function! s:get_func_open_paren_position()
    let [_, l_orig, c_orig, _] = getpos('.')
    " move forward to one of function's parentheses (unless already on one)
    call search(s:default_parens[0].'\|'.s:default_parens[1], 'c')
    " if we're on the closing parenthesis, move to other side
    if s:get_char_under_cursor() ==# s:default_parens[1]
        call searchpair(s:default_parens[0], '', s:default_parens[1], 'b')
    endif
    let [_, l, c, _] = getpos('.')
    call cursor(l_orig, c_orig)
    return [l, c]
endfunction
"}}}---------------------------------------------------------------------------

"{{{- move_to_func_open_paren (marker 2) --------------------------------------
function! s:move_to_func_open_paren()
    let [l, c] = s:get_func_open_paren_position()
    call cursor(l, c)
endfunction
"}}}---------------------------------------------------------------------------

"{{{- get_start_of_func_position (marker 1) -----------------------------------
function! s:get_start_of_func_position(word_size)
    let [_, l_orig, c_orig, _] = getpos('.')
    call s:move_to_func_open_paren()
    " move back to the start of the function name
    if a:word_size ==# 'small'
        let [l, c] = searchpos('\<', 'b', line('.'))
    elseif a:word_size ==# 'big'
        let [l, c] = searchpos('\('.s:legal_func_name_chars.'\)\@<!', 'b', line('.'))
    endif
    call cursor(l_orig, c_orig)
    return [l, c]
endfunction
"}}}---------------------------------------------------------------------------

"{{{- move_to_start_of_func (marker 1) ----------------------------------------
function! s:move_to_start_of_func(word_size)
    let [l, c] = s:get_start_of_func_position(a:word_size)
    call cursor(l, c)
endfunction
"}}}---------------------------------------------------------------------------

"{{{- get_end_of_func_position (marker 4) -------------------------------------
function! s:get_end_of_func_position()
    let [_, l_orig, c_orig, _] = getpos('.')
    call s:move_to_func_open_paren()
    let [l, c] = searchpairpos(s:default_parens[0], '', s:default_parens[1])
    call cursor(l_orig, c_orig)
    return [l, c]
endfunction
"}}}---------------------------------------------------------------------------

"{{{- move_to_end_of_func (marker 4) ------------------------------------------
function! s:move_to_end_of_func()
    let [l, c] = s:get_end_of_func_position()
    call cursor(l, c)
endfunction
"}}}---------------------------------------------------------------------------

"{{{- get_start_of_trailing_args_position (marker 3) --------------------------
function! s:get_start_of_trailing_args_position()
    let [_, l_orig, c_orig, _] = getpos('.')
    call s:move_to_func_open_paren()
    let [l, c] = s:searchpairpos2(s:default_parens[0], s:default_parens[1], s:default_parens[1], '')
    call cursor(l_orig, c_orig)
    if l < 0 || c < 0
        return s:get_end_of_func_position()
    elseif l == line('.') && c == col('.')
        return s:get_end_of_func_position()
    elseif s:get_char_at_pos(l, c) ==# s:default_parens[1]
        let [l, c] = [l, c+1]
    endif
    if s:get_char_at_pos(l, c) ==# ''
        let [l, c] = [l+1, 1]
    endif
    return [l, c]
endfunction
"}}}---------------------------------------------------------------------------

"{{{- move_to_start_of_trailing_args (marker 3) -------------------------------
function! s:move_to_start_of_trailing_args()
    let [l, c] = s:get_start_of_trailing_args_position()
    call cursor(l, c)
endfunction
"}}}---------------------------------------------------------------------------

"{{{- get_func_markers (markers 1-4) -----------------------------------------
function! s:get_func_markers(word_size)
    " expose the line and column positions of each of the four key function
    " markers (see top of file for explanation of these function markers)
    let s:start_pos = s:get_start_of_func_position(a:word_size)
    let s:open_pos = s:get_func_open_paren_position()
    let s:trail_pos = s:get_start_of_trailing_args_position()
    let s:close_pos = s:get_end_of_func_position()
endfunction
"}}}---------------------------------------------------------------------------
"}}}---------------------------------------------------------------------------

"--------------------------------- Extract ------------------------------------
"{{{---------------------------------------------------------------------------
"{{{- extract_substring -------------------------------------------------------
function! s:extract_substring(str, c1, c2)
    " remove the characters ranging from <c1> to <c2> (inclusive) from <str>
    " returns: the original string with characters removed
    "          the removed characters as a string
    let [c1, c2] = [a:c1, a:c2]
    let chars = s:string2list(a:str)
    " convert negative indices to positive
    let removed = remove(chars, c1-1, c2-1)
    return [join(chars, ''), join(removed, '')]
endfunction
"}}}---------------------------------------------------------------------------

"{{{- extract_substrings ------------------------------------------------------
function! s:extract_substrings(str, deletion_ranges)
    " extract a set of strings out of <str>
    " <deletion_ranges> is a list of lists where each sublist contains the
    " range (inclusive) to extract
    " returns: the original string with characters removed
    "          the removed characters as a list of strings
    let removed = []
    let result = a:str
    let offset = 0
    for [c1, c2] in a:deletion_ranges
        if c1 < 0
            let c1 = len(a:str)-abs(c1)+1
        endif
        if c2 < 0
            let c2 = len(a:str)-abs(c2)+1
        endif
        let [result, rm] = s:extract_substring(result, c1+offset, c2+offset)
        let offset -= len(rm)
        call add(removed, rm)
    endfor
    return [result, removed]
endfunction
"}}}---------------------------------------------------------------------------

"{{{- extract_func_name_and_open_paren ----------------------------------------
function! s:extract_func_name_and_open_paren(word_size)
    let str = getline(s:start_pos[0])
    return s:extract_substrings(str, [[s:start_pos[1], s:open_pos[1]]]) 
endfunction
"}}}---------------------------------------------------------------------------

"{{{- extract_online_args -----------------------------------------------------
function! s:extract_online_args(word_size)
    " the 'online args' are any arguments appearing on the same line as the
    " function opening parenthesis.
    " this will include the closing parenthesis if the function is on one line
    let str = getline(s:start_pos[0])
    if s:open_pos[0] != s:trail_pos[0]
        return ['', ['']]
    elseif s:open_pos[0] == s:trail_pos[0] && s:trail_pos[0] == s:close_pos[0]
        return s:extract_substrings(str, [[s:trail_pos[1], s:close_pos[1]]]) 
    else
        return s:extract_substrings(str, [[s:trail_pos[1], -1]]) 
    end
endfunction
"}}}---------------------------------------------------------------------------

"{{{- extract_offline_args ----------------------------------------------------
function! s:extract_offline_args(word_size)
    " the 'offline args' are any args that appear on a separate line to both
    " the function's opening and closing parentheses
    if s:open_pos[0] == s:trail_pos[0] && s:trail_pos[0] == s:close_pos[0]
        return ['', ['']]
    endif
    let results = []
    let intervening = []
    if s:open_pos[0] == s:trail_pos[0]
        let s:trail_pos[1] = 1
        let skip = 1
    else 
        let skip = 0
    endif
    " this loop will only happen if s:close_pos[0] != s:trail_pos[0]
    for l in range(s:trail_pos[0]+skip, s:close_pos[0]-1)
        let str = getline(l)
        if len(str) == 0
            let [result, rm2] = ['', '']
        else
            let [result, rm2] = s:extract_substrings(str, [[s:trail_pos[1], -1]]) 
        endif
        call add(results, result)
        call add(intervening, rm2[0])
        let s:trail_pos[1] = 1
    endfor
    return [results, intervening]
endfunction
"}}}---------------------------------------------------------------------------

"{{{- extract_last_line_with_closing_paren ------------------------------------
function! s:extract_last_line_with_closing_paren(word_size)
    " in the case of a multiline function call, here we get the last line of
    " args up to and including the closing parenthesis
    if s:open_pos[0] == s:trail_pos[0] && s:trail_pos[0] == s:close_pos[0]
        return ['', ['']]
    endif
    if s:trail_pos[0] != s:close_pos[0]
        let s:trail_pos[1] = 1
    endif
    let str = getline(s:close_pos[0])
    return s:extract_substrings(str, [[s:trail_pos[1], s:close_pos[1]]]) 
endfunction
"}}}---------------------------------------------------------------------------

"{{{- extract_func_parts ------------------------------------------------------
function! s:extract_func_parts(word_size)
    " package all the functions parts into a nested list structure
    let parts = {}
    let parts['func_name']         = [['', ['']], 0]
    let parts['online_args']       = [['', ['']], 0]
    let parts['offline_args']      = [['', ['']], s:close_pos[0]-1 > s:open_pos[0]]
    let parts['last']              = [['', ['']], s:close_pos[0]-s:open_pos[0]]
    let parts['func_name'][0]      = s:extract_func_name_and_open_paren(a:word_size)
    let parts['online_args'][0]    = s:extract_online_args(a:word_size)
    let parts['offline_args'][0]   = s:extract_offline_args(a:word_size)
    let parts['last'][0]           = s:extract_last_line_with_closing_paren(a:word_size)
    return parts
endfunction
"}}}---------------------------------------------------------------------------

"{{{- parts2string ------------------------------------------------------------
function! s:parts2string(parts, word_size)
    " take the nested list structure from extract_func_parts() and join the
    " parts together to make 3 strings:
    " a 'part removed beofore'
    " a 'part removed after'
    " the result after the parts were removed
    if s:open_pos[0] == s:trail_pos[0] && s:trail_pos[0] == s:close_pos[0]
        let str = getline('.')
        let [result, removed] = s:extract_substrings(str, [[s:start_pos[1], s:open_pos[1]], [s:trail_pos[1], s:close_pos[1]]]) 
        let [rm1, rm2] = [removed[0], removed[1]]
        let rm1 = [rm1]
        let rm2 = [rm2]
    else
        if a:parts['online_args'][1] == 0
            let result =   [a:parts['func_name'][0][0]]
                        \+  a:parts['offline_args'][0][0] 
                        \+ [a:parts['last'][0][0]]

        else
            let result =   [a:parts['func_name'][0][0]] 
                        \+ [a:parts['online_args'][0][0]] 
                        \+  a:parts['offline_args'][0][0]  
                        \+ [a:parts['last'][0][0]]
        endif

        let rm1 =       a:parts['func_name'][0][1] 

        let rm2 =       a:parts['online_args'][0][1] 
                    \+  a:parts['offline_args'][0][1]  
                    \+  a:parts['last'][0][1]

    endif
    let s:surroundfunk_func_parts = [rm1, rm2]
    let rm2 = join(rm2, "\n")
    return [result, rm1, rm2]
endfunction
"}}}---------------------------------------------------------------------------
"}}}---------------------------------------------------------------------------

"--------------------------------- Insert -------------------------------------
"{{{---------------------------------------------------------------------------
"{{{- insert_substrings -------------------------------------------------------
function! s:insert_substrings(str, insertion_list)
    " insert a set of new strings into <str>
    " <insertion_list> is a list of lists where:
    " the 1st element is the string to be insterted
    " the 2nd element is the index of where to insert into <str>
    " the 3rd is an optional flag to insert before (default) or after the index
    let chars = s:string2list(a:str)
    let offset = -1
    for insertion in a:insertion_list
        if insertion[1] < 0
            let insertion[1] = len(a:str)+insertion[1]+1
        endif
        if len(insertion) == 2 || insertion[2] ==# '<'
            call add(insertion, 0)
        elseif insertion[2] ==# '>'
            let insertion[2] = 1
        endif
        let insertion[0] = s:string2list(insertion[0])
        call extend(chars, insertion[0], insertion[1]+offset+insertion[2])
        let offset += len(insertion[0])
    endfor
    return join(chars, '')
endfunction
"}}}---------------------------------------------------------------------------

"{{{- insert_substrings_and_split_line ----------------------------------------
function! s:insert_substrings_and_split_line(l, insertion_list)
    " the same as insert_substrings() but a newline is made immediately after
    " each insertion
    if a:l ==# '.'
        let l = line('.')
    else
        let l = a:l
    endif
    let str = getline(l)
    for insertion in a:insertion_list
        let offset = insertion[1]+len(insertion[0])
        if insertion[2] ==# '<'
            let offset -= 1
        endif
        " insert as normal
        let changed = s:insert_substrings(str, [insertion])
        " delete everything after insertion
        let changed = s:string2list(changed)
        let front = join(changed[:offset-1], '')
        let back = join(changed[offset:], '')
        call setline(l, front)
        " append deleted part one line down
        call append(l, back)
    endfor
endfunction
"}}}---------------------------------------------------------------------------
"}}}---------------------------------------------------------------------------

"========================== PERFORM THE OPERATIONS ============================

"{{{- operate_on_surrounding_func ---------------------------------------------
function! s:operate_on_surrounding_func(word_size, operation)
    " copy and optionally delete all the parts of a function
    call s:get_func_markers(a:word_size)
    let parts = s:extract_func_parts(a:word_size)
    let [result, rm1, rm2] = s:parts2string(parts, a:word_size)
    call setreg('"', rm1[0].rm2)
    call cursor(s:start_pos[0], s:start_pos[1])
    if a:operation =~ 'delete\|change'
        call setline('.', result)
    endif
    if a:operation =~ 'change'
        startinsert
    endif
    call s:hot_switch()
endfunction
"}}}---------------------------------------------------------------------------

"{{{- visually_select_func_name -----------------------------------------------
function! surroundfunk#visually_select_func_name(word_size)
    call s:move_to_func_open_paren()
    normal! hv
    call s:move_to_start_of_func(a:word_size)
    call s:hot_switch()
endfunction
"}}}---------------------------------------------------------------------------

"{{{- visually_select_whole_func ----------------------------------------------
function! surroundfunk#visually_select_whole_func(word_size)
    call s:move_to_end_of_func()
    normal! v
    call s:move_to_start_of_func(a:word_size)
    call s:hot_switch()
endfunction
"}}}---------------------------------------------------------------------------

"{{{- grip_surround_object ----------------------------------------------------
function! s:grip_surround_object(type)
    " surround any text object or motion with a previously yanked/deleted
    " function call 
    if !exists("s:surroundfunk_func_parts")
        return
    endif
    let [start_pos, close_pos] = s:get_motion(a:type)
    let before = s:surroundfunk_func_parts[0][0]
    let after = s:surroundfunk_func_parts[1]
    let str = getline(start_pos[0])
    if start_pos[0] == close_pos[0] && len(after) == 1
        let func_line = s:insert_substrings(str, [[before, start_pos[1], '<'],
                    \[after[0], close_pos[1], '>']])
        call setline(start_pos[0], func_line)
    else
        if start_pos[0] == close_pos[0]
            let close_pos[1] += len(before)
        endif
        let func_line = s:insert_substrings(str, [[before, start_pos[1], '<']])
        call setline(start_pos[0], func_line)
        call s:insert_substrings_and_split_line(close_pos[0], [[after[0], close_pos[1], '>']])
        let the_rest = s:surroundfunk_func_parts[1][1:]
        call append(close_pos[0], the_rest)
    endif
    call cursor(start_pos[0], start_pos[1])
    call s:hot_switch()
endfunction
"}}}---------------------------------------------------------------------------

"{{{- grip_surround_object_no_paste -------------------------------------------
function! s:grip_surround_object_no_paste(type)
    " surround any text object or motion with a function call to be specified
    " at the command line prompt
    let func = input('function: ')
    if func ==# ''
        return
    endif
    let [start_pos, close_pos] = s:get_motion(a:type)
    let str = getline(start_pos[0])
    let func_line = s:insert_substrings(str, [[func.s:default_parens[0], start_pos[1], '<']])
    call setline(start_pos[0], func_line)
    if start_pos[0] == close_pos[0]
        let offset = len(func)+2
    else
        let offset = 1
    endif
    call cursor(close_pos[0], close_pos[1]+offset)
    normal! i)
    startinsert
    call s:hot_switch()
endfunction
"}}}---------------------------------------------------------------------------

"======================= CREATE MAPS AND TEXT OBJECTS =========================

"{{{- make maps repeatable ----------------------------------------------------
function! s:repeatable_delete(word_size, operation, mapname)
    call s:operate_on_surrounding_func(a:word_size, a:operation)
    silent! call repeat#set("\<Plug>".a:mapname, v:count)
endfunction
"}}}---------------------------------------------------------------------------

"{{{- define plug function calls ----------------------------------------------
xnoremap <silent> <Plug>(SelectWholeFunction)       :<C-U>call surroundfunk#visually_select_whole_func("small")<CR>
onoremap <silent> <Plug>(SelectWholeFunction)       :<C-U>call surroundfunk#visually_select_whole_func("small")<CR>
xnoremap <silent> <Plug>(SelectWholeFUNCTION)       :<C-U>call surroundfunk#visually_select_whole_func("big")<CR>
onoremap <silent> <Plug>(SelectWholeFUNCTION)       :<C-U>call surroundfunk#visually_select_whole_func("big")<CR>
xnoremap <silent> <Plug>(SelectFunctionName)        :<C-U>call surroundfunk#visually_select_func_name("small")<CR>
onoremap <silent> <Plug>(SelectFunctionName)        :<C-U>call surroundfunk#visually_select_func_name("small")<CR>
xnoremap <silent> <Plug>(SelectFunctionNAME)        :<C-U>call surroundfunk#visually_select_func_name("big")<CR>
onoremap <silent> <Plug>(SelectFunctionNAME)        :<C-U>call surroundfunk#visually_select_func_name("big")<CR>

nnoremap <silent> <Plug>(SwitchToParens)            :<C-U>call <SID>switch_default_parens('(')<CR>
nnoremap <silent> <Plug>(SwitchToCurlyBraces)       :<C-U>call <SID>switch_default_parens('{')<CR>
nnoremap <silent> <Plug>(SwitchToSquareBrackets)    :<C-U>call <SID>switch_default_parens('[')<CR>
            
nnoremap <silent> <Plug>(DeleteSurroundingFunction) :<C-U>call <SID>repeatable_delete("small", "delete", "DeleteSurroundingFunction")<CR>
nnoremap <silent> <Plug>(DeleteSurroundingFUNCTION) :<C-U>call <SID>repeatable_delete("big", "delete", "DeleteSurroundingFunction")<CR>
nnoremap <silent> <Plug>(ChangeSurroundingFunction) :<C-U>call <SID>operate_on_surrounding_func("small", "change")<CR>
nnoremap <silent> <Plug>(ChangeSurroundingFUNCTION) :<C-U>call <SID>operate_on_surrounding_func("big", "change")<CR>
nnoremap <silent> <Plug>(YankSurroundingFunction)   :<C-U>call <SID>operate_on_surrounding_func("small", "yank")<CR>
nnoremap <silent> <Plug>(YankSurroundingFUNCTION)   :<C-U>call <SID>operate_on_surrounding_func("big", "yank")<CR>

nnoremap <silent> <Plug>(GripSurroundObject)        :set operatorfunc=<SID>grip_surround_object<CR>g@
vnoremap <silent> <Plug>(GripSurroundObject)        :<C-U>call <SID>grip_surround_object(visualmode())<CR>
nnoremap <silent> <Plug>(GripSurroundObjectNoPaste) :set operatorfunc=<SID>grip_surround_object_no_paste<CR>g@
vnoremap <silent> <Plug>(GripSurroundObjectNoPaste) :<C-U>call <SID>grip_surround_object_no_paste(visualmode())<CR>

"}}}---------------------------------------------------------------------------

"{{{- create maps and text objects --------------------------------------------
if !exists("g:surround_funk_create_mappings") || g:surround_funk_create_mappings != 0

    " normal mode: delete/change/yank
    nmap <silent> dsf <Plug>(DeleteSurroundingFunction)
    nmap <silent> dsF <Plug>(DeleteSurroundingFUNCTION)
    nmap <silent> csf <Plug>(ChangeSurroundingFunction)
    nmap <silent> csF <Plug>(ChangeSurroundingFUNCTION)
    nmap <silent> ysf <Plug>(YankSurroundingFunction)
    nmap <silent> ysF <Plug>(YankSurroundingFUNCTION)

    " normal mode: change default grip
    nmap <silent> g( <Plug>(SwitchToParens)
    nmap <silent> g{ <Plug>(SwitchToCurlyBraces)
    nmap <silent> g[ <Plug>(SwitchToSquareBrackets)

    " visual mode selections
    xmap <silent> af <Plug>(SelectWholeFunction)
    omap <silent> af <Plug>(SelectWholeFunction)
    xmap <silent> aF <Plug>(SelectWholeFUNCTION)
    omap <silent> aF <Plug>(SelectWholeFUNCTION)
    xmap <silent> if <Plug>(SelectWholeFunction)
    omap <silent> if <Plug>(SelectWholeFunction)
    xmap <silent> iF <Plug>(SelectWholeFUNCTION)
    omap <silent> iF <Plug>(SelectWholeFUNCTION)
    xmap <silent> an <Plug>(SelectFunctionName)
    omap <silent> an <Plug>(SelectFunctionName)
    xmap <silent> aN <Plug>(SelectFunctionNAME)
    omap <silent> aN <Plug>(SelectFunctionNAME)
    xmap <silent> in <Plug>(SelectFunctionName)
    omap <silent> in <Plug>(SelectFunctionName)
    xmap <silent> iN <Plug>(SelectFunctionNAME)
    omap <silent> iN <Plug>(SelectFunctionNAME)

    " operator pending mode: grip surround
    nmap <silent> gs <Plug>(GripSurroundObject)
    vmap <silent> gs <Plug>(GripSurroundObject)
    nmap <silent> gS <Plug>(GripSurroundObjectNoPaste)
    vmap <silent> gS <Plug>(GripSurroundObjectNoPaste)

endif
"}}}---------------------------------------------------------------------------

"==============================================================================
