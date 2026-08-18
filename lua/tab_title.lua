local wezterm = require("wezterm")

local M = {}

-- Remember the "main" application for each pane.
local pane_state = {}

-- Whether the current font is a Nerd Font (set during setup).
local use_nerd_font = false

local cache_wsl_home_dirs = {}
-- (tab_id, shell_name eg. powershell, cmd, wslhost)
local cache_dict_tab_shells = {}

local list_known_shell_names = {
    powershell = true,
    pwsh = true,
    cmd = true,
    wslhost = true
}

local color_powershell = "4B84E7"
local color_ubuntu = "E95420"

--- Detect if a font family name is a Nerd Font variant.
--- Checks for common patterns: "Nerd Font", "NerdFont", "NFM", "NF"
---@param font_family string
---@return boolean
local function is_nerd_font(font_family)
	if not font_family then
		return false
	end
	local name = font_family:lower()
	-- Match "nerd font", "nerdfont", or suffix patterns like " nf", " nfm"
	if name:find("nerd font") or name:find("nerdfont") then
		return true
	end
	-- Match font names ending with " NF" or " NFM" (case-insensitive)
	if name:match("%s+nfm?$") or name:match("%s+nfm?%s") then
		return true
	end
	return false
end

--- Get filename with ext
---@param path string
---@return string
local function basename(path)
    local basename = path:match("[^/\\]+$") or path
    -- wezterm.log_info("basename = " .. basename)
    return basename
end

--- Get filename without ext
---@param path string
---@return string
local function basename_without_ext(path)
    local basename = path:match("[^/\\]+$") or path
    -- wezterm.log_info("basename = " .. basename)
    basename = basename:gsub(".exe", "")
    return basename
end

--- Get wsl home dir then cache for next use.
--- Called from update-status (which supports async) to pre-cache WSL home dirs.
---@param distro string
local function cache_wsl_home_dir(distro)
    if cache_wsl_home_dirs[distro] then
        return
    end
    local success, stdout = wezterm.run_child_process({
        "wsl.exe",
        "-d", distro,
        "--",
        "sh",
        "-lc",
        "printf '%s' \"$HOME\"",
    })
    if success and stdout and stdout ~= "" then
        cache_wsl_home_dirs[distro] = stdout
        -- wezterm.log_info("cached WSL home for " .. distro .. " = " .. stdout)
    end
end

--- Cache shell name 
---@param tab_id number
---@param foreground_process_name string
local function add_if_not_exist_cache_tab_shell(tab_id, foreground_process_name)
    if (cache_dict_tab_shells[tab_id]) then return end

    if list_known_shell_names[foreground_process_name] then 
        local shell_name = foreground_process_name
        cache_dict_tab_shells[tab_id] = shell_name
    end
end

--- Get cached wsl home dir. If not cached yet, try to infer from cwd.
---@param pane PaneInformation
---@param cwd_path string
---@return string
local function get_wsl_home_dir(pane, cwd_path)
    local distro = pane.domain_name:gsub("^WSL:", "")
    if cache_wsl_home_dirs[distro] then
        return cache_wsl_home_dirs[distro]
    end
    -- Fallback: infer home from cwd if it looks like /home/username/...
    local inferred = cwd_path:match("^(/home/[^/]+)")
    if inferred then
        cache_wsl_home_dirs[distro] = inferred
        return inferred
    end
    
    -- Cannot determine yet, return empty
    return ""
end

