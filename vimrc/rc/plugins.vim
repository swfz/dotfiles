" vim-plug
" Auto-install vim-plug if not present
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

" ============================================
" Complete and Format
" ============================================
Plug 'kana/vim-surround'
Plug 'vim-scripts/AutoClose'
Plug 'Shougo/neocomplcache'
Plug 'vim-scripts/smartchr'
Plug 'vim-scripts/Align'
Plug 'vim-scripts/SQLUtilities'
Plug 'tyru/caw.vim'
Plug 'AndrewRadev/linediff.vim'
Plug 'mattn/emmet-vim'
Plug 'Shougo/neosnippet'
Plug 'Shougo/neosnippet-snippets'
Plug 'LeafCage/yankround.vim'
Plug 'tpope/vim-speeddating'

" ============================================
" Filer and Navigation
" ============================================
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
Plug 'ctrlpvim/ctrlp.vim'
Plug 'Shougo/neomru.vim'
Plug 'Shougo/vimfiler', { 'on': ['VimFiler', 'VimFilerTab', 'VimFilerExplorer'] }
Plug 'Shougo/unite.vim'
Plug 'wesleyche/SrcExpl'
Plug 'vim-scripts/taglist.vim'
Plug 'h1mesuke/unite-outline'
Plug 'thinca/vim-ref'

" ============================================
" Shell and Execution
" ============================================
Plug 'thinca/vim-quickrun', { 'on': 'QuickRun' }
Plug 'Shougo/vimshell.vim', { 'on': ['VimShell', 'VimShellPop'] }
Plug 'rking/ag.vim'
Plug 'benmills/vimux', { 'on': ['VimuxRunCommand', 'VimuxPromptCommand'] }

" vimproc (required by unite.vim, vimfiler, vimshell)
Plug 'Shougo/vimproc.vim', { 'do': 'make' }

" ============================================
" Colorschemes
" ============================================
Plug 'nanotech/jellybeans.vim'
Plug 'vim-scripts/Lucius'
Plug 'vim-scripts/Zenburn'
Plug 'croaker/mustang-vim'
Plug 'altercation/vim-colors-solarized'
Plug 'jeffreyiacono/vim-colors-wombat'
Plug 'jpo/vim-railscasts-theme'
Plug 'tomasr/molokai'
Plug 'w0ng/vim-hybrid'
Plug 'vim-scripts/rdark'
Plug 'mrkn/mrkn256.vim'
Plug 'ChasingLogic/ChasingLogic-colorscheme-vim'
Plug 'raphamorim/lucario'
Plug 'ujihisa/unite-colorscheme'
Plug 'therubymug/vim-pyte'
Plug 'Blevs/vim-dzo'
Plug 'bcicen/vim-vice'
Plug 'jacoborus/tender.vim'
Plug 'arcticicestudio/nord-vim'

" ============================================
" Syntax and Linting
" ============================================
Plug 'dense-analysis/ale'
Plug 'tpope/vim-markdown'
Plug 'kien/rainbow_parentheses.vim'
Plug 't9md/vim-quickhl'
Plug 'slim-template/vim-slim'
Plug 'mattn/vim-lsp-settings'

" ============================================
" TypeScript
" ============================================
Plug 'leafgarland/typescript-vim', { 'for': 'typescript' }
Plug 'jason0x43/vim-js-indent', { 'for': ['javascript', 'typescript', 'html'] }
let g:js_indent_typescript = 1
Plug 'Quramy/tsuquyomi'

" ============================================
" Git Integration
" ============================================
Plug 'gregsexton/gitv', { 'on': 'Gitv' }
Plug 'tpope/vim-fugitive'
Plug 'vim-scripts/vcscommand.vim'

" ============================================
" API and Translation
" ============================================
Plug 'koron/codic-vim'
Plug 'rhysd/unite-codic.vim'

" ============================================
" Markdown Preview
" ============================================
if $IS_WSL != 1
  Plug 'kannokanno/previm'
  Plug 'tyru/open-browser.vim'
endif

" ============================================
" UI and Design
" ============================================
Plug 'kana/vim-submode'
Plug 'Yggdroot/indentLine'
" Plug 'nathanaelkane/vim-indent-guides'

" ============================================
" Other Utilities
" ============================================
Plug 'hotchpotch/perldoc-vim'
Plug 'gko/vim-coloresque'
Plug 'tsukkee/unite-tag'

" ============================================
" Statusline
" ============================================
if $IS_WSL == 1
  Plug 'itchyny/lightline.vim'
else
  Plug 'Lokaltog/powerline', { 'rtp': 'powerline/bindings/vim' }
endif

call plug#end()

" Required for plugin functionality
filetype plugin indent on
