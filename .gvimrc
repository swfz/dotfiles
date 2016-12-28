" フォント
set guifont=Ricty_For_Powerline:h12

" 透過
set transparency=10

" カラースキーム
colorscheme lucius

" 背景色
highlight Normal guibg=#071d40
highlight Cursor guifg=glay guibg=magenta

" windowサイズ
set columns=250
set lines=70

" IME関連
" EscでIMEをOFF
inoremap <ESC> <ESC>:set iminsert=0<CR>:set noimdisable<CR>

" Insertモード時にimdisableをONにする
au InsertEnter * call EnterIM()

function EnterIM()
  set iminsert=1
  set imdisable
endfunction

" TODO 動作しない
au InsertLeave * call LeaveIM()
function LeaveIM()
  set iminsert=0
  set noimdisable
endfunction

" mac用
nnoremap ; :
nnoremap : ;

