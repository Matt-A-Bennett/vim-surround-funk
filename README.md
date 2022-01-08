# surround-funk.vim (version 0.4.0)
***This plugin is currently in an initial testing phase***

This was inspired by tpope's
[surround.vim](https://github.com/tpope/vim-surround) and allows you to delete,
change and yank a surrounding function along with its additional arguments.
With the surrounding function in the unnamed register, you can 'grip' a word or
another function with it. 'Gripping' will wrap/encompass a word or function
with the one you have in the unnamed register (see below).

## Usage

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
    WORD, but is additionally delimited by commas, semicolons and opening
    parentheses.

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

```
dsf: Delete surrounding function

dsF: Like 'dsf', but the function name is delimited by whitespaces, commas,
     semicolons and opening parentheses.

csf: Like 'dsf' but start instert mode where the opening parenthesis of the
     changed function was

csF: Like 'csf', but the function name is delimited by whitespaces, commas,
     semicolons and opening parentheses.

ysf: Yank surrounding function

ysF: Like 'ysf', but the function name is delimited by whitespaces, commas,
     semicolons and opening parentheses.
```

### Gripping a word or another function

```
gsf: Grip (i.e wrap/encompass) another function with the function in the
     unnamed register.

gsF: Like 'gsf', but the function name is delimited by whitespaces, commas,
     semicolons and opening parentheses.

gsw: Grip (i.e wrap/encompass) a word with the function in the unnamed 
     register.

gsW: Like 'gsw', but the word name is delimited by whitespaces, commas,
     semicolons and opening parentheses.
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

## Licence
 Copyright (c) Matthew Bennett. Distributed under the same terms as Vim itself.
 See `:help license`.

