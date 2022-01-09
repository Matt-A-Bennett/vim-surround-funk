# Todo list
## Major
- [x] Integrate with repeat.vim
- [ ] Allow multi-line functions
- [ ] Have `gs` commands operate on any motion (constrained to a single line)

## Minor
- [x] Rewrite so we don't rely on tons of `exe norm!` commands
- [x] Fix big bug 1
- [x] Let users provide a list of legal function name characters
- [x] Allow users to define their own maps

## Patches
- [x] Fix small bug 1
- [ ] These functions are unneeded (s:move_to_end_of_func)

### Bugs
#### Big Bugs
1. `gs` commands mess up sometimes: see testing.vim

#### Small Bugs
1. `ysf` and `ysF` remove a line above if applied to function on last line of
   file 

