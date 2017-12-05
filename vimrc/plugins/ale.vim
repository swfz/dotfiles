highlight ALEWarning ctermbg=DarkGray
" ファイルオープン時は未チェック
let g:ale_lint_on_enter = 0
" シンボルのハイライトをクリア
highlight clear ALEErrorSign
highlight clear ALEWarningSign
" ステータスライン表示フォーマット
let g:ale_statusline_format = ['e %d', 'w %d', '⬥ ok']
" airline用設定
let g:airline#extensions#ale#enabled = 1
" error, warningの表示
let g:ale_echo_msg_error_str = 'E'
let g:ale_echo_msg_warning_str = 'W'
" エラーフォーマット
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'
" 保存時のみチェック
let g:ale_lint_on_save = 1
let g:ale_lint_on_text_changed = 0
