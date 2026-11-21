# Shared aliases and helpers for zsh and bash.
# Sourced by ~/.zshrc and ~/.bashrc. Keep it compatible with both shells.

# ---------------------------------------------------------------------------
# ls / files
# ---------------------------------------------------------------------------
if ls --color=auto >/dev/null 2>&1; then
    alias ls='ls --color=auto'
else
    alias ls='ls -G'
fi

alias ll='ls -lah'
alias la='ls -lah'
alias l='ls -lah'
alias lt='ls -laht'
alias lr='ls -lahtr'

if printf 'x\n' | grep --color=auto x >/dev/null 2>&1; then
    alias grep='grep --color=auto'
fi

alias df='df -h'
alias du='du -h'
command -v free >/dev/null 2>&1 && alias free='free -h'
command -v htop >/dev/null 2>&1 && alias top='htop'

if command -v bat >/dev/null 2>&1; then
    alias bat='bat --style=plain --paging=never'
elif command -v batcat >/dev/null 2>&1; then
    alias bat='batcat --style=plain --paging=never'
fi

if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
    alias fd='fdfind'
fi

if command -v tree >/dev/null 2>&1; then
    alias tree='tree -C'
fi

# ---------------------------------------------------------------------------
# navigation / shell
# ---------------------------------------------------------------------------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias c='clear'
alias h='history'
alias j='jobs -l'
alias reload='exec "$SHELL" -l'
alias please='sudo'

if ! command -v open >/dev/null 2>&1 && command -v xdg-open >/dev/null 2>&1; then
    alias open='xdg-open'
fi

# ---------------------------------------------------------------------------
# editors / interpreters
# ---------------------------------------------------------------------------
if command -v nvim >/dev/null 2>&1; then
    alias v='nvim'
    alias vim='nvim'
else
    alias v='vim'
fi

if command -v python3 >/dev/null 2>&1; then
    command -v python >/dev/null 2>&1 || alias python='python3'
    command -v pip >/dev/null 2>&1 || alias pip='pip3'
    alias py='python3'
fi

# ---------------------------------------------------------------------------
# git
# ---------------------------------------------------------------------------
if command -v git >/dev/null 2>&1; then
    alias g='git'
    alias gs='git status -sb'
    alias gd='git diff'
    alias gds='git diff --stat'
    alias ga='git add'
    alias gc='git commit'
    alias gco='git checkout'
    alias gb='git branch'
    alias gl='git log --oneline --graph --decorate --all -30'
    alias gp='git push'
    alias gpl='git pull'
fi

# ---------------------------------------------------------------------------
# tmux
# ---------------------------------------------------------------------------
if command -v tmux >/dev/null 2>&1; then
    alias t='tmux'
    alias tl='tmux ls'
    ta() { tmux attach -t "${1:-ad}" 2>/dev/null || tmux new -s "${1:-ad}"; }
    tn() { tmux new -s "${1:-ad}"; }
    tk() { tmux kill-session -t "${1:-ad}"; }
fi

# ---------------------------------------------------------------------------
# networking / CTF helpers
# ---------------------------------------------------------------------------
mkcd() {
    [ -n "$1" ] || { echo "usage: mkcd DIR" >&2; return 1; }
    mkdir -p -- "$1" && cd -- "$1"
}

serve() {
    local port="${1:-8000}"
    if command -v python3 >/dev/null 2>&1; then
        python3 -m http.server "$port" --bind 0.0.0.0
    elif command -v python >/dev/null 2>&1; then
        python -m SimpleHTTPServer "$port"
    else
        echo "serve: python3 not found" >&2
        return 1
    fi
}

listen() {
    local port="${1:-4444}"
    if ! command -v nc >/dev/null 2>&1; then
        echo "listen: nc not found" >&2
        return 1
    fi
    if [ "$(uname -s)" = "Darwin" ]; then
        nc -lv "$port"
    elif nc -h 2>&1 | grep -qi 'openbsd'; then
        nc -lvnp "$port"
    else
        nc -lvp "$port"
    fi
}

