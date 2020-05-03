filetype off
filetype plugin indent on

syntax on
"?? set modelines=0
set wrap
set spell 

set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab
set noshiftround
set ttyfast

set autochdir

set showmode
set showcmd

set matchpairs+=<:>

set mouse=a

set number

if has('persistent_undo')      "check if your vim version supports it
  silent !mkdir -p $HOME/.vim/undo
  set undofile                 "turn on the feature  
  set undodir=$HOME/.vim/undo  "directory where the undo files will be stored
endif

"Change cursor when in insert mode
let &t_SI = "\e[5 q"
let &t_EI = "\e[2 q"
"" optional reset cursor on start:
"augroup myCmds
"au!
"autocmd VimEnter * silent !echo -ne "\e[2 q"
"augroup END

" Map Ctrl-Backspace to delete the previous word in insert mode.
imap <C-BS> <C-W>
set backspace=indent,eol,start
noremap! <C-BS> <C-w>
noremap! <C-h> <C-w>
inoremap <C-w> <C-\><C-o>dB
inoremap <C-BS> <C-\><C-o>db

" Map Ctrl-Del to delete next word in insert mode
imap <C-Del> <C-o>dw

"set clipboard+=unnamedplus

if filereadable(expand("~/.vim/vimrc.plug"))
	source ~/.vim/vimrc.plug
endif

augroup quickfix
    autocmd!
    autocmd QuickFixCmdPost [^l]* cwindow
    autocmd QuickFixCmdPost l* lwindow
augroup END

colorscheme gruvbox
set background=dark

"autocmd BufRead *.tex 
"autocmd BufRead *.tex set background=light
"vnoremap <C-b> "hy:%s/<C-b>h//gc<left><left><left>

vnoremap <C-r> "hy:%s/<C-r>h//gc<left><left><left>

"NerdTree
let NERDTreeMinimalUI = 1
nmap <leader>u :UndotreeShow<CR>
nnoremap <leader>pt :NERDTreeToggle<CR>
nnoremap <silent> <Leader>pv :NERDTreeFind<CR>

"Deoplete
let g:deoplete#enable_at_startup = 1
call deoplete#custom#option('auto_complete_popup', "manual")
"imap <silent><expr> <Tab> deoplete#complete()
imap <silent><expr> <C-Space> deoplete#complete()
set pyxversion=3

"YouCompleteMe
nnoremap <silent> <Leader>gd :YcmCompleter GoTo<CR>
nnoremap <silent> <Leader>gf :YcmCompleter FixIt<CR>
autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
autocmd FileType cuda set ft=cuda.c "https://github.com/ycm-core/YouCompleteMe/issues/1766
" DEBUG STUFFS
let g:ycm_server_keep_logfiles = 1
let g:ycm_server_log_level = 'debug'
let g:ycm_warning_symbol = '.'
let g:ycm_error_symbol = '..'
let g:ycm_server_use_vim_stdout = 1
" make YCM compatible with UltiSnips (using supertab)
"let g:ycm_key_list_select_completion = ['<C-n>', '<Down>']
"let g:ycm_key_list_previous_completion = ['<C-p>', '<Up>']
"let g:SuperTabDefaultCompletionType = '<C-n>'
let g:ycm_key_list_select_completion = []
let g:ycm_key_list_previous_completion = []
let g:SuperTabDefaultCompletionType = 0 
" better key bindings for UltiSnipsExpandTrigger
let g:UltiSnipsExpandTrigger = '<c-j>'
let g:UltiSnipsJumpForwardTrigger = '<tab>'
let g:UltiSnipsJumpBackwardTrigger = '<c-k>'
let g:UltiSnipsListSnippets="<c-l>"

" ag items.  I need the silent ag.
if executable('ag')
  " Use ag over grep "
  set grepprg=ag\ --nogroup\ --nocolor\ --column

  " Use ag in CtrlP for listing files. Lightning fast and respects .gitignore "
  let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'

  " ag is fast enough that CtrlP doesn't need to cache "
  let g:ctrlp_use_caching = 0
endif

"Windows management
map - <C-W>-
map + <C-W>+
nnoremap <silent> <Leader>r+ :vertical resize +5<CR>
nnoremap <silent> <Leader>r- :vertical resize -5<CR>
"nmap <leader>h :wincmd h<CR>
"nmap <leader>j :wincmd j<CR>
"nmap <leader>k :wincmd k<CR>
"nmap <leader>l :wincmd l<CR>


""vim-latex
"let g:tex_flavor = 'latex'
"let g:Tex_DefaultTargetFormat = 'pdf'
"let g:Tex_CompileRule_pdf = 'lualatex -shell-escape'
"let g:Tex_ViewRule_pdf = 'xpdf'
""latex preview
"let g:livepreview_previewer = 'open -a Preview'
