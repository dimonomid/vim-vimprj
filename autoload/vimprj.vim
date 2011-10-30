

if v:version < 700
   call confirm("vimprj: You need Vim 7.0 or higher")
   finish
endif

let g:vimprj#version           = 100
let g:vimprj#loaded            = 0

let s:boolInitialized          = 0
let s:bool_OnFileOpen_executed = 0


" задаем пустые массивы с данными
function! vimprj#init()
   if s:boolInitialized
      return
   endif

   "echoerr "initing"

   let s:DEB_LEVEL__ASYNC  = 1
   let s:DEB_LEVEL__PARSE  = 2
   let s:DEB_LEVEL__ALL    = 3

   if !exists('g:vimprj_recurseUpCount')
      let g:vimprj_recurseUpCount = 10
   endif

   if !exists('g:vimprj_dirNameForSearch')
      let g:vimprj_dirNameForSearch = '.vimprj'
   endif

   if !exists('g:vimprj_changeCurDirIfVimprjFound')
      let g:vimprj_changeCurDirIfVimprjFound = 1
   endif


   " задаем пустые массивы с данными
   let g:vimprj#dRoots = {}
   let g:vimprj#dFiles = {}
   let g:vimprj#iCurFileNum = 0
   let g:vimprj#sCurVimprjKey = 'default'
   "  g:vimprj#sCurVimprjKey устанавливается позднее (хотя, может, это и не
   "  обязательно)
   let g:vimprj#dHooks = {
            \     'NeedSkipBuffer'      : {},
            \     'OnAddNewVimprjRoot'  : {},
            \     'SetDefaultOptions'   : {},
            \     'OnAddFile'           : {},
            \     'OnFileOpen'          : {},
            \     'ApplyVimprjSettings_after' : {},
            \  
            \     'onTest'              : {},
            \  }

   " запоминаем начальные &path
   "let s:sPathDefault = &path

   " указываем обработчик открытия нового файла: OnFileOpen
   augroup Vimprj_LoadFile
      autocmd! Vimprj_LoadFile BufReadPost
      autocmd! Vimprj_LoadFile BufNewFile
      autocmd Vimprj_LoadFile BufReadPost * call <SID>OnFileOpen()
      autocmd Vimprj_LoadFile BufNewFile * call <SID>OnFileOpen()
   augroup END

   " указываем обработчик входа в другой буфер: OnBufEnter
   augroup Vimprj_BufEnter
      autocmd! Vimprj_BufEnter BufEnter
      autocmd Vimprj_BufEnter BufEnter * call <SID>OnBufEnter()
   augroup END

   let s:boolInitialized = 1

   "function! g:vimprj#dHooks['OnAddNewVimprjRoot']['test'](dParams)
      "return 2
   "endfunction

   "function! g:vimprj#dHooks['OnAddNewVimprjRoot']['test2'](dParams)
      "return {'as' : 'fg'}
   "endfunction

   "echo g:vimprj#dHooks

endfunction

