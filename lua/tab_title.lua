local wezterm = require("wezterm")

local M = {}

-- Remember the "main" application for each pane.
local pane_state = {}

--- Get filename with ext
---@param path string
---@return string
local function basename(path)
    local basename = path:match("[^/\\]+$") or path
    -- wezterm.log_info("basename = " .. basename)
    return basename
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

	-- Build home path. Prefer USERPROFILE (full path) over USERNAME.
	local home
    local userprofile = os.getenv("USERPROFILE") or ""
    home = userprofile:gsub("\\", "/")
    -- wezterm.log_info("home = " .. home)

	local cwd_normalized = cwd.file_path

	-- wezterm.log_info("cwd_normalized = " .. cwd_normalized)
	-- Strip file:// or file://hostname/
	cwd_normalized = cwd_normalized:gsub("^file://[^/]*", "")

	-- Strip leading slash before drive letter (e.g. /C: -> C:)
	cwd_normalized = cwd_normalized:gsub("^/(%a:)", "%1")

	-- Normalize separators to forward slash.
	cwd_normalized = cwd_normalized:gsub("\\", "/")

	-- Remove trailing slash (but keep root like C:/)
	cwd_normalized = cwd_normalized:gsub("(.)/+$", "%1")

	-- wezterm.log_info("cwd_name: path=" .. cwd_normalized .. "  home=" .. home)

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


---@param pane PaneInformation
local function process_name(pane)
	local proc = pane.foreground_process_name or ""
	proc = basename(proc)
	proc = proc:gsub("%.exe$", "")
	return proc:lower()
end


function M.setup()
	-- this implementation is at wezterm version  20240203-110809-5046fc22
	-- in case it break in newer version
	-- wezterm.log_info("setup tab_title.lua")

	-- Log cwd on updates (no dedicated cwd-changed event in this version).
	-- wezterm.on("update-status", function(window, pane)
	-- 	local cwd = pane:get_current_working_dir()
	-- 	wezterm.log_info("On update-status - cwd: " .. tostring(cwd))
	-- end)

	wezterm.on("format-tab-title", function(tab)
		-- wezterm.log_info("== On format-tab-title - ")

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

		-- wezterm.log_info("tab_id: " .. tostring(tab.tab_id))
		-- wezterm.log_info("tab is_active: " .. tostring(tab.is_active))
		-- wezterm.log_info("pane_id: " .. tostring(pane.pane_id))
		-- wezterm.log_info("pane domain: " .. tostring(pane.domain_name))
		-- wezterm.log_info("pane title: " .. tostring(pane.title))
		-- wezterm.log_info("pane cwd: " .. tostring(pane.current_working_dir.file_path))
		-- wezterm.log_info("pane cwd filepath: " .. tostring(pane.current_working_dir))
		-- wezterm.log_info("pane foreground_process_name: " .. tostring(pane.foreground_process_name))

		-- Skip Debug Overlay (this virtual tab open when you press ctrl+shift+L   to debug wezterm)
		if pane.title == "Debug" then
			return nil
		end

		-- Let WSL use WezTerm's default implementation.
		if pane.domain_name and pane.domain_name:match("^WSL") then
			return nil
		end


        local proc = process_name(pane)
        local cwd = cwd_name(pane)
        -- wezterm.log_info("proc get: " .. proc)
        -- wezterm.log_info("cwd get: " .. cwd)

        -- local id = pane.pane_id
		-- if proc == "powershell" or proc == "pwsh" then
		-- 	pane_state[id] = nil
		-- elseif proc == "nvim" then
		-- 	pane_state[id] = "nvim"
		-- elseif pane_state[id] == nil then
		-- 	-- First non-shell program.
		-- 	pane_state[id] = proc
        -- end
        --
        local app = ""
		if proc == "powershell" then
		    app = "PS5"
		elseif proc == "pwsh" then
			app = "PS7"
        else
            app = proc
		end

		-- local app = pane_state[id]

		-- if app then
		-- 	return string.format("%s - %s", app, cwd)
		-- else
		-- 	return cwd
        -- end
        if cwd:match("^~") then
            return string.format("%s %s", app, cwd)
        else
            return string.format("%s - %s", app, cwd)
        end
	end)
end

return M
