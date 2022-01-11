# surround-funk.vim (version 1.0.0)

This was inspired by tpope's [surround.vim
plugin](https://github.com/tpope/vim-surround) and allows you to delete, change
and yank a surrounding function along with its additional arguments. With the
surrounding function in the unnamed register, you can 'grip' a word or another
function with it. 'Gripping' will wrap/encompass a word or function with the
one you have in the unnamed register (see below).

![demo](demo.gif)

## Table of contents
<!--ts-->
   * [Usage](#usage)
      * [What is a surrounding function?](#what-is-a-surrounding-function)
      * [Deleting, changing and yanking a surrounding function](#deleting-changing-and-yanking-a-surrounding-function)
      * [Gripping a word or another function](#gripping-a-word-or-another-function)
      * [Settings](#settings)
         * [Turn off automatic creation of normal mode mappings](#turn-off-automatic-creation-of-normal-mode-mappings)
         * [Specify what characters are allowed in a function name](#specify-what-characters-are-allowed-in-a-function-name)
   * [Installation](#installation)
   * [License](#license)
<!--te-->

## Usage
(Everything below can also be found with `:help surround-funk`, or just `:help
funk`)

### What is a surrounding function?

Below, the `*` symbols show what would be deleted (or yanked) with the `dsf`
(or `ysf`) command. The `^` symbols show where the cursor can be when issuing
the command:

```
sf: Where the name of the function (e.g. outerfunc) is a standard Vim word.

   **********               *
np.outerfunc(innerfunc(arg1))
   ^^^^^^^^^^               ^

   **********               *************
np.outerfunc(innerfunc(arg1), arg2, arg3)
   ^^^^^^^^^^               ^^^^^^^^^^^^^

   **********    *
np.outerfunc(arg1)
   ^^^^^^^^^^^^^^^

   **********                *
np.outerfunc(arg1, arg2, arg3)
   ^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

```
sF: Where the name of the function (e.g. np.outerfunc) is similar to a Vim
    WORD, but is additionally delimited by any character not in
    'g:surround_funk_legal_func_name_chars' (see below)

*************               *
np.outerfunc(innerfunc(arg1))
^^^^^^^^^^^^^               ^

*************               *************
np.outerfunc(innerfunc(arg1), arg2, arg3)
^^^^^^^^^^^^^               ^^^^^^^^^^^^^

*************    *
np.outerfunc(arg1)
^^^^^^^^^^^^^^^^^^

*************                *
np.outerfunc(arg1, arg2, arg3)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

### Deleting, changing and yanking a surrounding function

If you have tpope's excellent [repeat.vim
plugin](https://github.com/tpope/vim-repeat), then the `dsf` and `dsF` commands
are repeatable with the dot command.

To prevent these mappings from being generated, and define your own see
`g:surround_funk_create_mappings` below.

```
dsf: Delete surrounding function

dsF: Like `dsf`, but the function name is delimited by any character not in 
     'g:surround_funk_legal_func_name_chars' (see below)

csf: Like `dsf` but start instert mode where the opening parenthesis of the
     changed function used to be

csF: Like `csf`, but the function name is delimited by any character not in 
     'g:surround_funk_legal_func_name_chars' (see below)

ysf: Yank surrounding function ysF: Like `ysf`, but the function name is
     delimited by any character not in 'g:surround_funk_legal_func_name_chars'
     (see below)
```

### Gripping a word or another function

If you have tpope's excellent [repeat.vim
plugin](https://github.com/tpope/vim-repeat), then the following commands are
repeatable with the dot command.

To prevent these mappings from being generated, and define your own see
`g:surround_funk_create_mappings` below.

```
gsf: Grip (i.e wrap/encompass) another function with the function in the
     unnamed register.

gsF: Like 'gsf', but the function name is delimited by any character not in 
     'g:surround_funk_legal_func_name_chars' (see below)

gsw: Grip (i.e wrap/encompass) a word with the function in the unnamed 
     register.

gsW: Like 'gsw', but the function name is delimited by of 
     'g:surround_funk_legal_func_name_chars' (see below)
```

In the example below, with the cursor anywhere with a `^` symbol, you can do
`ysF` to 'yank the surrounding function' (which is all the stuff with `*` above
it):

```
*************               *************
np.outerfunc(innerfunc(arg1), arg2, arg3)
^^^^^^^^^^^^^               ^^^^^^^^^^^^^
```

Then go to some other function (or just a word) (the cursor can be anywhere in
this case)

```
os.lonelyfunc(argA, argB)
^^^^^^^^^^^^^^^^^^^^^^^^^
```

And do `gsF` to 'grip/surround' the lonely function with the yanked one:

```
************                          *************
np.outerfunc(os.lonelyfunc(argA, argB), arg2, arg3)
^
```

You could then move to a word:

```
MeNext
^^^^^^
```

and grip/surround it with `gsw`

```
*************      *************
np.outerfunc(MeNext, arg2, arg3)
^
```

### Settings

#### Turn off automatic creation of normal mode mappings

By default surround-funk creates the above normal mode mappings. If you would
rather it didn't do this (for instance if you already have those key
combinations mapped to something else) you can turn them off with:

```vim
let g:surround_funk_create_mappings = 0
```

And map them to something different with:

```vim
nmap <your-map-here> <Plug><OperationToMap>
```

For reference, the default mappings are as follows:

```vim
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
```

#### Specify what characters are allowed in a function name

By default the 'surround-funk' plugin defines any vim word character
(`[0-9A-Za-z_]`) and any period symbols as valid parts of a functions name.
These characters are used to find the function name when using the capitalised
(e.g. `dsF`, but not `dsf`) versions of the above commands. You can add to or
remove from these groups.

The default:

```vim
g:surround_funk_legal_func_name_chars = ['[0-9]', '[A-Z]', '[a-z]', '_', '\.']
```

will match function names like:

```
      *********  *************  **************
...), pd.mean(), np2.my_func(), 8np.my._func(), ...
      ^^^^^^^^^  ^^^^^^^^^^^^^  ^^^^^^^^^^^^^^
```

but would stop at characters not in the legal name set (e.g. `@`, `#`, `/`):

```
         ******         ******      **********
...), pd@mean(), np2.my#func(), 8np/my._func(), ...
         ^^^^^^         ^^^^^^      ^^^^^^^^^^
```

To make numbers illegal, and to introduce `#` and `@` as legal characters, use:

```vim
let g:surround_funk_legal_func_name_chars = ['[A-Z]', '[a-z]', '_', '\.', '#', '@']
```

will match function names like:

```
      *********     **********   *************
...), pd.mean(), np2.my_func(), 8np.my._func(), ...
      ^^^^^^^^^     ^^^^^^^^^^   ^^^^^^^^^^^^^

      *********     **********      **********
...), pd@mean(), np2.my#func(), 8np/my._func(), ...
      ^^^^^^^^^     ^^^^^^^^^^      ^^^^^^^^^^
```

## Installation

Use your favorite plugin manager.

- [Vim-plug][vim-plug]

    ```vim
    Plug 'Matt-A-Bennett/surround-funk.vim'
    ```

- [NeoBundle][neobundle]

    ```vim
    NeoBundle 'Matt-A-Bennett/surround-funk.vim'
    ```

- [Vundle][vundle]

    ```vim
    Plugin 'Matt-A-Bennett/surround-funk.vim'
    ```

- [Pathogen][pathogen]

    ```sh
    git clone git://github.com/Matt-A-Bennett/surround-funk.vim.git ~/.vim/bundle/surround-funk.vim
    ```

[neobundle]: https://github.com/Shougo/neobundle.vim
[vundle]: https://github.com/gmarik/vundle
[vim-plug]: https://github.com/junegunn/vim-plug
[pathogen]: https://github.com/tpope/vim-pathogen

## License
 Copyright (c) Matthew Bennett. Distributed under the same terms as Vim itself.
 See `:help license`.

