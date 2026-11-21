#!/usr/bin/env bash
# Install the portable CTF dotfiles.
#
# Default: symlink configs into $HOME, backing up anything that already exists.
# --copy: copy files instead of symlinking (useful for USB sticks).
# --all:  install configs + system packages + pwntools venv + Neovim plugins.
set -u

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$HOME/.dotfiles-installed"
BACKUP_ROOT="$HOME/.dotfiles-backup"
BACKUP_DIR="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)-$$"

COPY_MODE=0
DO_PACKAGES=0
DO_PWNYTOOLS=0
DO_NVIM=0
DO_UNINSTALL=0
FORCE=0

if [ -t 1 ]; then
    C_GREEN=$'\033[32m'
    C_YELLOW=$'\033[33m'
    C_RED=$'\033[31m'
    C_BLUE=$'\033[34m'
    C_RESET=$'\033[0m'
else
    C_GREEN=""
    C_YELLOW=""
    C_RED=""
    C_BLUE=""
    C_RESET=""
fi

say()  { printf '%s==>%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
info() { printf '%s  ->%s %s\n' "$C_BLUE" "$C_RESET" "$*"; }
warn() { printf '%s[!]%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
die()  { printf '%s[x]%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; exit 1; }

usage() {
    cat <<'EOF'
Установка переносимых dotfiles для CTF / Attack-Defence.

Использование:
  ./install.sh                 поставить конфиги симлинками (по умолчанию)
  ./install.sh --copy          скопировать конфиги в $HOME вместо симлинков
  ./install.sh --packages      поставить зависимости через brew/apt/dnf/pacman/apk
  ./install.sh --pwntools      создать ~/.venvs/ctf с pwntools
  ./install.sh --nvim          установить плагины LazyVim (headless)
  ./install.sh --all           всё сразу: конфиги + пакеты + pwntools + nvim
  ./install.sh --uninstall     убрать установленные симлинки
  ./install.sh --uninstall --force
                               additionally remove copied files

Полезные переменные:
  GIT_NAME="Your Name" GIT_EMAIL="you@example.com" ./install.sh
  CTF_ROOT=~/ctf ./install.sh

Перед установкой ничего удалять не нужно: существующие файлы будут
перемещены в ~/.dotfiles-backup/<timestamp>/.
EOF
}

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --copy) COPY_MODE=1 ;;
            --link) COPY_MODE=0 ;;
            --packages) DO_PACKAGES=1 ;;
            --pwntools) DO_PWNYTOOLS=1 ;;
            --nvim) DO_NVIM=1 ;;
            --all) DO_PACKAGES=1; DO_PWNYTOOLS=1; DO_NVIM=1 ;;
            --uninstall) DO_UNINSTALL=1 ;;
            --force) FORCE=1 ;;
            -h|--help) usage; exit 0 ;;
            *) die "неизвестный аргумент: $1 (см. --help)" ;;
        esac
        shift
    done
}

backup_path() {
    local dest="$1"
    local rel="${dest#"$HOME"/}"
    mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    mv "$dest" "$BACKUP_DIR/$rel"
    info "backup: $dest -> $BACKUP_DIR/$rel"
}

record() {
    printf '%s\t%s\n' "$1" "$2" >> "$MANIFEST"
}

