# dotfiles для Attack-Defence CTF

Переносимый набор конфигов и маленьких помощников, чтобы на чужом ноутбуке
быстро получить привычный терминал, tmux, vim/neovim, git, ssh и рабочую
раскладку для A/D.

Никаких приватных ключей, токенов и истории команд здесь нет. Всё, что
относится к конкретной машине, лежит в `*.local` файлах и в репозиторий не
попадает.

---

## Быстрый старт

Скопируйте папку `dotfiles` на ноутбук, например в `~/dotfiles`, и выполните:

```bash
cd ~/dotfiles
chmod +x install.sh
./install.sh
exec zsh -l
```

Если нужен полностью автоматический вариант (пакеты, pwntools, плагины Neovim):

```bash
cd ~/dotfiles
./install.sh --all
exec zsh -l
```

`--all` может занять 10–20 минут, потребовать `sudo` и интернет. Если на
машине нельзя ставить пакеты, используйте просто `./install.sh`: конфиги
установятся, а зависимости можно поставить позже.

### Если на ноутбуке нет git

Скопируйте папку любым способом:

```bash
# с вашей машины
scp -r ~/dotfiles user@laptop:~/
# или с флешки
cp -R /Volumes/USB/dotfiles ~/dotfiles
```

Затем:

```bash
cd ~/dotfiles
./install.sh
```

### Если хочется вообще ничего не линковать

```bash
./install.sh --copy
```

В этом режиме файлы копируются в `$HOME`. Это удобно для флешки, но изменения
в репозитории больше не будут автоматически попадать в домашнюю папку.

---

## Что установится

| Файл в репозитории | Куда | Зачем |
|---|---|---|
| `.zshrc`, `.zshenv`, `.zprofile` | `~` | zsh: история, prompt, fzf, zoxide, pyenv, алиасы |
| `.bashrc`, `.bash_profile` | `~` | то же для bash, если zsh нет |
| `.tmux.conf` | `~` | tmux: мышь, vi-copy, удобные split, статус-бар |
| `.vimrc` | `~` | fallback для обычного vim |
| `.gdbinit` | `~` | gdb: intel, история, автоподхват pwndbg/GEF/PEDA |
| `.gitconfig` | `~` | git-алиасы, editor, LFS, include локального identity |
| `.ssh/config` | `~/.ssh/config` | keepalive, ControlMaster, include `config.local` |
| `.inputrc` | `~` | readline: history-search, completion |
| `.ripgreprc` | `~` | нормальные настройки ripgrep |
| `.clang-format` | `~` | форматирование C/C++ |
| `.config/nvim` | `~/.config/nvim` | LazyVim-конфиг |
| `.config/btop` | `~/.config/btop` | btop + тема horizon |
| `.config/htop` | `~/.config/htop` | htop |
| `shell/common.sh` | `~/.config/dotfiles/common.sh` | общие алиасы и функции для zsh/bash |
| `bin/ad` | `~/.local/bin/ad` | помощник для A/D (см. ниже) |

Старые файлы не удаляются: при первом запуске они переезжают в
`~/.dotfiles-backup/<дата>-<pid>/`. Путь печатается в конце установки.

---

## Зависимости

`./install.sh --packages` пытается поставить:

- `tmux`, `neovim`, `fzf`, `ripgrep`, `fd`, `bat`, `git`, `curl`, `jq`, `tree`
- `nmap`, `socat`, `python3`, `pip`, `gdb`, `file`, `binutils`
- `htop`, `btop`, `zsh`, `unzip`, `p7zip`

Поддерживаются `brew`, `apt`, `dnf`, `pacman`, `apk`, `zypper`. Если пакет не
нашёлся, установка продолжается: один отсутствующий пакет не ломает остальное.

Минимальный набор, если ставить руками:

```bash
# Debian/Ubuntu
sudo apt update
sudo apt install -y tmux neovim fzf ripgrep fd-find bat git curl nmap socat python3 python3-venv

# macOS
brew install tmux neovim fzf ripgrep fd bat git curl nmap socat python
```

`./install.sh --all` дополнительно создаёт `~/.venvs/ctf` с `pwntools`,
`requests` и `pycryptodome`, а затем делает headless-установку плагинов LazyVim.

---

## Проверка после установки

```bash
exec zsh -l          # или exec bash -l
ad help
ad env
tmux -V
nvim --version
```

Если `ad: command not found`, проверьте, что `~/.local/bin` есть в `PATH`:

```bash
echo "$PATH" | tr ':' '\n' | grep -F "$HOME/.local/bin"
```

Новый терминал должен подхватить путь сам.

---

## `ad` — помощник для Attack-Defence

`ad` — это не эксплойт и не сканер уязвимостей. Это обёртка над обычными
вещами, которые всё равно нужны в A/D: порты, ssh, логи, заметки, быстрый
HTTP-сервер и листенер.

