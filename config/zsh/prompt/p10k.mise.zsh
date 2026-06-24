# Powerlevel10k prompt segments for mise
# [Feature request: add segment for mise](https://github.com/romkatv/powerlevel10k/issues/2212)
# Usage in ~/.zshrc:
#   [[ -f ~/.config/shell/p10k.mise.zsh ]] && source ~/.config/shell/p10k.mise.zsh

() {
    # Cache global configurations at shell startup
    typeset -gA POWERLEVEL9K_MISE_GLOBAL_VERSIONS
    if (( $+commands[mise] )); then
        local tool version
        while read -r tool version; do
            [[ -n "$tool" ]] && POWERLEVEL9K_MISE_GLOBAL_VERSIONS[$tool]="$version"
        done < <(mise ls --offline 2>/dev/null | awk '{for (i=1; i<=NF; i++) {if ($i ~ /^~\/\.config\/mise\/config\.toml$/ || $i ~ /^~\/\.tool-versions$/ || $i ~ /^~\/\.mise\.toml$/) {print $1, $2; break}}}')
    fi

    # User configurations (can be overridden in ~/.zshrc or prompt config)
    [[ -z "${POWERLEVEL9K_MISE_MAX_SEGMENTS}" ]] && typeset -g POWERLEVEL9K_MISE_MAX_SEGMENTS=2
    [[ -z "${POWERLEVEL9K_MISE_HIDE_GLOBAL}" ]] && typeset -g POWERLEVEL9K_MISE_HIDE_GLOBAL=true

    function prompt_mise() {
        local dir tool version
        local -A seen
        local -i count=0
        local -i max_segments=$POWERLEVEL9K_MISE_MAX_SEGMENTS

        for dir in $path; do
            if [[ "$dir" == *mise/installs/* ]]; then
                local resolved_dir="${dir:A}"
                if [[ "$resolved_dir" =~ "mise/installs/([^/]+)/([^/]+)(/bin)?$" ]]; then
                    tool="${(U)match[1]}"
                    version="${match[2]}"
                    [[ "$tool" == "USAGE" ]] && continue
                    [[ -n "${seen[$tool]}" ]] && continue

                    # Hide if version matches global configuration
                    if [[ "$POWERLEVEL9K_MISE_HIDE_GLOBAL" == "true" ]]; then
                        local lower_tool="${(L)tool}"
                        if [[ "${POWERLEVEL9K_MISE_GLOBAL_VERSIONS[$lower_tool]}" == "$version" ]]; then
                            continue
                        fi
                    fi

                    # Check max segments limit
                    if (( max_segments > 0 && count >= max_segments )); then
                        break
                    fi

                    p10k segment -r -i "${tool}_ICON" -s "$tool" -t "$version"
                    seen[$tool]=1
                    (( count++ ))
                fi
            fi
        done
    }

    # Colors
    typeset -g POWERLEVEL9K_MISE_BACKGROUND=1

    typeset -g POWERLEVEL9K_MISE_DOTNET_CORE_BACKGROUND=93
    typeset -g POWERLEVEL9K_MISE_ELIXIR_BACKGROUND=129
    typeset -g POWERLEVEL9K_MISE_ERLANG_BACKGROUND=160
    typeset -g POWERLEVEL9K_MISE_FLUTTER_BACKGROUND=33
    typeset -g POWERLEVEL9K_MISE_GO_BACKGROUND=81
    typeset -g POWERLEVEL9K_MISE_HASKELL_BACKGROUND=99
    typeset -g POWERLEVEL9K_MISE_JAVA_BACKGROUND=196
    typeset -g POWERLEVEL9K_MISE_JULIA_BACKGROUND=34
    typeset -g POWERLEVEL9K_MISE_LUA_BACKGROUND=33
    typeset -g POWERLEVEL9K_MISE_NODE_BACKGROUND=34
    typeset -g POWERLEVEL9K_MISE_PERL_BACKGROUND=33
    typeset -g POWERLEVEL9K_MISE_PHP_BACKGROUND=93
    typeset -g POWERLEVEL9K_MISE_POSTGRES_BACKGROUND=33
    typeset -g POWERLEVEL9K_MISE_PYTHON_BACKGROUND=33
    typeset -g POWERLEVEL9K_MISE_RUBY_BACKGROUND=196
    typeset -g POWERLEVEL9K_MISE_RUST_BACKGROUND=208

    # Substitute the default asdf prompt element
    typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=("${POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS[@]/asdf/mise}")
}

