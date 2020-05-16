if !has('nvim') || get(g:, 'neoterm_utils_loaded', 0)
  finish
endif

let g:neoterm_utils_loaded = 1

let g:neoterm_last_toggled_num = -1
let g:neoterm_last_focused_buf = {}                                      " tab-to-buf map

" Customizeable
let g:neoterm_batch_size = get(g:, 'neoterm_batch_size', 4)        		 " default terms batch len
let g:neoterm_predefined_coms = get(g:, 'neoterm_predefined_coms', {})   " predefined commands for neoterm startups
let g:neoterm_batch_at_startup = get(g:, 'neoterm_batch_at_startup', 1)  " creates terms batch at vim startup


function! s:memCurrentBufferHandle()
    " check if it isn't neoterm buffer
    let l:buf = nvim_get_current_buf()
    if bufname(l:buf) =~ '^term://'
        return
    endif

    let l:tab = tabpagenr()
    let l:win = nvim_get_current_win()
    let g:neoterm_last_focused_buf[l:tab] = l:win
endfunction


function! s:jumpToMemBuffer()
    let l:tab = tabpagenr()
    let l:win = get(g:neoterm_last_focused_buf, l:tab)
    call win_gotoid(l:win)
endfunction


function! s:tfocus(instance)
    let l:win = bufwinnr(a:instance.buffer_id)
    if l:win > 0
        let l:winid = win_getid(l:win)
        if win_gotoid(l:winid)
            startinsert
        endif
    endif
endfunction

function! s:closeall_terminals()
    for t in items(g:neoterm.instances)
        let l:num = t[0]
        let l:ins = t[1]
        if bufwinnr(l:ins.buffer_id) > 0
            call <SID>jumpToMemBuffer()
            let g:neoterm_last_toggled_num = l:num
            call g:neoterm#close({ 'target': l:ins.id })
        endif
    endfor
endfunction


function! TUtoggleLast()
    if g:neoterm_last_toggled_num != -1
        let l:instance = g:neoterm.instances[g:neoterm_last_toggled_num]
        if bufwinnr(l:instance.buffer_id) > 0
            call <SID>jumpToMemBuffer()
            call g:neoterm#close({ 'target': l:instance.id })
        else
            call <SID>memCurrentBufferHandle()
            call g:neoterm#open({ 'target': l:instance.id })
            call <SID>tfocus(l:instance)
        endif
    else
        echo "There is no last toggled terminal"
    endif
endfunction


function! TUopenNum(num)
    if !has_key(g:neoterm.instances, a:num)
        echo "There is no terminal".a:num
        return -1
    endif

    call <SID>memCurrentBufferHandle()

    let l:instance = g:neoterm.instances[a:num]
    if bufwinnr(l:instance.buffer_id) == -1
        " closee all other buffers
        call <SID>closeall_terminals()
        " and open selected one
        call g:neoterm#open({ 'target': l:instance.id })
    endif

    let g:neoterm_last_toggled_num = a:num
    call <SID>tfocus(l:instance)

    return 0
endfunction


function! TUtoggleNum(num)
    if !has_key(g:neoterm.instances, a:num)
        echo "There is no terminal".a:num
        return -1
    endif

    let l:instance = g:neoterm.instances[a:num]
    if bufwinnr(l:instance.buffer_id) > 0
        call <SID>jumpToMemBuffer()
        call g:neoterm#close({ 'target': l:instance.id })
    else

        call <SID>memCurrentBufferHandle()
        " closee all other buffers
        call <SID>closeall_terminals()
        " and open selected one
        call g:neoterm#open({ 'target': l:instance.id })
        call <SID>tfocus(l:instance)
    endif

    let g:neoterm_last_toggled_num = a:num

    return 0
endfunction


function! s:tpyactivate(instance)
    let l:env = $VIRTUAL_ENV
    if len(l:env)
        echom 'ENV:' l:env 
        let l:com = 'source ' . l:env . '/bin/activate'
        call g:neoterm#do({ 'target': instance.id, 'cmd': l:com })
        call g:neoterm#clear({ 'target': instance.id })
    elseif !len(l:env)
        let l:env = $CONDA_DEFAULT_ENV
        if len(l:env)
            echom 'ENV:' l:env 
            let l:com = 'source activate ' . l:env 
            call g:neoterm#do({ 'target': instance.id, 'cmd': l:com })
            call g:neoterm#clear({ 'target': instance.id })
        endif
    endif
