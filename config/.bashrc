#!/bin/bash
IS_MAC=false
[[ "$OSTYPE" == "darwin"* ]] && IS_MAC=true

source ~/.config/shell/prompt.sh

complete -cf sudo
shopt -s checkwinsize
shopt -s expand_aliases
shopt -s histappend

# bash completions
[ -r /usr/share/bash-completion/bash_completion ] && source /usr/share/bash-completion/bash_completion

source ~/.config/shell/environment.sh
$IS_MAC && [ -f ~/.config/mac/environment.sh ] && source ~/.config/mac/environment.sh
source ~/.config/shell/functions.sh
source ~/.config/shell/aliases.sh
$IS_MAC && [ -f ~/.config/mac/aliases.sh ] && source ~/.config/mac/aliases.sh

alias reload="source ~/.bashrc"

# Tool confs for bash
if type navi >/dev/null 2>&1; then eval "$(navi widget bash)"; fi
if type zoxide >/dev/null 2>&1; then eval "$(zoxide init bash)"; fi
if type fzf >/dev/null 2>&1; then eval "$(fzf --bash)"; fi
if type mise >/dev/null 2>&1; then eval "$(mise activate bash)"; fi

# Local configurations
[ -f ~/.config/shell/local.sh ] && source ~/.config/shell/local.sh
