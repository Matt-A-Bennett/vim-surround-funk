# surround-funk.vim (version 0.2.0)
This was inspired by tpope's [surround.vim](https://github.com/tpope/vim-surround) 
and allows you to delete, change, yank, and paste the 'surrounding function':

## What is a surrounding function?

Below, the `*` symbols show what would be deleted (or yanked) with the `dsf`
(or `ysf`) command. The `^` symbols show where the cursor can be when issuing
the command:

```
sf: Where the name of the function (e.g. outerfunc) is a standard Vim word.

   **********                *
np.outerfunc(arg1, arg2, arg3)
   ^^^^^^^^^^^^^^^^^^^^^^^^^^^

   **********               *************
np.outerfunc(innerfunc(arg1), arg2, arg3)
   ^^^^^^^^^^               ^^^^^^^^^^^^^

sF: Where the name of the function (e.g. outerfunc) is similar to a Vim WORD, 
    but in addition to whitespaces, includes commas, semicolons and opening
    parentheses.

*************                *
np.outerfunc(arg1, arg2, arg3)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

*************               *************
np.outerfunc(innerfunc(arg1), arg2, arg3)
^^^^^^^^^^^^^               ^^^^^^^^^^^^^
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