install_one() {
    local src="$1"
    local dest="$2"
    local mode="link"
    [ "$COPY_MODE" -eq 1 ] && mode="copy"

    [ -e "$src" ] || [ -L "$src" ] || die "нет исходника: $src"

    if [ "$COPY_MODE" -eq 0 ] && [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
        info "already linked: $dest"
        record "$mode" "$dest"
        return
    fi

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        backup_path "$dest"
    fi

    mkdir -p "$(dirname "$dest")"
    if [ "$COPY_MODE" -eq 1 ]; then
        cp -R "$src" "$dest"
        info "copied: $src -> $dest"
    else
        ln -s "$src" "$dest"
        info "linked: $dest -> $src"
    fi
    record "$mode" "$dest"
}

create_local_files() {
    mkdir -p "$HOME/.ssh/cm"
    chmod 700 "$HOME/.ssh" "$HOME/.ssh/cm" 2>/dev/null || true

    if [ ! -e "$HOME/.ssh/config.local" ]; then
        cat > "$HOME/.ssh/config.local" <<'EOF'
# Personal SSH hosts for this machine. Not part of the dotfiles repo.
# Example:
# Host target
#     HostName 10.10.10.10
#     User player
#     Port 22
#     IdentityFile ~/.ssh/id_ctf
#     IdentitiesOnly yes
EOF
        chmod 600 "$HOME/.ssh/config.local"
        info "created ~/.ssh/config.local"
    fi

    if [ ! -e "$HOME/.gitconfig.local" ]; then
        local name="${GIT_NAME:-${USER:-ctf}}"
        local email="${GIT_EMAIL:-${USER:-ctf}@localhost}"
        printf '[user]\n\tname = %s\n\temail = %s\n' "$name" "$email" > "$HOME/.gitconfig.local"
        info "created ~/.gitconfig.local ($name <$email>)"
        info "edit it or re-run with GIT_NAME/GIT_EMAIL to change identity"
    fi

    mkdir -p "$HOME/.vim/undo" "$HOME/.vim/backup" "$HOME/.vim/swap"
    mkdir -p "${CTF_ROOT:-$HOME/ctf}"
}

install_configs() {
    : > "$MANIFEST"

    local files="
.zshrc
.zshenv
.zprofile
.bashrc
.bash_profile
.tmux.conf
.vimrc
.gdbinit
.gitconfig
.inputrc
.ripgreprc
.clang-format
"
    local f
    for f in $files; do
        install_one "$DOTFILES_DIR/$f" "$HOME/$f"
    done

    install_one "$DOTFILES_DIR/.ssh/config" "$HOME/.ssh/config"
    install_one "$DOTFILES_DIR/.config/nvim" "$HOME/.config/nvim"
    install_one "$DOTFILES_DIR/.config/btop" "$HOME/.config/btop"
    install_one "$DOTFILES_DIR/.config/htop" "$HOME/.config/htop"
    install_one "$DOTFILES_DIR/shell" "$HOME/.config/dotfiles"
    install_one "$DOTFILES_DIR/bin/ad" "$HOME/.local/bin/ad"

    chmod +x "$HOME/.local/bin/ad" 2>/dev/null || true
    create_local_files
}

install_packages() {
    say "Установка зависимостей"

    local SUDO=""
    if [ "$(id -u)" -ne 0 ]; then
        if command -v sudo >/dev/null 2>&1; then
            SUDO="sudo"
        else
            warn "sudo не найден; установите пакеты вручную"
            return
        fi
    fi

    local brew_bin=""
    for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
        [ -x "$candidate" ] && brew_bin="$candidate" && break
    done
    [ -z "$brew_bin" ] && command -v brew >/dev/null 2>&1 && brew_bin="$(command -v brew)"

    if [ -n "$brew_bin" ]; then
        local pkgs="tmux neovim fzf ripgrep fd bat git curl jq tree htop btop nmap socat python"
        local p
        for p in $pkgs; do
            "$brew_bin" install "$p" || warn "brew: не удалось поставить $p"
        done
        eval "$("$brew_bin" shellenv)" 2>/dev/null || true
        return
    fi

    if command -v apt-get >/dev/null 2>&1; then
        $SUDO apt-get update || warn "apt-get update завершился с ошибкой"
        local pkgs="tmux neovim fzf ripgrep fd-find bat git curl jq tree htop btop nmap netcat-openbsd socat python3 python3-pip python3-venv gdb file binutils xxd unzip p7zip-full zsh"
        local p
        for p in $pkgs; do
            $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y "$p" || warn "apt: не удалось поставить $p"
        done
        return
    fi

    if command -v dnf >/dev/null 2>&1; then
        local pkgs="tmux neovim fzf ripgrep fd-find bat git curl jq tree htop btop nmap socat python3 python3-pip gdb file binutils vim-common unzip p7zip zsh"
        local p
        for p in $pkgs; do
            $SUDO dnf install -y "$p" || warn "dnf: не удалось поставить $p"
        done
        return
    fi

    if command -v pacman >/dev/null 2>&1; then
        local pkgs="tmux neovim fzf ripgrep fd bat git curl jq tree htop btop nmap socat python python-pip gdb file binutils vim unzip p7zip zsh"
        local p
        for p in $pkgs; do
            $SUDO pacman -S --needed --noconfirm "$p" || warn "pacman: не удалось поставить $p"
        done
        return
    fi

    if command -v apk >/dev/null 2>&1; then
        local pkgs="tmux neovim fzf ripgrep fd bat git curl jq tree htop btop nmap socat python3 py3-pip gdb file binutils xxd unzip p7zip zsh"
        local p
        for p in $pkgs; do
            $SUDO apk add "$p" || warn "apk: не удалось поставить $p"
        done
        return
    fi

    if command -v zypper >/dev/null 2>&1; then
        local pkgs="tmux neovim fzf ripgrep fd bat git curl jq tree htop btop nmap socat python3 python3-pip gdb file binutils xxd unzip p7zip zsh"
        local p
        for p in $pkgs; do
            $SUDO zypper --non-interactive install "$p" || warn "zypper: не удалось поставить $p"
        done
        return
    fi

    warn "не найден знакомый пакетный менеджер (brew/apt/dnf/pacman/apk/zypper)"
    warn "поставьте вручную: tmux neovim fzf ripgrep fd bat git curl nmap socat python3"
}

install_pwntools() {
    say "Создание Python-окружения для pwn"
    if ! command -v python3 >/dev/null 2>&1; then
        warn "python3 не найден; пропускаю pwntools"
        return
    fi
    local venv="$HOME/.venvs/ctf"
    mkdir -p "$HOME/.venvs"
    if [ ! -x "$venv/bin/python" ]; then
        python3 -m venv "$venv" || {
            warn "не удалось создать venv (нужен пакет python3-venv)"
            return
        }
    fi
    "$venv/bin/python" -m pip install --upgrade pip wheel || warn "pip upgrade failed"
    "$venv/bin/python" -m pip install pwntools requests pycryptodome || \
        warn "не удалось поставить pwntools; проверьте сеть/компилятор"
    info "venv: $venv"
    info "активация: source $venv/bin/activate  (или alias ctf-venv)"
}

install_nvim_plugins() {
    say "Установка плагинов Neovim (LazyVim)"
    if ! command -v nvim >/dev/null 2>&1; then
        warn "nvim не найден; пропускаю плагины"
        return
    fi
    nvim --headless "+Lazy! sync" +qa || {
        warn "Lazy sync не завершился; откройте nvim и выполните :Lazy sync"
    }
}

uninstall_configs() {
    say "Удаление установленных конфигов"
    if [ ! -f "$MANIFEST" ]; then
        warn "манифест $MANIFEST не найден; удалять нечего"
        return
    fi

    local mode dest target
    local leftovers=0
    while IFS=$'\t' read -r mode dest; do
        [ -n "$dest" ] || continue
        if [ -L "$dest" ]; then
            target="$(readlink "$dest")"
            case "$target" in
                "$DOTFILES_DIR"/*)
                    rm -f "$dest" && info "removed: $dest"
                    ;;
                *)
                    warn "skip (not ours): $dest -> $target"
                    ;;
            esac
        elif [ "$mode" = "copy" ]; then
            if [ "$FORCE" -eq 1 ]; then
                rm -rf "$dest" && info "removed copy: $dest"
            else
                warn "copy left in place: $dest (use --force to remove)"
                leftovers=1
            fi
        fi
    done < "$MANIFEST"

    if [ "$leftovers" -eq 1 ]; then
        warn "манифест сохранён: $MANIFEST (повторите с --force, чтобы удалить копии)"
    else
        rm -f "$MANIFEST"
    fi
    if [ -d "$BACKUP_ROOT" ]; then
        info "backups: $BACKUP_ROOT"
    fi
    info "~/.ssh/config.local, ~/.gitconfig.local and ~/ctf were left untouched"
}

main() {
    parse_args "$@"

    if [ "$DO_UNINSTALL" -eq 1 ]; then
        uninstall_configs
        exit 0
    fi

    [ -f "$DOTFILES_DIR/.zshrc" ] || die "не похоже на dotfiles: $DOTFILES_DIR"

    say "Dotfiles: $DOTFILES_DIR"
    install_configs
    say "Конфиги установлены"

    [ "$DO_PACKAGES" -eq 1 ] && install_packages
    [ "$DO_PWNYTOOLS" -eq 1 ] && install_pwntools
    [ "$DO_NVIM" -eq 1 ] && install_nvim_plugins

    if [ -d "$BACKUP_DIR" ]; then
        say "Старые файлы сохранены: $BACKUP_DIR"
    fi

    cat <<EOF

Готово. Откройте новый терминал или выполните:
  exec zsh -l

Проверка:
  ad help
  ad env

Если zsh не установлен:
  exec bash -l

Git identity:
  edit ~/.gitconfig.local

SSH-хосты:
  edit ~/.ssh/config.local   (ключи в репозиторий не входят)

Удаление:
  ./install.sh --uninstall
EOF
}

main "$@"
