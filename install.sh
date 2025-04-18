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

# Hide everthing from the dock
defaults write "com.apple.dock" "persistent-apps" -array

# turn off natural scroll
defaults -currentHost write -g com.apple.swipescrolldirection -bool false

# Remap capslock to control on the default keyboard
defaults -currentHost write -g com.apple.keyboard.modifiermapping '({                                                                
    HIDKeyboardModifierMappingDst = 30064771300;
    HIDKeyboardModifierMappingSrc = 30064771129;
})'

killall Dock

