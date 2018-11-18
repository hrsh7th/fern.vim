let s:Action = vital#fila#import('App.Action')
let s:Lambda = vital#fila#import('Lambda')
let s:Revelator = vital#fila#import('App.Revelator')

function! fila#action#get() abort
  return s:Action.get()
endfunction

function! fila#action#call(...) abort
  let action = s:Action.get()
  call call(action.call, a:000, action)
endfunction

function! fila#action#_init(...) abort
  let action = s:Action.new({
        \ 'args': { -> [fila#helper#new()] },
        \})
  call action.init()
endfunction

function! fila#action#_define() abort
  let action = fila#action#get()
  call action.define('echo', funcref('s:echo'), {
        \ 'hidden': 1,
        \ 'mapping_mode': 'nv',
        \})
  call action.define('yank', funcref('s:yank'), {
        \ 'mapping_mode': 'nv',
        \})
  call action.define('open', funcref('s:open'))
  call action.define('open:side', funcref('s:open_side'))
  call action.define('enter', funcref('s:enter'), {
        \ 'hidden': 1,
        \})
  call action.define('leave', funcref('s:leave'), {
        \ 'hidden': 1,
        \})
  call action.define('reload', funcref('s:reload'), {
        \ 'hidden': 1,
        \})
  call action.define('expand', funcref('s:expand'), {
        \ 'hidden': 1,
        \})
  call action.define('collapse', funcref('s:collapse'), {
        \ 'hidden': 1,
        \})
  call action.define('enter-or-open', funcref('s:enter_or_open'), {
        \ 'hidden': 2,
        \})
  call action.define('expand-or-open', funcref('s:expand_or_open'), {
        \ 'hidden': 2,
        \})
  call action.define('mark:set', funcref('s:mark_set'), {
        \ 'hidden': 1,
        \ 'mapping_mode': 'nv',
        \})
  call action.define('mark:unset', funcref('s:mark_unset'), {
        \ 'hidden': 1,
        \ 'mapping_mode': 'nv',
        \})
  call action.define('mark:toggle', funcref('s:mark_toggle'), {
        \ 'hidden': 1,
        \ 'mapping_mode': 'nv',
        \})
  call action.define('mark:clear', funcref('s:mark_clear'))
  call action.define('hidden:set', funcref('s:hidden_set'), {
        \ 'hidden': 1,
        \})
  call action.define('hidden:unset', funcref('s:hidden_unset'), {
        \ 'hidden': 1,
        \})
  call action.define('hidden:toggle', funcref('s:hidden_toggle'), {
        \ 'hidden': 1,
        \})
  call action.define('open:select', 'open select')
  call action.define('open:split', 'open split')
  call action.define('open:vsplit', 'open vsplit')
  call action.define('open:tabedit', 'open tabedit')
  call action.define('open:pedit', 'open pedit')
  call action.define('open:above', 'open leftabove split')
  call action.define('open:left', 'open leftabove vsplit')
  call action.define('open:below', 'open rightbelow split')
  call action.define('open:right', 'open rightbelow vsplit')
  call action.define('open:top', 'open topleft split')
  call action.define('open:leftest', 'open topleft vsplit')
  call action.define('open:bottom', 'open botright split')
  call action.define('open:rightest', 'open botright vsplit')
  call action.define('mark', 'mark:toggle', {
        \ 'mapping_mode': 'nv',
        \})
  call action.define('hidden', 'hidden:toggle')
  " Mapping
  nmap <buffer> <Backspace> <Plug>(fila-action-leave)
  nmap <buffer> <C-h>       <Plug>(fila-action-leave)
  nmap <buffer> <Return>    <Plug>(fila-action-enter-or-open)
  nmap <buffer> <C-m>       <Plug>(fila-action-enter-or-open)
  nmap <buffer> <F5>        <Plug>(fila-action-reload)
  nmap <buffer> l           <Plug>(fila-action-expand-or-open)
  nmap <buffer> h           <Plug>(fila-action-collapse)
  nmap <buffer> -           <Plug>(fila-action-mark-toggle)
  vmap <buffer> -           <Plug>(fila-action-mark-toggle)
  nmap <buffer> !           <Plug>(fila-action-hidden-toggle)
  nmap <buffer> e           <Plug>(fila-action-open)
  nmap <buffer> E           <Plug>(fila-action-open-side)
  nmap <buffer> s           <Plug>(fila-action-open-select)
  nmap <buffer> t           <Plug>(fila-action-open-tabedit)
  nmap <buffer> p           <Plug>(fila-action-open-pedit)
  " Allow users to define extra actions
  doautocmd <nomodeline> User FilaActionDefine
endfunction

function! s:echo(range, params, helper) abort
  let nodes = a:helper.get_marked_nodes()
  if empty(nodes)
    let nodes = a:helper.get_selection_nodes(a:range)
  endif
  for node in nodes
    echo printf("key     : %s", node.key)
    echo printf("text    : %s", node.text)
    echo printf("hidden  : %s", node.hidden)
    echo printf("status  : %s", node.status)
    echo printf("parent  : %s", has_key(node, 'parent'))
    echo printf("children: %s", has_key(node, 'children'))
    echo printf("bufname : %s", get(node, 'bufname', ''))
  endfor
endfunction

function! s:yank(range, params, helper) abort
  let nodes = a:helper.get_marked_nodes()
  if empty(nodes)
    let nodes = a:helper.get_selection_nodes(a:range)
  endif
  let buffer = map(copy(nodes), { -> get(v:val, 'bufname', '') })
  call setreg(v:register, join(buffer, "\n"))
endfunction

function! s:open(range, params, helper) abort
  let node = a:helper.get_cursor_node(a:range)
  if !has_key(node, 'bufname')
    throw s:Revelator.info('the node does not have bufname')
  endif
  call fila#buffer#open(node.bufname, {
        \ 'opener': empty(a:params) ? 'edit' : a:params,
        \ 'locator': fila#drawer#is_drawer(win_getid()),
        \})
        \.catch({ e -> fila#helper#handle_error(e) })
endfunction

function! s:open_side(range, params, helper) abort
  if fila#drawer#is_drawer(win_getid())
    call fila#action#call('open:left')
  else
    call fila#action#call('open:right')
  endif
endfunction

function! s:enter(range, params, helper) abort
  let node = a:helper.get_cursor_node(a:range)
  if !has_key(node, 'bufname')
    throw s:Revelator.info('the node does not have bufname')
  endif
  let winid = win_getid()
  call a:helper.enter_node(node)
        \.then({ h -> h.cursor_node(winid, node, 1) })
        \.catch({ e -> fila#helper#handle_error(e) })
endfunction

function! s:leave(range, params, helper) abort
  let root = a:helper.get_root_node()
  if !has_key(root, 'parent') || !has_key(root.parent, 'bufname')
    throw s:Revelator.info('the node does not have bufname')
  endif
  let node = root.parent
  let winid = win_getid()
  call a:helper.enter_node(node)
        \.then({ h -> h.cursor_node(winid, root) })
        \.catch({ e -> fila#helper#handle_error(e) })
endfunction

function! s:reload(range, params, helper) abort
  let node = a:helper.get_cursor_node(a:range)
  if !fila#node#is_expanded(node)
    return
  endif
  let winid = win_getid()
  call a:helper.reload_node(node)
        \.then({ h -> h.redraw() })
        \.catch({ e -> fila#helper#handle_error(e) })
endfunction

function! s:expand(range, params, helper) abort
  let node = a:helper.get_cursor_node(a:range)
  if !fila#node#is_branch(node) || fila#node#is_expanded(node)
    call fila#action#call('reload')
    return
  endif
  let winid = win_getid()
  call a:helper.expand_node(node)
        \.then({ h -> h.redraw() })
        \.then({ h -> h.cursor_node(winid, node, 1) })
        \.catch({ e -> fila#helper#handle_error(e) })
endfunction

function! s:collapse(range, params, helper) abort
  let node = a:helper.get_cursor_node(a:range)
  if !fila#node#is_branch(node) || !fila#node#is_expanded(node)
    if !has_key(node, 'parent') || !fila#node#is_branch(node.parent) || !fila#node#is_expanded(node.parent)
      return
    endif
    let node = node.parent
  endif
  let winid = win_getid()
  call a:helper.collapse_node(node)
        \.then({ h -> h.redraw() })
        \.then({ h -> h.cursor_node(winid, node) })
        \.catch({ e -> fila#helper#handle_error(e) })
endfunction

function! s:enter_or_open(range, params, helper) abort
  let node = a:helper.get_cursor_node(a:range)
  if fila#node#is_branch(node)
    call fila#action#call('enter')
  else
    call fila#action#call('open')
  endif
endfunction

function! s:expand_or_open(range, params, helper) abort
  let node = a:helper.get_cursor_node(a:range)
  if fila#node#is_branch(node)
    call fila#action#call('expand')
  else
    call fila#action#call('open')
  endif
endfunction

function! s:mark_set(range, params, helper) abort
  let nodes = a:helper.get_selection_nodes(a:range)
  let marks = a:helper.get_marks()
  for node in nodes
    call add(marks, node.key)
  endfor
  call a:helper.set_marks(uniq(marks))
  call a:helper.redraw()
endfunction

function! s:mark_unset(range, params, helper) abort
  let nodes = a:helper.get_selection_nodes(a:range)
  let marks = a:helper.get_marks()
  for node in nodes
    let index = index(marks, node.key)
    if index isnot# -1
      call remove(marks, index)
    endif
  endfor
  call a:helper.set_marks(uniq(marks))
  call a:helper.redraw()
endfunction

function! s:mark_toggle(range, params, helper) abort
  let nodes = a:helper.get_selection_nodes(a:range)
  let marks = a:helper.get_marks()
  for node in nodes
    let index = index(marks, node.key)
    if index isnot# -1
      call remove(marks, index)
    else
      call add(marks, node.key)
    endif
  endfor
  call a:helper.set_marks(uniq(marks))
  call a:helper.redraw()
endfunction

function! s:mark_clear(range, params, helper) abort
  call a:helper.set_marks([])
  call a:helper.redraw()
endfunction

function! s:hidden_set(range, params, helper) abort
  let node = a:helper.get_cursor_node(a:range)
  let winid = win_getid()
  call a:helper.set_hidden(1)
  call a:helper.redraw()
        \.then({ h -> h.cursor_node(winid, node) })
endfunction

function! s:hidden_unset(range, params, helper) abort
  let node = a:helper.get_cursor_node(a:range)
  let winid = win_getid()
  call a:helper.set_hidden(0)
  call a:helper.redraw()
        \.then({ h -> h.cursor_node(winid, node) })
endfunction

function! s:hidden_toggle(range, params, helper) abort
  let node = a:helper.get_cursor_node(a:range)
  let winid = win_getid()
  call a:helper.set_hidden(!a:helper.get_hidden())
  call a:helper.redraw()
        \.then({ h -> h.cursor_node(winid, node) })
endfunction