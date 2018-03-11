" File: grep.vim
" Author: Yegappan Lakshmanan (yegappan AT yahoo DOT com)
" Version: 2.1
" Last Modified: March 11, 2018
" 
" Plugin to integrate grep like utilities with Vim
" Supported ones are: grep, fgrep, egrep, agrep, findstr, ag, ack, ripgrep and
" git grep
"
" License: MIT License
" Copyright (c) 2002-2018 Yegappan Lakshmanan
"
" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to
" deal in the Software without restriction, including without limitation the
" rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
" sell copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:
"
" The above copyright notice and this permission notice shall be included in
" all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
" FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
" IN THE SOFTWARE.
" =======================================================================

" Line continuation used here
let s:cpo_save = &cpo
set cpo&vim

" Location of the grep utility
if !exists("Grep_Path")
    let Grep_Path = 'grep'
endif

" Location of the fgrep utility
if !exists("Fgrep_Path")
    let Fgrep_Path = 'fgrep'
endif

" Location of the egrep utility
if !exists("Egrep_Path")
    let Egrep_Path = 'egrep'
endif

" Location of the agrep utility
if !exists("Agrep_Path")
    let Agrep_Path = 'agrep'
endif

" Location of the Silver Searcher (ag) utility
if !exists("Ag_Path")
    let Ag_Path = 'ag'
endif

" Location of the Ripgrep (rg) utility
if !exists("Rg_Path")
    let Rg_Path = 'rg'
endif

" Location of the ack utility
if !exists("Ack_Path")
    let Ack_Path = 'ack'
endif

" Location of the findstr utility
if !exists("Findstr_Path")
    let Findstr_Path = 'findstr.exe'
endif

" Location of the git utility used by the git grep command
if !exists("Git_Path")
    let Git_Path = 'git'
endif

" Location of the find utility
if !exists("Grep_Find_Path")
    let Grep_Find_Path = 'find'
endif

" Location of the xargs utility
if !exists("Grep_Xargs_Path")
    let Grep_Xargs_Path = 'xargs'
endif

" Open the Grep output window.  Set this variable to zero, to not open
" the Grep output window by default.  You can open it manually by using
" the :cwindow command.
if !exists("Grep_OpenQuickfixWindow")
    let Grep_OpenQuickfixWindow = 1
endif

" Default grep file list
if !exists("Grep_Default_Filelist")
    let Grep_Default_Filelist = '*'
endif

" Default grep options
if !exists("Grep_Default_Options")
    let Grep_Default_Options = ''
endif

" Use the 'xargs' utility in combination with the 'find' utility. Set this
" to zero to not use the xargs utility.
if !exists("Grep_Find_Use_Xargs")
    let Grep_Find_Use_Xargs = 1
endif

" The command-line arguments to supply to the xargs utility
if !exists('Grep_Xargs_Options')
    let Grep_Xargs_Options = '-0'
endif

" The find utility is from the cygwin package or some other find utility.
if !exists("Grep_Cygwin_Find")
    let Grep_Cygwin_Find = 0
endif

" NULL device name to supply to grep.  We need this because, grep will not
" print the name of the file, if only one filename is supplied. We need the
" filename for Vim quickfix processing.
if !exists("Grep_Null_Device")
    if has('win32')
	let Grep_Null_Device = 'NUL'
    else
	let Grep_Null_Device = '/dev/null'
    endif
endif

" Character to use to escape special characters before passing to grep.
if !exists("Grep_Shell_Escape_Char")
    if has('win32')
	let Grep_Shell_Escape_Char = ''
    else
	let Grep_Shell_Escape_Char = '\'
    endif
endif

" The list of directories to skip while searching for a pattern. Set this
" variable to '', if you don't want to skip directories.
if !exists("Grep_Skip_Dirs")
    let Grep_Skip_Dirs = 'RCS CVS SCCS'
endif

" The list of files to skip while searching for a pattern. Set this variable
" to '', if you don't want to skip any files.
if !exists("Grep_Skip_Files")
    let Grep_Skip_Files = '*~ *,v s.*'
endif

