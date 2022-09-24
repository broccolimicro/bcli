"filetype plugin indent on
"set backspace=indent,eol,start

"let g:go_fmt_command = "goimports"
"let g:go_auto_type_info = 1
nnoremap <C-g> :NERDTreeToggle<CR>
let g:NERDTreeWinSize=20

set undofile " Maintain undo history between sessions
set undodir=~/.vim/undodir

command T execute "vertical term"

set tabstop=2
set softtabstop=0 noexpandtab
set shiftwidth=2

set foldmethod=indent
set foldlevelstart=99
nnoremap <space> za
nnoremap <space><space> zA

autocmd FileType tex,md,html setlocal spell spelllang=en

nnoremap U <C-R>
vmap v <Plug>(expand_region_expand)
vmap <C-v> <Plug>(expand_region_shrink)

filetype on
syntax on
set hlsearch
" used to dark background, use cyan instead of blue for comments
:highlight darkComment ctermfg=6
:highlight cComment ctermfg=6
:highlight texComment ctermfg=6
:highlight shComment ctermfg=6
:highlight cshComment ctermfg=6
:highlight makeComment ctermfg=2
:highlight gnuplotComment ctermfg=6
"//#:imap ` <ESC>
:highlight awkComment ctermfg=2
au BufRead,BufNewFile *.hac set filetype=hackt
au BufRead,BufNewFile *.actmx set filetype=hackt
au BufRead,BufNewFile *.act set filetype=hackt
au! Syntax hackt source ~/.vim/syntax/hackt.vim

imap <silent> <Down> <C-o>gj
imap <silent> <Up> <C-o>gk
nmap <silent> <Down> gj
nmap <silent> <Up> gk

command C execute "set splitbelow | 20new | setlocal buftype=nofile | setlocal bufhidden=hide | setlocal noswapfile | r ! hseenc # -c"
command CU execute "set splitbelow | 20new | setlocal buftype=nofile | setlocal bufhidden=hide | setlocal noswapfile | r ! hseenc # -cu"
command CD execute "set splitbelow | 20new | setlocal buftype=nofile | setlocal bufhidden=hide | setlocal noswapfile | r ! hseenc # -cd"
command S execute "set splitbelow | 20new | setlocal buftype=nofile | setlocal bufhidden=hide | setlocal noswapfile | r ! hseenc # -s"
command SU execute "set splitbelow | 20new | setlocal buftype=nofile | setlocal bufhidden=hide | setlocal noswapfile | r ! hseenc # -su"
command SD execute "set splitbelow | 20new | setlocal buftype=nofile | setlocal bufhidden=hide | setlocal noswapfile | r ! hseenc # -sd"

command HSE execute "exe \"ConqueTermVSplit hsesim \" . expand(\"%\")"

