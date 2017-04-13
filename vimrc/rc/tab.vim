" tab settings
hi TabLineSel  term=bold    cterm=bold,underline ctermfg=219  ctermbg=024   gui=bold,underline guifg=255      guibg=031
hi TabLineFill term=reverse cterm=reverse,bold   ctermfg=236  ctermbg=075   gui=reverse,bold   guifg=DarkGray guibg=LightGray
hi TabLine     term=reverse cterm=underline      ctermfg=117  ctermbg=236   gui=underline      guifg=255      guibg=DarkGray
hi TabLineInfo term=reverse ctermfg=Black        ctermbg=cyan guifg=black                      guibg=cyan

" Anywhere SID.
function! s:SID_PREFIX()
  return matchstr(expand('<sfile>'), '<SNR>\d\+_\zeSID_PREFIX$')
endfunction

" Set tabline.
function! s:my_tabline()  "{{{
  let s = ''
  for i in range(1, tabpagenr('$'))
    let bufnrs = tabpagebuflist(i)
    let bufnr = bufnrs[tabpagewinnr(i) - 1]  " first window, first appears
    let no = i  " display 0-origin tabpagenr.
    let mod = getbufvar(bufnr, '&modified') ? '!' : ' '
    let title = fnamemodify(bufname(bufnr), ':t')
    let title = '[' . title . ']'
    let s .= '%'.i.'T'
    let s .= '%#' . (i == tabpagenr() ? 'TabLineSel' : 'TabLine') . '#'
    let s .= no . ':' . title
    let s .= mod
    let s .= '%#TabLineFill# '
  endfor
  let s .= '%#TabLineFill#%T%=%#TabLine#'
  return s
endfunction "}}}
let &tabline = '%!'. s:SID_PREFIX() . 'my_tabline()'
set showtabline=2 " 常にタブラインを表示

" The prefix key.
nnoremap    [Tag]   <Nop>
nmap    t [Tag]
" Tab jump
for n in range(1, 9)
  execute 'nnoremap <silent> [Tag]'.n  ':<C-u>tabnext'.n.'<CR>'
endfor
" t1 で1番左のタブ、t2 で1番左から2番目のタブにジャンプ

noremap <silent> [Tag]c :tablast <bar> tabnew<CR>
" tc 新しいタブを一番右に作る
noremap <silent> [Tag]x :tabclose<CR>
" tx タブを閉じる
noremap <silent> [Tag]n :tabnext<CR>
" tn 次のタブ
noremap <silent> [Tag]p :tabprevious<CR>
" tp 前のタブ
noremap <silent> [Tag]l :Unite tab<CR>
" タブで開いているファイル一覧