" Run the grep commands asynchronously and update the quickfix list with the
" results in the background. Needs Vim version 8.0 and above.
if !exists('Grep_Run_Async')
    " Check whether we can run the grep command asynchronously.
    if v:version >= 800
	let Grep_Run_Async = 1
	" Check whether we can use the quickfix identifier to add the grep
	" output to a specific quickfix list.
	if has('patch-8.0.1023')
	    let s:Grep_Use_QfID = 1
	else
	    let s:Grep_Use_QfID = 0
	endif
    else
	let Grep_Run_Async = 0
    endif
endif

" Table containing information about various grep commands.
"   command path, option prefix character, command options and the search
"   pattern expression option
let s:cmdTable = {
	    \   'grep' : {
	    \     'cmdpath' : g:Grep_Path,
	    \     'optprefix' : '-',
	    \     'cmdopt' : '-s -n',
	    \     'expropt' : '--',
	    \     'nulldev' : g:Grep_Null_Device
	    \   },
	    \   'fgrep' : {
	    \     'cmdpath' : g:Fgrep_Path,
	    \     'optprefix' : '-',
	    \     'cmdopt' : '-s -n',
	    \     'expropt' : '-e',
	    \     'nulldev' : g:Grep_Null_Device
	    \   },
	    \   'egrep' : {
	    \     'cmdpath' : g:Egrep_Path,
	    \     'optprefix' : '-',
	    \     'cmdopt' : '-s -n',
	    \     'expropt' : '-e',
	    \     'nulldev' : g:Grep_Null_Device
	    \   },
	    \   'agrep' : {
	    \     'cmdpath' : g:Agrep_Path,
	    \     'optprefix' : '-',
	    \     'cmdopt' : '-n',
	    \     'expropt' : '',
	    \     'nulldev' : g:Grep_Null_Device
	    \   },
	    \   'ag' : {
	    \     'cmdpath' : g:Ag_Path,
	    \     'optprefix' : '-',
	    \     'cmdopt' : '--vimgrep',
	    \     'expropt' : '',
	    \     'nulldev' : ''
	    \   },
	    \   'rg' : {
	    \     'cmdpath' : g:Rg_Path,
	    \     'optprefix' : '-',
	    \     'cmdopt' : '--vimgrep',
	    \     'expropt' : '-e',
	    \     'nulldev' : ''
	    \   },
	    \   'ack' : {
	    \     'cmdpath' : g:Ack_Path,
	    \     'optprefix' : '-',
	    \     'cmdopt' : '-H --column --nofilter --nocolor --nogroup',
	    \     'expropt' : '--match',
	    \     'nulldev' : ''
	    \   },
	    \   'findstr' : {
	    \     'cmdpath' : g:Findstr_Path,
	    \     'optprefix' : '/',
	    \     'cmdopt' : '/N',
	    \     'expropt' : '',
	    \     'nulldev' : ''
	    \   },
	    \   'git' : {
	    \     'cmdpath' : g:Git_Path,
	    \     'optprefix' : '-',
	    \     'cmdopt' : 'grep --no-color -n',
	    \     'expropt' : '-e',
	    \     'nulldev' : ''
	    \   }
	    \ }

" warnMsg
" Display a warning message
function! s:warnMsg(msg)
    echohl WarningMsg | echomsg a:msg | echohl None
endfunction

let s:grep_cmd_job = 0
let s:grep_tempfile = ''

" deleteTempFile()
" Delete the temporary file created on MS-Windows to run the grep command
function! s:deleteTempFile()
    if has('win32') && !has('win32unix') && (&shell =~ 'cmd.exe')
	if exists('s:grep_tempfile') && s:grep_tempfile != ''
	    " Delete the temporary cmd file created on MS-Windows
	    call delete(s:grep_tempfile)
	    let s:grep_tempfile = ''
	endif
    endif
endfunction

