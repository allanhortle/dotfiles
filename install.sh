#!/usr/bin/env zsh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval $(/opt/homebrew/bin/brew shellenv)

brew bundle 
stow dotfiles --no-folding
source ~/.zshrc

defaults write "com.apple.dock" "persistent-apps" -array
killall Dock

