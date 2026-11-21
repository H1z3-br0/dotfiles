# Minimal environment for all zsh invocations (interactive and scripts).
export PATH="$HOME/.local/bin:$PATH"

# Rust toolchain, if present
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
