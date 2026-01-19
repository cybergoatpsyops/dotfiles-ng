#!/usr/bin/env bash
#
# Cross-Platform Bootstrap Script v3
# Supports: macOS (Intel/Apple Silicon), Ubuntu, WSL
# 
# Features:
#   - Idempotent: safe to run multiple times
#   - --dry-run: preview what would happen
#   - --force: reinstall even if already present
#   - --uninstall: remove all installed components
#   - --skip <component>: skip specific installs
#   - --status: show installation status
#
# Usage:
#   ./bootstrap.sh [OPTIONS]
#
# Components: packages, nvim, emacs, doom, tmux, oh-my-tmux, bash-it, blesh, dotfiles, stow
#

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================
readonly DOTFILES_REPO="git@github.com:cybergoatpsyops/dotfiles-ng.git"
readonly DOTFILES_DIR="$HOME/dotfiles"
readonly STOW_PACKAGES="bash doom tmux"
readonly NVIM_FALLBACK_VERSION="v0.11.5"
readonly SCRIPT_VERSION="3.1.0"

# ============================================================================
# OS Detection (set early, used everywhere)
# ============================================================================
detect_os() {
    case "$(uname -s)" in
        Darwin*)
            if [[ "$(uname -m)" == "arm64" ]]; then
                echo "macos-arm64"
            else
                echo "macos-x86_64"
            fi
            ;;
        Linux*)
            if grep -qi microsoft /proc/version 2>/dev/null; then
                echo "wsl"
            else
                echo "linux"
            fi
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

readonly DETECTED_OS="$(detect_os)"

# ============================================================================
# Global State
# ============================================================================
DRY_RUN=false
FORCE=false
UNINSTALL=false
STATUS_ONLY=false
declare -A SKIP=()
ERRORS=()

# ============================================================================
# Colors & Logging
# ============================================================================
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly DIM='\033[2m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_skip()    { echo -e "${DIM}[SKIP]${NC} $1"; }
log_dry()     { echo -e "${CYAN}[DRY-RUN]${NC} $1"; }
log_remove()  { echo -e "${RED}[REMOVE]${NC} $1"; }

# ============================================================================
# Helper Functions
# ============================================================================
usage() {
    cat << EOF
${BOLD}Cross-Platform Bootstrap Script v${SCRIPT_VERSION}${NC}
Detected OS: ${DETECTED_OS}

${BOLD}USAGE:${NC}
    $(basename "$0") [OPTIONS]

${BOLD}OPTIONS:${NC}
    -n, --dry-run     Show what would be done without doing it
    -f, --force       Force reinstall of components
    -u, --uninstall   Remove all installed components (restore to defaults)
    -s, --skip NAME   Skip component (can be used multiple times)
    --status          Show current installation status and exit
    -h, --help        Show this help message

${BOLD}COMPONENTS:${NC}
    packages, nvim, emacs, doom, tmux, oh-my-tmux, bash-it, blesh, dotfiles, stow

${BOLD}EXAMPLES:${NC}
    $(basename "$0")                     # Normal install
    $(basename "$0") --dry-run           # Preview changes
    $(basename "$0") --skip doom         # Skip Doom Emacs
    $(basename "$0") --force             # Reinstall everything
    $(basename "$0") --uninstall         # Remove everything
    $(basename "$0") --status            # Check what's installed

${BOLD}PLATFORM NOTES:${NC}
    macOS:  Uses Homebrew for packages, installs nvim to /usr/local/bin
    Linux:  Uses apt for packages, installs nvim to /opt
    WSL:    Same as Linux, with WSL-specific detection

EOF
    exit 0
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -u|--uninstall)
                UNINSTALL=true
                shift
                ;;
            -s|--skip)
                SKIP["$2"]=1
                shift 2
                ;;
            --status)
                STATUS_ONLY=true
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information."
                exit 1
                ;;
        esac
    done
}

should_skip() {
    [[ -v SKIP["$1"] ]]
}