```text
ad tmux [session]        готовая раскладка tmux (по умолчанию сессия ad)
ad ssh HOST [args...]    ssh с keepalive
ad scan HOST             nmap, если есть; иначе перебор частых портов
ad ports [HOST]          локальные слушающие порты / скан HOST
ad check HOST PORT...    проверить TCP-порты через nc
ad serve [PORT]          HTTP-сервер в текущей папке (по умолчанию 8000)
ad listen [PORT]         nc-листенер (по умолчанию 4444)
ad ip                    локальные IP
ad watch FILE            tail -Fn 200 FILE
ad logs SERVICE          journalctl -u SERVICE -f (или syslog)
ad restart SERVICE       перезапустить сервис
ad status                упавшие сервисы и запущенные юниты
ad grep PATTERN [PATH]   рекурсивный поиск
ad flag [PATH]           поиск флагов в файлах
ad extract ARCHIVE       распаковать архив
ad note [TEXT]           заметка в notes.md / открыть редактор
ad env                   версии инструментов и окружение
```

### Раскладка `ad tmux`

```bash
mkdir -p ~/ctf && cd ~/ctf
ad tmux
```

Создаётся сессия `ad`:

- окно `ops` — три панели: слева большой shell, справа сверху и снизу ещё два;
- окно `notes` — `notes.md` в редакторе;
- окно `target` — если задан `AD_HOST`;
- окно `logs` — если задан `AD_LOG`.

Пример с целью и логом:

```bash
AD_HOST=player@10.10.10.10 \
AD_LOG=/var/log/nginx/error.log \
ad tmux
```

Если сессия уже существует, `ad tmux` просто подключится к ней.

### Типичный цикл A/D

```bash
cd ~/ctf
ad tmux
ad scan 10.10.10.10
ad check 10.10.10.10 22 80 443 8080
ad serve 8000                 # отдать файл соседней машине
ad listen 4444                # принять подключение
ad note "после рестарта сервис поднялся, флаг читается"
ad flag .                     # проверить, не осталось ли флагов в файлах
```

---

## Горячие клавиши

### tmux

Префикс — `C-b` (как в дефолтном tmux).

| Клавиши | Действие |
|---|---|
| `prefix + |` | split по вертикали |
| `prefix + -` | split по горизонтали |
| `prefix + h/j/k/l` | перейти между панелями |
| `prefix + H/J/K/L` | изменить размер панели |
| `prefix + c` | новое окно в текущей папке |
| `prefix + r` | перечитать `~/.tmux.conf` |
| `prefix + [` | copy mode (vi) |
| `v`, затем `y` | выделить и скопировать |
| `prefix + Q` | убить сессию с подтверждением |
| `prefix + X` | убить окно с подтверждением |

Мышь включена: можно кликать по панелям, окнам и ресайзить.

### zsh

| Клавиши | Действие |
|---|---|
| `Ctrl-R` | поиск по истории (fzf) |
| `Ctrl-T` | выбрать файл (fzf) |
| `Alt-C` | перейти в папку (fzf) |
| `Ctrl-X Ctrl-E` | открыть текущую команду в `$EDITOR` |
| `Ctrl-Left/Right` | слово влево/вправо |

Команда, начинающаяся с пробела, не попадает в историю — удобно для токенов
и паролей.

### vim / neovim

- `Space w` — сохранить.
- `Space h` — снять подсветку поиска.
- `F2` — toggle paste.
- `F3` — toggle numbers.
- `F4` — toggle invisible chars.
- В Neovim действуют стандартные LazyVim-клавиши: `Space f f` — файлы,
  `Space f g` — grep, `Space e` — explorer, `Space t` — терминал.

---

## SSH

В репозитории только шаблон `~/.ssh/config`. Приватные ключи и реальные хосты
в него не входят.

Свои хосты добавляйте в `~/.ssh/config.local`:

```sshconfig
Host target
    HostName 10.10.10.10
    User player
    Port 22
    IdentityFile ~/.ssh/id_ctf
    IdentitiesOnly yes
```

`~/.ssh/config` автоматически подключает этот файл через
`Include ~/.ssh/config.local*`. Права:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config.local
chmod 600 ~/.ssh/id_ctf
```

Ключи можно загрузить в агент:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ctf
```

Для A/D удобно, что в конфиге уже включены `ServerAliveInterval`,
`ServerAliveCountMax` и `ControlMaster` — ssh не отваливается на паузах и
быстрее открывает повторные сессии.

---

## Git identity

`~/.gitconfig` подключает `~/.gitconfig.local`, чтобы имя и почта не лежали в
репозитории. При установке файл создаётся автоматически:

```bash
GIT_NAME="Your Name" GIT_EMAIL="you@example.com" ./install.sh
```

Или отредактируйте вручную:

```bash
$EDITOR ~/.gitconfig.local
```

Проверка:

```bash
git config --global --get user.name
git config --global --get user.email
```

