# ~/.bashrc - Cross-platform Bash configuration
# Works on: macOS, WSL, Linux
#
# Load order:
#   1. ble.sh (early attach)
#   2. Environment detection
#   3. Path setup
#   4. Bash-it
#   5. Aliases & functions
#   6. Tool initialization
#   7. ble.sh (late attach)

# =============================================================================
# ble.sh - Early initialization (must be at top)
# =============================================================================
if [[ $- == *i* ]] && [[ ! -v POETRY_ACTIVE ]] && [[ -f ~/.local/share/blesh/ble.sh ]]; then
    source ~/.local/share/blesh/ble.sh --noattach
fi

# =============================================================================
# Exit if not interactive
# =============================================================================
case $- in
    *i*) ;;
    *) return;;
esac

# =============================================================================
# OS Detection
# =============================================================================
detect_os() {
    case "$(uname -s)" in
        Darwin*)  echo "macos" ;;
        Linux*)
            if grep -qi microsoft /proc/version 2>/dev/null; then
                echo "wsl"
            else
                echo "linux"
            fi
            ;;
        *)        echo "unknown" ;;
    esac
}

export DETECTED_OS="$(detect_os)"

# =============================================================================
# Path Configuration
# =============================================================================
# Local bin (cross-platform)
export PATH="${HOME}/.local/bin:${PATH}"

# Doom Emacs
[[ -d "${HOME}/.config/emacs/bin" ]] && export PATH="${HOME}/.config/emacs/bin:${PATH}"

# Cargo/Rust
[[ -f "${HOME}/.cargo/env" ]] && source "${HOME}/.cargo/env"

# macOS-specific paths
if [[ "$DETECTED_OS" == "macos" ]]; then
    # Homebrew
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        
        # GNU tools from Homebrew (prefer over BSD)
        for gnubin in /opt/homebrew/Cellar/*/*/libexec/gnubin; do
            [[ -d "$gnubin" ]] && export PATH="$gnubin:$PATH"
        done
    fi
fi

# Linux/WSL-specific paths
if [[ "$DETECTED_OS" == "linux" || "$DETECTED_OS" == "wsl" ]]; then
    # Linuxbrew (if installed)
    if [[ -f /home/linuxbrew/.linuxbrew/bin/brew ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
    
    # fd is named fdfind on Ubuntu
    if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
        alias fd='fdfind'
    fi
fi

# =============================================================================
# History Configuration
# =============================================================================
HISTCONTROL=ignoreboth:erasedups
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend

# =============================================================================
# Shell Options
# =============================================================================
shopt -s checkwinsize   # Update LINES/COLUMNS after each command
shopt -s globstar 2>/dev/null  # ** matches all files and directories

# =============================================================================
# Bash-it
# =============================================================================
export BASH_IT="$HOME/.bash_it"

if [[ -f "$BASH_IT/bash_it.sh" ]]; then
    # Theme configuration
    export BASH_IT_THEME='bobby-python'
    
    # Theme options
    export THEME_CHECK_SUDO='true'
    export BASH_IT_COMMAND_DURATION=true
    export COMMAND_DURATION_MIN_SECONDS=1
    export SCM_CHECK=true
    
    # Disable unused features
    export GIT_HOSTING='git@git.domain.com'
    unset MAILCHECK
    export IRC_CLIENT=false
    export TODO=false
    
    # Load Bash-it
    source "$BASH_IT/bash_it.sh"
fi

# =============================================================================
# Aliases - Editor
# =============================================================================
if command -v nvim &>/dev/null; then
    alias vim='nvim'
    alias vi='nvim'
    export EDITOR='nvim'
    export VISUAL='nvim'
else
    export EDITOR='vim'
    export VISUAL='vim'
fi

# =============================================================================
# Aliases - Navigation & Listing
# =============================================================================
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Color support
if [[ "$DETECTED_OS" == "macos" ]]; then
    alias ls='ls -G'
    export CLICOLOR=1
else
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# =============================================================================
# Aliases - Git (commonly used)
# =============================================================================
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline -10'
alias gd='git diff'

# =============================================================================
# Aliases - Safety
# =============================================================================
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# =============================================================================
# Aliases - WSL-specific
# =============================================================================
if [[ "$DETECTED_OS" == "wsl" ]]; then
    # Open files in Windows default app
    alias open='wslview'
    alias explorer='explorer.exe .'
    
    # Access Windows home
    export WINHOME="/mnt/c/Users/${USER}"
fi

# =============================================================================
# Tool Initialization (only if installed)
# =============================================================================

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

# Gitstatus prompt
[[ -f ~/gitstatus/gitstatus.prompt.sh ]] && source ~/gitstatus/gitstatus.prompt.sh

# Zoxide (smarter cd)
command -v zoxide &>/dev/null && eval "$(zoxide init bash)"

# fzf (fuzzy finder)
[[ -f ~/.fzf.bash ]] && source ~/.fzf.bash

# direnv (directory-specific env vars)
command -v direnv &>/dev/null && eval "$(direnv hook bash)"

# =============================================================================
# Vi Mode (for shells without ble.sh)
# =============================================================================
if [[ ! ${BLE_VERSION-} ]]; then
    set -o vi
    bind -m vi-command 'Control-l: clear-screen'
    bind -m vi-insert 'Control-l: clear-screen'
fi

# =============================================================================
# Functions
# =============================================================================

# Create and cd into directory
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract any archive
extract() {
    if [[ -f "$1" ]]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "Cannot extract '$1'" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Quick find
qfind() {
    find . -name "*$1*" 2>/dev/null
}

# =============================================================================
# Local Overrides (machine-specific, not in git)
# =============================================================================
[[ -f ~/.bashrc.local ]] && source ~/.bashrc.local

# =============================================================================
# ble.sh - Late attach (must be at bottom)
# =============================================================================
[[ ! -v POETRY_ACTIVE ]] && [[ ${BLE_VERSION-} ]] && ble-attach
