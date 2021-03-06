" File:        ftplugin/ruby/rubytextobjects.vim
" Version:     0.1a
" Modified:    2011-00-00
" Description: This ftplugin provides new text objects for Ruby files.
" Maintainer:  Israel Chauca F. <israelchauca@gmail.com>
" Manual:      The new text objects are 'ir' and 'ar'. Place this file in
"              'ftplugin/ruby/' inside $HOME/.vim or somewhere else in your
"              runtimepath.
"              :let testing_RubyTextObjects = 1 to allow reloading of the
"              plugin without closing Vim.
" Pending:     - Use Visual mode instead of Line Visual mode.
"              - Optionally, first ar goes to do..end, second gets the rest of
"                the line.
"              - Ignore multiple statements per line.
" ============================================================================

" Mappings {{{1
if exists('no_plugin_maps') || exists('no_ruby_maps')
  " User doesn't want this functionality.
  finish
endif

if !exists('testing_RubyTextObjects')
  " Be nice with existing mappings

  onoremap <silent> <buffer> <expr> <Plug>RubyTextObjectsAll <SID>RubyTextObjectsAll(0)
  if !hasmapto('<Plug>RubyTextObjectsAll', 'o')
    omap <unique> <buffer> ar <Plug>RubyTextObjectsAll
  endif

  onoremap <silent> <buffer> <expr> <Plug>RubyTextObjectsInner <SID>RubyTextObjectsInner(0)
  if !hasmapto('<Plug>RubyTextObjectsInner', 'o')
    omap <unique> <buffer> ir <Plug>RubyTextObjectsInner
  endif

  vnoremap <silent> <buffer> <Plug>RubyTextObjectsAll :call <SID>RubyTextObjectsAll(1)<CR><Esc>gv
  if !hasmapto('<Plug>RubyTextObjectsAll', 'v')
    vmap <unique> <buffer> ar <Plug>RubyTextObjectsAll
  endif

  vnoremap <silent> <buffer> <Plug>RubyTextObjectsInner :call <SID>RubyTextObjectsInner(1)<CR><Esc>gv
  if !hasmapto('<Plug>RubyTextObjectsInner', 'v')
    vmap <unique> <buffer> ir <Plug>RubyTextObjectsInner
  endif
else
  " Unless we are testing, be merciless in this case
  silent! ounmap <buffer> ar
  silent! ounmap <buffer> ir
  silent! vunmap <buffer> ar
  silent! vunmap <buffer> ir
  onoremap <silent> <buffer> <expr> ar <SID>RubyTextObjectsAll(0)
  onoremap <silent> <buffer> <expr> ir <SID>RubyTextObjectsInner(0)
  vnoremap <silent> <buffer> ar :call <SID>RubyTextObjectsAll(1)<CR><Esc>gv
  vnoremap <silent> <buffer> ir :call <SID>RubyTextObjectsInner(1)<CR><Esc>gv
endif

" }}}1

" Variables {{{1
" Lines where this expression returns 1 will be skipped
let s:skip_e  = 'getline(''.'') =~ ''^\s*#'' || synIDattr(synID(line("."), col("."), 0), "name") =~? ''\%(string\)\|\%(comment\)'''

" List of words that start a block at the beginning of the line
let s:beg_words = '<def>|<module>|<class>|<case>|<if>|<unless>|<begin>|<for>|<until>|<while>|<catch>'

" Start of the block matches this
let s:start_p = '\C\v^\s*\zs%('.s:beg_words.')|%(%('.s:beg_words.').*)@<!<do>'

" Middle of the block matches this
let s:middle_p= '\C\v^\s*\zs%(<els%(e|if)>|<rescue>|<ensure>|<when>)'

" End of the block matches this
let s:end_p   = '\C\v^\s*\zs<end>'

" Don't wrap or move the cursor
let s:flags = 'Wn'

" }}}1

" Functions {{{1
" Load guard {{{2
if exists('loaded_RubyTextObjects') && !exists('testing_RubyTextObjects')
  " No need to beyond this twice, unless testing.
  finish
elseif exists('testing_RubyTextObjects')
  echom '----Loaded on: '.strftime("%Y %b %d %X")

  function! Test(test,...) range
    if a:test == 1
      return s:Match(a:firstline, 'start').', '.s:Match(a:firstline, 'middle').', '.s:Match(a:firstline, 'end')
    elseif a:test == 2
      return s:FindTextObject([a:firstline,0], [a:lastline,0], s:start_p, s:middle_p,
            \s:end_p, s:flags, s:skip_e)
    elseif a:test == 3
      return searchpairpos(s:start_p, s:middle_p, s:end_p, a:1, s:skip_e)
    elseif a:test == 4
      return match(getline('.'), 'bWn')
    elseif a:test == 5
      return searchpos(s:start_p,'bn')
    else
      throw 'Ooops!'
    endif
  endfunction

