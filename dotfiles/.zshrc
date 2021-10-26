# Brew Completions
if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
fi


autoload -U compinit
autoload -U colors && colors
autoload -Uz vcs_info
compinit -i


unsetopt correct_all  
setopt correct
setopt auto_cd



#
# Prompt
# 

# colors
b="%{$fg[blue]%}"
g="%{$fg[green]%}"
r="%{$fg[red]%}"
y="%{$fg[yellow]%}"

main_prompt() {
    local pathPrompt="%~  "
    local extraPrompt="$(puffin_prmpt_extra &>/dev/null && puffin_prompt_extra)"
    PROMPT="${b}${pathPrompt}${g}${vcs_info_msg_0_}${y}${extraPrompt}${y}%D{%R}${b}
=>%{$reset_color%} "
} 

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:git*' formats "%b%m  "
zstyle ':vcs_info:git*' actionformats "%a%b%m  "
zstyle ':vcs_info:*+*:*' debug false
zstyle ':vcs_info:git*+set-message:*' hooks git-extras

git_changes() {
    local NUM="$(echo $1 | grep $2 | wc -l | xargs echo)"
    if [[ "$NUM" -gt 0 ]]; then
        echo "$3$NUM"
    fi
}

function +vi-git-extras(){
    local changes=$(git status --short --branch -u 2> /dev/null);
    local STAGED=""
    local MISC=""
    local UNSTAGED=""

    # Staged
    STAGED+="$(git_changes "${changes}" "^[AC]" "+")"
    STAGED+="$(git_changes "${changes}" "^M" "~")"
    STAGED+="$(git_changes "${changes}" "^D" "-")"
    STAGED+="$(git_changes "${changes}" "^R" ">")"
    if [[ -n $STAGED ]]; then
        hook_com[misc]+=" [${STAGED}]"
    fi

    # Unstaged
    UNSTAGED+="$(git_changes "${changes}" "^.M" "~")"
    UNSTAGED+="$(git_changes "${changes}" "^.D" "-")"
    UNSTAGED+="$(git_changes "${changes}" "^??" "?")"
    if [[ -n $UNSTAGED ]]; then
        hook_com[misc]+=" $UNSTAGED";
    fi

    # Ahead/Behind/Conficts
    #local NUM_AHEAD="$(git log --oneline @{u}.. 2> /dev/null | wc -l | xargs echo)"
    local NUM_AHEAD=$(echo $changes | head -1 | pcregrep -io1 "ahead (\d+)")
    if [ "$NUM_AHEAD" -gt 0 ]; then
        hook_com[misc]+=" ⬆ $NUM_AHEAD"
    fi

    #local NUM_BEHIND="$(git log --oneline ..@{u} 2> /dev/null | wc -l | xargs echo)"
    local NUM_BEHIND=$(echo $changes | head -1 | pcregrep -io1 "behind (\d+)")
    if [ "$NUM_BEHIND" -gt 0 ]; then
        hook_com[misc]+=" ⬇ $NUM_BEHIND"
    fi

    MISC+="$(git_changes "${changes}" '^UU' "${r}✕")"
    if [[ -n $MISC ]]; then
        hook_com[misc]+=" ${MISC}"
    fi
}

zstyle ':completion:*' verbose yes
zstyle ':completion:*' menu select
#zstyle ':completion:*' list-colors 'di=34:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format "$fg[yellow]%B[%d]%b"
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format "$fg[red]No matches for:$reset_color %d"
zstyle ':completion:*:corrections' format '%B%d (errors: %e)%b'
zstyle ':completion:*' group-name ''
zstyle ':completion:::::' completer _complete _approximate
zstyle ':completion:*:approximate:*' max-errors 2

precmd() {
    vcs_info;
    main_prompt;
}

#
# Environment
# 

eval "$(fasd --init auto)"
eval "$(fnm env --use-on-cd)"
export CLICOLOR=1
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git"'
export FZF_DEFAULT_OPTS='--color=16,bg+:-1,pointer:2,prompt:2,hl+:2,hl:2,fg+:2'
export EDITOR="/usr/local/bin/vim"


#
# Functions
#

# Tell me how slow my shell is
timezsh() {
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
z() {
  [ $# -gt 0  ] && fasd_cd -d "$*" && return
    cd "$(fasd_cd -d 2>&1 | fzf --height 40% --reverse --inline-info +s --tac --query "$*" | sed 's/^[0-9,.]* *//')"

}

root() {
    cd ...
    "$@"
    cd - 
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
alias album="vd ~/Dropbox/data/albums.csv"

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
alias l='ls -lFh' 


# Machine Specifig Config
if [ -f ~/.zshrc.local ]; then
    source ~/.zshrc.local
fi
