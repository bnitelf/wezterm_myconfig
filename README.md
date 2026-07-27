
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
