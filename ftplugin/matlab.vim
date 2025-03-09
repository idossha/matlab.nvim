" Enhanced highlighting for MATLAB cell sections and better UI

" Make sure fold settings are appropriate for MATLAB files
setlocal foldmethod=manual
setlocal foldtext=GetMatlabFoldText()

" Make cell sections more visible with custom highlighting
hi MatlabCellHeader cterm=bold gui=bold ctermfg=14 guifg=#00afff guibg=#2a2a2f

" Apply this highlighting after the syntax file has loaded
augroup MatlabCellHighlighting
  autocmd!
  autocmd Syntax matlab syntax match MatlabCellHeader /^[ \t]*%%.*$/ containedin=ALL
augroup END

" Custom function to display nicer fold text for MATLAB cells
function! GetMatlabFoldText()
  let line = getline(v:foldstart)
  let cellHeader = getline(v:foldstart-1)
  
  " If this fold starts right after a cell header, use that for the title
  if cellHeader =~ '^[ \t]*%%'
    let cellTitle = substitute(cellHeader, '^[ \t]*%%[ \t]*', '', '')
    return '+ ' . cellTitle . ' [' . (v:foldend - v:foldstart + 1) . ' lines]'
  endif
  
  " Default fold text
  return '+-- ' . (v:foldend - v:foldstart + 1) . ' lines folded'
endfunction