#!/usr/bin/env bash
#
# WSL Ubuntu 24.04 Bootstrap Script
# Installs: stow, emacs, doom-emacs, tmux, oh-my-tmux, bash-it, ble.sh, nvim
# Then clones and stows dotfiles
#
# Usage: curl -fsSL <raw-url> | bash
#    or: chmod +x wsl-bootstrap.sh && ./wsl-bootstrap.sh
#

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================
DOTFILES_REPO="git@github.com:cybergoatpsyops/dotfiles-ng.git"
DOTFILES_DIR="$HOME/dotfiles"

# Stow packages to link (space-separated)
# Your repo structure:
#   bash/           -> ~/.bashrc, ~/.bash_profile, etc.
#   doom/.doom.d/   -> ~/.doom.d/
#   tmux/.config/tmux/ -> ~/.config/tmux/
#   wezterm/.config/wezterm/ -> skip on WSL (Windows Terminal instead)
STOW_PACKAGES="bash doom tmux"

# ============================================================================
# Colors for output
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# ============================================================================
# Pre-flight checks
# ============================================================================
preflight_checks() {
    log_info "Running preflight checks..."
    
    # Check if running in WSL
    if grep -qi microsoft /proc/version 2>/dev/null; then
        log_success "WSL environment detected"
    else
        log_warn "Not running in WSL - script may still work on native Ubuntu"
    fi

    # Check Ubuntu version
    if command -v lsb_release &>/dev/null; then
        UBUNTU_VERSION=$(lsb_release -rs)
        log_info "Ubuntu version: $UBUNTU_VERSION"
    fi
}

# ============================================================================
# System package installation
# ============================================================================
install_system_packages() {
    log_info "Updating package lists..."
    sudo apt update

    log_info "Installing base packages..."
    sudo apt install -y \
        git \
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

    log_success "Base packages installed"
}

# ============================================================================
# Neovim (latest stable from GitHub releases)
# ============================================================================
install_nvim() {
    log_info "Installing Neovim..."
    
    # Remove old nvim if exists
    sudo apt remove -y neovim 2>/dev/null || true
    
    # Get latest stable release
    NVIM_VERSION=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    
    log_info "Downloading Neovim ${NVIM_VERSION}..."
    curl -LO "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux64.tar.gz"
    
    sudo rm -rf /opt/nvim
    sudo tar -C /opt -xzf nvim-linux64.tar.gz
    rm nvim-linux64.tar.gz
    
    # Add to path via symlink
    sudo ln -sf /opt/nvim-linux64/bin/nvim /usr/local/bin/nvim
    
    log_success "Neovim ${NVIM_VERSION} installed"
}

# ============================================================================
# Emacs
# ============================================================================
install_emacs() {
    log_info "Installing Emacs..."
    
    # Ubuntu 24.04 has Emacs 29 in repos which is good for Doom
    sudo apt install -y emacs
    
    EMACS_VERSION=$(emacs --version | head -1)
    log_success "Installed: $EMACS_VERSION"
}

# ============================================================================
# Doom Emacs
# ============================================================================
install_doom_emacs() {
    log_info "Installing Doom Emacs..."
    
    # Backup existing emacs config if present
    if [[ -d "$HOME/.emacs.d" ]]; then
        log_warn "Existing ~/.emacs.d found, backing up to ~/.emacs.d.bak"
        mv "$HOME/.emacs.d" "$HOME/.emacs.d.bak.$(date +%Y%m%d%H%M%S)"
    fi
    
    if [[ -d "$HOME/.config/emacs" ]]; then
        log_warn "Existing ~/.config/emacs found, backing up"
        mv "$HOME/.config/emacs" "$HOME/.config/emacs.bak.$(date +%Y%m%d%H%M%S)"
    fi
    
    # Clone Doom into ~/.config/emacs (the Doom installation itself)
    git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
    
    # NOTE: We use --no-config because your dotfiles will stow ~/.doom.d
    # The install order is:
    #   1. Install Doom (this function)
    #   2. Stow dotfiles (creates ~/.doom.d symlink)
    #   3. Run doom sync (post-install)
    log_info "Running Doom install (this takes a few minutes)..."
    log_info "Using --no-config since your dotfiles provide ~/.doom.d"
    ~/.config/emacs/bin/doom install --no-config --no-env --no-fonts
    
    log_success "Doom Emacs framework installed to ~/.config/emacs"
    log_info "Your private config will be symlinked to ~/.doom.d via stow"
    log_info "After stowing, run: ~/.config/emacs/bin/doom sync"
}