---

## Neovim

`~/.config/nvim` — это LazyVim-конфиг. При первом запуске `nvim` сам скачает
`lazy.nvim` и плагины. `./install.sh --nvim` делает это заранее в headless-
режиме:

```bash
nvim --headless "+Lazy! sync" +qa
```

AI-плагины (Claude Code, Supermaven) в переносимой версии отключены: на чужой
машине нет ваших аккаунтов, а лишние запросы только мешают. Включить обратно
можно через `:LazyExtras` или добавив нужный extra в
`~/.config/nvim/lua/config/lazy.lua`.

Если в терминале нет Nerd Font, иконки LazyVim могут выглядеть квадратиками.
Это не мешает работе; для красоты поставьте любой Nerd Font и выберите его в
терминале.

---

## Настройка под себя

Не редактируйте файлы в репозитории, если не хотите коммитить личное. Для
локальных изменений есть:

| Файл | Для чего |
|---|---|
| `~/.zshrc.local` | ваши zsh-алиасы и переменные |
| `~/.bashrc.local` | то же для bash |
| `~/.ssh/config.local` | ваши ssh-хосты и ключи |
| `~/.gitconfig.local` | ваше git-имя и почта |

Они подключаются в конце основных конфигов и не входят в репозиторий.

### Oh My Zsh / Powerlevel10k

По умолчанию `.zshrc` работает без Oh My Zsh: меньше зависимостей и быстрее
старт. Если хочется вернуть привычный p10k:

```bash
# 1. Поставьте oh-my-zsh и powerlevel10k (инструкции на их сайтах).
# 2. Включите OMZ:
echo 'export DOTFILES_USE_OMZ=1' >> ~/.zshrc.local
# 3. Верните p10k-конфиг:
cp ~/dotfiles/extras/p10k.zsh ~/.p10k.zsh
echo '[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh' >> ~/.zshrc.local
```

p10k требует Nerd Font. Без него prompt будет с квадратиками.

---

## Удаление

Убрать симлинки, которые поставил скрипт:

```bash
cd ~/dotfiles
./install.sh --uninstall
```

Если использовался `--copy`, скрипт не будет удалять копии без явного
подтверждения:

```bash
./install.sh --uninstall --force
```

`~/.ssh/config.local`, `~/.gitconfig.local`, `~/ctf` и бэкапы не удаляются.
Старые файлы можно достать из `~/.dotfiles-backup/<дата>-<pid>/`.

---

## Troubleshooting

**`ad: command not found`**

Откройте новый терминал или проверьте `PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

**`nvim` не ставит плагины**

Нужны `git`, `ripgrep`, интернет. Затем:

```bash
nvim
:Lazy sync
:checkhealth
```

**`pwntools` не ставится**

На Debian/Ubuntu нужен `python3-venv` и иногда `python3-dev`:

```bash
sudo apt install -y python3-venv python3-dev
~/.venvs/ctf/bin/pip install pwntools
```

**gdb на macOS**

Homebrew-gdb требует codesigning, а pwndbg/GEF лучше работают на Linux.
`.gdbinit` сам подхватит плагин, если он установлен, но на macOS проще
использовать `lldb` или Linux-виртуалку.

**tmux без цветов**

Проверьте, что терминал поддерживает 256/truecolor, и что `tmux -V` не
совсем древний. Конфиг рассчитан на tmux 2.6+.

**Сломался `.zshrc`**

Верните бэкап:

```bash
ls ~/.dotfiles-backup/
cp ~/.dotfiles-backup/<дата>-<pid>/.zshrc ~/.zshrc
```

Или запустите `zsh -f` (без конфигов) и почините.

---

## Структура

```text
dotfiles/
├── install.sh              установка / удаление
├── README.md
├── Makefile                make test / make lint
├── .zshrc .zshenv .zprofile
├── .bashrc .bash_profile
├── .tmux.conf
├── .vimrc
├── .gdbinit
├── .gitconfig
├── .gitconfig.local.example
├── .inputrc
├── .ripgreprc
├── .clang-format
├── .ssh/config
├── .config/
│   ├── nvim/
│   ├── btop/
│   └── htop/
├── bin/ad
├── shell/common.sh
└── extras/p10k.zsh         опциональный p10k-конфиг
```

---

## Безопасность

- В репозитории нет приватных ключей, токенов, `.zsh_history` и реальных
  `Host`-блоков.
- `~/.ssh/config.local`, `~/.gitconfig.local`, `~/.zshrc.local` и
  `~/.bashrc.local` — локальные файлы, не коммитьте их.
- Перед публикацией репозитория проверьте:

```bash
git status
git diff --cached
```

- Если команда содержит токен или пароль, начните её с пробела — она не
  попадёт в историю zsh.
- `ad serve` слушает `0.0.0.0`. Не запускайте его на публичном Wi-Fi без
  необходимости.
# dotfiles
