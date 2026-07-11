#!/usr/bin/env zsh

# Install brew
which -s brew
if [[ $? != 0 ]] ; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval $(/opt/homebrew/bin/brew shellenv)
else
    brew update
fi

brew bundle
stow dotfiles --no-folding
source ~/.zshrc
fnm install --latest

# Build tree-sitter parsers (replaces nvim-treesitter :TSUpdate)
./extras/install-parsers.sh

# Disable macOS font smoothing for ghostty (sharper text, matches alacritty)
defaults write com.mitchellh.ghostty AppleFontSmoothing -int 0

# Hide everthing from the dock
defaults write "com.apple.dock" "persistent-apps" -array

killall Dock

