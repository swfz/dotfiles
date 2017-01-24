" neobundle
set nocompatible               " Be iMproved
filetype off                   " Required!

if has('vim_starting')
  set runtimepath+=~/.vim/bundle/neobundle.vim/
endif

call neobundle#begin(expand('~/.vim/bundle/'))

" Let NeoBundle manage NeoBundle
NeoBundleFetch 'Shougo/neobundle.vim'
NeoBundle 'Shougo/vimproc', {
      \ 'build' : {
      \     'windows' : 'echo "Sorry, cannot update vimproc binary file in Windows."',
      \     'cygwin' : 'make -f make_cygwin.mak',
      \     'mac' : 'make -f make_mac.mak',
      \     'unix' : 'make -f make_unix.mak',
      \    },
      \ }

" plugins
" complete and format
NeoBundle 'kana/vim-surround'
NeoBundle 'vim-scripts/AutoClose'
NeoBundle 'Shougo/neocomplcache'
NeoBundle "smartchr"
NeoBundle 'vim-scripts/Align'
NeoBundle 'vim-scripts/SQLUtilities'
NeoBundle 'tyru/caw.vim.git'
NeoBundle 'AndrewRadev/linediff.vim'
NeoBundle 'mattn/emmet-vim'
NeoBundle 'Shougo/neosnippet'
NeoBundle 'Shougo/neosnippet-snippets'
NeoBundle 'LeafCage/yankround.vim'
NeoBundle 'tpope/vim-speeddating'

" filer move
NeoBundle 'scrooloose/nerdtree'
NeoBundle 'ctrlpvim/ctrlp.vim'
NeoBundle 'Shougo/neomru.vim'
NeoBundle 'Shougo/vimfiler'
NeoBundle 'Shougo/unite.vim'
NeoBundle 'wesleyche/SrcExpl'
NeoBundle 'vim-scripts/taglist.vim'
NeoBundle 'h1mesuke/unite-outline'
NeoBundle 'thinca/vim-ref'

" shell
NeoBundle 'thinca/vim-quickrun'
NeoBundle 'Shougo/vimshell.vim'
NeoBundle 'rking/ag.vim'

" colorscheme
NeoBundle 'nanotech/jellybeans.vim'
NeoBundle 'vim-scripts/Lucius'
NeoBundle 'vim-scripts/Zenburn'
NeoBundle 'croaker/mustang-vim'
NeoBundle 'altercation/vim-colors-solarized'
NeoBundle 'jeffreyiacono/vim-colors-wombat'
NeoBundle 'jpo/vim-railscasts-theme'
NeoBundle 'tomasr/molokai'
NeoBundle 'w0ng/vim-hybrid'
NeoBundle 'vim-scripts/rdark'
NeoBundle 'mrkn/mrkn256.vim'
NeoBundle 'ChasingLogic/ChasingLogic-colorscheme-vim'
NeoBundle 'raphamorim/lucario'
NeoBundle 'ujihisa/unite-colorscheme'
NeoBundle 'therubymug/vim-pyte'
NeoBundle 'Blevs/vim-dzo'
NeoBundle 'bcicen/vim-vice'


" syntax
NeoBundle 'scrooloose/syntastic'
NeoBundle 'derekwyatt/vim-scala'
NeoBundle 'tpope/vim-markdown'
NeoBundle 'kien/rainbow_parentheses.vim'
NeoBundle 't9md/vim-quickhl'
NeoBundle "slim-template/vim-slim"
NeoBundle 'fatih/vim-go'

" TypeScript
NeoBundleLazy 'leafgarland/typescript-vim', {
      \ 'autoload' : {
      \   'filetypes' : ['typescript'] }
      \}
NeoBundleLazy 'jason0x43/vim-js-indent', {
      \ 'autoload' : {
      \   'filetypes' : ['javascript', 'typescript', 'html'],
      \}}
let g:js_indent_typescript = 1
NeoBundle 'Quramy/tsuquyomi'


" git
NeoBundle 'gregsexton/gitv'
NeoBundle 'tpope/vim-fugitive'
NeoBundle 'vim-scripts/vcscommand.vim'

" api
NeoBundle 'koron/codic-vim'
NeoBundle 'rhysd/unite-codic.vim'

" markdown-preview
NeoBundle 'kannokanno/previm'
NeoBundle 'tyru/open-browser.vim'

" design
NeoBundle 'kana/vim-submode'
NeoBundle "Yggdroot/indentLine"
" NeoBundle 'nathanaelkane/vim-indent-guides'

" other
NeoBundle 'hotchpotch/perldoc-vim'

" powerline
NeoBundle 'Lokaltog/powerline.git'

" not using
" NeoBundle 'itchyny/lightline.vim'

" Installation check.
if neobundle#exists_not_installed_bundles()
  echomsg 'Not installed bundles : ' .
        \ string(neobundle#get_not_installed_bundle_names())
  echomsg 'Please execute ":NeoBundleInstall" command.'
  "finish
endif

call neobundle#end()
