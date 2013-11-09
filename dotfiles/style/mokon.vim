" (C) 2013 David 'Mokon' Bond, All Rights Reserved

set tabstop=2 shiftwidth=2 expandtab " My default indentation.

function! TESTINGFindAndReplaceAllConfirm(from, to)
  exe '%s/' . a:from . '/' . a:to . '/gc'
endfunction