endif
let loaded_RubyTextObjects = '0.1a'
 "}}}2

function! s:RubyTextObjectsAll(visual) range "{{{2
  let lastline      = line('$')
  let start         = [0,0]
  let middle_p      = ''
  let end           = [-1,0]
  let count1        = v:count1

  let t_start = [a:firstline + 1, 0]
  let t_end   = [a:lastline  - 1, 0]
  let passes  = 0

  let match_both_outer = (
        \ s:Match(t_start[0] - 1, 'start') &&
        \ s:Match(t_end[0] + 1, 'end'))
  while  count1 > 0 &&
        \ (!(count1 > 1) || (t_start[0] - 1 > 1 && t_end[0] + 1 < lastline))
    let passes  += 1
    "let t_start[0] -= 1
    "let t_end[0]   += 1

    let [t_start, t_end] = s:FindTextObject([t_start[0] - 1, 0], [t_end[0] + 1, 0], s:start_p, middle_p,
          \ s:end_p, s:flags, s:skip_e)

    "echom string(t_start).';'.string(t_end).':'.passes
    if t_start[0] > 0 && t_end[0] > 0
      let start = t_start
      let end   = t_end
    else
      break
    endif

    if match_both_outer &&
          \ start[0] == a:firstline && end[0] == a:lastline && passes == 1
      continue
    endif
    let count1  -= 1
  endwhile

  if a:visual
    if end[0] >= start[0] && start[0] >= 1 && end[0] >= 1
      " Do magic
      exec "normal! \<Esc>"
      call cursor(start)
      exec "normal! v".end[0]."G^e"
      "echom string(start).';'.string(end).':'.passes
    endif
  else
    if end[0] >= start[0] && start[0] >= 1 && end[0] >= 1
      " Do magic
      return ':exec "normal! '.start.'G0V'.end."G\"\<CR>$"
    else
      " No pair found, do nothing
      return "\<Esc>"
    endif
  endif

endfunction " }}}2

function! s:RubyTextObjectsInner(visual) range "{{{2
  let lastline      = line('$')
  let start         = [0,0]
  let middle_p      = s:middle_p
  let end           = [-1,0]
  let count1        = v:count1
  "let visual        = a:visual ? visualmode() ==# 'V' : 0
  let initial       = [getpos("'<")[1:2], getpos("'>")[1:2]]
  let visual        = a:visual

  let t_start = [a:firstline, 0]
  let t_end   = [a:lastline, 0]
  let passes  = 0

  let match_both_outer = (
        \ s:Match(t_start[0] - 1, 'start') &&
        \ s:Match(t_end[0] + 1, 'end'))
  let start_matches = s:Match(t_start[0], 'start')
  let middle_matches= s:Match(a:firstline, 'm')
  let end_matches   = s:Match(t_end[0], 'e')

  while  count1 > 0 &&
        \ (!(count1 > 1) || (t_start[0] - 1 > 1 && t_end[0] + 1 < lastline))
    let passes += 1

    if passes == 1 && middle_matches
      " If a middle pattern is matched, use it as start
      let if = 1
      let d_start = 0
      let d_end   = 1
    elseif passes > 1 && (!start_matches && !end_matches)
      let if = 2
      let d_start = -1
      let d_end   = 1
    elseif start_matches && !end_matches
      let if = 3
      let d_start = 1
      let d_end   = 0
    elseif !start_matches && end_matches
      let if = 4
      let d_start = -1
      let d_end   = -1
    elseif start_matches && end_matches
      let if = 5
      let d_start = -1
      let d_end   = 1
    else 
      let if = 6
      let d_start = 0
      let d_end   = 0
    endif

    let [t_start, t_end] = s:FindTextObject([t_start[0] + d_start, 0], [t_end[0] + d_end, 0], s:start_p,
          \ s:middle_p, s:end_p, s:flags, s:skip_e)

    echom string(t_start).';'.string(t_end).':'.passes.':'.if
    if t_start[0] > 0 && t_end[0] > 0
      let start = t_start
      let end   = t_end
    else
      break
    endif

    let final = [[start[0]+1,1],[end[0]-1,len(getline(end[0]-1)) + 1]]
    echom string(initial).' == '.string(final)
    if match_both_outer &&
          \ start[0] == (a:firstline - 1) && end[0] == (a:lastline + 1) &&
          \ passes == 1 && (!a:visual || initial == final)
      continue
    endif
    let count1  -= 1
  endwhile

  if (end[0] - start[0]) > 1
    " There is an inner section, use it
    let start[0] += 1
    let end[0]   -= 1
  else
    " There is no inner section, nothing to do
    let start[0] = 0
    let end[0] = 0
  endif

  if a:visual
    if end[0] >= start[0] && start[0] >= 1 && end[0] >= 1
      " Do magic
      exec "normal! \<Esc>"
      call cursor(start[0],1)
      exec "normal! 0v".end[0]."G$"
      echom string(start).';'.string(end).':'.passes
    endif
  else
    if end[0] >= start[0] && start[0] >= 1 && end[0] >= 1
      " Do magic for operator pending mapping
      return ':exec "normal! '.start[0].'G0V'.end[0]."G\"\<CR>"
    else
      " No pair found, cancel operator
      return "\<Esc>"
    endif
  endif
