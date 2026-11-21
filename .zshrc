# Portable zsh config for CTF / Attack-Defence.
# Everything is optional: the shell works even if none of the tools are installed.

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
export DOTFILES_DIR="${${(%):-%x}:P:h}"
export PATH="$HOME/.local/bin:$PATH"

# Homebrew (macOS and Linuxbrew)
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Go binaries, if Go is installed
if command -v go >/dev/null 2>&1; then
    export PATH="$PATH:$(go env GOPATH 2>/dev/null)/bin"
fi

# ---------------------------------------------------------------------------
# History
# ---------------------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt HIST_IGNORE_SPACE HIST_IGNORE_DUPS HIST_REDUCE_BLANKS
setopt HIST_SAVE_NO_DUPS HIST_EXPIRE_DUPS_FIRST HIST_FIND_NO_DUPS
setopt SHARE_HISTORY

# Prefix a command with a space to keep it out of history (useful for tokens).

# ---------------------------------------------------------------------------
# Shell behaviour
# ---------------------------------------------------------------------------
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT
setopt EXTENDED_GLOB INTERACTIVE_COMMENTS NO_BEEP MULTIOS
setopt PIPE_FAIL PROMPT_SUBST TRANSIENT_RPROMPT
setopt COMPLETE_IN_WORD ALWAYS_TO_END AUTO_MENU
unsetopt FLOW_CONTROL

KEYTIMEOUT=1
REPORTTIME=10

# ---------------------------------------------------------------------------
# Completion
# ---------------------------------------------------------------------------
autoload -Uz compinit
compinit -i

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list \
    'm:{a-zA-Z}={A-Za-z}' \
    'r:|[._-]=* r:|=*' \
    'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}%d%f'
zstyle ':completion:*:warnings' format '%F{red}no matches%f'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compcache"
[[ -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compcache" ]] || \
    mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compcache"

# Bash-style completions for tools that ship them.
autoload -Uz bashcompinit 2>/dev/null && bashcompinit 2>/dev/null

# ---------------------------------------------------------------------------
# Optional integrations (only if installed)
# ---------------------------------------------------------------------------
if [[ -t 0 ]] && command -v fzf >/dev/null 2>&1; then
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
    if command -v fd >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
    elif command -v fdfind >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --exclude .git'
    fi
    if fzf --zsh >/dev/null 2>&1; then
        source <(fzf --zsh)
    elif [[ -f /usr/share/fzf/completion.zsh ]]; then
        source /usr/share/fzf/completion.zsh
        [[ -f /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
    elif [[ -f "$HOME/.fzf.zsh" ]]; then
        source "$HOME/.fzf.zsh"
    fi
fi

command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"

if command -v pyenv >/dev/null 2>&1; then
    export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
    command -v pyenv-virtualenv-init >/dev/null 2>&1 && eval "$(pyenv virtualenv-init -)"
fi

# Optional: set DOTFILES_USE_OMZ=1 to load Oh My Zsh. The prompt below still wins.
if [[ "${DOTFILES_USE_OMZ:-0}" == "1" && -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
    export ZSH="$HOME/.oh-my-zsh"
    ZSH_THEME=""
    plugins=(git)
    source "$ZSH/oh-my-zsh.sh"
fi

# ---------------------------------------------------------------------------
# Prompt
# ---------------------------------------------------------------------------
__dotfiles_git_branch() {
    local branch
    branch=$(command git symbolic-ref --quiet --short HEAD 2>/dev/null) ||
        branch=$(command git rev-parse --short HEAD 2>/dev/null) || return 0
    [[ -n "$branch" ]] || return 0
    branch=${branch//\%/%%}
    printf ' %%F{magenta} %s%%f' "$branch"
}

__dotfiles_venv() {
    [[ -n "${VIRTUAL_ENV:-}" ]] || return 0
    printf ' %%F{blue}(%s)%%f' "${VIRTUAL_ENV:t}"
}

__dotfiles_ssh() {
    [[ -n "${SSH_CONNECTION:-}" ]] && printf '%%F{yellow}[ssh]%%f '
}

PROMPT='%F{green}%n@%m%f %F{blue}%~%f$(__dotfiles_git_branch)$(__dotfiles_venv)
%(?..%F{red}[%?] %f)%F{cyan}❯%f '
RPROMPT='$(__dotfiles_ssh)'

# ---------------------------------------------------------------------------
# Key bindings
# ---------------------------------------------------------------------------
if [[ -t 0 ]]; then
    bindkey -e
    bindkey '^[[A' up-line-or-history
    bindkey '^[[B' down-line-or-history
    bindkey '^[[H' beginning-of-line
    bindkey '^[[F' end-of-line
    bindkey '^[[3~' delete-char
    bindkey '^[[Z' reverse-menu-complete
    bindkey '^[[1;5C' forward-word
    bindkey '^[[1;5D' backward-word
    autoload -Uz edit-command-line
    zle -N edit-command-line
    bindkey '^X^E' edit-command-line
fi

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
[[ -f "$HOME/.ripgreprc" ]] && export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

# ---------------------------------------------------------------------------
# Shared aliases / helpers
# ---------------------------------------------------------------------------
DOTFILES_COMMON="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/common.sh"
[[ -f "$DOTFILES_COMMON" ]] && source "$DOTFILES_COMMON"

# ---------------------------------------------------------------------------
# Local overrides (not part of the repo)
# ---------------------------------------------------------------------------
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