run() {
    if $DRY_RUN; then
        log_dry "$*"
        return 0
    fi
    "$@"
}

run_sudo() {
    if $DRY_RUN; then
        log_dry "sudo $*"
        return 0
    fi
    sudo "$@"
}

record_error() {
    ERRORS+=("$1")
}

confirm() {
    local prompt="$1"
    local default="${2:-n}"
    
    if $DRY_RUN; then
        return 0
    fi
    
    local yn
    if [[ "$default" == "y" ]]; then
        read -p "$prompt [Y/n] " -n 1 -r yn
    else
        read -p "$prompt [y/N] " -n 1 -r yn
    fi
    echo
    
    case "$yn" in
        [Yy]*) return 0 ;;
        [Nn]*) return 1 ;;
        "") [[ "$default" == "y" ]] && return 0 || return 1 ;;
        *) return 1 ;;
    esac
}

is_macos() {
    [[ "$DETECTED_OS" == macos-* ]]
}

is_linux() {
    [[ "$DETECTED_OS" == "linux" || "$DETECTED_OS" == "wsl" ]]
}

# Cross-platform file size check
get_file_size() {
    local file="$1"
    if is_macos; then
        stat -f%z "$file" 2>/dev/null || echo 0
    else
        stat -c%s "$file" 2>/dev/null || echo 0
    fi
}

# ============================================================================
# Status Check
# ============================================================================
show_status() {
    echo ""
    echo -e "${BOLD}=== Installation Status (${DETECTED_OS}) ===${NC}"
    echo ""
    
    echo -e "${BOLD}Commands:${NC}"
    for cmd in nvim emacs tmux stow git gh brew; do
        if command -v "$cmd" &>/dev/null; then
            local version
            version=$("$cmd" --version 2>/dev/null | head -1 || echo "installed")
            echo -e "  ${GREEN}✓${NC} $cmd: $version"
        else
            if [[ "$cmd" == "brew" ]] && is_linux; then
                echo -e "  ${DIM}○${NC} $cmd: n/a (Linux)"
            else
                echo -e "  ${RED}✗${NC} $cmd: not found"
            fi
        fi
    done
    
    echo ""
    echo -e "${BOLD}Directories:${NC}"
    
    local nvim_dir
    if is_macos; then
        nvim_dir="/usr/local/bin/nvim"
    else
        nvim_dir="/opt/nvim-linux-x86_64"
    fi
    
    declare -A dirs=(
        ["dotfiles"]="$DOTFILES_DIR"
        ["bash-it"]="$HOME/.bash_it"
        ["ble.sh"]="$HOME/.local/share/blesh"
        ["doom"]="$HOME/.config/emacs"
        ["oh-my-tmux"]="$HOME/.tmux"
        ["nvim"]="$nvim_dir"
    )
    
    for name in "${!dirs[@]}"; do
        if [[ -e "${dirs[$name]}" ]]; then
            echo -e "  ${GREEN}✓${NC} $name: ${dirs[$name]}"
        else
            echo -e "  ${DIM}○${NC} $name: not installed"
        fi
    done
    
    echo ""
    echo -e "${BOLD}Symlinks:${NC}"
    for f in ~/.bashrc ~/.bash_profile ~/.blerc ~/.inputrc ~/.doom.d ~/.tmux.conf.local; do
        if [[ -L "$f" ]]; then
            echo -e "  ${GREEN}✓${NC} $f -> $(readlink "$f")"
        elif [[ -e "$f" ]]; then
            echo -e "  ${YELLOW}○${NC} $f (exists, not symlink)"
        else
            echo -e "  ${DIM}○${NC} $f (missing)"
        fi
    done
    
    echo ""
}

