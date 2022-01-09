# Todo list
## Major
- [x] Allow users to define their own maps
- [ ] Have `gs` commands operate on any motion (constrained to a single line)
- [x] Fix major bug 1

## Minor
- [x] Let users provide a list of legal function name characters
- [x] Integrate with repeat.vim
- [x] Rewrite so we don't rely on tons of `exe norm!` commands

## Patches
- [x] Fix minor bug 1

# Bugs
## Major Bugs
1. `gs` commands mess up sometimes: see testing.vim

## Minor Bugs
1. `ysf` and `ysF` remove a line above if applied to function on last line of
   file 

