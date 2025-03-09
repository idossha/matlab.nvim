if exists("b:current_syntax")
  finish
endif

" Keywords
syn keyword matlabStatement           return function
syn keyword matlabConditional         switch case else elseif end if otherwise break continue
syn keyword matlabRepeat              do for while
syn keyword matlabStorageClass        classdef methods properties events persistent global
syn keyword matlabExceptions          try catch rethrow throw
syn keyword matlabOO                  classdef properties methods events
syn keyword matlabBoolean             true false

" Comments and special markup
syn keyword matlabTodo                contained TODO NOTE FIXME XXX
syn match matlabComment               "%.*$" contains=matlabTodo,matlabTab
syn region matlabBlockComment         start="^\s*%{\s*$" end="^\s*%}\s*$" contains=matlabBlockComment,matlabTodo
syn match matlabHeadline              "%%.*$" contains=matlabTodo

" Strings and numbers
syn region matlabString               start=+'+ end=+'+ oneline
syn match matlabNumber                "\<\d\+[ij]\=\>"
syn match matlabFloat                 "\<\d\+\(\.\d*\)\=\([edED][-+]\=\d\+\)\=[ij]\=\>"
syn match matlabFloat                 "\.\d\+\([edED][-+]\=\d\+\)\=[ij]\=\>"
syn keyword matlabConstant            eps Inf NaN pi

" Operators and delimiters
syn match matlabRelationalOperator    "\(==\|\~=\|>=\|<=\|=\~\|>\|<\|=\)"
syn match matlabArithmeticOperator    "[-+]"
syn match matlabArithmeticOperator    "\.\=[*/\\^]"
syn match matlabLogicalOperator       "[&|~]"
syn match matlabLineContinuation      "\.\{3}"
syn match matlabDelimiter             "[][]"
syn match matlabTransposeOperator     "[])a-zA-Z0-9.]'"lc=1
syn match matlabSemicolon             ";"
syn keyword matlabImport              import

" Link to standard types
hi def link matlabComment             Comment
hi def link matlabBlockComment        Comment
hi def link matlabHeadline            Title
hi def link matlabString              String
hi def link matlabNumber              Number
hi def link matlabFloat               Float
hi def link matlabConstant            Constant
hi def link matlabBoolean             Boolean
hi def link matlabStatement           Statement
hi def link matlabConditional         Conditional
hi def link matlabRepeat              Repeat
hi def link matlabStorageClass        StorageClass
hi def link matlabExceptions          Exception
hi def link matlabOO                  Structure
hi def link matlabTodo                Todo
hi def link matlabImport              Include
hi def link matlabDelimiter           Delimiter
hi def link matlabTransposeOperator   Operator
hi def link matlabSemicolon           SpecialChar
hi def link matlabLineContinuation    Special
hi def link matlabRelationalOperator  Operator
hi def link matlabArithmeticOperator  Operator
hi def link matlabLogicalOperator     Operator

" For basic MATLAB functions
syn keyword matlabFunc  abs acos acosd acosh acot acotd acoth acsc acscd acsch asec
syn keyword matlabFunc  asecd asech asin asind asinh atan atan2 atand atanh ceil
syn keyword matlabFunc  complex conj cos cosd cosh cot cotd coth csc cscd csch
syn keyword matlabFunc  double exp fix floor imag log log2 log10 mod real round
syn keyword matlabFunc  sec secd sech sign sin sind sinh sqrt tan tand tanh
syn keyword matlabFunc  char disp error eval input ischar isletter isspace lower
syn keyword matlabFunc  sprintf sscanf strcat strcmp strcmpi strings strncmp
syn keyword matlabFunc  strncmpi strfind strrep strtok upper fclose feof fgetl
syn keyword matlabFunc  fgets fopen fprintf frewind fscanf fseek fwrite gets printf
syn keyword matlabFunc  length size clc clear close figure hold plot title xlim ylim zlim

" Highlight MATLAB functions
hi def link matlabFunc               Function

let b:current_syntax = "matlab"