# ============================================================================
# Idempotent Install Wrapper
# ============================================================================
ensure_installed() {
    local name="$1"
    local check_cmd="$2"
    local install_fn="$3"
    
    if should_skip "$name"; then
        log_skip "$name (--skip flag)"
        return 0
    fi
    
    log_info "Checking $name..."
    
    if ! $FORCE && eval "$check_cmd" &>/dev/null; then
        log_skip "$name (already installed)"
        return 0
    fi
    
    if $FORCE && eval "$check_cmd" &>/dev/null; then
        log_warn "$name exists, reinstalling (--force)"
    fi
    
    if $DRY_RUN; then
        log_dry "Would install $name"
        return 0
    fi
    
    if "$install_fn"; then
        log_success "$name installed"
        return 0
    else
        log_error "Failed to install $name"
        record_error "$name"
        return 1
    fi
}

# ============================================================================
# Pre-flight Checks
# ============================================================================
preflight_checks() {
    log_info "Running preflight checks..."
    log_info "Detected OS: $DETECTED_OS"
    
    case "$DETECTED_OS" in
        macos-arm64)
            log_success "macOS (Apple Silicon) detected"
            ;;
        macos-x86_64)
            log_success "macOS (Intel) detected"
            ;;
        wsl)
            log_success "WSL environment detected"
            ;;
        linux)
            log_success "Linux detected"
            ;;
        *)
            log_warn "Unknown OS - script may not work correctly"
            ;;
    esac
    
    for cmd in git curl; do
        if ! command -v "$cmd" &>/dev/null; then
            log_error "Required command not found: $cmd"
            exit 1
        fi
    done
    
    # Check for package manager
    if is_macos; then
        if ! command -v brew &>/dev/null; then
            log_error "Homebrew not found. Install from https://brew.sh"
            exit 1
        fi
    fi
    
    log_success "Preflight checks passed"
}

# ============================================================================
# Package Installation (Platform-specific)
# ============================================================================
do_install_packages() {
    if is_macos; then
        do_install_packages_macos
    else
        do_install_packages_linux
    fi
}

do_install_packages_macos() {
    log_info "Installing packages via Homebrew..."
    
    run brew update
    
    # Core tools
    run brew install \
        git \
        gh \
        stow \
        curl \
        wget \
        cmake \
        ripgrep \
        fd \
        fzf \
        node \
        python@3
    
    # Install coreutils for GNU versions of tools
    run brew install coreutils
}

do_install_packages_linux() {
    log_info "Installing packages via apt..."
    
    run_sudo apt update
    run_sudo apt install -y \
        git \
        gh \
        stow \
        curl \
        wget \
        build-essential \
        cmake \
        pkg-config \
        libssl-dev \
        ripgrep \
        fd-find \
        fzf \
        unzip \
        fontconfig \
        xclip \
        python3 \
        python3-pip \
        python3-venv \
        nodejs \
        npm
}

# ============================================================================
# Neovim Installation (Platform-specific)
# ============================================================================
do_install_nvim() {
    if is_macos; then
        do_install_nvim_macos
    else
        do_install_nvim_linux
    fi
}

do_install_nvim_macos() {
    log_info "Installing Neovim via Homebrew..."
    
    if $FORCE; then
        run brew uninstall neovim 2>/dev/null || true
    fi
    
    run brew install neovim
}

