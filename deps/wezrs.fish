if status is-interactive; and type -q base64; and type -q trzsz
    function __wezrs_get_base64_version
        if not set -q WEZRS_BASE64_VERSION
            set -xg WEZRS_BASE64_VERSION (base64 --version  2> /dev/null)
        end
    end

    function __wezrs_b64_encode
        __wezrs_get_base64_version
        if string match -r "GNU" $WEZRS_BASE64_VERSION &> /dev/null
            base64 -w0  # Disable line wrap
        else
            base64
        end
    end

    # function __wezrs_b64_decode
    #     __wezrs_get_base64_version
    #     if string match -r "fourmilab" $WEZRS_BASE64_VERSION &> /dev/null
    #         set BASE64ARG -d
    #     else if string match -r "GNU" $WEZRS_BASE64_VERSION &> /dev/null
    #         set BASE64ARG -di
    #     else
    #         set BASE64ARG -D
    #     end
    #     base64 $BASE64ARG
    # end

    function __wezrs_show_help
        if contains -- -h $argv or contains -- --help $argv
            $argv[1] -h &| sed "1s/$argv[1]/$argv[2]/" 
            true 
        else 
            false
        end
    end

    function __wezrs_set_usr_var
        set -l cmd  $(printf %s\n $argv | jq -R -s -c 'split("\n")[:-1]')
        set -l args $(jq -n -c --arg user "$USER" --arg host (hostname) --argjson cmd $cmd --arg cwd $PWD '{user: $user, host: $host, cmd: $cmd, cwd: $cwd}')
        
        # printf "SetUserVar=wez_file_transfer=%s" $args
        if [ -z "$TMUX" ]
            printf "\033]1337;SetUserVar=wez_file_transfer=%s\007" $(echo $args | __wezrs_b64_encode)
        else
            # <https://github.com/tmux/tmux/wiki/FAQ#what-is-the-passthrough-escape-sequence-and-how-do-i-use-it>
            # Note that you ALSO need to add "set -g allow-passthrough on" to your tmux.conf
            printf "\033Ptmux;\033\033]1337;SetUserVar=wez_file_transfer=%s\007\033\\" $(echo $args | __wezrs_b64_encode)
        end
    end

    function wezs -d "Download (send) data from the server back to local" -w tsz
        __wezrs_show_help tsz wezs $argv
        or __wezrs_set_usr_var tsz $argv
    end


    function wezr -d "Recieve data on the remote servert, from the local" -w trz
        __wezrs_show_help tsz wezr $argv
        or __wezrs_set_usr_var trz $argv
    end
end
