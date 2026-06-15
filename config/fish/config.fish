if status is-interactive
    function source_if_exists
        if test -f $argv[1]
            source $argv[1]
        end
    end

    function init_tool
        if type -q $argv[1]
            eval "$argv[2]"
        end
    end

    set -l cache_dir $HOME/.cache/shell_init
    if not test -d $cache_dir
        mkdir -p $cache_dir
    end

    function cache_fish_init
        set -l cache_dir $HOME/.cache/shell_init
        set -l tool $argv[1]
        set -l init_cmd $argv[2]
        if not test -f $cache_dir/$tool.fish
            if type -q $tool
                eval $init_cmd > $cache_dir/$tool.fish
            end
        end
        if test -f $cache_dir/$tool.fish
            source $cache_dir/$tool.fish
        end
    end

    cache_fish_init fzf "fzf --fish"
    cache_fish_init zoxide "zoxide init fish"
    cache_fish_init mise "mise activate fish"
    cache_fish_init navi "navi widget fish"

    functions -e cache_fish_init

    # Source shell config files
    for file in aliases.sh local.sh
        source_if_exists $HOME/.config/shell/$file
    end

    # Mac-specific configuration
    if string match -q "darwin*" (uname -s)
        set -l mac_config_dir ~/.config/mac
        for file in environment.sh aliases.sh
            source_if_exists $mac_config_dir/$file
        end
    end
end

