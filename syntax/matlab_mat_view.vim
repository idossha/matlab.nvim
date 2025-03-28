 " syntax/matlab_mat_view.vim
if exists("b:current_syntax")
  finish
endif

" Highlights for MAT file viewer
syn match matViewHeader /^MAT File:.*/
syn match matViewHeader /^Variables:.*/
syn match matViewDivider /^====================$/
syn match matViewVariable /^## .*/
syn match matViewProperty /^Type:.*/
syn match matViewPreview /^Preview.*/
syn match matViewValue /^Value:.*/
syn match matViewHelp /^Press q to close this view$/

" Link to standard highlight groups
hi def link matViewHeader Title
hi def link matViewDivider Special
hi def link matViewVariable Identifier
hi def link matViewProperty Type
hi def link matViewPreview Comment
hi def link matViewValue Constant
hi def link matViewHelp Comment

let b:current_syntax = "matlab_mat_view"
