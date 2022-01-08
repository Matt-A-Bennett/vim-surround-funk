" Script for doing unit tests on test.vim

" set cursor position and specify the commands to run
let initial_cursor_col = [7, 7, 7, 7, 
            \7, 7, 7]
let commands_to_apply = ['dsf', 'dsF', 'csfhello', 'csFhello',
            \'ysfjf(lgsf', 'ysfjf(lgsF', 'ysFjgsF']

let n_paste_tests = 3
" failed tests will leave 3, not 2, lines
let failed_case = '^.\+$\n^.\+$\n^.\+$'

call cursor(1,1)
let paste = searchpos(failed_case.'\n^.\+$')[0]
call cursor(1,1)

let test_count = 0
for command in commands_to_apply
    " move to next test
    call search('test'.string(test_count))
    execute "normal j"
    call cursor('.', initial_cursor_col[test_count])
    " apply test
    execute "normal ".command
    " passed tests should produce a duplicate line, which we remove
    :.,+!uniq
    let test_count += 1
endfor
call cursor(1,1)

" jump to and highlight any failed cases
if searchpos(failed_case, 'c')[0] ==# paste-test_count+n_paste_tests
    let failed_case = failed_case.'\n^.\+$'
endif
call search(failed_case, 'c')
call setreg("/", failed_case)
set hlsearch

