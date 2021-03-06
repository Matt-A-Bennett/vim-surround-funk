# vim-surround-funk

This was inspired by tpope's [vim-surround
plugin](https://github.com/tpope/vim-surround) and allows you to delete, change
and yank a surrounding function call along with its additional arguments. With
the surrounding function call in the unnamed register, you can 'grip' any text
object with it (including a different function call, see below). 'Gripping'
will wrap/encompass a word or function call with the one you have in the
unnamed register (see below).

*N.B. This plugin was formerly called surround-funk.vim, but was renamed to be
more consistent with tpope's vim-surround.*

## Table of contents
* [Feature Demos](#feature-demos)
    * [Commands for stripping function calls and gripping other objects](#commands-for-stripping-function-calls-and-gripping-other-objects)
    * [Text objects for function body and name](#text-objects-for-function-body-and-name)
* [Usage](#usage)
    * [What is a surrounding function call?](#what-is-a-surrounding-function-call)
    * [Deleting, changing and yanking a surrounding function call](#deleting-changing-and-yanking-a-surrounding-function-call)
    * [Text objects](#text-objects)
    * [Gripping a text object or motion with a function call](#gripping-a-text-object-or-motion-with-a-function-call)
        * [Gripping with function call in unnamed register](#gripping-with-function-call-in-unnamed-register)
        * [Gripping with a new function call](#gripping-with-a-new-function-call)
    * [Toggle grip focus: `(` vs. `{` vs. `[`](#toggle-grip-focus--vs--vs-)
    * [Settings](#settings)
        * [Prevent automatic creation of mappings](#prevent-automatic-creation-of-mappings)
        * [Specify what characters are allowed in a function name](#specify-what-characters-are-allowed-in-a-function-name)
        * [Specify the default parenthesis type](#specify-the-default-parenthesis-type)
        * [Make toggle grip last for one command each time](#make-toggle-grip-last-for-one-command-each-time)
        * [Overriding global defaults for individual filetypes](#overriding-global-defaults-for-individual-filetypes)
* [Installation](#installation)
* [Contribution guidelines](#contribution-guidelines)
    * [Report a bug](#report-a-bug)
    * [Request a feature](#request-a-feature)
* [Related plugins](#related-plugins)
* [My other plugins](#my-other-plugins)
* [License](#license)

## Feature demos
### Commands for stripping function calls and gripping other objects
![demo](https://github.com/Matt-A-Bennett/vim_plugin_external_docs/blob/master/vim-surround-funk/operator_1100_775_annotated.gif)
         
### Text objects for function body and name
![demo](https://github.com/Matt-A-Bennett/vim_plugin_external_docs/blob/master/vim-surround-funk/textobjects_1100_775_annotated.gif)

## Usage

(Everything in this section can also be found in Vim's help docs with `:help
surround-funk`, or just `:help funk`)

### What is a surrounding function call?

Below, the `*` symbols show what would be deleted (or yanked) with the `dsf`
(or `ysf`) command. The `^` symbols show where the cursor can be when issuing
the command:

```
sf : Where the name of the function (e.g. outerfunc) is a standard Vim word.
        
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

# multi-line function calls also work:

   **********               ***************
np.outerfunc(innerfunc(arg1),   
                                arg2, arg3) < anywhere on this line is fine too
   ^^^^^^^^^^               ^^^^^^^^^^^^^^^
```

```
sF : Where the name of the function (e.g. np.outerfunc) is similar to a Vim
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

# multi-line function calls also work:

*************               ***************
np.outerfunc(innerfunc(arg1),   
                                arg2, arg3) < anywhere on this line is fine too
^^^^^^^^^^^^^               ^^^^^^^^^^^^^^^
```                                       

### Deleting, changing and yanking a surrounding function call

If you have tpope's excellent [repeat.vim
plugin](https://github.com/tpope/vim-repeat), then the `dsf` and `dsF` commands
are repeatable with the dot command.

To prevent these mappings from being generated, and define your own custom
ones, see `g:surround_funk_create_mappings`
[below](#prevent-automatic-creation-of-normal-mode-mappings).

```
dsf : Delete surrounding function call

dsF : Like 'dsf', but the function name is delimited by any character not in
      'g:surround_funk_legal_func_name_chars' (see below)

csf : Like 'dsf' but start insert mode where the opening parenthesis of the
      changed function used to be

csF : Like 'csf', but the function name is delimited by any character not in
      'g:surround_funk_legal_func_name_chars' (see below)

ysf : Yank surrounding function call 

ysF : Like 'ysf', but the function name is delimited by any character not in
      'g:surround_funk_legal_func_name_chars' (see below)
```

### Text objects

The following text objects are made available by surround-funk:

To prevent these mappings from being generated, and define your own, see
`g:surround_funk_create_mappings`
[below](#prevent-automatic-creation-of-normal-mode-mappings).

```
af : From the first letter of the function's name to the closing parenthesis of
     that function call

aF : Like 'af', but the function name is delimited by any character not in
     'g:surround_funk_legal_func_name_chars' (see below)

if : Alias of 'af'
        
iF : Alias of 'aF'
        
an : The function's name
        
aN : Like 'an', but the function name is delimited by any character not in
     'g:surround_funk_legal_func_name_chars' (see below)

in : Alias of 'an'
        
iN : Alias of 'aN' 
```
     
For example, with the cursor anywhere indicated by the `^` symbols, doing `vif`
will visually select the entire function call, indicated by the `*` symbols (to
include the `np.` part of the function name, use `viF`):

```
   **************************************
np.outerfunc(innerfunc(arg1), arg2, arg3)
   ^^^^^^^^^^               ^^^^^^^^^^^^^
```

To select just the function's name, use `vin` (again, use `viN` to include the
`np.` part):

```
   *********
np.outerfunc(innerfunc(arg1), arg2, arg3)
   ^^^^^^^^^^               ^^^^^^^^^^^^^
```

### Gripping a text object or motion with a function call

#### Gripping with function call in unnamed register

If you have tpope's excellent [repeat.vim
plugin](https://github.com/tpope/vim-repeat), then the following command is
repeatable with the dot command.

To prevent these mappings from being generated, and define your own see
`g:surround_funk_create_mappings`
[below](#prevent-automatic-creation-of-mappings).

```
gs : Grip (i.e wrap/encompass) any text object or motion with the function call
     in the unnamed register.
```

In the example below, with the cursor anywhere with a `^` symbol, you can do
`ysF` to 'yank the surrounding function call' (which is all the stuff with `*`
above it):

```
*************               *************
np.outerfunc(innerfunc(arg1), arg2, arg3)
^^^^^^^^^^^^^               ^^^^^^^^^^^^^
```

Then go to some other function call (or just a word) (the cursor can be
anywhere in this case)

```
os.lonelyfunc(argA, argB)
^^^^^^^^^^^^^^^^^^^^^^^^^
```

And do `gsiF` or `gsaF` to 'grip/surround' the lonely function call with the
yanked one:

```
*************                         *************
np.outerfunc(os.lonelyfunc(argA, argB), arg2, arg3)
^
```

You could then move to a word:

```
MeNext
^^^^^^
```

and grip/surround it with `gsiw`

```
*************      *************
np.outerfunc(MeNext, arg2, arg3)
^
```

You could also grip a multi-line function call (again using `gsiF` or `gsaF`):

```
**************      *******
os.multi_line(argA(),
                argB, argC) < anywhere on this line is fine too
^^^^^^^^^^^^^^  ^^^^^^^^^^^
```

To get:

```
*************                    *
np.outerfunc(os.multi_line(argA(),
                argB, argC), arg2, arg3)
                           *************
```
#### Gripping with a new function call

This one is pretty much the same as tpope's surround `ys<textobject>f` command:
If `gS` is used, Vim prompts for a function name to insert. The target text
will be wrapped in a function call. This command differs from the surround
plugin in that after wrapping the target text, you are left in insert mode just
before the closing parenthesis (in case you want to start adding trailing
arguments).

```
gS : Grip (i.e wrap/encompass) any text object or motion with with a function
     call to be specified on the command line
```

For example, doing `gSaF` on this line:

```
os.lonelyfunc(argA, argB)
^^^^^^^^^^^^^^^^^^^^^^^^^
```

and entering 'np.mean' at the prompt will yield the following with the cursor
(in insert mode) indicated by the `^` symbol:

```
********                         *
np.mean(os.lonelyfunc(argA, argB))
                                 ^
```
### Toggle grip focus: `(` vs. `{` vs. `[`

The following text objects are made available by surround-funk. For a setting
that makes these toggle commands last for one command only see
`g:surround_funk_default_hot_switch`
[below](#make-toggle-grip-last-for-one-command-each-time). 

To prevent these mappings from being generated, and define your own, see
`g:surround_funk_create_mappings`
[below](#prevent-automatic-creation-of-mappings).


```
g( : Make parentheses the focus of all future surround funk commands and text
     objects. 

g{ : Make curly braces the focus of all future surround funk commands and text
     objects. 

g[ : Make square brackets the focus of all future surround funk commands and
     text objects. 
```


For example, if you want to work with latex function calls, you could do `g{`
to make curly braces the focus of surround funk. Then, `dsF` would remove the
part of the line indicated with * symbols. 

```
***************       *
\documentclass{article} 
^^^^^^^^^^^^^^^^^^^^^^^
```

N.B, to include the backslash as part of the funcion name, you also need to add
the following to your .vimrc (see
[below](#specify-what-characters-are-allowed-in-a-function-name)):

```vim
let g:surround_funk_legal_func_name_chars = ['[0-9]', '[A-Z]', '[a-z]', '_', '\.', '\\']
```

### Settings

#### Prevent automatic creation of mappings

By default surround-funk creates the above mappings. If you would
rather it didn't do this (for instance if you already have those key
combinations mapped to something else) you can turn them off with:

```vim
let g:surround_funk_create_mappings = 0
```

And map them to something different with:

```vim
<mode>map <your-map-here> <Plug>(<OperationToMap>)
```

For reference, the default mappings are as follows:

```vim
" normal mode: delete/change/yank
nmap <silent> dsf <Plug>(DeleteSurroundingFunction)
nmap <silent> dsF <Plug>(DeleteSurroundingFUNCTION)
nmap <silent> csf <Plug>(ChangeSurroundingFunction)
nmap <silent> csF <Plug>(ChangeSurroundingFUNCTION)
nmap <silent> ysf <Plug>(YankSurroundingFunction)
nmap <silent> ysF <Plug>(YankSurroundingFUNCTION)

" normal mode: change default grip
nmap <silent> g( <Plug>(SwitchToParens)
nmap <silent> g{ <Plug>(SwitchToCurlyBraces)
nmap <silent> g[ <Plug>(SwitchToSquareBrackets)

" visual mode selections
xmap <silent> af <Plug>(SelectWholeFunction)
omap <silent> af <Plug>(SelectWholeFunction)
xmap <silent> aF <Plug>(SelectWholeFUNCTION)
omap <silent> aF <Plug>(SelectWholeFUNCTION)
xmap <silent> if <Plug>(SelectWholeFunction)
omap <silent> if <Plug>(SelectWholeFunction)
xmap <silent> iF <Plug>(SelectWholeFUNCTION)
omap <silent> iF <Plug>(SelectWholeFUNCTION)
xmap <silent> an <Plug>(SelectFunctionName)
omap <silent> an <Plug>(SelectFunctionName)
xmap <silent> aN <Plug>(SelectFunctionNAME)
omap <silent> aN <Plug>(SelectFunctionNAME)
xmap <silent> in <Plug>(SelectFunctionName)
omap <silent> in <Plug>(SelectFunctionName)
xmap <silent> iN <Plug>(SelectFunctionNAME)
omap <silent> iN <Plug>(SelectFunctionNAME)

" operator pending mode: grip surround
nmap <silent> gs <Plug>(GripSurroundObject)
vmap <silent> gs <Plug>(GripSurroundObject)
nmap <silent> gS <Plug>(GripSurroundObjectNoPaste)
vmap <silent> gS <Plug>(GripSurroundObjectNoPaste)
```

#### Specify what characters are allowed in a function name

By default the 'surround-funk' plugin defines any vim word character
(`[0-9A-Za-z_]`) and any period symbols as valid parts of a function's name.
These characters are used to find the function name when using the capitalised
(e.g. `dsF`, but not `dsf`) versions of the above commands. You can add to, or
remove from, these groups (see
[here](#overriding-global-defaults-for-individual-filetypes) to configure this
setting differently for different filetypes).

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
#### Specify the default parenthesis type

By default, surround funk uses parentheses `(` and `)` to define function
calls. To use curly braces `{` and `}` instead (for instance when working on
latex documents) or square brackets `[` and `]`, put the following in your
.vimrc (see [here](#overriding-global-defaults-for-individual-filetypes) to
configure this setting differently for different filetypes):

```vim
let g:surround_funk_default_parens = '{'
```

or 

```vim
let g:surround_funk_default_parens = '['
```


#### Make toggle grip last for one command each time

By default, when using the `g(`, `g{`, and `g[` commands (see
[here](#toggle-grip-focus--vs--vs-)) surround funk will remember the new
setting. However, if you prefer that these commands only apply for one
operation ('hot switching'), before reverting to the default (see
[here](#specify-the-default-parenthesis-type)) you should put the following in
your .vimrc (see [here](#overriding-global-defaults-for-individual-filetypes)
to configure this setting differently for different filetypes):

```vim
let g:surround_funk_default_hot_switch = 1
```

#### Overriding global defaults for individual filetypes

Global defaults can be overridden for individual filetypes by setting a buffer
default in an `augroup`. For example, suppose you wanted the global defaults to
use square brackets, for function names not to contain numbers, and for hot
switching to be on. You can do this with the following in your vimrc:

```vim
let g:surround_funk_default_parens = '['
let g:surround_funk_default_hot_switch = 1
let g:surround_funk_legal_func_name_chars = ['[A-Z]', '[a-z]', '_', '\.']
```

But now suppose that for python files, you would prefer to use parentheses
instead of square brackets, and not to have hot-switching. For tex files, you
want curly braces, no hot-switching, and for function names to include numbers
again and also a `\`
character:

```vim
augroup surround_funk
    autocmd!
    autocmd FileType python let b:surround_funk_default_parens = '('
    autocmd FileType python let b:surround_funk_default_hot_switch = 0

    autocmd FileType tex let b:surround_funk_default_parens = '{'
    autocmd FileType tex let b:surround_funk_default_hot_switch = 0
    autocmd FileType tex let b:surround_funk_legal_func_name_chars = ['[0-9]', '[A-Z]', '[a-z]', '_', '\.', '\\']
augroup END
```

## Installation

Use your favorite plugin manager.

- [Vim-plug][vim-plug]

    ```vim
    Plug 'Matt-A-Bennett/vim-surround-funk'
    ```

- [NeoBundle][neobundle]

    ```vim
    NeoBundle 'Matt-A-Bennett/vim-surround-funk'
    ```

- [Vundle][vundle]

    ```vim
    Plugin 'Matt-A-Bennett/vim-surround-funk'
    ```

- [Pathogen][pathogen]

    ```sh
    git clone git://github.com/Matt-A-Bennett/vim-surround-funk.git ~/.vim/bundle/vim-surround-funk
    ```

[neobundle]: https://github.com/Shougo/neobundle.vim
[vundle]: https://github.com/gmarik/vundle
[vim-plug]: https://github.com/junegunn/vim-plug
[pathogen]: https://github.com/tpope/vim-pathogen

## Contribution guidelines

### Report a bug
First, check if the bug is already known by seeing whether it's listed on the
[surround-funk todo list](https://github.com/Matt-A-Bennett/vim_plugin_external_docs/blob/master/vim-surround-funk/todo.md).

If it's not there, then please raise a [new
issue](https://github.com/Matt-A-Bennett/vim-surround-funk/issues) (or submit a
pull request) so I can fix it. To make it easier, you can use the following
template (If multi-line was broken, you could show me something like this):

---

Command used: `dsF`

Reproducible example (with arrows showing where the cursor was, in this case,
the 'e' in 'mean'):

```
np.mean(st.std(arg1),     <---
            arg2, arg3)

    ^
    |
```

Result:

```
np.mean(st.std(arg1),     <---
    arg2, ar

^
|
```

Expected:

```
st.std(arg1)  <---
            
^
|
```

---

### Request a feature
First, check if the feature is already planned by looking at the 
[surround-funk todo list](https://github.com/Matt-A-Bennett/vim_plugin_external_docs/blob/master/vim-surround-funk/todo.md).

If it's not there, then please raise a [new
issue](https://github.com/Matt-A-Bennett/vim-surround-funk/issues) describing what
you would like and I'll see what I can do! If you would like to submit a pull
request, then do so (please let me know this is your plan first in a [new issue](https://github.com/Matt-A-Bennett/vim-surround-funk/issues)).

## Related plugins
 - [vim-surround](https://github.com/tpope/vim-surround)
 - [vim-sandwich](https://github.com/machakann/vim-sandwich)
## My other plugins
 - [vim-surround-funk](https://github.com/Matt-A-Bennett/vim-surround-funk):  A
   Vim plugin to manipulate function calls 
 - [vim-visual-history](https://github.com/Matt-A-Bennett/vim-visual-history):
   A Vim plugin that keeps a traversable record of previous visual selections
                       
## License
 Copyright (c) Matthew Bennett. Distributed under the same terms as Vim itself.
 See `:help license`.

