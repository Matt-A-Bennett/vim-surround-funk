# Todo list
## Major
- [ ] Integrate with repeat.vim
- [ ] Have `gs` commands operation on any motion (constrained to a single line)
- [x] Fix major bugs 1

## Minor
- [ ] Let users provide a list of legal function name characters
- [ ] Allow users to define their own maps
- [x] Rewrite so we don't rely on tons of `exe norm!` commands

## Patches
- [x] Fix minor bug 1

# Bugs
## Major Bugs
1. `gs` commands mess up sometimes: see testing.vim

## Minor Bugs
1. `ysf` and `ysF` remove a line above if applied to function on last line of
   file 

