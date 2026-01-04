if [[ $- == *i* ]] && [[ ! -v POETRY_ACTIVE ]] && [[ -f ~/.local/share/blesh/ble.sh ]]; then
    source ~/.local/share/blesh/ble.sh --noattach
fi

# If not running interactively, don't do anything
case $- in
    *i*) ;;
    *) return;;
esac

# Custom Alias
alias vim='nvim'
alias vi='nvim'

# Load Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Load Bash-It
export BASH_IT="$HOME/.bash_it"
source "$BASH_IT/bash_it.sh"

# source ~/gitstatus/gitstatus.prompt.sh


# Enable showing mode in prompt
#set show-mode-in-prompt on

# Set cursor shape for different vi modes
#set vi-cmd-mode-string "\1\e[2 q\2"  # Block cursor for command mode
#set vi-ins-mode-string "\1\e[6 q\2"  # Bar cursor for insert mode

export PATH="${HOME}/.local/bin:${PATH}"
#export PATH="/opt/homebrew/opt/python@3.11/bin:$PATH"
export PATH="/opt/homebrew/Cellar/grep/3.11/libexec/gnubin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


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
export IRC_CLIENT=false

# Set this to the command you use for todo.txt-cli
export TODO=false

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
export BASH_IT_COMMAND_DURATION=true
# You can choose the minimum time in seconds before
# command duration is displayed.
export COMMAND_DURATION_MIN_SECONDS=1

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

# Vi mode bindings for non-ble.sh shells (poetry shell, etc.)
if [[ ! ${BLE_VERSION-} ]]; then
    set -o vi
    bind -m vi-command 'Control-l: clear-screen'
    bind -m vi-insert 'Control-l: clear-screen'
fi

source ~/gitstatus/gitstatus.prompt.sh
eval "$(zoxide init bash)"

# Attach ble.sh if it was loaded
[[ ! -v POETRY_ACTIVE ]] && [[ ${BLE_VERSION-} ]] && ble-attach
