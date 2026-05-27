require("full-border"):setup()

require("recycle-bin"):setup()

require("bunny"):setup({
	hops = {
		{ key = "/", path = "/" },
		{ key = "t", path = "/tmp" },
		{ key = "h", path = "~", desc = "Home" },
		{ key = "m", path = "~/Modding/", desc = "Modding" },
		{ key = "d", path = "~/Downloads", desc = "Downloads" },
		{ key = "D", path = "~/Documents", desc = "Documents" },
		{ key = "v", path = "~/Videos", desc = "Videos" },
		{ key = "M", path = "~/Music", desc = "Music" },
		{ key = "e", path = "~/Emulation", desc = "Emulation" },
		{ key = "p", path = "~/Pictures", desc = "Pictures" },
		{ key = "c", path = "~/.config", desc = "Config files" },
		-- key and path attributes are required, desc is optional
	},
	desc_strategy = "path", -- If desc isn't present, use "path" or "filename", default is "path"
	ephemeral = true, -- Enable ephemeral hops, default is true
	tabs = true, -- Enable tab hops, default is true
	notify = false, -- Notify after hopping, default is false
	fuzzy_cmd = "fzf", -- Fuzzy searching command, default is "fzf"
})

require("yatline"):setup({
	-- Powerline-style separators
	section_separator = { open = "", close = "" },
	part_separator = { open = "", close = "" },
	inverse_separator = { open = "", close = "" },

	padding = { inner = 1, outer = 1 },

	-- style_a: teal accent for tabs, mode indicator, and highlighted sections
	-- style_b: mid-dark surface for secondary info
	-- style_c: darkest bg for tertiary/path sections
	style_a = {
		bg = "#94e2d5", -- mocha teal
		fg = "#1e1e2e", -- mocha base (dark text on teal reads cleanly)
		bg_mode = {
			normal = "#94e2d5", -- teal
			select = "#f9e2af", -- mocha yellow
			un_set = "#f38ba8", -- mocha red
		},
	},
	style_b = { bg = "#313244", fg = "#cdd6f4" }, -- surface0 / text
	style_c = { bg = "#181825", fg = "#bac2de" }, -- mantle / subtext1

	permissions_t_fg = "green",
	permissions_r_fg = "yellow",
	permissions_w_fg = "red",
	permissions_x_fg = "cyan",
	permissions_s_fg = "white",

	tab_width = 20,

	selected = { icon = "󰻭", fg = "yellow" },
	copied = { icon = "", fg = "green" },
	cut = { icon = "", fg = "red" },

	files = { icon = "", fg = "blue" },
	filtereds = { icon = "", fg = "magenta" },

	total = { icon = "󰮍", fg = "yellow" },
	success = { icon = "", fg = "green" },
	failed = { icon = "", fg = "red" },

	show_background = true,
	display_header_line = true,
	display_status_line = true,

	header_line = {
		left = {
			section_a = {
				{ type = "line", custom = false, name = "tabs", params = { "left" } },
			},
			section_b = {},
			section_c = {},
		},
		right = {
			-- Disk usage sits in section_a so it gets the teal background.
			-- The addon's green/yellow/red text colors read well on the darker mantle
			-- section_c, so swap these if you prefer the traffic-light text on dark.
			section_a = {},
			section_b = {},
			section_c = {

				{ type = "coloreds", custom = false, name = "disk-usage" },
			},
		},
	},

	status_line = {
		left = {
			section_a = {
				{ type = "string", custom = false, name = "tab_mode" },
			},
			section_b = {
				{ type = "string", custom = false, name = "hovered_size" },
				-- Hidden automatically when nothing is selected
				{ type = "coloreds", custom = false, name = "selected-files-size" },
			},
			section_c = {
				{ type = "string", custom = false, name = "hovered_path" },
				{ type = "coloreds", custom = false, name = "count" },
			},
		},
		right = {
			section_a = {
				{ type = "string", custom = false, name = "cursor_position" },
			},
			section_b = {
				{ type = "string", custom = false, name = "tab_num_files" },
				-- Mtime replaces the global clock — more useful per-file context
			},
			section_c = {
				{ type = "string", custom = false, name = "hovered_file_extension", params = { true } },
				{ type = "string", custom = false, name = "hovered_ownership" },
				{ type = "coloreds", custom = false, name = "permissions" },
			},
		},
	},
})

-- Addons must be initialized AFTER yatline:setup()
require("yatline-disk-usage"):setup()
require("yatline-selected-size"):setup()

-- ~/.config/yazi/init.lua
require("linemode-plus"):setup({
	-- Date formatting mode
	-- Available options:
	--   "default" - Yazi's native format with conditional year display:
	--               • For current year:     "MM/DD HH:mm"
	--               • For other years:      "MM/DD  YYYY"
	--
	--   "custom"  - smart user-defined format with today detection:
	--               • For today's files:     "HH:mm" (time only)
	--               • For older files:       Custom date format from 'custom' table
	--                 (configurable order, separator and year digits)
	date_mode = "custom",
	-- Custom format settings (only used when mode = "custom")
	custom = {
		-- Date components order
		-- MUST contain all three components: "year", "month", "day"
		-- Each component must appear exactly once (no duplicates)
		--
		-- All valid examples:
		--   { "year", "month", "day" }     -- year → month → day
		--   { "year", "day", "month" }     -- year → day → month
		--   { "month", "year", "day" }     -- month → year → day
		--   { "month", "day", "year" }     -- month → day → year
		--   { "day", "year", "month" }     -- day → year → month
		--   { "day", "month", "year" }     -- day → month → year
		order = { "year", "month", "day" },
		-- Separator between date components
		-- Allowed separators: "-", "/", "."  (only these characters are supported)
		--
		-- Examples:
		--   "-" -> 2026-02-20
		--   "/" -> 2026/02/20
		--   "." -> 2026.02.20
		separator = "-",

		-- Number of digits for the year:
		--   4 -> 2026 (full year)
		--   2 -> 26   (short year)
		year_digits = 4,
	},
})
