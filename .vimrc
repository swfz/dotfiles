source ~/dotfiles/vimrc/rc/basic.vim
source ~/dotfiles/vimrc/rc/plugins.vim
source ~/dotfiles/vimrc/rc/mapping.vim
source ~/dotfiles/vimrc/rc/tab.vim

source ~/dotfiles/vimrc/plugins/unite.vim
source ~/dotfiles/vimrc/plugins/complete.vim

" this settings dependencies colorscheme. section
if $IS_WSL == 1
  source ~/dotfiles/vimrc/plugins/lightline.vim
else
  source ~/dotfiles/vimrc/plugins/powerline.vim
endif

" colorscheme patch
autocmd ColorScheme * highlight IncSearch ctermfg=17 ctermbg=214
autocmd ColorScheme * highlight Search ctermfg=17 ctermbg=214

set background=dark
colorscheme solarized
" colorscheme lucius
" LuciusBlack
" hi Normal ctermbg=NONE

" source ~/dotfiles/vimrc/plugins/lightline.vim
source ~/dotfiles/vimrc/plugins/unite-outline.vim
source ~/dotfiles/vimrc/plugins/taglist.vim
source ~/dotfiles/vimrc/plugins/submode.vim
source ~/dotfiles/vimrc/plugins/quickhl.vim
source ~/dotfiles/vimrc/plugins/indentline.vim
source ~/dotfiles/vimrc/plugins/yankround.vim
source ~/dotfiles/vimrc/plugins/caw.vim
source ~/dotfiles/vimrc/plugins/smartchr.vim
source ~/dotfiles/vimrc/plugins/srcexpl.vim
source ~/dotfiles/vimrc/plugins/ale.vim
source ~/dotfiles/vimrc/plugins/vim-go.vim