function! <SID>CreateDefaultProjectIfNotAlready()
   if !has_key(g:vimprj#dRoots, "default")
      " создаем дефолтный "проект"
      call <SID>AddNewVimprjRoot("default", "", getcwd())
      call <SID>AddFile(0, 'default')
      "x3, надо ли послед.строчка
      "let g:vimprj#sCurVimprjKey = "default"  
   endif
endfunction

function! <SID>AddFile(iBufNum, sVimprjKey)
   "call confirm('AddFile '.a:iBufNum.' '.a:sVimprjKey)

   let g:vimprj#dFiles[ a:iBufNum ] = {'sVimprjKey' : a:sVimprjKey}
   call <SID>ExecHooks('OnAddFile', {'iBufNum' : a:iBufNum, 'sVimprjKey' : a:sVimprjKey})
endfunction


" sets
"    g:vimprj#iCurFileNum     ( from bufnr('%') )
"    g:vimprj#sCurVimprjKey   ( from g:vimprj#dFiles )
function! <SID>SetCurrentFile(iFileNum)

   call <SID>_AddToDebugLog(s:DEB_LEVEL__ALL, 'function start: __SetCurrentFile__', {'filename' : expand('<afile>')})

   if has_key(g:vimprj#dFiles, a:iFileNum)
      let g:vimprj#iCurFileNum = a:iFileNum
   else
      let g:vimprj#iCurFileNum = 0
   endif
   let g:vimprj#sCurVimprjKey = g:vimprj#dFiles[ g:vimprj#iCurFileNum ].sVimprjKey

   call <SID>_AddToDebugLog(s:DEB_LEVEL__ALL, 'function end: __SetCurrentFile__', {'text' : ('g:vimprj#iCurFileNum='.g:vimprj#iCurFileNum.'; g:vimprj#sCurVimprjKey='.g:vimprj#sCurVimprjKey)})

endfunction



function! <SID>_AddToDebugLog(iLevel, sType, dData)
   "call confirm (a:sType)
endfunction

function! <SID>ExecHooks(sHooksgroup, dParams)
   "echoerr a:sHooksgroup
   "call confirm("ExecHooks ".a:sHooksgroup)
   let l:lRetValues = []
   let l:dParams = a:dParams

   if !has_key(g:vimprj#dHooks, a:sHooksgroup)
      echoerr "No hook group ".a:sHooksgroup
      return 
   endif

   for l:sKey in keys(g:vimprj#dHooks[ a:sHooksgroup ])
      "call confirm("-- ".l:sKey)


      silent! let l:dParams['dVimprjRootParams'] = 
                  \  g:vimprj#dRoots[g:vimprj#sCurVimprjKey][ l:sKey ]

      call add(l:lRetValues, g:vimprj#dHooks[ a:sHooksgroup ][ l:sKey ](l:dParams))

      silent! unlet l:dParams['dVimprjRootParams']


      "echo l:sKey
      "call g:vimprj#dHooks[ a:sHooksgroup ][ l:sKey ](l:dParams)

      "let l:tmp = g:vimprj#dHooks[ a:sHooksgroup ][ l:sKey ](l:dParams)
      "call add(l:lRetValues, l:tmp)
      "unlet l:tmp

   endfor
   return l:lRetValues
endfunction

"call <SID>ExecHooks('OnAddNewVimprjRoot', {})

"function! vimprj#test(sKey)
   "let g:vimprj#dRoots[a:sKey] = {}
   "let g:vimprj#dRoots[a:sKey].test = "qwe"
   "call <SID>ExecHooks('onTest', {'sKey' : a:sKey})
"endfunction

"function! g:vimprj#dHooks.onTest.first(dParams)
   "echo a:dParams
"endfunction


" добавляет новый vimprj root, заполняет его текущими параметрами
"
" ВНИМАНИЕ! "текущими" параметрами - это означает, что на момент вызова
" этого метода все .vim файлы из .vimprj уже должны быть выполнены!
function! <SID>AddNewVimprjRoot(sKey, sPath, sCdPath)

   if !has_key(g:vimprj#dRoots, a:sKey)

      call <SID>_AddToDebugLog(s:DEB_LEVEL__PARSE, 'function start: __AddNewVimprjRoot__', {'sKey' : a:sKey, 'sPath' : a:sPath, 'sCdPath' : a:sCdPath})

      let g:vimprj#dRoots[a:sKey] = {}
      let g:vimprj#dRoots[a:sKey]["cd_path"] = a:sCdPath
      let g:vimprj#dRoots[a:sKey]["proj_root"] = a:sPath
      if (!empty(a:sPath))
         let g:vimprj#dRoots[a:sKey]["path"] = a:sPath.'/'.g:vimprj_dirNameForSearch
      else
         let g:vimprj#dRoots[a:sKey]["path"] = ""
      endif

      call <SID>ExecHooks('OnAddNewVimprjRoot', {'sKey' : a:sKey})

      call <SID>_AddToDebugLog(s:DEB_LEVEL__PARSE, 'function end: __AddNewVimprjRoot__', {})
   endif
endfunction


" applies all settings from .vimprj dir
function! vimprj#applyVimprjSettings(sVimprjKey, iFileNum)

   call <SID>_AddToDebugLog(s:DEB_LEVEL__ALL, 'function start: __ApplyVimprjSettings__', {'sVimprjKey' : a:sVimprjKey})


   " TODO
   "if (!empty(s:indexer_defaultSettingsFilename))
   "    exec 'source '.s:indexer_defaultSettingsFilename
   "endif

   call <SID>SourceVimprjFiles(g:vimprj#dRoots[ a:sVimprjKey ]["path"])
   call <SID>ChangeDirToVimprj(g:vimprj#dRoots[ a:sVimprjKey ]["cd_path"])


   call <SID>ExecHooks('ApplyVimprjSettings_after', {
            \     'sVimprjKey' : a:sVimprjKey,
            \     'iFileNum'   : a:iFileNum,
            \  })

   "let l:sTmp .= "===".&ts
   "let l:tmp2 = input(l:sTmp)
   " для каждого проекта, в который входит файл, добавляем tags и path

   call <SID>_AddToDebugLog(s:DEB_LEVEL__ALL, 'function end: __ApplyVimprjSettings__', {})
endfunction



" returns if we should to skip this buffer ('skip' means not to generate tags
" for it)
function! <SID>NeedSkipBuffer(iFileNum)

   " file should be readable
   if !filereadable(bufname(a:iFileNum))
      return 1
   endif

   " &buftype should be empty for regular files
   if !empty(getbufvar(a:iFileNum, "&buftype"))
      return 1
   endif

   " buffer name should not be empty
   if empty(bufname(a:iFileNum))
      return 1
   endif


   let l:lNeedSkip = <SID>ExecHooks('NeedSkipBuffer', {
            \     'iFileNum' : a:iFileNum,
            \  })

   for l:boolCurNeedSkip in l:lNeedSkip
      if l:boolCurNeedSkip
         return 1
      endif
   endfor


   return 0
endfunction

function! <SID>SourceVimprjFiles(sPath)
   "call confirm("sourcing files from: ". a:sPath)
   
   call <SID>ExecHooks('SetDefaultOptions', {'sDirName' : a:sPath})

   if (!empty(a:sPath))
      " sourcing all *vim files in .vimprj dir

      let l:lSourceFilesList = split(glob(a:sPath.'/*vim'), '\n')
      let l:sThisFile = expand('%:p')
      for l:sFile in l:lSourceFilesList
         exec 'source '.l:sFile
      endfor

   endif
endfunction

function! <SID>ChangeDirToVimprj(sPath)
   " переключаем рабочую директорию
   if (g:vimprj_changeCurDirIfVimprjFound)
      exec "cd ".a:sPath
      " ???? иначе не работает
      exec "cd ".a:sPath
   endif
endfunction

function! <SID>GetKeyFromPath(sPath)
   return substitute(a:sPath, '[^a-zA-Z0-9_]', '_', 'g')
endfunction

function! <SID>OnFileOpen()

   let l:iFileNum = bufnr(expand('<afile>'))


   call <SID>CreateDefaultProjectIfNotAlready()

   if (<SID>NeedSkipBuffer(l:iFileNum))
      return
   endif

   call <SID>_AddToDebugLog(s:DEB_LEVEL__PARSE, 'function start: __OnFileOpen__', {'filename' : expand('%')})

   let s:bool_OnFileOpen_executed = 1

   "let l:sTmp = input("OnNewFileOpened_".getbufvar('%', "&buftype"))

   " actual tags dirname. If .vimprj directory will be found then this tags
   " dirname will be /path/to/dir/.vimprj/tags

   " ищем .vimprj
   let l:sVimprjKey = "default"


   let l:i = 0
   let l:sCurPath = ''
   let l:sProjectRoot = ''
   while (l:i < g:vimprj_recurseUpCount)
      if (isdirectory(expand('%:p:h').l:sCurPath.'/'.g:vimprj_dirNameForSearch))
         let l:sProjectRoot = simplify(expand('%:p:h').l:sCurPath)
         break
      endif
      let l:sCurPath = l:sCurPath.'/..'
      let l:i = l:i + 1
   endwhile

   if !empty(l:sProjectRoot)

      " .vimprj directory is found.
      " проверяем, не открыли ли мы файл из директории .vimprj

      let l:sPathToDirNameForSearch = l:sProjectRoot.'/'.g:vimprj_dirNameForSearch
      let l:iPathToDNFSlen = strlen(l:sPathToDirNameForSearch)

      if (strpart(expand('%:p:h'), 0, l:iPathToDNFSlen) != l:sPathToDirNameForSearch)
         " нет, открытый файл - не из директории .vimprj, так что применяем
         " для него настройки из этой директории .vimprj
         let l:sVimprjKey = <SID>GetKeyFromPath(l:sProjectRoot)
      endif
   endif


   " if this .vimprj project is not known yet, then adding it.
   " otherwise just applying settings, if necessary.

   call <SID>AddFile(l:iFileNum, l:sVimprjKey)

   if !has_key(g:vimprj#dRoots, l:sVimprjKey)
      " adding

      " sourcing all *vim files in .vimprj dir

      call <SID>SourceVimprjFiles(l:sProjectRoot.'/'.g:vimprj_dirNameForSearch)
      call <SID>ChangeDirToVimprj(substitute(l:sProjectRoot, ' ', '\\ ', 'g'))

      call <SID>AddNewVimprjRoot(l:sVimprjKey, l:sProjectRoot, l:sProjectRoot)
   else
      " .vimprj project is known.
      " if it is inactive - applying settings from it.
      if l:sVimprjKey != g:vimprj#sCurVimprjKey
         call vimprj#applyVimprjSettings(l:sVimprjKey, l:iFileNum)
      endif

   endif



   "let g:vimprj#dFiles[ a:iBufNum ]['justAdded'] = 1

   call <SID>SetCurrentFile(l:iFileNum)

   " here we pass g:vimprj#sCurVimprjKey, g:vimprj#iCurFileNum
   " because they are just modified by SetCurrentFile

   call <SID>ExecHooks('OnFileOpen', {
            \     'sVimprjKey' : l:sVimprjKey,
            \     'iFileNum'   : l:iFileNum,
            \  })

   call <SID>ExecHooks('ApplyVimprjSettings_after', {
            \     'sVimprjKey' : l:sVimprjKey,
            \     'iFileNum'   : l:iFileNum,
            \  })

   " НЕ НАДО: для того, чтобы при входе в OnBufEnter сработал IsBufSwitched, ставим
   " текущий номер буфера в 0
   "let g:vimprj#iCurFileNum = 0
   "let g:vimprj#sCurVimprjKey = "default"

   call <SID>_AddToDebugLog(s:DEB_LEVEL__PARSE, 'function end: __OnFileOpen__', {})
endfunction

" returns if buffer is changed (swithed) to another, or not
function! <SID>IsBufSwitched()
   return (g:vimprj#iCurFileNum != bufnr('%'))
endfunction


function! <SID>OnBufEnter()
   let l:iFileNum = bufnr(expand('<afile>'))

   call <SID>CreateDefaultProjectIfNotAlready()

   if (<SID>NeedSkipBuffer(l:iFileNum))
      return
   endif

   call <SID>_AddToDebugLog(s:DEB_LEVEL__ALL, 'function start: __OnBufEnter__', {'filename' : expand('%')})

   if (!<SID>IsBufSwitched())
      return
   endif

   if empty(s:bool_OnFileOpen_executed)
      call <SID>OnFileOpen()
   endif

   "let l:sTmp = input("OnBufWinEnter_".getbufvar('%', "&buftype"))

   let l:sPrevVimprjKey = g:vimprj#sCurVimprjKey
   call <SID>SetCurrentFile(l:iFileNum)

   " applying vimprj settings if only vimprj root changed
   if l:sPrevVimprjKey != g:vimprj#sCurVimprjKey
      call vimprj#applyVimprjSettings(g:vimprj#sCurVimprjKey, l:iFileNum)
   endif

   call <SID>_AddToDebugLog(s:DEB_LEVEL__ALL, 'function end: __OnBufEnter__', {})

endfunction

if !s:boolInitialized
   call vimprj#init()
endif


