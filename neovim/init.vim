let plug_install = 0
let autoload_plug_path = '~/.vim/autoload/plug.vim'
if empty(glob(autoload_plug_path))
    silent exe '!curl -fL --create-dirs -o ' . autoload_plug_path .
        \ ' https://raw.github.com/junegunn/vim-plug/master/plug.vim'
    let plug_install = 1
endif
unlet autoload_plug_path

set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath

if plug_install
    source ~/.vimrc
    PlugInstall --sync
endif
source ~/.vimrc

unlet plug_install