do_install_nvim_linux() {
    local nvim_version asset_name
    
    # Get latest version via gh if authenticated
    if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
        nvim_version=$(gh api repos/neovim/neovim/releases/latest --jq '.tag_name')
        log_info "Found latest Neovim version via gh: ${nvim_version}"
    else
        nvim_version="$NVIM_FALLBACK_VERSION"
        log_warn "gh not available/authenticated, using fallback: ${nvim_version}"
    fi
    
    # v0.11+ uses new asset naming
    local major_minor
    major_minor=$(echo "$nvim_version" | sed 's/v//' | cut -d. -f1,2)
    if awk "BEGIN {exit !($major_minor >= 0.11)}"; then
        asset_name="nvim-linux-x86_64"
    else
        asset_name="nvim-linux64"
    fi
    
    log_info "Downloading Neovim ${nvim_version}..."
    run curl -fLO "https://github.com/neovim/neovim/releases/download/${nvim_version}/${asset_name}.tar.gz"
    
    if [[ ! -f "${asset_name}.tar.gz" ]]; then
        log_error "Download failed"
        return 1
    fi
    
    local filesize
    filesize=$(get_file_size "${asset_name}.tar.gz")
    if [[ $filesize -lt 1000000 ]]; then
        log_error "Downloaded file too small (${filesize} bytes)"
        rm -f "${asset_name}.tar.gz"
        return 1
    fi
    
    run_sudo rm -rf /opt/nvim /opt/nvim-linux64 /opt/nvim-linux-x86_64
    run_sudo tar -C /opt -xzf "${asset_name}.tar.gz"
    run rm "${asset_name}.tar.gz"
    run_sudo ln -sf "/opt/${asset_name}/bin/nvim" /usr/local/bin/nvim
}

# ============================================================================
# Emacs Installation (Platform-specific)
# ============================================================================
do_install_emacs() {
    if is_macos; then
        log_info "Installing Emacs via Homebrew..."
        run brew install emacs
    else
        log_info "Installing Emacs via apt..."
        run_sudo apt install -y emacs
    fi
}

# ============================================================================
# Tmux Installation (Platform-specific)
# ============================================================================
do_install_tmux() {
    if is_macos; then
        log_info "Installing tmux via Homebrew..."
        run brew install tmux
    else
        log_info "Installing tmux via apt..."
        run_sudo apt install -y tmux
    fi
}

# ============================================================================
# Doom Emacs Installation (Cross-platform)
# ============================================================================
do_install_doom() {
    if [[ -d "$HOME/.emacs.d" ]]; then
        log_warn "Backing up ~/.emacs.d"
        run mv "$HOME/.emacs.d" "$HOME/.emacs.d.bak.$(date +%Y%m%d%H%M%S)"
    fi
    
    if [[ -d "$HOME/.config/emacs" ]]; then
        if $FORCE; then
            log_warn "Removing existing ~/.config/emacs"
            run rm -rf "$HOME/.config/emacs"
        else
            log_warn "Backing up ~/.config/emacs"
            run mv "$HOME/.config/emacs" "$HOME/.config/emacs.bak.$(date +%Y%m%d%H%M%S)"
        fi
    fi
    
    log_info "Cloning Doom Emacs..."
    run git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
    
    log_info "Running Doom install (this takes a few minutes)..."
    run ~/.config/emacs/bin/doom install --no-config --no-env
}

# ============================================================================
# Oh My Tmux Installation (Cross-platform)
# ============================================================================
do_install_oh_my_tmux() {
    if [[ -d "$HOME/.tmux" ]] && $FORCE; then
        log_warn "Removing existing ~/.tmux"
        run rm -rf "$HOME/.tmux"
    fi
    
    if [[ -f "$HOME/.tmux.conf" ]] && [[ ! -L "$HOME/.tmux.conf" ]]; then
        log_warn "Backing up ~/.tmux.conf"
        run mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.bak.$(date +%Y%m%d%H%M%S)"
    fi
    
    run git clone https://github.com/gpakosz/.tmux.git "$HOME/.tmux"
    run ln -sf "$HOME/.tmux/.tmux.conf" "$HOME/.tmux.conf"
    
    # Only copy template if .tmux.conf.local doesn't exist (might be stowed)
    if [[ ! -e "$HOME/.tmux.conf.local" ]]; then
        run cp "$HOME/.tmux/.tmux.conf.local" "$HOME/.tmux.conf.local"
    fi
}

# ============================================================================
# Bash-it Installation (Cross-platform)
# ============================================================================
do_install_bash_it() {
    if [[ -d "$HOME/.bash_it" ]] && $FORCE; then
        log_warn "Removing existing ~/.bash_it"
        run rm -rf "$HOME/.bash_it"
    fi
    
    run git clone --depth=1 https://github.com/Bash-it/bash-it.git "$HOME/.bash_it"
    run "$HOME/.bash_it/install.sh" --silent --no-modify-config
}

