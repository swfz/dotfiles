nnoremap <silent> <Leader>mru :<C-u>Unite file_mru<CR>
nnoremap <silent> <Leader>vf :<C-u>VimFilerBufferDir -split -simple -winwidth=35 -no-quit<CR>
nnoremap <silent> <Leader>ucs :<C-u>Unite colorscheme -auto-preview<CR>
nnoremap <silent> <Leader>uc :<C-u>Unite codic<CR>
nnoremap <silent> <Leader>nt :<C-u>NERDTree<CR>
nnoremap <silent> <Leader>vs :<C-u>VimShell<CR>
nnoremap <silent> <Leader>md :<C-u>PrevimOpen<CR>
nmap <Leader>w  <Plug>(openbrowser-smart-search)
noremap <buffer> ,ptv <Esc>:'<,'>! perltidy -pbp<CR>
map <silent> <Leader>pt :%! perltidy

" vimux line open
noremap <silent> <Leader>vlo :call VimuxOpenRunner()<CR>
" vimux register run
noremap <silent> <Leader>vrr :call VimuxRunCommand('<C-r>"')<CR>
" vimux register paste
noremap <silent> <Leader>vrp :call VimuxSendText('<C-r>"')<CR>

function VimuxRunFromYank()
  call setreg('z',getline('.'))
  VimuxRunCommand(@z)
endfunction

function VimuxSendTextFromYank()
  call setreg('z',getline('.'))
  call VimuxSendText(@z)
endfunction

" vimux line run
noremap <silent> <Leader>vlr :call VimuxRunFromYank()<CR>
" vimux line paste
noremap <silent> <Leader>vlp :call VimuxSendTextFromYank()<CR>
