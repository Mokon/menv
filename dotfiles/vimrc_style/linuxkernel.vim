" (C) 2013 David 'Mokon' Bond, All Rights Reserved

set wildignore+=*.ko,*.mod.c,*.order,modules.builtin

autocmd FileType c,cpp call s:LinuxKernelFormatting()
autocmd FileType diff,kconfig setlocal tabstop=8

function s:LinuxKernelFormatting()
  setlocal tabstop=8
  setlocal shiftwidth=8
  setlocal softtabstop=8
  setlocal textwidth=80
  setlocal noexpandtab
  setlocal cindent
  setlocal formatoptions=tcqlron
  setlocal cinoptions=:0,l1,t0,g0

  syn keyword cOperator likely unlikely
  syn keyword cType u8 u16 u32 u64 s8 s16 s32 s64

  highlight default link LinuxError ErrorMsg

  syn match LinuxError /  \+/    
  syn match LinuxError /^ \+/
  syn match LinuxError / \+\ze\t/
  syn match LinuxError /\s\+$/
  syn match LinuxError /\%81v.\+/
endfunction

