return {
	"zk-org/zk-nvim",
	name = "zk",
	opts = {
		-- Can be "telescope", "fzf", "fzf_lua", "minipick", "snacks_picker",
		-- or select" (`vim.ui.select`).
		picker = "select",

		lsp = {
			-- `config` is passed to `vim.lsp.start(config)`
			config = {
				name = "zk",
				cmd = { "zk", "lsp" },
				filetypes = { "markdown" },
				-- on_attach = ...
				-- etc, see `:h vim.lsp.start()`
			},

			-- automatically attach buffers in a zk notebook that match the given filetypes
			auto_attach = {
				enabled = true,
			},
		},

		tags = {
			-- Configure how multiple tags should be combined in a ZkTags search
			-- Can be "AND" or "OR"
			multi_select_strategy = "AND",
		},
	},
}
