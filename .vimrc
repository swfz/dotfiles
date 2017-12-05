source ~/dotfiles/vimrc/rc/basic.vim
source ~/dotfiles/vimrc/rc/plugins.vim
source ~/dotfiles/vimrc/rc/mapping.vim
source ~/dotfiles/vimrc/rc/tab.vim

source ~/dotfiles/vimrc/plugins/unite.vim
source ~/dotfiles/vimrc/plugins/complete.vim

" this settings dependencies colorscheme. section
source ~/dotfiles/vimrc/plugins/powerline.vim

" colorscheme patch
autocmd ColorScheme * highlight IncSearch ctermfg=17 ctermbg=214
autocmd ColorScheme * highlight Search ctermfg=17 ctermbg=214

colorscheme lucario
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

