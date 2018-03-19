scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


function! s:_vital_loaded(V)
	let s:V = a:V
	let s:List = s:V.import("Data.List")
endfunction


function! s:_vital_depends()
	return [
\		"Data.List",
\	]
endfunction


function! s:_clamp(x, max, min)
	return min([max([a:x, a:max]), a:min])
endfunction


let s:base = {}

function! s:base.set(item)
	return type(a:item) == type("") ? self.set_str(a:item)
\		 : type(a:item) == type(0)  ? self.set_pos(a:item)
\		 : self
endfunction

function! s:base.str()
	return join(self.list, "")
endfunction

function! s:base.set_pos(pos)
	let self.col = s:_clamp(a:pos, 0, self.length())
	return self
endfunction

function! s:base.backward()
	return self.col > 0 ? join(self.list[ : self.col-1], '') : ""
endfunction

function! s:base.forward()
	return join(self.list[self.col+1 : ], '')
endfunction

function! s:base.pos_char()
	return get(self.list, self.col, "")
endfunction

function! s:base.set_str(str)
	let self.list = split(a:str, '\zs')
	let self.col  = strchars(a:str, 1)
	return self
endfunction

function! s:base.pos()
	return self.col
endfunction

function! s:base.input(str)
	call extend(self.list, split(a:str, '\zs'), self.col)
	let self.col += len(split(a:str, '\zs'))
	return self
endfunction

function! s:base.length()
	return len(self.list)
endfunction

function! s:base.next()
	return self.set_pos(self.col + 1)
endfunction

function! s:base.prev()
	return self.set_pos(self.col - 1)
endfunction

function! s:base.remove(index)
	if a:index < 0 || self.length() <= a:index
		return ""
	endif
	let result = self.list[a:index]
	unlet self.list[a:index]
	if a:index < self.col
		call self.set(self.col - 1)
	endif
	return result
endfunction

function! s:base.remove_pos()
	return self.remove(self.col)
endfunction

function! s:base.remove_prev()
	return self.remove(self.col - 1)
endfunction

function! s:base.remove_next()
	return self.remove(self.col + 1)
endfunction


function! s:make(...)
	let default = get(a:, 1, "")
	let result = deepcopy(s:base)
	call result.set(default)
	return result
endfunction

" NOTE: old regexpengine has a bug with string which contains binary
" :echo "\x80" =~ "\\%#=1\x80"   | " => 0
" But it matches correctly with :h /collection
" :echo "\x80" =~ "\\%#=1[\x80]" | " => 1
" http://lingr.com/room/vim/archives/2015/02/13#message-21261450
let s:_engine = exists("+regexpengine") ? '\%#=2' : ''
" \<A-]> => Û\xfdQ
" \<A-@> => À\xfeX
let s:_regex = exists("+regexpengine")
\	? "\\%(Û\xfdQ\\|À\xfeX\\|\x80\xfc.\\%(\x80..\\|.\\)\\|\x80..\\|.\\)\\zs"
\	: "\\%(Û[\xfd]Q\\|À[\xfe]X\\|[\x80][\xfc].\\%([\x80]..\\|.\\)\\|[\x80]..\\|.\\)\\zs"
function! s:_split_keystring(str, ...)
	return split(a:str, s:_engine . '\m\%(' . get(a:, 1, '') . s:_regex . '\)')
endfunction

function! s:split_by_keys(str)
	return s:_split_keystring(a:str, "\\%(\<Plug>\\|<Over>\\)(.\\{-})\\zs\\|")
endfunction

function! s:index(haystack, needle, ...)
	let start = get(a:, 1, 0)
	let ignorecase = get(a:, 2, &ignorecase)
	if ignorecase
		return stridx(tolower(a:haystack), tolower(a:needle), start)
	else
		return stridx(a:haystack, a:needle, start)
	endif
endfunction


function! s:length(str)
	return len(s:split_by_keys(a:str))
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
