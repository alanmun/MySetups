" Exit insert mode quickly with jj
inoremap jj <Esc>

" Keep multi-key mapping timeout short so jj must be fast
set timeoutlen=300

" VSCode-like move line/selection mappings
nnoremap <A-Down> :m+1<CR>==
nnoremap <A-Up>   :m-2<CR>==
nnoremap <A-j>    :m+1<CR>==
nnoremap <A-k>    :m-2<CR>==

xnoremap <A-Down> :m '>+1<CR>gv=gv
xnoremap <A-Up>   :m '<-2<CR>gv=gv
xnoremap <A-j>    :m '>+1<CR>gv=gv
xnoremap <A-k>    :m '<-2<CR>gv=gv
