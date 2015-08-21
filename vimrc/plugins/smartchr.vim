" smartchr
inoremap <buffer> <expr> - smartchr#loop('-', ' - ', '->', '--', '----------')
inoremap <buffer> <expr> , smartchr#loop(',', ', ')
inoremap <buffer> <expr> = smartchr#loop('=', ' == ', '=>')
inoremap <buffer> <expr> ` smartchr#loop('`', '```' )


