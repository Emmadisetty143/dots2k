#!/usr/bin/env bash
__build_ys_prompt() {
    local exit_val=$?
    local start_esc="" end_esc="" user_esc="" host_esc="" dir_esc="" time_esc="" prompt_char=""

    if [[ -n "$ZSH_VERSION" ]]; then
        start_esc="%{"
        end_esc="%}"
        user_esc="%n"
        host_esc="%m"
        dir_esc="%~"
        time_esc="%D{%I:%M:%S %P}"
        prompt_char="%#"
    else
        echo -ne "\033]0;${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/\~}\007"
        start_esc="\["
        end_esc="\]"
        user_esc="\u"
        host_esc="\h"
        dir_esc="\w"
        time_esc="\D{%I:%M:%S %P}"
        prompt_char="\\\$"
    fi

    # Define escape and newline characters natively
    local esc=$'\e'
    local newline=$'\n'

    # ANSI Colors
    local reset="${start_esc}${esc}[0m${end_esc}"
    local bold_blue="${start_esc}${esc}[1;34m${end_esc}"
    local blue="${start_esc}${esc}[34m${end_esc}"
    local green="${start_esc}${esc}[32m${end_esc}"
    local yellow="${start_esc}${esc}[33m${end_esc}"
    local bold_yellow="${start_esc}${esc}[1;33m${end_esc}"
    local cyan="${start_esc}${esc}[36m${end_esc}"
    local red="${start_esc}${esc}[31m${end_esc}"
    local bold_red="${start_esc}${esc}[1;31m${end_esc}"
    local bg_yellow_fg_black="${start_esc}${esc}[43;30m${end_esc}"

    # Privileges and Username
    local user_part=""
    if [[ ${EUID} == 0 ]]; then
        user_part="${bg_yellow_fg_black}${user_esc}${reset}"
    else
        user_part="${cyan}${user_esc}${reset}"
    fi

    # Git details
    local git_part=""
    local branch
    if branch=$(git symbolic-ref --short HEAD 2>/dev/null); then
        local status_color="${green}"
        local status_char="o"
        if ! git diff-index --quiet HEAD -- 2>/dev/null ||
            [[ -n "$(git ls-files --others --exclude-standard --directory --no-empty-directory --max-depth=1 2>/dev/null | head -n 1)" ]]; then
            status_color="${red}"
            status_char="x"
        fi
        git_part=" on ${blue}git${cyan}:${branch}${status_color} ${status_char}${reset}"
    fi

    # Exit code detail
    local exit_part=""
    if [[ $exit_val -ne 0 ]]; then
        exit_part=" ${red}C:${exit_val}${reset}"
    fi

    # Assemble prompt
    local result_prompt="${newline}${bold_blue}#${reset} ${user_part} @ ${green}${host_esc}${reset} in ${bold_yellow}${dir_esc}${reset}${git_part} ${time_esc}${exit_part}${newline}${bold_red}${prompt_char}${reset} "

    if [[ -n "$ZSH_VERSION" ]]; then
        PROMPT="$result_prompt"
    else
        PS1="$result_prompt"
    fi
}

if [[ -n "$ZSH_VERSION" ]]; then
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd __build_ys_prompt
else
    PROMPT_COMMAND=__build_ys_prompt
fi
