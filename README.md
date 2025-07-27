# wezrs (wezr/wezs)


## Overview
`wezrs` is an inline file transfer tool based on [`trzsz`](https://github.com/trzsz/trzsz-go)
and ment to be used in the Wezterm software. 

## Usage
### `wezr` upload files to the remote server
```
usage: wezr [-h] [-v] [-q] [-y] [-b] [-e] [-d] [-B N] [-t N] [path]

Receive file(s), similar to rz and compatible with tmux.

positional arguments:
  path               path to save file(s). (default: current directory)

optional arguments:
  -h, --help         show this help message and exit
  -v, --version      show program's version number and exit
  -q, --quiet        quiet (hide progress bar)
  -y, --overwrite    yes, overwrite existing file(s)
  -b, --binary       binary transfer mode, faster for binary files
  -e, --escape       escape all known control characters
  -d, --directory    transfer directories and files
  -r, --recursive    transfer directories and files, same as -d
  -B N, --bufsize N  max buffer chunk size (1K<=N<=1G). (default: 10M)
  -t N, --timeout N  timeout ( N seconds ) for each buffer chunk.
                     N <= 0 means never timeout. (default: 20)
```

### `wezs` download files from the remote server
```
usage: tsz [-h] [-v] [-q] [-y] [-b] [-e] [-d] [-B N] [-t N] file [file ...]

Send file(s), similar to sz and compatible with tmux.

positional arguments:
  file               file(s) to be sent

optional arguments:
  -h, --help         show this help message and exit
  -v, --version      show program's version number and exit
  -q, --quiet        quiet (hide progress bar)
  -y, --overwrite    yes, overwrite existing file(s)
  -b, --binary       binary transfer mode, faster for binary files
  -e, --escape       escape all known control characters
  -d, --directory    transfer directories and files
  -r, --recursive    transfer directories and files, same as -d
  -B N, --bufsize N  max buffer chunk size (1K<=N<=1G). (default: 10M)
  -t N, --timeout N  timeout ( N seconds ) for each buffer chunk.
                     N <= 0 means never timeout. (default: 20)
```

## Installation
Currently, this tool only supports Unix-like systems with the `fish` shell. Support for `bash` and `zsh` shells is coming soon.

1. Install the depencencies
   - [`trzsz`](https://github.com/trzsz/trzsz): Please follow the [offical instructions](https://trzsz.github.io/go) to install the `trzsz` tools on both the local and 
   - `base64`: In most distributions, `base64` is installed by default. Users can use `base64 -h` to test if it works. 
2. Install the shell init script. 
   - For `fish`, download [wezrs.fish](https://raw.githubusercontent.com/expnn/wezrs/master/deps/wezrs.fish), and put it in the `$HOME/.config/fish/conf.d/` directory on the remote machine. Restart the shell or source this file to apply the changes.
   - For `bash` or `zsh`, download [wezrs.bash](https://raw.githubusercontent.com/expnn/wezrs/master/deps/wezrs.sh), 
     and put it anywhere you prefer on the remote machine and source it in the `~/.bashrc` or `~/.zshrc` file, respectively. Restart the shell or source this file to apply the changes.
3. Configure wezterm: add the following snippet to the wezterm configuration file on the local machine.
   ```lua
   wezterm.plugin.require("https://github.com/expnn/wezrs").apply_to_config(config, {
       trzsz_cmd = "/opt/homebrew/bin/trzsz",  -- absolute path to the trzsz executable. Wezterm uses a restricted PATH environment variable, which can result in a failure to find the trzsz command. 
       hosts = {},  -- a dict of hostname to ip and port. can be omitted if you have configured the SSH client such that `ssh user@hostname` 
       -- hosts = { 
       --   ['example.org'] = { 
       --       ip = "192.168.x.x", 
       --       port = 2222 
       --   },   -- -> generate connection by: ssh -p 2222 user@192.168.x.x, where user is obtained automatically by the wezs/wezr commands. 
       --   "host" = "10.10.101.11"   -- port defaults to 22. 
       -- }
       timeout = 0.5, -- wait for 0.5 seconds for the login. 
   })
   ```

## Screenshot

Upload files to the remote server:

[![upload video](https://img.youtube.com/vi/8jNuF_gvy0w/maxresdefault.jpg)](https://youtu.be/8jNuF_gvy0w)

Download files from the remote server:

[![upload video](https://img.youtube.com/vi/N5jy9dKO2-0/maxresdefault.jpg)](https://youtu.be/N5jy9dKO2-0)
