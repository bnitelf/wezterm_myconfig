
## How to use 

Clone to local 

### Linux / WSL

```bash
git clone https://github.com/bnitelf/wezterm_myconfig.git ~/.config/wezterm
```

### Windows (PowerShell)

```bash
git clone https://github.com/bnitelf/wezterm_myconfig.git "$HOME\.config\wezterm"
```

Then   

__Option 1: Add env var `WEZTERM_CONFIG_FILE` (Recommended)__
```
WEZTERM_CONFIG_FILE = C:\Users\{your_username}\.config\wezterm\.wezterm.lua
```
then launch wezterm normally.


__Option 2: Launch Wezterm with__
```bash
# Linux 
westerm ~/.config/wezterm/.wezterm.lua

# Windows
# create shortcut 
# -> right click -> properties
# -> shortcut tab
# -> in Target field add 
{your_root}\wezterm-gui.exe --config-file "C:\Users\{your_username}\.config\wezterm\.wezterm.lua"
```

__Cons__   
on Window, if you pin shortcut to Taskbar / Start, it won't use the our custom wezterm config file.

## Set Powershell profile to send OSC 7
To Terminal Emulator, in this case wezterm

by default powershell doesn't broadcast OSC 7   
this cause current working directory(cwd) detected by wezterm is not up-to-date   

For example   
- You start wezterm in `C:\Users\{your_username}`
- You cd to `D:\git\your_reponame`
- Wezterm still detect cwd to `C:\Users\{your_username}` 
- but the correct should be `D:\git\your_reponame`

Check where is powershell profile locate
```Powershell
# Powershell
$PROFILE

# This output something like 
# C:\Users\{your_username}\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
```

Add this function to Powershell profile
```Powershell
function prompt {
    $p = $executionContext.SessionState.Path.CurrentLocation
    $pathStr = $p.ProviderPath -replace '\\', '/'
    
    # Construct OSC 7 string
    $osc7 = "$([char]27)]7;file://$env:COMPUTERNAME/$pathStr$([char]27)\"
    
    # Write OSC 7 to the terminal and return standard prompt text
    Write-Host -NoNewline $osc7
    return "PS $p> "
}
```

without adding this function, custom wezterm tab title won't work.

## Add wezterm API Type Definition (optional)
In case you want to write wezterm lua config and want to have autocomplete (I tested on Zed Editor, it worked)

```bash
git clone https://github.com/DrKJeff16/wezterm-types.git
```

__My preference__   
I clone to `D:\sw`

then edit `.luarc.json`   
```json
{
  "workspace.library": [
    // point to where you clone 
    "D:\\SW\\wezterm-types"
  ],
}
```

Then open folder where `.wezterm.lua` is located.   
in my case `~/.config/wezterm` with Zed Editor, Done, you now have wezterm config api autocompletion.