--- Custom current working dir path.
---@param pane PaneInformation
---@return string
local function cwd_name(pane)
    -- ~                          => if cwd = C:/Users/{your_username}
    -- ~/folder_lv1               => if cwd = C:/Users/{your_username}/folder_lv1
    -- ~/folder_lv1/folder_lv2    => if cwd = C:/Users/{your_username}/folder_lv1/folder_lv2
    -- ~/folder_lv1/../folder_lv3 => if cwd = C:/Users/{your_username}/folder_lv1/folder_lv2/folder_lv3
    -- else return last folder only

    local cwd = pane.current_working_dir
    if not cwd then
        return ""
    end

    local cwd_normalized = cwd.file_path

    -- wezterm.log_info("cwd_normalized = " .. cwd.file_path)
    -- Strip file:// or file://hostname/
    cwd_normalized = cwd_normalized:gsub("^file://[^/]*", "")

    -- Strip leading slash before drive letter (e.g. /C: -> C:)
    cwd_normalized = cwd_normalized:gsub("^/(%a:)", "%1")

    -- Normalize separators to forward slash.
    cwd_normalized = cwd_normalized:gsub("\\", "/")

    -- Remove trailing slash (but keep root like C:/)
    cwd_normalized = cwd_normalized:gsub("(.)/+$", "%1")

    -- wezterm.log_info("cwd_name: path=" .. cwd_normalized .. "  home=" .. home)

    -- Build home path. Prefer USERPROFILE (full path) over USERNAME.
    local home
    -- wezterm.log_info("home_dir = " .. wezterm.home_dir)
    -- Detect Window or Unix path
    if cwd_normalized:match("^/") then
        -- Linux:   home is /home/your_username
        -- macOS:   homs is /Users/your_username
        local unix_home = os.getenv("HOME") or ""
        if unix_home == "" then
            -- we are in wsl
            unix_home = get_wsl_home_dir(pane, cwd_normalized)
        end
        home = unix_home
        -- wezterm.log_info("unix_home = " .. unix_home)
    else
        local userprofile = os.getenv("USERPROFILE") or ""
        home = userprofile:gsub("\\", "/")
        -- wezterm.log_info("userprofile = " .. userprofile)
    end
    -- wezterm.log_info("home = " .. home)

    -- Case-insensitive comparison for Windows paths.
    local cwd_normalized_lower = cwd_normalized:lower()
    local home_lower = home:lower()

    -- Home directory -> "~"
    if cwd_normalized_lower == home_lower then
        return "~"
    end

    -- Under home directory: show relative to ~
    local home_prefix_lower = home_lower .. "/"
    if cwd_normalized_lower:sub(1, #home_prefix_lower) == home_prefix_lower then
        local rel = cwd_normalized:sub(#home_prefix_lower + 1)

        local parts = {}
        for part in rel:gmatch("[^/]+") do
            table.insert(parts, part)
        end

        -- 1 level:  ~/.config
        -- 2 levels: ~/.config/wezterm
        -- 3+ levels: ~/.config/../last_folder
        if #parts <= 2 then
            return "~/" .. table.concat(parts, "/")
        else
            return "~/" .. parts[1] .. "/.. /" .. parts[#parts]
        end
    end

    -- Outside home: show only the last directory name.
    return cwd_normalized:match("([^/]+)$") or cwd_normalized
end



--- Get process name with out ext. Example Powershell.exe -> powershell, wslhost.exe -> wslhost
---@param pane PaneInformation
local function process_name(pane)
    local fg_proc = pane.foreground_process_name or ""

    local is_window = wezterm.target_triple:find("windows")

    if is_window and pane.domain_name == "local" then
        fg_proc = basename(pane.title)
    elseif is_window and pane.domain_name:match("^WSL") then
        fg_proc = basename(fg_proc)
    else
        fg_proc = basename(fg_proc)
    end

	fg_proc = fg_proc:gsub("%.exe$", "")
	return fg_proc:lower()
end


--- Setup tab title formatting.
--- @param opts { font_name: string }  Pass the font name to auto-detect nerd font.
function M.setup(opts)
	opts = opts or {}

	-- Detect nerd font from the provided font name.
	if opts.font_name then
		use_nerd_font = is_nerd_font(opts.font_name)
	end

	-- Pre-cache WSL home dirs via update-status (supports async/coroutines).
	wezterm.on("update-status", function(window, pane)
		if pane:get_domain_name() and pane:get_domain_name():match("^WSL:") then
			local distro = pane:get_domain_name():gsub("^WSL:", "")
			cache_wsl_home_dir(distro)
		end
	end)

	wezterm.on("format-tab-title", function(tab)
        -- [TODO] - Customeize tab title to show nvim.exe - current_working_dir when open nvim
        -- NOTE:
        -- - on (format-tab-title) fire more frequent than on (update-status)
        -- - foreground_process_name change to git.exe, git-remote-https.exe while nvim doing its plugin checking while startup and change cwd to
        -- file:///D:/sw/LazyVim/nvim-data/lazy/blink.cmp/
        -- file:///D:/sw/LazyVim/nvim-data/lazy/nvim-lint/
        -- file:///D:/sw/LazyVim/nvim-data/lazy/conform.nvim/
        -- file:///D:/sw/LazyVim/nvim-data/lazy/mini.pairs/
        -- file:///D:/sw/LazyVim/nvim-data/lazy/snacks.nvim/
        -- once git settle
        -- foreground_process_name change to  D:\SW\nvim-win64\bin\nvim.exe
        -- then cwd change to
        -- your current_working_dir
        -- git.exe might executed run periodically. on current_working_dir

        
        local pane = tab.active_pane
		
		-- wezterm.log_info("== format-tab-title")
		-- wezterm.log_info("tab_id: " .. tostring(tab.tab_id))
		-- wezterm.log_info("tab is_active: " .. tostring(tab.is_active))
		-- wezterm.log_info("pane_id: " .. tostring(pane.pane_id))
		-- wezterm.log_info("pane domain: " .. tostring(pane.domain_name))
		-- wezterm.log_info("pane title: " .. tostring(pane.title))
		-- -- wezterm.log_info("pane cwd: " .. tostring(pane.current_working_dir.file_path))
		-- wezterm.log_info("pane cwd filepath: " .. tostring(pane.current_working_dir))
        -- wezterm.log_info("pane foreground_process_name: " .. tostring(pane.foreground_process_name))
		
		-- Skip Debug Overlay (this virtual tab open when you press ctrl+shift+L to debug wezterm)
		if pane.title == "Debug" then
			return nil
		end

		-- -- Let WSL use WezTerm's default implementation.
		-- if pane.domain_name and pane.domain_name:match("^WSL") then
		-- 	return nil
        -- end
        --
        -- ==== Example Value - in different cases ====
        -- Window - in normal cli session (not running nvim.exe, ai-related cli)
        -- active_pane.domain_name = local
        -- active_pane.title = powershell.exe
        -- active_pane.foreground_process_name = {full}/powershell.exe
        --
        -- Window - nvim
        -- active_pane.domain_name = local
        -- active_pane.title = nvim.exe
        -- active_pane.foreground_process_name = {full}/nvim.exe
        --
        -- Window - domain=WSL:Ubuntu (in case we are at /home/your_username)
        -- active_pane.domain_name = WSL:Ubuntu
        -- active_pane.title = ~ 
        -- active_pane.foreground_process_name = {full}/wslhost.exe
        -- 
        -- Window - domain=WSL:Ubuntu (in case we are at /mnt/d/Workspace_Py)
        -- active_pane.domain = WSL:Ubuntu
        -- active_pane.title = ../Workspace_Py
        -- active_pane.foreground_process_name = {full}/wslhost.exe
        --
        -- Window - nvim, domain=WSL:Ubuntu (in case we are at /mnt/d/Workspace_Py)
        -- active_pane.domain = WSL:Ubuntu
        -- active_pane.title = nvim
        -- active_pane.foreground_process_name = {full}/wslhost.exe
        --
        -- Window - kiro-cli, domain=WSL:Ubuntu (in case we are at /mnt/d/Workspace_Py)
        -- active_pane.domain = WSL:Ubuntu
        -- active_pane.title = kiro-cli
        -- active_pane.foreground_process_name = {full}/wslhost.exe

        local foreground_process_name = basename_without_ext(pane.foreground_process_name)
        local processName = process_name(pane)
        local cwd = cwd_name(pane)

        add_if_not_exist_cache_tab_shell(tab.tab_id, foreground_process_name);
        local shell = cache_dict_tab_shells[tab.tab_id] or ""
        local shell_or_icon = ""
        local custom_shell_name = ""
        local icon_color = nil

        -- wezterm.log_info("proc = "..processName);

        if shell == "powershell" then
            custom_shell_name = "PS5"
            shell_or_icon = use_nerd_font and "\u{e86c}" or custom_shell_name
            icon_color = color_powershell
            
        elseif shell == "pwsh" then
            custom_shell_name = "PS7"
            shell_or_icon = use_nerd_font and "\u{e70f}" or custom_shell_name
            icon_color = color_powershell
            
        elseif shell == "cmd" then
            custom_shell_name = "CMD"
            shell_or_icon = use_nerd_font and "\u{ebc4}" or custom_shell_name
            -- elseif foreground_proc == "wslhost" and not pane.title:find("/") then
            --     -- WSL pane: pane.title contains the sub-process name (e.g. "bash", "zsh")
            --     wezterm.log_info("wslhost")

            --     shell = sub_proc
            --     shell_or_icon = (use_nerd_font and "\u{f0548}" or shell) .. " " .. sub_proc
        else
            custom_shell_name = processName
            shell_or_icon = use_nerd_font and "\u{f0548}" or custom_shell_name
            -- Color Ubuntu/WSL icon
            if pane.domain_name and pane.domain_name:match("^WSL") then
                icon_color = color_ubuntu
            end
        end

        -- wezterm.log_info("shell = " .. custom_shell_name)
        -- wezterm.log_info("shell_or_icon = " .. shell_or_icon)

        local sub_proc = ""
        
        local is_window = wezterm.target_triple:find("windows")
    
        if is_window and pane.domain_name == "local" then
            -- when in normal shell session (ie. not enter nvim, ai related cli)
            -- these 2 value will be the same
            -- pane.title                   = full shell path (like {full}/powershell.exe)
            -- pane.foreground_process_name = full shell path
            --
            -- when in nvim
            -- pane.title                   = nvim.exe
            -- pane.foreground_process_name = {full}/nvim.exe
            -- 
            -- when in nvim, ai related cli (not sure about this)
            -- pane.title                   = full shell path
            -- pane.foreground_process_name = nvim.exe | git.exe | etc...
            sub_proc = basename_without_ext(pane.foreground_process_name)
            if list_known_shell_names[sub_proc] then
                sub_proc = "/"
            end
        elseif is_window and pane.domain_name:match("^WSL") then
            sub_proc = pane.title:gsub("\\", "/")
        else
            sub_proc = pane.title:gsub("\\", "/")
        end

        -- wezterm.log_info("sub_proc = " .. sub_proc)

        -- add actual application running inside shell to tab title (ignore if detect / or ~ assume they are path)
        -- when on wsl, in normal cli session, pane.title become ..excerpt_of_full_cwd
        if not sub_proc:find("/") and not sub_proc:find("~") and not sub_proc:find("%.%.") then
            shell_or_icon = shell_or_icon .. " " .. sub_proc
        end
        
        local idx = tab.tab_index + 1

        -- wezterm.log_info("tab ".. idx .. " app_or_icon = " .. shell_or_icon);

        local separator = cwd:match("^~") and " " or " - "
        local title_text = string.format("%d: ", idx)
        local after_icon = separator .. cwd

        -- If we have a color and nerd font icon, use FormatItem for colored icon
        if icon_color and use_nerd_font then
            return wezterm.format({
                { Text = title_text },
                { Foreground = { Color = "#" .. icon_color } },
                { Text = shell_or_icon },
                "ResetAttributes",
                { Text = after_icon },
            })
        else
            return string.format("%d: %s%s", idx, shell_or_icon, after_icon)
        end
    
	end)
end

return M
