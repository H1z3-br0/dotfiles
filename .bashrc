# Portable bash config for CTF / Attack-Defence.
# The interactive part is intentionally close to .zshrc.

# Non-interactive shells do not need aliases or prompts.
[ -z "$PS1" ] && return

export PATH="$HOME/.local/bin:$PATH"

# Homebrew (macOS and Linuxbrew)
if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

if command -v go >/dev/null 2>&1; then
    export PATH="$PATH:$(go env GOPATH 2>/dev/null)/bin"
fi

# ---------------------------------------------------------------------------
# History
# ---------------------------------------------------------------------------
HISTCONTROL=ignoreboth:erasedups
HISTSIZE=100000
HISTFILESIZE=200000
shopt -s histappend checkwinsize 2>/dev/null
shopt -s cdspell dirspell 2>/dev/null || true
shopt -s globstar 2>/dev/null || true
set -o pipefail 2>/dev/null

# ---------------------------------------------------------------------------
# Completion and line editing
# ---------------------------------------------------------------------------
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

if [ -t 0 ]; then
    bind 'set completion-ignore-case on' 2>/dev/null
    bind 'set show-all-if-ambiguous on' 2>/dev/null
    bind '"\e[A": history-search-backward' 2>/dev/null
    bind '"\e[B": history-search-forward' 2>/dev/null
    bind 'set enable-bracketed-paste on' 2>/dev/null
fi

if [ -t 0 ] && command -v fzf >/dev/null 2>&1; then
    if fzf --bash >/dev/null 2>&1; then
        eval "$(fzf --bash)"
    fi
fi

command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init bash)"
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook bash)"

if command -v pyenv >/dev/null 2>&1; then
    export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi

# ---------------------------------------------------------------------------
# Prompt
# ---------------------------------------------------------------------------
__dotfiles_git_branch() {
    local branch
    branch=$(command git symbolic-ref --quiet --short HEAD 2>/dev/null) ||
        branch=$(command git rev-parse --short HEAD 2>/dev/null) || return 0
    [ -n "$branch" ] && printf ' (%s)' "$branch"
}

__dotfiles_venv() {
    [ -n "$VIRTUAL_ENV" ] && printf ' (%s)' "${VIRTUAL_ENV##*/}"
}

PS1='\[\e[32m\]\u@\h\[\e[0m\] \[\e[34m\]\w\[\e[0m\]$(__dotfiles_git_branch)$(__dotfiles_venv)\n\[\e[36m\]\$\[\e[0m\] '
PROMPT_DIRTRIM=2

# ---------------------------------------------------------------------------
# Editor / pager / Python
# ---------------------------------------------------------------------------
if command -v nvim >/dev/null 2>&1; then
    export EDITOR=nvim VISUAL=nvim
else
    export EDITOR=vim VISUAL=vim
fi
export PAGER=less
export LESS='-R -F -X -i -M'
export MANPAGER='less -R'

export PYTHONUNBUFFERED=1
export PYTHONDONTWRITEBYTECODE=1
export CTF_ROOT="${CTF_ROOT:-$HOME/ctf}"
[ -f "$HOME/.ripgreprc" ] && export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

# ---------------------------------------------------------------------------
# Shared aliases / helpers
# ---------------------------------------------------------------------------
DOTFILES_COMMON="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/common.sh"
[ -f "$DOTFILES_COMMON" ] && . "$DOTFILES_COMMON"

# ---------------------------------------------------------------------------
# Local overrides
# ---------------------------------------------------------------------------
[ -f "$HOME/.bashrc.local" ] && . "$HOME/.bashrc.local"
