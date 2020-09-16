let s:modes = {
  \  'n':      ['%1*', ' normal '],
  \  'i':      ['%2*', ' insert '],
  \  'R':      ['%4*', ' r-mode '],
  \  'v':      ['%3*', ' visual '],
  \  'V':      ['%3*', ' v-line '],
  \  "\<C-v>": ['%3*', ' v-rect '],
  \  'c':      ['%1*', ' c-mode '],
  \  's':      ['%3*', ' select '],
  \  'S':      ['%3*', ' s-line '],
  \  "\<C-s>": ['%3*', ' s-rect '],
  \  't':      ['%2*', ' term '],
  \}

function! moonfly_statusline#ModeColor(mode) abort
    return get(s:modes, a:mode, '%*1')[0]
endfunction

function! moonfly_statusline#ModeText(mode) abort
    return get(s:modes, a:mode, ' normal ')[1]
endfunction

function! moonfly_statusline#ShortFilePath() abort
    if &buftype ==# 'terminal'
        return expand('%:t')
    else
        let l:path = expand('%:f')
        if len(l:path) == 0
            return ''
        else
            return pathshorten(fnamemodify(expand('%:f'), ':~:.'))
        endif
    endif
endfunction

function! moonfly_statusline#ShortCurrentPath() abort
    return pathshorten(fnamemodify(getcwd(), ':~:.'))
endfunction

function! moonfly_statusline#GitBranch() abort
    if !g:moonflyWithGitBranch || bufname('%') == ''
        return ''
    endif

    let l:gitBranchName = s:GitBranchName()
    if len(l:gitBranchName) == 0
        return ''
    endif

    if g:moonflyWithGitBranchCharacter
        return ' [ ' . l:gitBranchName . '] '
    else
        return ' [' . l:gitBranchName . '] '
    endif
endfunction

function! moonfly_statusline#PluginsStatus() abort
    let l:status = ''

    " Obsession plugin status.
    if exists('g:loaded_obsession')
        if g:moonflyWithObessionGeometricCharacters
            let l:status .= ObsessionStatus('● ', '■ ')
        else
            let l:status .= ObsessionStatus('$ ', 'S ')
        endif
    endif

    " ALE plugin indicator.
    if g:moonflyWithALEIndicator && exists('g:loaded_ale')
        if ale#statusline#Count(bufnr('')).total > 0
            let l:status .= g:moonflyDiagnosticsIndicator . ' '
        endif
    endif

    " Coc plugin indicator.
    if g:moonflyWithCocIndicator && exists('g:did_coc_loaded')
        if len(coc#status()) > 0
            let l:status .= g:moonflyDiagnosticsIndicator . ' '
        endif
    endif

    " Neovin LSP diagnostics indicator.
    if g:moonflyWithNvimLspIndicator && has('nvim-0.5')
        let l:count = luaeval('vim.lsp.util.buf_diagnostics_count([[Error]])') 
                  \ + luaeval('vim.lsp.util.buf_diagnostics_count([[Warning]])')
        if l:count > 0
            let l:status .= g:moonflyDiagnosticsIndicator . ' '
        endif
    endif

    return l:status
endfunction

" The following Git branch functionality derives from:
"   https://github.com/itchyny/vim-gitbranch
"
" MIT Licensed Copyright (c) 2014-2017 itchyny
"
function! s:GitBranchName() abort
    if get(b:, 'gitbranch_pwd', '') !=# expand('%:p:h') || !has_key(b:, 'gitbranch_path')
        call s:GitDetect()
    endif

    if has_key(b:, 'gitbranch_path') && filereadable(b:gitbranch_path)
        let l:branchDetails = get(readfile(b:gitbranch_path), 0, '')
        if l:branchDetails =~# '^ref: '
            return substitute(l:branchDetails, '^ref: \%(refs/\%(heads/\|remotes/\|tags/\)\=\)\=', '', '')
        elseif l:branchDetails =~# '^\x\{20\}'
            return l:branchDetails[:6]
        endif
    endif

    return ''
endfunction

function! s:GitDetect() abort
    unlet! b:gitbranch_path
    let b:gitbranch_pwd = expand('%:p:h')
    let l:dir = s:GitDir(b:gitbranch_pwd)

    if l:dir !=# ''
        let l:path = l:dir . '/HEAD'
        if filereadable(l:path)
            let b:gitbranch_path = l:path
        endif
    endif
endfunction

function! s:GitDir(path) abort
    let l:path = a:path
    let l:prev = ''

    while l:path !=# prev
        let l:dir = path . '/.git'
        let l:type = getftype(l:dir)
        if l:type ==# 'dir' && isdirectory(l:dir . '/objects')
                    \ && isdirectory(l:dir . '/refs')
                    \ && getfsize(l:dir . '/HEAD') > 10
            " Looks like we found a '.git' directory.
            return l:dir
        elseif l:type ==# 'file'
            let l:reldir = get(readfile(l:dir), 0, '')
            if l:reldir =~# '^gitdir: '
                return simplify(l:path . '/' . l:reldir[8:])
            endif
        endif
        let l:prev = l:path
        " Go up a directory searching for a '.git' directory.
        let path = fnamemodify(l:path, ':h')
    endwhile

    return ''
endfunction
