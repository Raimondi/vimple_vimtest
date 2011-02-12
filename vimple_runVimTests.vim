nnoremap <silent><leader>t :call test.runTests()<CR>
command! -bar -nargs=? -complete=file RunTests call test.runTests(<q-args>)

hi def VimTestPass  ctermfg=16 ctermbg=150 guifg=Black guibg=#A4E57E
hi def VimTestFail  ctermfg=16 ctermbg=203 guifg=Black guibg=#FF7272

"echo 'Sourced!'
if !exists('test')
  let test = {}
  let test.timeout = 5
  let test.exec    = 'runVimTests.expect'
endif
function! test.runTests(...) dict "{{{
  if !executable(self.exec)
    " Abort, expect script is not available.
    echohl ErrorMsg
    echom '"'.self.exec . '" was not found.'
    echohl Normal
    return
  elseif exists('self.status') && self.status == 'pending'
    " Test is running, do not start another.
    echohl ErrorMsg
    echom 'The previous test has not finished yet.'
    echohl Normal
    return
  endif

  " Get testing file if not available.
  if a:0
    " Argument provided on the command line, use that.
    let self.testfile = a:1
  elseif !exists('self.testfile') || glob(self.testfile) == '' || v:count > 0
    " Doesn't exists or a count was used with the mapping, ask for a path.
    let self.testfile = input("Tell me where the tests are: ", get(self,'testfile',''), 'file')
    "echom string(self)
  endif

  if glob(self.testfile) == ''
    echohl ErrorMsg
    echom '"'.self.testfile '" is not a valid path.'
    echohl Normal
    return
  else
    let self.testfile = fnamemodify(self.testfile, ':p')
    echom 'Running test(s) from: '.self.testfile
  endif

  let self.tempfile = tempname()
  let self.time     = localtime()
  let self.stamp    = strftime('%Y-%m-%d %X', localtime())
  let self.status   = 'pending'
  for v in ['output', 'files', 'tests', 'skipped', 'run', 'failures', 'errors', 'files_failed', 'files_errors']
    sil! unlet self[v]
  endfor

  " Run test.
  silent exec '!'.self.exec.' '.
        \ shellescape(self.testfile).' '.
        \ shellescape(self.tempfile).' &'

  let self.elapsed  = localtime() - self.time
  augroup TestRunning
    au!
    exec 'au CursorHold,CursorHoldI,InsertEnter,InsertLeave * call test.updateTests()'
  augroup END
endfunction "}}}

function! test.updateTests() dict "{{{
  if !filereadable(self.tempfile)
    " File is not available"
    if localtime() - self.time > self.timeout
      let self.status = 'timeout'
      echohl ErrorMsg
      " echom join(readfile(self.tempfile), ',')
    else
      return
    endif
  else
    " Parse it
    "echom join(readfile(self.tempfile), ', ')
    let self.output = readfile(self.tempfile)
    for f in self.output
      "echom string(f).' '.substitute(f, '^\(\k\+\):.*$', '\1', '').':'.substitute(f, '^.\{-}: \(.\+\)$', '\1', '')
      if f =~# '^\(\k\+\): \(.\+\)$'
        let self[substitute(f, '^\(\k\+\):.*$', '\1', '')] = substitute(f, '^.\{-}: \(.\+\)$', '\1', '')
      endif
    endfor

    " Check for failures (should we check for errors also?)
    if exists('self.failures')
      if self.failures > 0
        let self.status = 'failed'
        echohl VimTestFail
      else
        let self.status = 'passed'
        echohl VimTestPass
      endif
    else
      echohl ErrorMsg
      let self.status = 'error'.(exists('self.error') ? (': '.self.error) : '')
    endif
  endif
  "echom system('cat '.self.tempfile)
  "echom string(self)
  " fmod() is 7.3... what say you?
  echom self.status . repeat(" ",(&columns -(len(self.status) - (len(self.status)/&columns) * &columns)))
  "echon repeat("_",&columns - 1) . "\r" . self.status
  echohl None
  augroup TestRunning
    au!
  augroup END
  augroup! TestRunning
endfunction "}}}
