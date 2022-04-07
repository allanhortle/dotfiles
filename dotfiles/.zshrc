# Brew Completions
if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
fi

autoload -U compinit
autoload -U colors && colors
autoload -Uz vcs_info
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
compinit -i

# History Search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search # Up
bindkey "^[[B" down-line-or-beginning-search # Down


unsetopt correct_all  
setopt extended_history
setopt correct
setopt auto_cd
setopt extended_history       # record timestamp of command in HISTFILE
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_verify            # show command with history expansion to user before running it
setopt share_history          # share command history data

[ -z "$HISTFILE" ] && HISTFILE="$HOME/.zsh_history"
[ "$HISTSIZE" -lt 50000 ] && HISTSIZE=50000
[ "$SAVEHIST" -lt 10000 ] && SAVEHIST=10000



#
# Prompt
# 
function zle-line-init zle-keymap-select {
    RPS1="${${KEYMAP/vicmd/${r}<<<}/(main|viins)/}"
    RPS2=$RPS1
    zle reset-prompt
}

zle -N zle-line-init
zle -N zle-keymap-select

# colors
b="%{$fg[blue]%}"
g="%{$fg[green]%}"
r="%{$fg[red]%}"
y="%{$fg[yellow]%}"

function main_prompt() {
    local pathPrompt="%~  "
    PROMPT="${b}${pathPrompt}${g}${vcs_info_msg_0_}${y}%D{%R}${b}
=>%{$reset_color%} "
} 

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:git*' formats "%b%m  "
zstyle ':vcs_info:git*' actionformats "%a%b%m  "
zstyle ':vcs_info:*+*:*' debug false
zstyle ':vcs_info:git*+set-message:*' hooks git-extras

zstyle ':completion:*' matcher-list '' \
  'm:{a-z\-}={A-Z\_}' \
  'r:[^[:alpha:]]||[[:alpha:]]=** r:|=* m:{a-z\-}={A-Z\_}' \
  'r:|?=** m:{a-z\-}={A-Z\_}'

function git_changes() {
    local num="$(echo $1 | grep $2 | wc -l | xargs echo)"
    if [[ "$num" -gt 0 ]]; then
        echo "$3$num"
    fi
}

function +vi-git-extras(){
    local changes=$(git status --short --branch -u 2> /dev/null);
    local staged=""
    local misc=""
    local unstaged=""

    # Staged
    staged+="$(git_changes "${changes}" "^[AC]" "+")"
    staged+="$(git_changes "${changes}" "^M" "~")"
    staged+="$(git_changes "${changes}" "^D" "-")"
    staged+="$(git_changes "${changes}" "^R" ">")"
    if [[ -n $staged ]]; then
        hook_com[misc]+=" [${staged}]"
    fi

    # Unstaged
    unstaged+="$(git_changes "${changes}" "^.M" "~")"
    unstaged+="$(git_changes "${changes}" "^.D" "-")"
    unstaged+="$(git_changes "${changes}" "^??" "?")"
    if [[ -n $unstaged ]]; then
        hook_com[misc]+=" $unstaged";
    fi

    # Ahead/Behind/Conficts
    local num_ahead=$(echo $changes | head -1 | pcregrep -io1 "ahead (\d+)")
    if [ "$num_ahead" -gt 0 ]; then
        hook_com[misc]+=" ⬆ $num_ahead"
    fi

    local num_behind=$(echo $changes | head -1 | pcregrep -io1 "behind (\d+)")
    if [ "$num_behind" -gt 0 ]; then
        hook_com[misc]+=" ⬇ $num_behind"
    fi

    misc+="$(git_changes "${changes}" '^UU' "${r}✕")"
    if [[ -n $misc ]]; then
        hook_com[misc]+=" ${misc}"
    fi
}

zstyle ':completion:*' verbose yes
zstyle ':completion:*' menu select
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format "$fg[yellow]%B[%d]%b"
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format "$fg[red]No matches for:$reset_color %d"
zstyle ':completion:*:corrections' format '%B%d (errors: %e)%b'
zstyle ':completion:*' group-name ''
zstyle ':completion:::::' completer _complete _approximate
zstyle ':completion:*:approximate:*' max-errors 2

function precmd() {
    vcs_info;
    main_prompt;
}

#
# Environment
# 

eval "$(fasd --init auto)"
eval "$(fnm env --fnm-dir=$HOME/.fnm --use-on-cd)"
export CLICOLOR=1
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git"'
export FZF_DEFAULT_OPTS='--color=16,bg+:-1,pointer:2,prompt:2,hl+:2,hl:2,fg+:2'
export EDITOR="/usr/local/bin/vim"
export HOMEBREW_NO_INSTALL_UPGRADE=1


#
# Functions
#

# Tell me how slow my shell is
function timezsh() {
    shell=${1-$SHELL}
    for i in $(seq 1 10); do /usr/bin/time $shell -i -c exit; done
}

# Find a process - http://onethingwell.org/post/14669173541/any
function any() {
    emulate -L zsh
    unsetopt KSH_ARRAYS
    if [[ -z "$1" ]] ; then
        echo "any - grep for process(es) by keyword" >&2
        echo "Usage: any " >&2 ; return 1
    else
        ps xauwww | grep -i --color=auto "[${1[1]}]${1[2,-1]}"
    fi
}

function weather() {
    bom hobart -p "%t°C"
}

unalias z 2> /dev/null
function z() {
  [ $# -gt 0  ] && fasd_cd -d "$*" && return
    cd "$(fasd_cd -d 2>&1 | fzf --height 40% --reverse --inline-info +s --tac --query "$*" | sed 's/^[0-9,.]* *//')"

}

function root() {
    cd ...
    "$@"
    cd - 
}

#
# Tmux
#
function tmux() {
    if [[ -n "$@" ]]; then
        command tmux "$@"
    else 
        tmux attach || tmux new
    fi
}


#
# Aliases
#

# Git
alias gb='git branch --sort=committerdate'
alias ga='git add -A :/'
alias gc='git commit'
alias gco='git checkout'
alias gf='git fetch -p'
alias gl='git pull'
alias gp='git push'
alias grb='git rebase'
alias grbc='git rebase --continue'
alias grba='git rebase --abort'
alias gmt='git mergetool'
alias gst='git status --short --branch'
alias gbmd='gb --merged | rg -v "(\*|master)" | xargs git branch -d'
alias monodiff='git diff --name-only origin/master... | grep "packages" | sed "s/packages\/\([^\/]*\).*/\1/g" | uniq'
alias monofiles='git diff --name-only origin/master...'

# Github
alias prs="gh pr status"
alias prc="gh pr create"
alias prl="gh pr list"
alias changes="gh pr diff | delta -s"

# data
alias music="vd --quitguard ~/Dropbox/data/albums.csv"
alias to='vim ~/Dropbox/bigdatr.md'

# npm
alias npm_patch_publish='npm version patch && git push --follow-tags && npm publish'
alias npm_minor_publish='npm version minor && git push --follow-tags && npm publish'

# tig
alias t='tig'
alias tst='tig status'

# tmux
alias tmrw='tmux rename-window'
alias tmrs='tmux rename-session'
alias tmn='tmux new'

# zsh
alias zr=". ~/.zshrc"
alias k='kill -9'
alias l='ls -lFha' 
alias vim='nvim'
#alias "-"='cd -'
alias ...="../.."



[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Machine Specifig Config
if [ -f ~/.zshrc.local ]; then
    source ~/.zshrc.local
fi