# ============================================================================
# tmux
# ============================================================================
install_tmux() {
    log_info "Installing tmux..."
    sudo apt install -y tmux
    log_success "tmux installed: $(tmux -V)"
}

# ============================================================================
# Oh My Tmux (OPTIONAL - your dotfiles may already have tmux config)
# ============================================================================
install_oh_my_tmux() {
    log_info "Checking Oh My Tmux installation..."
    
    # Your dotfiles use ~/.config/tmux/ (XDG path)
    # Oh-my-tmux uses ~/.tmux.conf (legacy path)
    # These can coexist, but you may want to skip if your config is complete
    
    if [[ -d "$HOME/.tmux" ]]; then
        log_warn "~/.tmux already exists, skipping oh-my-tmux"
        return
    fi
    
    read -p "Install Oh My Tmux? Your dotfiles have tmux config already. (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping Oh My Tmux (using your dotfiles config only)"
        return
    fi
    
    # Backup existing tmux config
    if [[ -f "$HOME/.tmux.conf" ]]; then
        log_warn "Existing ~/.tmux.conf found, backing up"
        mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.bak.$(date +%Y%m%d%H%M%S)"
    fi
    
    # Clone oh-my-tmux
    git clone https://github.com/gpakosz/.tmux.git "$HOME/.tmux"
    
    # Create symlink for base config
    ln -sf "$HOME/.tmux/.tmux.conf" "$HOME/.tmux.conf"
    
    # Copy local config template (this is where customizations go)
    cp "$HOME/.tmux/.tmux.conf.local" "$HOME/.tmux.conf.local"
    
    log_success "Oh My Tmux installed"
    log_info "Note: tmux checks ~/.config/tmux/tmux.conf (XDG) before ~/.tmux.conf"
    log_info "Your stowed config in ~/.config/tmux/ will take precedence"
}

# ============================================================================
# Bash-it
# ============================================================================
install_bash_it() {
    log_info "Installing Bash-it..."
    
    # Clone bash-it
    git clone --depth=1 https://github.com/Bash-it/bash-it.git "$HOME/.bash_it"
    
    # Run install script (interactive mode disabled)
    # The --silent flag prevents it from modifying .bashrc
    "$HOME/.bash_it/install.sh" --silent --no-modify-config
    
    log_success "Bash-it installed"
    log_info "Add to .bashrc: source \"\$HOME/.bash_it/bash_it.sh\""
}

# ============================================================================
# ble.sh (Bash Line Editor)
# ============================================================================
install_blesh() {
    log_info "Installing ble.sh..."
    
    # Clone and build ble.sh
    git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git "$HOME/.local/share/blesh-src"
    
    cd "$HOME/.local/share/blesh-src"
    make install PREFIX="$HOME/.local"
    cd -
    
    log_success "ble.sh installed"
    log_info "Add to .bashrc (at the TOP): [[ \$- == *i* ]] && source \"\$HOME/.local/share/blesh/ble.sh\" --noattach"
    log_info "Add to .bashrc (at the BOTTOM): [[ \${BLE_VERSION-} ]] && ble-attach"
}

