-- lua/plugins/textobjects.lua
return {
	{
		"nvim-mini/mini.ai",
		opts = function(_, opts)
			local ai = require("mini.ai")
			opts.custom_textobjects = opts.custom_textobjects or {}
			opts.custom_textobjects.x = ai.gen_spec.treesitter({
				a = "@attribute.outer",
				i = "@attribute.inner",
			})
			return opts
		end,
	},
}
