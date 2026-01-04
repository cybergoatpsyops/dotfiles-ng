#if [[ $- == *i* ]] && [[ -f ~/.local/share/blesh/ble.sh ]]; then
#  source ~/.local/share/blesh/ble.sh
#fi

# Base PATH setup
export PATH="${HOME}/.local/bin:${PATH}"
export PATH="/opt/homebrew/bin:${PATH}"
export PATH="/usr/local/bin:${PATH}"

# Homebrew specific paths
export PATH="${HOMEBREW_PREFIX}/opt/openssl/bin:${PATH}"
export PATH="/usr/local/sbin:${PATH}"
export PATH="/usr/local/opt/grep/libexec/gnubin:${PATH}"

# Python specific configuration
#export PATH="/opt/homebrew/opt/python@3.11/bin:${PATH}"
#export PYTHONPATH="/opt/homebrew/opt/python@3.11/lib/python3.11/site-packages:${PYTHONPATH}"

# Homebrew grep
export PATH="/opt/homebrew/Cellar/grep/3.11/libexec/gnubin:$PATH"

# Keep Python aliases
#alias python="/opt/homebrew/opt/python@3.11/bin/python3.11"
#alias python3="/opt/homebrew/opt/python@3.11/bin/python3.11"

# Python aliases - cover all common commands
#alias python="/opt/homebrew/opt/python@3.11/bin/python3.11"
#alias python3="/opt/homebrew/opt/python@3.11/bin/python3.11"
#alias pip="/opt/homebrew/opt/python@3.11/bin/pip3.11"
#alias pip3="/opt/homebrew/opt/python@3.11/bin/pip3.11"

# Load .bashrc for interactive shells
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

# Enable showing mode in prompt
#set show-mode-in-prompt on

# Set cursor shape for different vi modes
#set vi-cmd-mode-string "\1\e[2 q\2"  # Block cursor for command mode
#set vi-ins-mode-string "\1\e[6 q\2"  # Bar cursor for insert mode

# clear screen in VI mode
bind -m vi-command 'Control-l: clear-screen'
bind -m vi-insert 'Control-l: clear-screen'


# tmux function when WezTerm starts
create_session() {
    local session_name=$1
    tmux new-session -d -s "$session_name"
    tmux split-window -h -t "$session_name:0"
    tmux select-pane -t "$session_name:0.0"
    tmux new-window -t "$session_name:1"
    tmux split-window -h -t "$session_name:1"
    tmux select-pane -t "$session_name:1.0"
}


# If not running interactively, don't do anything
case $- in
  *i*) ;;
    *) return;;
esac

# Path to the bash it configuration
export BASH_IT="/Users/lbastidas/.bash_it"

# Lock and Load a custom theme file.
# Leave empty to disable theming.
# location /.bash_it/themes/
export BASH_IT_THEME='bobby-python'
#THEME_SHOW_PYTHON='true'
#THEME_SHOW_CLOCK='true'
#THEME_SHOW_BATTERY='true'

# Some themes can show whether `sudo` has a current token or not.
# Set `$THEME_CHECK_SUDO` to `true` to check every prompt:
THEME_CHECK_SUDO='true'

# (Advanced): Change this to the name of your remote repo if you
# cloned bash-it with a remote other than origin such as `bash-it`.
# export BASH_IT_REMOTE='bash-it'

# (Advanced): Change this to the name of the main development branch if
# you renamed it or if it was changed for some reason
# export BASH_IT_DEVELOPMENT_BRANCH='master'

# Your place for hosting Git repos. I use this for private repos.
export GIT_HOSTING='git@git.domain.com'

# Don't check mail when opening terminal.
unset MAILCHECK

# Change this to your console based IRC client of choice.
export IRC_CLIENT='irssi'

# Set this to the command you use for todo.txt-cli
export TODO="t"

# Set this to the location of your work or project folders
#BASH_IT_PROJECT_PATHS="${HOME}/Projects:/Volumes/work/src"

# Set this to false to turn off version control status checking within the prompt for all themes
export SCM_CHECK=true
# Set to actual location of gitstatus directory if installed
#export SCM_GIT_GITSTATUS_DIR="$HOME/gitstatus"
# per default gitstatus uses 2 times as many threads as CPU cores, you can change this here if you must
#export GITSTATUS_NUM_THREADS=8

# Set Xterm/screen/Tmux title with only a short hostname.
# Uncomment this (or set SHORT_HOSTNAME to something else),
# Will otherwise fall back on $HOSTNAME.
#export SHORT_HOSTNAME=$(hostname -s)

# Set Xterm/screen/Tmux title with only a short username.
# Uncomment this (or set SHORT_USER to something else),
# Will otherwise fall back on $USER.
#export SHORT_USER=${USER:0:8}

# If your theme use command duration, uncomment this to
# enable display of last command duration.
#export BASH_IT_COMMAND_DURATION=true
# You can choose the minimum time in seconds before
# command duration is displayed.
#export COMMAND_DURATION_MIN_SECONDS=1

# Set Xterm/screen/Tmux title with shortened command and directory.
# Uncomment this to set.
#export SHORT_TERM_LINE=true

# Set vcprompt executable path for scm advance info in prompt (demula theme)
# https://github.com/djl/vcprompt
#export VCPROMPT_EXECUTABLE=~/.vcprompt/bin/vcprompt

# (Advanced): Uncomment this to make Bash-it reload itself automatically
# after enabling or disabling aliases, plugins, and completions.
# export BASH_IT_AUTOMATIC_RELOAD_AFTER_CONFIG_CHANGE=1

# Uncomment this to make Bash-it create alias reload.
# export BASH_IT_RELOAD_LEGACY=1


# Load Bash It
source "$BASH_IT"/bash_it.sh


eval "$(/opt/homebrew/bin/brew shellenv)"

# Alias for tmux with custom config
alias tm='~/.local/bin/tmux-init.sh'
alias tk='tmux kill-server'

# clear screen in VI mode
#bind -m vi-command 'Control-l: clear-screen'
#bind -m vi-insert 'Control-l: clear-screen'


# SSH wrapper function for background color changes
ssh() {
    # Lighter purple background
    printf '\033]11;#5d4e75\007'
    printf '\033]10;#ebdbb2\007'
    
    command ssh "$@"
    
    # Restore gruvbox dark
    printf '\033]11;#282828\007'
    printf '\033]10;#ebdbb2\007'
}
