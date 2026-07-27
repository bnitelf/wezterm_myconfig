local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

config.color_scheme = "Tokyo Night"
config.font = wezterm.font("FiraCode Nerd Font")
config.font_size = 12.0
config.line_height = 1.2

config.window_frame = {
	font = wezterm.font("Roboto", { weight = "Bold" }),
	font_size = 12.0, -- Smaller = shorter tab bar
}

-- Default Shell
-- Powershell 5.1
config.default_prog = { "C:\\WINDOWS\\System32\\WindowsPowerShell\\v1.0\\powershell.exe" }

-- Powershell 7
-- config.default_prog = { "C:\\Users\\{your_username}\\AppData\\Local\\Microsoft\\WindowsApps\\Microsoft.PowerShell_8wekyb3d8bbwe\\pwsh.exe" }

config.keys = {
	-- Copy
	{
		key = "c",
		mods = "CTRL",
		action = wezterm.action.CopyTo("Clipboard"),
	},

	-- Paste
	{
		key = "v",
		mods = "CTRL",
		action = wezterm.action.PasteFrom("Clipboard"),
	},
  {
    key = 'Tab',
    mods = 'CTRL',
    action = wezterm.action.ActivateLastTab,
  },
  {
    key = "Enter",
    mods = "SHIFT",
    action = wezterm.action.SendString("\n"),
  }
}

return config
