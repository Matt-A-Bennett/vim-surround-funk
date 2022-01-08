let positions = [7, 7]
let tests = ['dsf', 'dsF']

let failure = '^.\+$\n^.\+$\n^.\+$'

call cursor(1,1)
let test_count = 0
for test in tests
    call search('test'.string(test_count))
    execute "normal j"
    call cursor('.', positions[test_count])
    execute "normal ".test
    :.,+!uniq
    let test_count += 1
endfor
call cursor(1,1)

call search(failure)
call setreg("/", failure)
set hlsearch
