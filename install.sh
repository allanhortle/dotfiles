#!/usr/bin/env zsh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval $(/opt/homebrew/bin/brew shellenv)

brew bundle 
brew cleanup
stow dotfiles --no-folding
source ~/.zshrc

