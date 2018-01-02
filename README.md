# Neoterm Utils
A set of wrappers around original neoterm commands 
and functions. Adds a litle UX improvenments, like follows:
* Show only one neoterm instance opened (say no to visual buffers overload)
* Auto focus neoterm immediately after opening, and jump back after closing it (say no to extra `<C-W><C-hjkl>` after opening pane)
* Bind exit terminal-mode to `<esc>` locally for each neoterm buffer (so this binding doesn't impacts/brokes other plugins, like `fzf`)
* Each neoterm toggle action- automatically mapped to `<M-1>`, `<M-2>`, ... keys (inspired by Intellij panes)

## Usage
```vimscript
:TnewBatch      " creates batch of 4 neterm instances (by default)
:TnewImproved   " creates one neoterm instance
:TtoggleLast    " toggles last opened neoterm window
```

## Installation
Using Vim-Plug:
```vimsrcript
Plug 'kassio/neoterm'
Plug 'yanlobkarev/neoterm-utils'
```

## Configuration
```vimscript
nmap <silent> <M-`> :TtoggleLast<cr>
tmap <silent> <M-`> <esc>:TtoggleLast<cr>
imap <silent> <M-`> <esc>:TtoggleLast<cr>

nnoremap <silent><localleader>nt :TnewImproved<CR>

let g:neoterm_batch_size = 4        "  Customize terms batch size
let g:neoterm_batch_at_startup = 0  "  Disable auto cration of neoterm 
                                    " batch at startup (for manual 
                                    " creation use :TnewBatch and
                                    " :TnewImproved)
```

...docs in progress