# ============================================================================
# ble.sh Installation (Cross-platform)
# ============================================================================
do_install_blesh() {
    if $FORCE; then
        run rm -rf "$HOME/.local/share/blesh"
        run rm -rf "$HOME/.local/share/blesh-src"
    fi
    
    run git clone --recursive --depth 1 --shallow-submodules \
        https://github.com/akinomyoga/ble.sh.git "$HOME/.local/share/blesh-src"
    
    cd "$HOME/.local/share/blesh-src"
    run make install PREFIX="$HOME/.local"
    cd "$HOME"
}

# ============================================================================
# Dotfiles Installation (Cross-platform)
# ============================================================================
do_install_dotfiles() {
    cd "$HOME"
    
    if [[ -d "$DOTFILES_DIR" ]]; then
        if $FORCE; then
            log_warn "Removing existing dotfiles directory"
            run rm -rf "$DOTFILES_DIR"
        else
            log_warn "Dotfiles exist, pulling latest"
            run git -C "$DOTFILES_DIR" pull
            return 0
        fi
    fi
    
    log_info "Cloning dotfiles..."
    if ! run git clone "$DOTFILES_REPO" "$DOTFILES_DIR" 2>/dev/null; then
        log_warn "SSH clone failed, trying HTTPS..."
        local https_repo
        https_repo=$(echo "$DOTFILES_REPO" | sed 's|git@github.com:|https://github.com/|')
        run git clone "$https_repo" "$DOTFILES_DIR"
    fi
}

do_stow_dotfiles() {
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        log_error "Dotfiles directory not found: $DOTFILES_DIR"
        return 1
    fi
    
    cd "$DOTFILES_DIR"
    
    log_info "Available packages: $(ls -1d */ 2>/dev/null | tr -d '/' | tr '\n' ' ')"
    log_info "Stowing: $STOW_PACKAGES"
    
    for pkg in $STOW_PACKAGES; do
        if [[ -d "$pkg" ]]; then
            log_info "Stowing $pkg..."
            run stow -D "$pkg" 2>/dev/null || true
            if ! run stow -v "$pkg" 2>&1; then
                log_warn "Conflict stowing $pkg - try: stow --adopt $pkg"
            fi
        else
            log_warn "Package not found: $pkg"
        fi
    done
    
    cd "$HOME"
}

# ============================================================================
# Uninstall Functions
# ============================================================================

do_uninstall_nvim() {
    log_remove "Neovim"
    
    if is_macos; then
        run brew uninstall neovim 2>/dev/null || true
    else
        run_sudo rm -rf /opt/nvim /opt/nvim-linux64 /opt/nvim-linux-x86_64
        run_sudo rm -f /usr/local/bin/nvim
    fi
    
    run rm -rf "$HOME/.local/share/nvim"
    run rm -rf "$HOME/.cache/nvim"
}

do_uninstall_doom() {
    log_remove "Doom Emacs"
    run rm -rf "$HOME/.config/emacs"
    run rm -rf "$HOME/.doom.d"
    run rm -rf "$HOME/.emacs.d"
    run rm -rf "$HOME/.local/share/doom"
    run rm -rf "$HOME/.cache/doom"
}

do_uninstall_oh_my_tmux() {
    log_remove "oh-my-tmux"
    run rm -rf "$HOME/.tmux"
    run rm -f "$HOME/.tmux.conf"
    run rm -f "$HOME/.tmux.conf.local"
}

do_uninstall_bash_it() {
    log_remove "bash-it"
    run rm -rf "$HOME/.bash_it"
}

do_uninstall_blesh() {
    log_remove "ble.sh"
    run rm -rf "$HOME/.local/share/blesh"
    run rm -rf "$HOME/.local/share/blesh-src"
    run rm -f "$HOME/.blerc"
}

