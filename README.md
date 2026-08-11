
## Clone to local 
__Linux / WSL__

```bash
git clone https://github.com/bnitelf/wezterm_myconfig.git ~/.config/wezterm
```

__Windows (PowerShell)__

```bash
git clone https://github.com/bnitelf/wezterm_myconfig.git "$HOME\.config\wezterm"
```

__Launch Wezterm with__
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