# ============================================================================
# Clone dotfiles repo
# ============================================================================
clone_dotfiles() {
    log_info "Cloning dotfiles repository..."
    
    if [[ -d "$DOTFILES_DIR" ]]; then
        log_warn "Dotfiles directory already exists at $DOTFILES_DIR"
        read -p "Remove and re-clone? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$DOTFILES_DIR"
        else
            log_info "Skipping clone, using existing directory"
            return
        fi
    fi
    
    # Try SSH first, fall back to HTTPS
    if git clone "$DOTFILES_REPO" "$DOTFILES_DIR" 2>/dev/null; then
        log_success "Dotfiles cloned via SSH"
    else
        log_warn "SSH clone failed, trying HTTPS..."
        HTTPS_REPO=$(echo "$DOTFILES_REPO" | sed 's|git@github.com:|https://github.com/|')
        git clone "$HTTPS_REPO" "$DOTFILES_DIR"
        log_success "Dotfiles cloned via HTTPS"
    fi
}

# ============================================================================
# Stow dotfiles
# ============================================================================
stow_dotfiles() {
    log_info "Stowing dotfiles..."
    
    cd "$DOTFILES_DIR"
    
    # List available packages
    log_info "Available packages in dotfiles repo:"
    ls -1d */ 2>/dev/null | sed 's|/$||' || log_warn "No subdirectories found"
    
    echo ""
    log_info "Attempting to stow: $STOW_PACKAGES"
    
    for pkg in $STOW_PACKAGES; do
        if [[ -d "$pkg" ]]; then
            log_info "Stowing $pkg..."
            # Use --adopt to pull in existing files, then you can review/commit
            # Use -n for dry-run first time
            if stow -v "$pkg" 2>&1; then
                log_success "Stowed: $pkg"
            else
                log_error "Failed to stow: $pkg (conflicts exist?)"
                log_info "Try: cd $DOTFILES_DIR && stow --adopt $pkg"
            fi
        else
            log_warn "Package not found: $pkg"
        fi
    done
    
    cd -
}

# ============================================================================
# Post-install configuration hints
# ============================================================================
post_install_hints() {
    echo ""
    echo "============================================================"
    echo -e "${GREEN}Installation Complete!${NC}"
    echo "============================================================"
    echo ""
    echo "Your dotfiles packages:"
    echo "  bash   -> ~/.bashrc, ~/.bash_profile, etc."
    echo "  doom   -> ~/.doom.d/ (Doom Emacs private config)"
    echo "  tmux   -> ~/.config/tmux/"
    echo "  wezterm -> skipped (use Windows Terminal on WSL)"
    echo ""
    echo "Next steps:"
    echo ""
    echo "1. Verify stow worked:"
    echo "   ls -la ~/.bashrc ~/.doom.d ~/.config/tmux"
    echo ""
    echo "2. IMPORTANT: Sync Doom Emacs with your config:"
    echo "   ~/.config/emacs/bin/doom sync"
    echo ""
    echo "3. Add doom to your PATH (in your .bashrc):"
    echo "   export PATH=\"\$HOME/.config/emacs/bin:\$PATH\""
    echo ""
    echo "4. Source your new bash config:"
    echo "   source ~/.bashrc"
    echo ""
    echo "5. If SSH clone failed, set up keys:"
    echo "   ssh-keygen -t ed25519 -C \"your_email@example.com\""
    echo "   cat ~/.ssh/id_ed25519.pub  # add to GitHub"
    echo "   cd $DOTFILES_DIR && git remote set-url origin git@github.com:cybergoatpsyops/dotfiles-ng.git"
    echo ""
    echo "6. Test everything:"
    echo "   tmux      # should load your config"
    echo "   emacs     # should launch Doom"
    echo ""
    echo "============================================================"
}

# ============================================================================
# Main
# ============================================================================
main() {
    echo ""
    echo "============================================================"
    echo "WSL Ubuntu Bootstrap Script"
    echo "============================================================"
    echo ""
    
    preflight_checks
    
    install_system_packages
    install_nvim
    install_emacs
    install_tmux
    
    # These modify home directory, so order matters
    install_oh_my_tmux
    install_bash_it
    install_blesh
    
    # Doom last since it takes longest
    install_doom_emacs
    
    # Clone and stow dotfiles
    clone_dotfiles
    stow_dotfiles
    
    post_install_hints
}

# Run if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