" grep#cmd_output_cb()
" Add output (single line) from a grep command to the quickfix list
function! grep#cmd_output_cb(qf_id, channel, msg)
    let job = ch_getjob(a:channel)
    if job_status(job) == 'fail'
	call s:warnMsg('Error: Job not found in grep command output callback')
	return
    endif

    " Check whether the quickfix list is still present
    if s:Grep_Use_QfID
	let l = getqflist({'id' : a:qf_id})
	if !has_key(l, 'id') || l.id == 0
	    " Quickfix list is not present. Stop the search.
	    call job_stop(job)
	    return
	endif

	call setqflist([], 'a', {'id' : a:qf_id,
		    \ 'efm' : '%f:%\\s%#%l:%c:%m,%f:%\s%#%l:%m',
		    \ 'lines' : [a:msg]})
    else
	let old_efm = &efm
	set efm=%f:%\\s%#%l:%c:%m,%f:%\\s%#%l:%m
	caddexpr a:msg . "\n"
	let &efm = old_efm
    endif
endfunction

" grep#chan_close_cb
" Close callback for the grep command channel. No more grep output is
" available.
function! grep#chan_close_cb(qf_id, channel)
    let job = ch_getjob(a:channel)
    if job_status(job) == 'fail'
	call s:warnMsg('Error: Job not found in grep channel close callback')
	return
    endif
    let emsg = '[Search command exited with status ' . job_info(job).exitval . ']'

    " Check whether the quickfix list is still present
    if s:Grep_Use_QfID
	let l = getqflist({'id' : a:qf_id})
	if has_key(l, 'id') && l.id == a:qf_id
	    call setqflist([], 'a', {'id' : a:qf_id,
			\ 'efm' : '%f:%\s%#%l:%m',
			\ 'lines' : [emsg]})
	endif
    else
	caddexpr emsg
    endif
endfunction

" grep#cmd_exit_cb()
" grep command exit handler
function! grep#cmd_exit_cb(qf_id, job, exit_status)
    " Process the exit status only if the grep cmd is not interrupted
    " by another grep invocation
    if s:grep_cmd_job == a:job
	let s:grep_cmd_job = 0
	call s:deleteTempFile()
    endif
endfunction

" runGrepCmdAsync()
" Run the grep command asynchronously
function! s:runGrepCmdAsync(cmd, pattern, action)
    if s:grep_cmd_job isnot 0
	" If the job is already running for some other search, stop it.
	call job_stop(s:grep_cmd_job)
	caddexpr '[Search command interrupted]'
    endif

    let title = '[Search results for ' . a:pattern . ']'
    if a:action == 'add'
	caddexpr title . "\n"
    else
	cexpr title . "\n"
    endif
    "caddexpr 'Search cmd: "' . a:cmd . '"'
    call setqflist([], 'a', {'title' : title})
    " Save the quickfix list id, so that the grep output can be added to
    " the correct quickfix list
    let l = getqflist({'id' : 0})
    if has_key(l, 'id')
	let qf_id = l.id
    else
	let qf_id = -1
    endif

    if has('win32') && !has('win32unix') && (&shell =~ 'cmd.exe')
	let cmd_list = [a:cmd]
    else
	let cmd_list = ['/bin/sh', '-c', a:cmd]
    endif
    let s:grep_cmd_job = job_start(cmd_list,
		\ {'callback' : function('grep#cmd_output_cb', [qf_id]),
		\ 'close_cb' : function('grep#chan_close_cb', [qf_id]),
		\ 'exit_cb' : function('grep#cmd_exit_cb', [qf_id]),
		\ 'in_io' : 'null'})

    if job_status(s:grep_cmd_job) == 'fail'
	let s:grep_cmd_job = 0
	call s:warnMsg('Error: Failed to start the grep command')
	call s:deleteTempFile()
	return
    endif

    " Open the grep output window
    if g:Grep_OpenQuickfixWindow == 1
	" Open the quickfix window below the current window
	botright copen
    endif
endfunction

