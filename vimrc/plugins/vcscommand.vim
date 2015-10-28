augroup VCSCommand
  autocmd!
  autocmd User VCSBufferCreated call s:vcscommand_buffer_settings()
augroup END

function! s:vcscommand_buffer_settings() "{{{3
  if !exists('b:VCSCommandCommand') | return | endif
  if b:VCSCommandCommand !=# 'commitlog' | setlocal readonly     | endif
  if b:VCSCommandCommand !=# 'vimdiff'   | setlocal nofoldenable | endif
  if &filetype ==# 'gitlog'              | setlocal syntax=git   | endif
  nmap <unique> <buffer> <silent> q :bwipeout<CR>
  if &filetype =~# '^\(svnlog\|gitlog\|hglog\)$'
    nnoremap <silent> <buffer> <CR> :<C-u>call <SID>vcscommand_filetype('log', 'VCSDiff')<CR>gg
    nnoremap <silent> <buffer> v    :<C-u>call <SID>vcscommand_filetype('log', 'VCSVimDiff')<CR>gg
    nnoremap <silent> <buffer> r    :<C-u>call <SID>vcscommand_filetype('log', 'VCSReview')<CR>gg
    nnoremap <silent> <buffer> i    :<C-u>call <SID>vcscommand_filetype('log', 'VCSInfo')<CR>gg
  elseif b:VCSCommandCommand =~# '.*annotate'
    nnoremap <silent> <buffer> <CR> :<C-u>call <SID>vcscommand_filetype('annotate', 'VCSDiff')<CR>gg
    nnoremap <silent> <buffer> v    :<C-u>call <SID>vcscommand_filetype('annotate', 'VCSVimDiff')<CR>gg
    nnoremap <silent> <buffer> r    :<C-u>call <SID>vcscommand_filetype('annotate', 'VCSReview')<CR>gg
    nnoremap <silent> <buffer> l    :<C-u>call <SID>vcscommand_filetype('annotate', 'VCSLog')<CR>gg
    nnoremap <silent> <buffer> i    :<C-u>call <SID>vcscommand_filetype('annotate', 'VCSInfo')<CR>gg
  endif
endfunction "}}}

function! s:vcscommand_exec(command, option) "{{{3
  if a:command =~# '^\(VCSDiff\|VCSLog\)$'
    let g:VCSCommandSplit = winnr('$') == 1 ? 'vertical' : 'horizontal'
  endif
  execute a:command a:option
  unlet! g:VCSCommandSplit
endfunction "}}}

function! s:vcscommand_log(...) "{{{3
  let option = join(a:000)
  if exists('b:VCSCommandVCSType')
    if exists('b:VCSCommandCommand')
      if b:VCSCommandCommand ==# 'log'
        echo "Sorry, you cannot open vcslog on vcslog buffer"
        unlet option
      elseif b:VCSCommandCommand =~# 'diff\|review'
        if !exists('b:VCSCommandStatusText')
          echo "Sorry, you are on a working buffer"
          unlet option
        else
          " Shows only the target revision/commit
          if b:VCSCommandVCSType ==# 'SVN'
            let matched = matchlist(b:VCSCommandStatusText, '(\d\+ : \(\d\+\))')
            if len(matched) | let option = matched[1] | endif
          elseif b:VCSCommandVCSType ==# 'git'
            let matched = matchlist(b:VCSCommandStatusText, '\S\+ \(\w\+\)')
            if len(matched) | let option = '-n 1 ' . matched[1] | endif
          elseif b:VCSCommandVCSType ==# 'HG'
            let matched = matchlist(b:VCSCommandStatusText, '(\(\d\+\) : \w\+)')
            if len(matched) | let option = matched[1] | endif
          endif
        endif
      endif
    elseif v:count
      if b:VCSCommandVCSType ==# 'SVN'
        let limit_option = '-l'
      elseif b:VCSCommandVCSType ==# 'git'
        let limit_option = '-n'
      elseif b:VCSCommandVCSType ==# 'HG'
        let limit_option = '-l'
      endif
      let option = limit_option . ' ' . v:count
    endif
  endif
  if exists('option')
    call s:vcscommand_exec('VCSLog', option)
  endif
endfunction "}}}

function! s:vcscommand_filetype(filetype, command) " {{{3
  let given_count1 = v:count1
  let revision = s:vcscommand_get_revision_on_cursor_line(a:filetype)
  if strlen(revision)
    let option = s:vcscommand_make_vcs_option(a:command, revision, given_count1)
    call s:vcscommand_exec(a:command, option)
  endif
endfunction "}}}

function! s:vcscommand_get_revision_on_cursor_line(filetype) " {{{3
  let save_cursor = getpos('.')
  let save_yank_register = getreg('"')
  if a:filetype ==# 'log'
    if &filetype ==# 'svnlog'
      normal! j
      ?^r\d\+\ |
      normal! 0lye
    elseif &filetype ==# 'gitlog'
      normal! j
      ?^commit\ \w\+$
      normal! 0wy7l
    elseif b:VCSCommandVCSType ==# 'HG'
      normal! j
      ?^changeset:\ \+\d\+:\w\+$
      normal! Wyw
    endif
  elseif a:filetype ==# 'annotate'
    if b:VCSCommandVCSType ==# 'SVN'
      normal! 0wye
    elseif b:VCSCommandVCSType ==# 'git'
      normal! 0t yb
    elseif b:VCSCommandVCSType ==# 'HG'
      normal! 0f:yb
    endif
  endif
  let revision = @"
  call setpos('.', save_cursor)
  call setreg('"', save_yank_register)
  return revision
endfunction "}}}

function! s:vcscommand_make_vcs_option(command, revision, given_count1) " {{{3
  let option = a:revision
  if b:VCSCommandVCSType ==# 'SVN'
    if a:command ==# 'VCSLog'
      let older = a:given_count1 == 1 ? '' : a:given_count1 . ':'
      let option = '-r ' . older . a:revision
    elseif a:command ==# 'VCSInfo'
      let option = '-r ' . a:revision
    elseif a:command =~# 'VCSDiff\|VCSVimDiff'
      let older = a:given_count1 == 1 ? str2nr(a:revision) - 1 : a:given_count1
      let option = older . ' ' . a:revision
    endif
  elseif b:VCSCommandVCSType ==# 'git'
    if a:command ==# 'VCSLog'
      let option = '-n ' . a:given_count1 . ' ' . a:revision
    elseif a:command =~# 'VCSDiff\|VCSVimDiff'
      let older = a:revision . '~' . a:given_count1
      let option = older . ' ' . a:revision
    endif
  elseif b:VCSCommandVCSType ==# 'HG'
    if a:command ==# 'VCSLog'
      let option = '-l ' . a:given_count1 . ' -r ' . a:revision
    elseif a:command =~# 'VCSDiff\|VCSVimDiff'
      let older = a:given_count1 == 1 ? str2nr(a:revision) - 1 : a:given_count1
      "let option = '-r ' . older . ' -r ' . a:revision
      let option = a:revision
    endif
  endif
  return option
endfunction "}}}
