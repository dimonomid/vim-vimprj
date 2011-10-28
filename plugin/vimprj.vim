

call vimprj#init()

function! g:vimprj#dHooks['OnAddNewVimprjRoot']['test'](dParams)
   "echo a:dParams
endfunction

"function! g:vimprj#dHooks.onTest.second(dParams)
   "echo "second! "
   "echo a:dParams
   "let g:vimprj#dRoots[a:dParams.sKey].test2 = "asd"
"endfunction

"call vimprj#test("sdf")