" runGrepCmd()
" Run the specified grep command using the supplied pattern
function! s:runGrepCmd(cmd, pattern, action)
    if has('win32') && !has('win32unix') && (&shell =~ 'cmd.exe')
	" Windows does not correctly deal with commands that have more than 1
	" set of double quotes.  It will strip them all resulting in:
	" 'C:\Program' is not recognized as an internal or external command
	" operable program or batch file.  To work around this, place the
	" command inside a batch file and call the batch file.
	" Do this only on Win2K, WinXP and above.
	let s:grep_tempfile = fnamemodify(tempname(), ':h:8') . '\mygrep.cmd'
	call writefile(['@echo off', a:cmd], s:grep_tempfile)

	if g:Grep_Run_Async
	    call s:runGrepCmdAsync(s:grep_tempfile, a:pattern, a:action)
	    return
	endif
	let cmd_output = system('"' . s:grep_tempfile . '"')

	if exists('s:grep_tempfile')
	    " Delete the temporary cmd file created on MS-Windows
	    call delete(s:grep_tempfile)
	endif
    else
	if g:Grep_Run_Async
	    return s:runGrepCmdAsync(a:cmd, a:pattern, a:action)
	endif
	let cmd_output = system(a:cmd)
    endif

    " Do not check for the shell_error (return code from the command).
    " Even if there are valid matches, grep returns error codes if there
    " are problems with a few input files.

    if cmd_output == ''
	call s:warnMsg('Error: Pattern ' . a:pattern . ' not found')
	return
    endif

    let tmpfile = tempname()

    let old_verbose = &verbose
    set verbose&vim

    exe 'redir! > ' . tmpfile
    silent echon '[Search results for pattern: ' . a:pattern . "]\n"
    silent echon cmd_output
    redir END

    let &verbose = old_verbose

    let old_efm = &efm
    set efm=%f:%\\s%#%l:%c:%m,%f:%\\s%#%l:%m

    if a:action == 'add'
	execute 'silent! caddfile ' . tmpfile
    else
	execute 'silent! cgetfile ' . tmpfile
    endif

    let &efm = old_efm

    " Open the grep output window
    if g:Grep_OpenQuickfixWindow == 1
	" Open the quickfix window below the current window
	botright copen
    endif

    call delete(tmpfile)
endfunction

" parseArgs()
" Parse arguments to the grep command. The expected order for the various
" arguments is:
" 	<grep_option[s]> <search_pattern> <file_pattern[s]>
" grep command-line flags are specified using the "-flag" format.
" the next argument is assumed to be the pattern.
" and the next arguments are assumed to be filenames or file patterns.
function! s:parseArgs(cmd_name, args)
    let cmdopt    = ''
    let pattern     = ''
    let filepattern = ''

    let optprefix = s:cmdTable[a:cmd_name].optprefix

    for one_arg in a:args
	if one_arg[0] == optprefix && pattern == ''
	    " Process grep arguments at the beginning of the argument list
	    let cmdopt = cmdopt . ' ' . one_arg
	elseif pattern == ''
	    " Only one search pattern can be specified
	    let pattern = shellescape(one_arg)
	else
	    " More than one file patterns can be specified
	    if filepattern != ''
		let filepattern = filepattern . ' ' . one_arg
	    else
		let filepattern = one_arg
	    endif
	endif
    endfor

    if cmdopt == ''
	let cmdopt = g:Grep_Default_Options
    endif

    return [cmdopt, pattern, filepattern]
endfunction

" recursive_search_cmd
" Returns TRUE if a command recursively searches by default.
function! s:recursive_search_cmd(cmd_name)
    return a:cmd_name == 'ag' ||
		\ a:cmd_name == 'rg' ||
		\ a:cmd_name == 'ack' ||
		\ a:cmd_name == 'git'
endfunction

" formFullCmd()
" Generate the full command to run based on the user supplied command name,
" options, pattern and file names.
function! s:formFullCmd(cmd_name, useropts, pattern, filenames)
    if !has_key(s:cmdTable, a:cmd_name)
	call s:warnMsg('Error: Unsupported command ' . a:cmd_name)
	return ''
    endif

    if has('win32')
	" On MS-Windows, convert the program pathname to 8.3 style pathname.
	" Otherwise, using a path with space characters causes problems.
	let s:cmdTable[a:cmd_name].cmdpath =
		    \ fnamemodify(s:cmdTable[a:cmd_name].cmdpath, ':8')
    endif

    let fullcmd = s:cmdTable[a:cmd_name].cmdpath . ' ' .
		\ s:cmdTable[a:cmd_name].cmdopt . ' ' . a:useropts . ' ' .
		\ s:cmdTable[a:cmd_name].expropt . ' ' .
		\ a:pattern . ' ' . a:filenames . ' ' .
		\ s:cmdTable[a:cmd_name].nulldev

    return fullcmd