do_uninstall_dotfiles() {
    log_remove "dotfiles symlinks"
    
    if [[ -d "$DOTFILES_DIR" ]]; then
        cd "$DOTFILES_DIR"
        for pkg in $STOW_PACKAGES; do
            if [[ -d "$pkg" ]]; then
                log_info "Unstowing $pkg..."
                run stow -D "$pkg" 2>/dev/null || true
            fi
        done
        cd "$HOME"
    fi
    
    if confirm "Remove dotfiles repo ($DOTFILES_DIR)?"; then
        run rm -rf "$DOTFILES_DIR"
        log_remove "dotfiles repo"
    else
        log_info "Keeping dotfiles repo"
    fi
}

do_restore_default_bashrc() {
    log_info "Restoring default shell config..."
    
    # Remove symlinks
    run rm -f "$HOME/.bashrc"
    run rm -f "$HOME/.bash_profile"
    run rm -f "$HOME/.inputrc"
    
    if is_macos; then
        # macOS: create minimal .bash_profile
        cat > "$HOME/.bash_profile" << 'BASHRC'
# ~/.bash_profile for macOS

# Load .bashrc if it exists
[[ -f ~/.bashrc ]] && source ~/.bashrc

# Homebrew
if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi
BASHRC

        cat > "$HOME/.bashrc" << 'BASHRC'
# ~/.bashrc for macOS

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# History
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000

# Prompt
PS1='\u@\h:\w\$ '

# Aliases
alias ls='ls -G'
alias ll='ls -alF'
alias la='ls -A'
BASHRC
        log_success "Created default macOS shell config"
    else
        # Linux: copy from /etc/skel or create minimal
        if [[ -f /etc/skel/.bashrc ]]; then
            run cp /etc/skel/.bashrc "$HOME/.bashrc"
            log_success "Restored default .bashrc from /etc/skel"
        else
            cat > "$HOME/.bashrc" << 'BASHRC'
# ~/.bashrc for Linux

case $- in
    *i*) ;;
      *) return;;
esac

HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s histappend
shopt -s checkwinsize

PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
fi

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
BASHRC
            log_success "Created minimal default .bashrc"
        fi
    fi
}

run_uninstall() {
    echo ""
    echo -e "${RED}${BOLD}=== UNINSTALL MODE (${DETECTED_OS}) ===${NC}"
    echo ""
    echo "This will remove the following components:"
    echo ""
    
    should_skip "nvim"      || echo "  • Neovim"
    should_skip "doom"      || echo "  • Doom Emacs (~/.config/emacs)"
    should_skip "oh-my-tmux"|| echo "  • oh-my-tmux (~/.tmux)"
    should_skip "bash-it"   || echo "  • bash-it (~/.bash_it)"
    should_skip "blesh"     || echo "  • ble.sh (~/.local/share/blesh)"
    should_skip "dotfiles"  || echo "  • dotfiles (symlinks + optionally repo)"
    should_skip "bashrc"    || echo "  • Custom shell config (restore default)"
    
    echo ""
    echo -e "${YELLOW}Note: System packages (brew/apt) will NOT be removed.${NC}"
    echo ""
    
    if ! $DRY_RUN && ! confirm "Proceed with uninstall?" "n"; then
        log_info "Uninstall cancelled"
        exit 0
    fi
    
    echo ""
    
    should_skip "nvim"       || do_uninstall_nvim
    should_skip "doom"       || do_uninstall_doom
    should_skip "oh-my-tmux" || do_uninstall_oh_my_tmux
    should_skip "bash-it"    || do_uninstall_bash_it
    should_skip "blesh"      || do_uninstall_blesh
    should_skip "dotfiles"   || do_uninstall_dotfiles
    should_skip "bashrc"     || do_restore_default_bashrc
    
    echo ""
    echo -e "${GREEN}Uninstall complete!${NC}"
    echo ""
    echo "To complete the reset:"
    echo "  1. Close this terminal"
    echo "  2. Open a new terminal"
    echo ""
    
    if is_macos; then
        echo "To remove Homebrew packages:"
        echo "  brew uninstall emacs tmux stow ripgrep fd fzf"
    else
        echo "To remove apt packages:"
        echo "  sudo apt remove emacs tmux stow ripgrep fd-find fzf"
    fi
    echo ""
}

