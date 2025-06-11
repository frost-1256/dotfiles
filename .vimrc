packadd vim-jetpack
call jetpack#begin()
Jetpack 'tani/vim-jetpack', {'opt': 1} "bootstrap
Jetpack 'sainnhe/everforest' , { 'as': 'everforest' }
" Jetpack 'vim-airline/vim-airline'
Jetpack 'tpope/vim-fugitive'
Jetpack 'preservim/nerdtree'
call jetpack#end()
" Important!!
if has('termguicolors')
 set termguicolors
endif

" For dark version.
set background=dark
let g:everforest_background = 'medium'

let g:everforest_better_performance = 1

" let g:airline_theme = 'everforest'
"let g:lightline = {'colorscheme' : 'everforest'}

colorscheme everforest
nnoremap <C-q> :NERDTreeToggle<CR>
