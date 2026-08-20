-- Clipboard provider — chosen explicitly, not by Neovim's auto-detection.
--
-- Why explicit: inside a dev container running on WSL2, `has("wsl")` is TRUE (the
-- container sees the HOST kernel's /proc/version), so the built-in probe order
-- prefers win32yank.exe — which doesn't exist in the container. The result is a
-- silently dead `clipboard=unnamedplus` (LazyVim's default). Deciding here keeps
-- host and container behaviour predictable and identical.
--
-- Resolution order:
--   1. A live Wayland socket + wl-clipboard -> wl-copy/wl-paste. On a host that's
--      the local compositor; in a dev container it's the HOST's socket, forwarded
--      by devcontainer.json (see devcontainer-templates — on WSLg that clipboard
--      is bridged to Windows). Bidirectional, so "+y and "+p both work.
--   2. A container with no usable socket -> OSC 52: copies are written to the
--      terminal as an escape sequence, and the terminal puts them on the clipboard
--      of whatever machine IT runs on. Paste deliberately reads the unnamed
--      register instead of issuing an OSC 52 read: only some terminals (Ghostty,
--      kitty, wezterm) answer one, and a query that blocks then times out on every
--      "+p is worse than a local fallback. Host->container paste goes through the
--      terminal's own paste (Ctrl+Shift+V). Set NVIM_OSC52_PASTE=1 on a terminal
--      that does answer to get the real read.
--   3. A host with neither -> leave Neovim's own detection alone (X11, tmux, ...).

-- Absolute path of the Wayland socket if one is actually there, else nil.
-- WAYLAND_DISPLAY is either an absolute path or a name under XDG_RUNTIME_DIR;
-- libwayland accepts both, and the dev containers use the absolute form.
local function wayland_socket()
	local name = vim.env.WAYLAND_DISPLAY
	if not name or name == "" then
		return nil
	end
	local path = name
	if name:sub(1, 1) ~= "/" then
		local runtime_dir = vim.env.XDG_RUNTIME_DIR or ("/run/user/" .. vim.uv.getuid())
		path = runtime_dir .. "/" .. name
	end
	local stat = vim.uv.fs_stat(path)
	-- Must be a live socket: the dev containers always set WAYLAND_DISPLAY, and on
	-- a host without Wayland the mount is a placeholder regular file.
	if stat and stat.type == "socket" then
		return path
	end
	return nil
end

if wayland_socket() and vim.fn.executable("wl-copy") == 1 then
	vim.g.clipboard = {
		name = "wl-clipboard",
		copy = {
			["+"] = { "wl-copy" },
			["*"] = { "wl-copy", "--primary" },
		},
		paste = {
			["+"] = { "wl-paste", "--no-newline" },
			["*"] = { "wl-paste", "--no-newline", "--primary" },
		},
		cache_enabled = true,
	}
elseif require("config.profile").is_container() then
	local osc52 = require("vim.ui.clipboard.osc52")

	local function paste(reg)
		if vim.env.NVIM_OSC52_PASTE == "1" then
			return osc52.paste(reg)
		end
		return function()
			return vim.split(vim.fn.getreg('"'), "\n")
		end
	end

	vim.g.clipboard = {
		name = "OSC 52",
		copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
		paste = { ["+"] = paste("+"), ["*"] = paste("*") },
	}
end
