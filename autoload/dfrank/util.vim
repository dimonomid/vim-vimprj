
" IsAbsolutePath(path) <<<
"   this function from project.vim is written by Aric Blumer.
"   Returns true if filename has an absolute path.
function! dfrank#util#IsAbsolutePath(path)
   if a:path =~ '^ftp:' || a:path =~ '^rcp:' || a:path =~ '^scp:' || a:path =~ '^http:'
      return 2
   endif
   let path=expand(a:path) " Expand any environment variables that might be in the path
   if path[0] == '/' || path[0] == '~' || path[0] == '\\' || path[1] == ':'
      return 1
   endif
   return 0
endfunction " >>>


" acts like bufname({expr}), but always return absolute path
function! dfrank#util#BufName(mValue)
   let l:sFilename = bufname(a:mValue)

   " make absolute path
   if !empty(l:sFilename) && !dfrank#util#IsAbsolutePath(l:sFilename)
      let l:sFilename = getcwd().'/'.l:sFilename
   endif

   " on Windows systems happens stupid things: bufname returns path without
   " drive letter, e.g. something like that: "/path/to/file", but it should be
   " "D:/path/to/file". So, we need to add drive letter manually.
   if has('win32') || has('win64')
      if strpart(l:sFilename, 0, 1) == '/' && strpart(getcwd(), 1, 1) == ':'
         let l:sFilename = strpart(getcwd(), 0, 2).l:sFilename
      endif
   endif

   " simplify
   let l:sFilename = simplify(l:sFilename)

   return l:sFilename
endfunction



function! dfrank#util#SetDefaultValues(dParams, dDefParams)
   let l:dParams = a:dParams

   for l:sKey in keys(a:dDefParams)
      if (!has_key(l:dParams, l:sKey))
         let l:dParams[ l:sKey ] = a:dDefParams[ l:sKey ]
      else
         if type(l:dParams[ l:sKey ]) == type({}) && type(a:dDefParams[ l:sKey ]) == type({})
            let l:dParams[ l:sKey ] = dfrank#util#SetDefaultValues(l:dParams[ l:sKey ], a:dDefParams[ l:sKey ])
         endif
      endif
   endfor

   return l:dParams
endfunction

function! dfrank#util#GetKeyFromPath(sPath)
   let l:sKey = substitute(a:sPath, '[^a-zA-Z0-9_]', '_', 'g')

   if has('win32') || has('win64')
      let l:sKey = tolower(l:sKey)
   endif

   return l:sKey
endfunction