endfunction

" getListOfBufferNames()
" Get the file names of all the listed and valid buffer names 
function! s:getListOfBufferNames()
    let filenames = ''

    " Get a list of all the buffer names
    for i in range(1, bufnr("$"))
	if bufexists(i) && buflisted(i)
	    let fullpath = fnamemodify(bufname(i), ':p')
	    if filereadable(fullpath)
		if v:version >= 702
		    let filenames = filenames . ' ' . fnameescape(fullpath)
		else
		    let filenames = filenames . ' ' . fullpath
		endif
	    endif
	endif
    endfor

    return filenames
endfunction

" getListOfArgFiles()
" Get the names of all the files in the argument list
function! s:getListOfArgFiles()
    let filenames = ''

    let arg_cnt = argc()
    if arg_cnt != 0
	for i in range(0, arg_cnt - 1)
	    let filenames = filenames . ' ' . argv(i)
	endfor
    endif

    return filenames
endfunction

" grep#runGrepRecursive()
" Run specified grep command recursively
function! grep#runGrepRecursive(cmd_name, grep_cmd, action, ...)
    if a:0 > 0 && (a:1 == '-?' || a:1 == '-h')
	echo 'Usage: ' . a:cmd_name . ' [<grep_options>] [<search_pattern> ' .
		    \ '[<file_name(s)>]]'
	return
    endif

    " Parse the arguments and get the grep options, search pattern
    " and list of file names/patterns
    let [opts, pattern, filenames] = s:parseArgs(a:grep_cmd, a:000)

    " No argument supplied. Get the identifier and file list from user
    if pattern == '' 
	let pattern = input('Search for pattern: ', expand('<cword>'))
	if pattern == ''
	    return
	endif
	let pattern = shellescape(pattern)
	echo "\r"
    endif

    let cwd = getcwd()
    if g:Grep_Cygwin_Find == 1
	let cwd = substitute(cwd, "\\", "/", 'g')
    endif
    let startdir = input('Start searching from directory: ', cwd, 'dir')
    if startdir == ''
	return
    endif
    echo "\r"

    if startdir == cwd
	let startdir = '.'
    endif

    if filenames == ''
	let filenames = input('Search in files matching pattern: ', 
		    \ g:Grep_Default_Filelist)
	if filenames == ''
	    return
	endif
	echo "\r"
    endif

    let find_file_pattern = ''
    for one_pattern in split(filenames, ' ')
	if find_file_pattern != ''
	    let find_file_pattern = find_file_pattern . ' -o'
	endif
	let find_file_pattern = find_file_pattern . ' -name ' .
		    \ shellescape(one_pattern)
    endfor
    let find_file_pattern = g:Grep_Shell_Escape_Char . '(' .
		\ find_file_pattern . ' ' . g:Grep_Shell_Escape_Char . ')'

    let find_prune = ''
    if g:Grep_Skip_Dirs != ''
	for one_dir in split(g:Grep_Skip_Dirs, ' ')
	    if find_prune != ''
		let find_prune = find_prune . ' -o'
	    endif
	    let find_prune = find_prune . ' -name ' .
			\ shellescape(one_dir)
	endfor

	let find_prune = '-type d ' . g:Grep_Shell_Escape_Char . '(' .
		    \ find_prune . ' ' . g:Grep_Shell_Escape_Char . ')'
    endif

    let find_skip_files = '-type f'
    for one_file in split(g:Grep_Skip_Files, ' ')
	let find_skip_files = find_skip_files . ' ! -name ' .
		    \ shellescape(one_file)
    endfor

    " On MS-Windows, convert the find/xargs program path to 8.3 style path
    if has('win32')
	let g:Grep_Find_Path = fnamemodify(g:Grep_Find_Path, ':8')
	let g:Grep_Xargs_Path = fnamemodify(g:Grep_Xargs_Path, ':8')
    endif

    if g:Grep_Find_Use_Xargs == 1
	let grep_cmd = s:formFullCmd(a:grep_cmd, opts, pattern, '')
	let cmd = g:Grep_Find_Path . ' "' . startdir . '"'
		    \ . ' ' . find_prune . " -prune -o"
		    \ . ' ' . find_skip_files
		    \ . ' ' . find_file_pattern
		    \ . " -print0 | "
		    \ . g:Grep_Xargs_Path . ' ' . g:Grep_Xargs_Options
		    \ . ' ' . grep_cmd
    else
	let grep_cmd = s:formFullCmd(a:grep_cmd, opts, pattern, '{}')
	let cmd = g:Grep_Find_Path . ' ' . startdir
		    \ . ' ' . find_prune . " -prune -o"
		    \ . ' ' . find_skip_files
		    \ . ' ' . find_file_pattern
		    \ . " -exec " . grep_cmd . ' ' .
		    \ g:Grep_Shell_Escape_Char . ';'
    endif

    call s:runGrepCmd(cmd, pattern, a:action)
