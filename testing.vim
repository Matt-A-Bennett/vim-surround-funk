" Script for doing unit tests on test.vim

" set cursor position and specify the commands to run
let initial_cursor_col = [7, 7]
let commands_to_apply = ['dsf', 'dsF']

" failed tests will leave 3, not 2, lines
let failed_case = '^.\+$\n^.\+$\n^.\+$'

call cursor(1,1)
let test_count = 0
for command in commands_to_apply
    " move to next test
    call search('command'.string(test_count))
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
call search(failed_case)
call setreg("/", failed_case)
set hlsearch