# ============================================================================
# Summary
# ============================================================================
print_summary() {
    echo ""
    echo "============================================================"
    
    if [[ ${#ERRORS[@]} -eq 0 ]]; then
        echo -e "${GREEN}Installation Complete!${NC}"
    else
        echo -e "${YELLOW}Installation completed with errors:${NC}"
        for err in "${ERRORS[@]}"; do
            echo -e "  ${RED}•${NC} $err"
        done
    fi
    
    echo "============================================================"
    echo ""
    
    if $DRY_RUN; then
        echo "This was a dry run. No changes were made."
        echo "Run without --dry-run to apply changes."
        return
    fi
    
    cat << 'EOF'
Next steps:

1. Sync Doom Emacs with your config:
   ~/.config/emacs/bin/doom sync

2. Reload your shell:
   source ~/.bashrc

3. Verify tmux:
   tmux

EOF
}

# ============================================================================
# Main
# ============================================================================
main() {
    parse_args "$@"
    
    if $STATUS_ONLY; then
        show_status
        exit 0
    fi
    
    echo ""
    echo "============================================================"
    echo -e "${BOLD}Cross-Platform Bootstrap Script v${SCRIPT_VERSION}${NC}"
    echo -e "OS: ${CYAN}${DETECTED_OS}${NC}"
    if $DRY_RUN; then
        echo -e "${CYAN}DRY RUN MODE - No changes will be made${NC}"
    fi
    if $FORCE; then
        echo -e "${YELLOW}FORCE MODE - Will reinstall existing components${NC}"
    fi
    if $UNINSTALL; then
        echo -e "${RED}UNINSTALL MODE - Will remove components${NC}"
    fi
    echo "============================================================"
    echo ""
    
    if $UNINSTALL; then
        run_uninstall
        exit 0
    fi
    
    preflight_checks
    
    # System packages
    log_info "Installing system packages..."
    if ! should_skip "packages"; then
        if $DRY_RUN; then
            log_dry "Would install system packages"
        else
            do_install_packages
            log_success "System packages installed"
        fi
    else
        log_skip "packages (--skip flag)"
    fi
    
    # Nvim check differs by platform
    local nvim_check
    if is_macos; then
        nvim_check="command -v nvim"
    else
        nvim_check="command -v nvim && [[ -d /opt/nvim-linux-x86_64 || -d /opt/nvim-linux64 ]]"
    fi
    
    ensure_installed "nvim" "$nvim_check" do_install_nvim
    ensure_installed "emacs" "command -v emacs" do_install_emacs
    ensure_installed "tmux" "command -v tmux" do_install_tmux
    ensure_installed "oh-my-tmux" "[[ -d $HOME/.tmux ]]" do_install_oh_my_tmux
    ensure_installed "bash-it" "[[ -d $HOME/.bash_it ]]" do_install_bash_it
    ensure_installed "blesh" "[[ -d $HOME/.local/share/blesh ]]" do_install_blesh
    ensure_installed "doom" "[[ -f $HOME/.config/emacs/bin/doom ]]" do_install_doom
    ensure_installed "dotfiles" "[[ -d $DOTFILES_DIR ]]" do_install_dotfiles
    
    if ! should_skip "stow" && ! $DRY_RUN; then
        do_stow_dotfiles
    elif should_skip "stow"; then
        log_skip "stow (--skip flag)"
    else
        log_dry "Would stow dotfiles: $STOW_PACKAGES"
    fi
    
    if ! $DRY_RUN; then
        show_status
    fi
    
    print_summary
}

main "$@"