endfunction "}}}2

function! s:FindTextObject(first, last, start, middle, end, flags, skip) "{{{2

  let first = {'start':[0,0], 'end':[0,0], 'range':0}
  let last  = {'start':[0,0], 'end':[0,0], 'range':0}

  if a:first[0] == a:last[0] " Range is the current line {{{3
    " searchpair() starts looking at the cursor position. Find out where that
    " should be. Also determine if the current line should be searched.
    if s:Match(a:first[0], 'e')
      let spos   = 1
      let sflags = a:flags.'b'
    else
      let spos   = 9999
      let sflags = a:flags.'bc'
    endif

    " Let's see where they are
    call cursor(a:first[0], spos)
    let first.start  = searchpairpos(a:start,a:middle,a:end,sflags,a:skip)

    if s:Match(a:first[0], 's')
      let epos   = 9999
      let eflags = a:flags
    else
      let epos   = 1
      let eflags = a:flags.'c'
    endif

    " Let's see where they are
    call cursor(a:first[0], epos)
    let first.end    = searchpairpos(a:start,a:middle,a:end,eflags,a:skip)

    let result = [first.start, first.end]

  else " Range is not the current line {{{3

    " Let's find a set with the first line of the range
    if s:Match(a:first[0], 'e')
      let spos   = 1
      let sflags = a:flags.'b'
    else
      let spos   = 9999
      let sflags = a:flags.'bc'
    endif

    if s:Match(a:first[0], 's')
      let epos   = 9999
      let eflags = a:flags
    else
      let epos   = 1
      let eflags = a:flags.'c'
    endif

    call cursor(a:first[0], spos)
    let first.start  = searchpairpos(a:start,a:middle,a:end,sflags,a:skip)
    call cursor(a:first[0], epos)
    let first.end    = searchpairpos(a:start,a:middle,a:end,eflags,a:skip)
    let first.range  = first.end[0] - first.start[0]

    " Let's find the second set with the last line of the range
    if s:Match(a:last[0], 'e')
      let spos   = 1
      let sflags = a:flags.'b'
    else
      let spos   = 9999
      let sflags = a:flags.'bc'
    endif

    if s:Match(a:last[0], 's')
      let epos   = 9999
      let eflags = a:flags
    else
      let epos   = 1
      let eflags = a:flags.'c'
    endif

    call cursor(a:last[0], spos)
    let last.start  = searchpairpos(a:start,a:middle,a:end,sflags,a:skip)
    call cursor(a:last[0], epos)
    let last.end    = searchpairpos(a:start,a:middle,a:end,eflags,a:skip)
    let last.range  = last.end[0] - last.start[0]

    " Now, decide what to return
    if first.range > last.range
      if first.start[0] <= last.start[0] && first.end[0] >= last.end[0]
        " last is inside first
        let result = [first.start, first.end]
      else
        " Something is wrong, last is not inside first
        let result = [[0,0],[0,0]]
      endif
    elseif first.range < last.range
      if first.start[0] >= last.start[0] && first.end[0] <= last.end[0]
        " first is inside last
        let result = [last.start, last.end]
      else
        " Something is wrong, first is not inside last
        let result = [[0,0],[0,0]]
      endif
    else
      if first.start[0] == last.start[0]
        " first and last are the same
        let result = [first.start, first.end]
      else
        " first and last are not the same
        let result = [a:first, a:last]
      endif
    endif
  endif "}}}3

  "echom string(result) . ', first: ' . string(first) . ', last' .
  "      \ string(last) . ', epos: ' . epos . ', spos: ' . spos .
  "      \ ', sflags: ' . sflags . ', eflags: ' . eflags

  return result

endfunction "}}}2

function! s:Match(line, part) " {{{2
  if a:part =~? '\ms\%[tart]'
    let part = s:start_p
  elseif a:part =~? '\mm\%[iddle]'
    let part = s:middle_p
  elseif a:part =~? '\me\%[nd]'
    let part = s:end_p
  else
    throw 'Oops!'
  endif
  call cursor(a:line, 1)
  "call search(part, 'cW', a:line)
  "let result = getline('.') =~# part && !eval(s:skip_e)
  let result = search(part, 'cW', a:line) > 0 && !eval(s:skip_e)
  "echom result
  return result
endfunction " }}}2
