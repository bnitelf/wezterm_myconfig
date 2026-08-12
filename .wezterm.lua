local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

wezterm.log_info("start my custom wezterm config.")

-- config.color_scheme = "Tokyo Night"
config.colors = config.colors or {}
config.colors.foreground = "#CCCCCC"
config.colors.background = "#1E1E1E"
config.font = wezterm.font("FiraCode Nerd Font", { weight = "Regular"})
config.font_size = 12.0
config.line_height = 1.2

config.window_frame = {
	font = wezterm.font("Roboto", { weight = "Bold" }),
	font_size = 12.0, -- Smaller = shorter tab bar
}

-- Check if the current OS is Windows
if wezterm.target_triple:find("windows") then
    -- Define the launch menu choices
    config.launch_menu = {
        {
            label = 'PowerShell',
            args = { 'powershell.exe' },
        },
        {
            label = 'PowerShell 7',
            args = { 'pwsh.exe' },
        },
        {
            label = 'Window Command Prompt',
            args = { 'cmd.exe' },
        },
    }

    -- Default Shell
    -- Powershell 5.1
    config.default_prog = { "C:\\WINDOWS\\System32\\WindowsPowerShell\\v1.0\\powershell.exe" }

    -- Powershell 7
    -- config.default_prog = { "C:\\Users\\{your_username}\\AppData\\Local\\Microsoft\\WindowsApps\\Microsoft.PowerShell_8wekyb3d8bbwe\\pwsh.exe" }
end

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
	-- To Switch back-forth last 2 tab
    {
        key = 'Tab',
        mods = 'CTRL',
        action = wezterm.action.ActivateLastTab,
    },
    -- To allow Shift + Enter to input new line when using AI agent like Kiro-cli
    {
        key = "Enter",
        mods = "SHIFT",
        action = wezterm.action.SendString("\n"),
    },
    -- Enable Ctrl + t to open new tab and show options to select Powershell, cmd (on Window only)
    {
		key = "t",
		mods = "CTRL",
		action = wezterm.action.ShowLauncher,
    },
}
-- add my custom wezterm config dir to lua package.path so that lua know where to find module we require(module)
package.path = package.path
  .. ";" .. wezterm.config_dir .. "/?.lua"
  .. ";" .. wezterm.config_dir .. "/lua/?.lua"

require("lua.tab_title").setup()

return config
