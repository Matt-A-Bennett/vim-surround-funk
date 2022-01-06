# surround-funk.vim (version 0.0.1)
This was inspired by tpope's [surround.vim](https://github.com/tpope/vim-surround) 
and allows you to delete, change, yank, and paste the 'surrounding function':

```python

np.outerfunc(arg1, arg2, arg3)
   ----------                -
            |________________|
                    sf

np.outerfunc(innerfunc(arg1), arg2, arg3)
   ----------               -------------
            |_______________|
                    sf

np.outerfunc(arg1, arg2, arg3)
-------------                -
            |________________|
                    sF

np.outerfunc(innerfunc(arg1), arg2, arg3)
-------------               -------------
            |_______________|
                    sF

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

