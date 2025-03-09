" Vim syntax file
" Language:     MATLAB
" Maintainer:   Your Name
" Last Change:  2023

" Quit when a syntax file was already loaded
if exists("b:current_syntax")
  finish
endif

" MATLAB is case sensitive
syntax case match

" Comments
syntax match matlabComment "%.*$" contains=matlabTodo,@Spell
syntax region matlabBlockComment start="%{" end="%}" contains=matlabTodo,@Spell
syntax match matlabCellComment "^%%.*$" contains=matlabTodo,@Spell

" Todo patterns
syntax keyword matlabTodo TODO FIXME XXX NOTE HACK contained

" Strings
syntax region matlabString start=+'+ end=+'+ skip=+\\\\\|\\'+ contains=@Spell
syntax region matlabString start=+"+ end=+"+ skip=+\\\\\|\\"+ contains=@Spell

" Numbers
syntax match matlabNumber "\<\d\+\>"
syntax match matlabFloat "\<\d\+\.\d*\>"
syntax match matlabFloat "\<\.\d\+\>"
syntax match matlabFloat "\<\d\+\.\d*e[-+]\=\d\+\>"
syntax match matlabFloat "\<\.\d\+e[-+]\=\d\+\>"
syntax match matlabFloat "\<\d\+e[-+]\=\d\+\>"

" Operators
syntax match matlabOperator "+\|-\|\*\|\/\|\\\\=\|&\||\|!\|=\|>\|<\|\^\|\.\k\@="

" Delimiters
syntax match matlabDelimiter "[\[\](){}.,;]"

" Functions
syntax match matlabFunction "\<\w\+\>\ze\s*("

" Keywords
syntax keyword matlabStatement return function end global persistent
syntax keyword matlabConditional if else elseif switch case otherwise
syntax keyword matlabRepeat for while break continue
syntax keyword matlabExceptions try catch
syntax keyword matlabOO classdef properties methods events enumeration
syntax keyword matlabOO get set

" Special variables
syntax keyword matlabConstant true false inf nan pi eps
syntax keyword matlabArithmeticOperator plus minus rdivide ldivide times mtimes power

" Cell separator
syntax match matlabCell "^%%.*$"

" Define highlighting links
highlight default link matlabComment Comment
highlight default link matlabBlockComment Comment
highlight default link matlabCellComment SpecialComment
highlight default link matlabTodo Todo
highlight default link matlabString String
highlight default link matlabNumber Number
highlight default link matlabFloat Float
highlight default link matlabOperator Operator
highlight default link matlabDelimiter Delimiter
highlight default link matlabFunction Function
highlight default link matlabStatement Statement
highlight default link matlabConditional Conditional
highlight default link matlabRepeat Repeat
highlight default link matlabExceptions Exception
highlight default link matlabOO Keyword
highlight default link matlabConstant Constant
highlight default link matlabArithmeticOperator Operator
highlight default link matlabCell Title

" Special highlighting for cell separators
highlight default matlabCell term=bold cterm=bold gui=bold

let b:current_syntax = "matlab"
