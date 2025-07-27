local wezterm = require("wezterm")

local M = {}

---@class Config
---@field hosts? table
---@field trzsz_cmd? string
---@field timeout? number


---@type Config
local default_config = {
    hosts = { },
    trzsz_cmd = "trzsz",
    timeout = 0.5,
}



---@param t1 table
---@param t2 table
---@return table t
local function deep_merge_table(t1, t2)
    for k, v in pairs(t2) do
        if type(v) == "table" then
            if type(t1[k] or false) == "table" then
                deep_merge_table(t1[k] or {}, t2[k] or {})
            else
                t1[k] = v
            end
        else
            t1[k] = v
        end
    end

    return t1
end


---@param config unknown
---@param opts? Config
---@return unknown config
function M.apply_to_config(config, opts)

    ---@type Config
    opts = opts and deep_merge_table(default_config, opts) or default_config

    wezterm.on('user-var-changed', function(window, pane, name, serialized_args)
        -- When the 'wez_file_transfer' user var is set or updated by the terminal, 
        -- we will recive a serialized json string encodes informations include:
        --    * what is the remote server?
        --    * In what remote directory, the transission job should run in?
        --    * What transimssion command should run? 
        -- All these informations are encoded in the 'wez_file_transfer' UserVar. 
    
        if name ~= "wez_file_transfer" then  -- not a wez_file_transfer event. 
            return true
        end
    
        -- the 'serialized_args' is a json serialized string. 
        -- After deserializing, it contains a table like:
        --   {
        --      "cwd": "/path/to/the/dir/to/run/trz/or/tsz/",
        --      "cmd": ["trz", "--options", "..."],
        --      "user": "username to login to the remote server", 
        --      "host": "hostname of the remote server"
        --   }

        local json_decode = nil
        if wezterm.serde ~= nil then
            json_decode = wezterm.serde.json_decode
        else
            json_decode = wezterm.json_parse
        end

        local args = json_decode(serialized_args)
        wezterm.log_info("[wezrs] wez_file_transfer args: ", args)
    
        local trzsz_cmd = opts.trzsz_cmd
        local port = "22"
        local host = opts.hosts[args.host] or args.host
        if type(host) == 'table' then
            host = host.ip or args.host
            port = tostring(host.port or "22")
        end

        if host == nil or host == "" then
            local msg = string.format("[wezrs] Did not get correct ip/domain name for %s. Quit", args.host)
            wezterm.log_error(msg)
            pane:inject_output(string.format('\r\n%s', msg))
            return true
        end

        local timeout = opts.timeout
        local cwd = args.cwd
        local cmd = args.cmd
        local user = args.user
        
        local dest = string.format("%s@%s", user, host)
    
        -- Unfortunately, pane:split not working in mux domains.
        -- local new_pane = pane:split {
        --     args = {trzsz_cmd, "ssh", "-p", port, dest}, 
        --     domain = { DomainName = 'local' },
        --     direction = 'Bottom',
        -- }
        window:perform_action(wezterm.action.SpawnCommandInNewTab { 
            args = {trzsz_cmd, "ssh", "-p", port, dest}, 
            domain = { DomainName = 'local' },
         }, pane)

         wezterm.sleep_ms(timeout * 1000)
         local new_pane = window:active_pane()
    
        if new_pane ~= nil then 
            wezterm.log_info("[wezrs] created new pane for file transission. pane id is: ", new_pane:pane_id())
            local msg = new_pane:get_logical_lines_as_text(new_pane:get_dimensions().scrollback_rows)
            if string.find(msg, "exit_behavior=") then
                wezterm.log_error("[wezrs] It seems failed to login the remove server. quit.")
                window:perform_action(wezterm.action.CloseCurrentPane { confirm = true }, new_pane)
                pane:activate()
                pane:send_text("# Some error occurs to login to the remote server. Quit the transmission. Please open the debug overlay to see the logs.")
                return true
            end
        else
            wezterm.log_error("[wezrs] Failed to create pane for file transission")
            return true
        end
    
        new_pane:send_text(wezterm.shell_join_args {"cd", cwd})
        new_pane:send_text("\n")
        new_pane:send_text("echo -e '\\033[0;31m!! Warning !!\\033[0m: Please \\033[0;31mDO NOT\\033[0m close this pane unitil the transmission is completed. After transmission, you can close this pane, for example, by executing the 'exit' command or pressing Ctrl-D shortcut.' \n")
        new_pane:send_text(wezterm.shell_join_args(cmd))
        new_pane:send_text("\n")
    
        return true
    end)

    return config
end

return M
