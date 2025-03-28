 " syntax/matlab_mat_view.vim
if exists("b:current_syntax")
  finish
endif

" Highlights for the MAT file viewer
syn match matViewHeader /^MAT File:.*/
syn match matViewDivider /^=\+$/
syn match matViewVariable /^## .*/
syn match matViewProperty /^Type: .*, Size: .*/
syn match matViewValue /^Value:.*$/
syn match matViewPreview /^Preview.*$/

" Link to standard highlight groups
hi def link matViewHeader Title
hi def link matViewDivider Special
hi def link matViewVariable Identifier
hi def link matViewProperty Type
hi def link matViewValue Constant
hi def link matViewPreview Comment

let b:current_syntax = "matlab_mat_view"
