#!/usr/bin/env zsh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval $(/opt/homebrew/bin/brew shellenv)

brew update

brew install gh
brew install fnm
brew install fzf
brew install git
brew install htop
brew install neovim
brew install node
brew install qlmarkdown
brew install qlstephen
brew install ripgrep
brew install saulpw/vd/visidata
brew install stow
brew install tig
brew install tmux
brew install vim
brew install yarn
brew install zoxide

brew cleanup

stow dotfiles --no-folding

source ~/.zshrc

# Python rubbish for nvim snippets
pip3 install pynvim

