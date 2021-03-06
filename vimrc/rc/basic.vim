set clipboard=unnamed
""set nocompatible
set expandtab
set nolist
set smartcase
set smartindent
set shiftwidth=2
"set smarttab
set ts=4
set nowrapscan
set autoindent
set tabstop=4
set number
set showmatch
set encoding=utf-8
set termencoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8
set laststatus=2
set t_Co=256
set incsearch
set hlsearch

syntax on

" shortcut mapping
nmap <Esc>id :IndentLinesDisable<CR>
nmap <Esc>ie :IndentLinesEnable<CR>
nmap <Esc>nn :set nonu<CR><Esc>
nmap <Esc>nu :set nu<CR><Esc>
nmap <Esc><Esc> :noh<CR><Esc>

" コロンとセミコロンを入れ替え(for 英字キーボード)
if $KB_TYPE == 'US'
  nnoremap ; :
  nnoremap : ;
endif

inoremap <c-j> <esc>

" backspace enable
noremap ^H <BS>
noremap! ^H <BS>
set backspace=2

" date input ------------------------------------------
inoremap ,todo <C-R>=strftime('%Y-%m-%d %a')<CR>
inoremap ,date <C-R>=strftime('%Y-%m-%d')<CR>
inoremap ,time <C-R>=strftime('%H:%M:%S')<CR>
" -----------------------------------------------------

" file type setting
au BufNewFile,BufRead *.tt :set ft=html
au BufRead,BufNewFile *.tmp set filetype=tmp

" highlight
highlight PreProc guifg=#ffffff

" cursorline ------------------------------------------
" autocmd InsertEnter,InsertLeave * set cursorline!
" set cursorline
" highlight CursorLine ctermbg=240
" -----------------------------------------------------

" status line -----------------------------------------
set statusline=%n\:%y%F\ \|%{(&fenc!=''?&fenc:&enc).'\|'.&ff.'\|'}%m%r%{fugitive#statusline()}%=<%l/%L:%p%%>
" -----------------------------------------------------

" highlight space -------------------------------------
augroup HighlightTrailingSpaces
  autocmd!
  autocmd VimEnter,WinEnter,ColorScheme * highlight TrailingSpaces term=underline ctermbg=DarkCyan
  set list
  set listchars=tab:>.,trail:_,extends:>,precedes:<,nbsp:%
  autocmd VimEnter,WinEnter * match TrailingSpaces /\s\+$/
augroup END
" -----------------------------------------------------

" json syntax
autocmd Filetype json setl conceallevel=0
let g:vim_json_syntax_conceal = 0

" always transparency
if !has('gui_running')
  augroup seiya
    autocmd!
    autocmd VimEnter,ColorScheme * highlight Normal ctermbg=none
    autocmd VimEnter,ColorScheme * highlight LineNr ctermbg=none
    autocmd VimEnter,ColorScheme * highlight SignColumn ctermbg=none
    autocmd VimEnter,ColorScheme * highlight VertSplit ctermbg=none
    autocmd VimEnter,ColorScheme * highlight NonText ctermbg=none
  augroup END
endif