ports() {
    if command -v lsof >/dev/null 2>&1; then
        lsof -nP -iTCP -sTCP:LISTEN
    elif command -v ss >/dev/null 2>&1; then
        ss -tlnp
    elif command -v netstat >/dev/null 2>&1; then
        netstat -tlnp 2>/dev/null || netstat -an | grep -i listen
    else
        echo "ports: lsof/ss/netstat not found" >&2
        return 1
    fi
}

myip() {
    if command -v ip >/dev/null 2>&1; then
        ip -brief addr show scope global 2>/dev/null | awk '{print $3}'
    elif command -v ifconfig >/dev/null 2>&1; then
        ifconfig | awk '/inet / && $2 != "127.0.0.1" {print $2}'
    else
        hostname -I 2>/dev/null
    fi
}

clip() {
    if command -v pbcopy >/dev/null 2>&1; then
        pbcopy
    elif command -v wl-copy >/dev/null 2>&1; then
        wl-copy
    elif command -v xclip >/dev/null 2>&1; then
        xclip -selection clipboard
    elif command -v xsel >/dev/null 2>&1; then
        xsel --clipboard --input
    else
        cat >/dev/null
    fi
}

pasteclip() {
    if command -v pbpaste >/dev/null 2>&1; then
        pbpaste
    elif command -v wl-paste >/dev/null 2>&1; then
        wl-paste
    elif command -v xclip >/dev/null 2>&1; then
        xclip -selection clipboard -o
    elif command -v xsel >/dev/null 2>&1; then
        xsel --clipboard --output
    fi
}

# Make pbcopy/pbpaste available on Linux where possible.
if ! command -v pbcopy >/dev/null 2>&1; then
    pbcopy() { clip; }
fi
if ! command -v pbpaste >/dev/null 2>&1; then
    pbpaste() { pasteclip; }
fi

venv() {
    local dir="${1:-.venv}"
    if [ ! -d "$dir" ]; then
        python3 -m venv "$dir" || return 1
    fi
    # shellcheck disable=SC1090
    . "$dir/bin/activate"
}

extract() {
    [ -n "$1" ] || { echo "usage: extract ARCHIVE" >&2; return 1; }
    case "$1" in
        *.tar.gz|*.tgz)       tar xzf "$1" ;;
        *.tar.bz2|*.tbz2)     tar xjf "$1" ;;
        *.tar.xz|*.txz)       tar xJf "$1" ;;
        *.tar)                tar xf "$1" ;;
        *.zip)                unzip "$1" ;;
        *.7z)                 7z x "$1" ;;
        *.rar)                unrar x "$1" ;;
        *.gz)                 gunzip "$1" ;;
        *) echo "extract: unknown archive type: $1" >&2; return 1 ;;
    esac
}

sha256() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$@"
    else
        shasum -a 256 "$@"
    fi
}

b64e() { base64 | tr -d '\n'; printf '\n'; }

b64d() {
    if printf 'YQ==' | base64 --decode >/dev/null 2>&1; then
        base64 --decode
    else
        base64 -D
    fi
}

urlenc() {
    python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read().strip()))'
}

urldec() {
    python3 -c 'import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip()))'
}

hex() {
    if command -v xxd >/dev/null 2>&1; then
        xxd -p | tr -d '\n'; printf '\n'
    else
        od -An -tx1 | tr -d ' \n'; printf '\n'
    fi
}

unhex() {
    xxd -r -p
}

jwt() {
    [ -n "$1" ] || { echo "usage: jwt TOKEN" >&2; return 1; }
    python3 - "$1" <<'PY'
import base64, json, sys
for part in sys.argv[1].split(".")[:2]:
    part += "=" * (-len(part) % 4)
    try:
        data = json.loads(base64.urlsafe_b64decode(part))
    except Exception as exc:
        print(f"decode error: {exc}", file=sys.stderr)
        sys.exit(1)
    print(json.dumps(data, indent=2, ensure_ascii=False))
PY
}

ctfroot() {
    cd "${CTF_ROOT:-$HOME/ctf}" || return
}

# Activate the pwntools venv created by install.sh --pwntools.
if [ -x "$HOME/.venvs/ctf/bin/python" ]; then
    alias ctfpy="$HOME/.venvs/ctf/bin/python"
    alias ctf-venv='. "$HOME/.venvs/ctf/bin/activate"'
fi