endfunction

" grep#runGrepSpecial()
" Search for a pattern in all the opened buffers or filenames in the
" argument list
function! grep#runGrepSpecial(cmd_name, which, action, ...)
    if a:0 > 0 && (a:1 == '-?' || a:1 == '-h')
	echo 'Usage: ' . a:cmd_name . ' [<grep_options>] [<search_pattern>]'
	return
    endif

    " Search in all the Vim buffers
    if a:which == 'buffer'
	let filenames = s:getListOfBufferNames()
	" No buffers
	if filenames == ''
	    call s:warnMsg('Error: Buffer list is empty')
	    return
	endif
    elseif a:which == 'args'
	" Search in all the filenames in the argument list
	let filenames = s:getListOfArgFiles()
	" No arguments
	if filenames == ''
	    call s:warnMsg('Error: Argument list is empty')
	    return
	endif
    endif

    " Parse the arguments and get the command line options and pattern.
    " Filenames are not be supplied and should be ignored.
    let [opts, pattern, temp] = s:parseArgs(a:grep_cmd, a:000)

    if pattern == ''
	" No argument supplied. Get the identifier and file list from user
	let pattern = input('Search for pattern: ', expand('<cword>'))
	if pattern == ''
	    return
	endif
	echo "\r"
    endif

    " Form the complete command line and run it
    let cmd = s:formFullCmd('grep', opts, pattern, filenames)
    call s:runGrepCmd(cmd, pattern, a:action)
endfunction

" grep#runGrep()
" Run the specified grep command
function! grep#runGrep(cmd_name, grep_cmd, action, ...)
    if a:0 > 0 && (a:1 == '-?' || a:1 == '-h')
	echo 'Usage: ' . a:cmd_name . ' [<grep_options>] [<search_pattern> ' .
		    \ '[<file_name(s)>]]'
	return
    endif

    " Parse the arguments and get the grep options, search pattern
    " and list of file names/patterns
    let [opts, pattern, filenames] = s:parseArgs(a:grep_cmd, a:000)

    " Get the identifier and file list from user
    if pattern == '' 
	let pattern = input('Search for pattern: ', expand('<cword>'))
	if pattern == ''
	    return
	endif
	let pattern = shellescape(pattern)
	echo "\r"
    endif

    if filenames == '' && !s:recursive_search_cmd(a:grep_cmd)
	let filenames = input('Search in files: ', g:Grep_Default_Filelist,
		    \ 'file')
	if filenames == ''
	    return
	endif
	echo "\r"
    endif

    " Form the complete command line and run it
    let cmd = s:formFullCmd(a:grep_cmd, opts, pattern, filenames)
    call s:runGrepCmd(cmd, pattern, a:action)
endfunction

" restore 'cpo'
let &cpo = s:cpo_save
unlet s:cpo_save