endfunction


function! s:tnew(full)
    if a:full
        call <SID>memCurrentBufferHandle()
        call <SID>closeall_terminals()
    endif

    let l:instance = g:neoterm#new()
    call l:instance.vim_exec("tnoremap \<buffer\> \<esc\> \<C-\\>\<C-n\>")

    if get(g:, 'neoterm_default_mod', '') == 'botright'
        call l:instance.vim_exec("nmap \<up\> \<C-W\>\<C-P\>") |  " In case buffer at bottiom
    endif

    let l:i = l:instance.id
    execute "nmap <silent> <M-" . l:i . "> :call TUtoggleNum(" . l:i . ")<cr>"
    execute "imap <silent> <M-" . l:i . "> <esc>:call TUtoggleNum(" . l:i . ")<cr>"
    execute "tmap <silent> <M-" . l:i . "> <esc>:call TUtoggleNum(" . l:i . ")<cr>"
    execute "vmap <silent> <M-" . l:i . "> <esc>:call TUtoggleNum(" . l:i . ")<cr>"

    " Type-in predefined command
    if has_key(g:neoterm_predefined_coms, l:i)
        let l:predefined_com = g:neoterm_predefined_coms[l:i]
        call g:neoterm#clear({ 'target': l:instance.id })
        call g:neoterm#exec({ 'target': l:instance.id, 'cmd': [l:predefined_com] })
    endif

    if a:full
        let g:neoterm_last_toggled_num = l:instance.id
        call <SID>tpyactivate(l:instance)
        call <SID>tfocus(l:instance)
    else
        call g:neoterm#close({'target': l:i})
    endif
endfunction


function! s:tnewcmd(...)
    let l:cmd = join(a:000)
    let l:mem_win = winnr()
    call <SID>closeall_terminals()

    let l:instance = {}

    if has_key(g:neoterm_utils_cmds, l:cmd) 
        let l:i = g:neoterm_utils_cmds[l:cmd]
        if has_key(g:neoterm.instances, l:i)
            let l:instance = g:neoterm.instances[l:i]
            call g:neoterm#open({ 'target': l:instance.id })
        endif
    endif

    if empty(l:instance)
        " Init instance
        let l:instance = g:neoterm#new()
        call l:instance.vim_exec("tnoremap \<buffer\> \<esc\> \<C-\\>\<C-n\>")
        let l:i = l:instance.id
        call g:neoterm#clear({ 'target': l:i })
        call g:neoterm#do({ 'target': l:i, 'cmd': l:cmd })

        " Register
        let g:neoterm_utils_cmds[l:cmd] = l:instance.id
    endif

    let g:neoterm_last_toggled_num = l:instance.id
    "call <SID>tpyactivate(l:instance)   " TODO: or remove?
    "switch to and back other buffers
    
    " NOTE: coping with https://github.com/junegunn/fzf.vim/issues/21
    
    call <SID>tfocus(l:instance)
    "call win_gotoid(win_getid(l:mem_win))
    "startinsert
    "call <SID>tfocus(l:instance)
    "echom "final:"
    "echom winnr()
endfunction


function! s:tnewbatch(...)
    let l:count = a:0 ? a:1 : g:neoterm_batch_size
    while l:count > 0
        let l:count -= 1
        call <SID>tnew(0)
    endwhile
endfunction


command! TtoggleLast :call TUtoggleLast()
command! -nargs=? TnewBatch :call <SID>tnewbatch(<args>)
command! -bar -complete=shellcmd TnewImproved silent call <SID>tnew(1)
command! -nargs=+ TRun :call <SID>tnewcmd(<f-args>)
cabbrev Tnew TnewImproved

let g:neoterm_utils_loaded = 0
let g:neoterm_utils_cmds = {}

function! s:initNeotermUtils()
    if g:neoterm_utils_loaded == 1
        return
    endif

    if get(g:, 'neoterm_loaded', 0) == 0
        return
    endif

    let g:neoterm_utils_loaded = 1
    if g:neoterm_batch_at_startup
        call <SID>tnewbatch(g:neoterm_batch_size)
    endif
endfunction

aug neoterm_utils
    au!
    au VimEnter * call <SID>initNeotermUtils()
aug END
