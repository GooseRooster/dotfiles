-- Minuet-AI: LLM-powered autocomplete via opencode-oai (local OpenAI-compatible bridge).
-- The bridge endpoint is fixed to http://localhost:5000. Per-host, the API key and
-- model come from ~/.config/nushell/env.local.nu (untracked). If either
-- MINUET_API_KEY or MINUET_MODEL is missing, the plugin is disabled entirely --
-- so containers and hosts without the bridge configured stay silent.
local enabled = vim.env.MINUET_API_KEY ~= nil
	and vim.env.MINUET_API_KEY ~= ""
	and vim.env.MINUET_MODEL ~= nil
	and vim.env.MINUET_MODEL ~= ""

return {
	{
		"milanglacier/minuet-ai.nvim",
		enabled = enabled,
		event = "InsertEnter",
		config = function()
			require("minuet").setup({
				provider = "openai_compatible",
				throttle = 800,
				debounce = 300,
				request_timeout = 3,
				n_completions = 1,
				context_window = 12000,
				notify = "error",
				add_single_line_entry = false,
				provider_options = {
					openai_compatible = {
						name = "opencode-oai",
						end_point = "http://localhost:5000/v1/chat/completions",
						api_key = "MINUET_API_KEY", -- env var *name*, not value
						model = vim.env.MINUET_MODEL,
						stream = true,
						optional = {
							max_tokens = 256,
							stop = { "\n\n" },
						},
					},
				},
				virtualtext = {
					auto_trigger_ft = { "*" },
					auto_trigger_ignore_ft = {
						"TelescopePrompt",
						"snacks_picker_input",
						"neo-tree",
						"help",
						"gitcommit",
						"gitrebase",
						"dashboard",
					},
					show_on_completion_menu = false,
					keymap = {
						accept = "<Tab>",
						accept_line = "<A-a>",
						accept_n_lines = "<A-z>",
						next = "<A-]>",
						prev = "<A-[>",
						dismiss = "<A-e>",
					},
				},
			})
		end,
	},

	-- Wire minuet into blink.cmp (LazyVim's default completion engine).
	{
		"saghen/blink.cmp",
		optional = true,
		opts = function(_, opts)
			if not enabled then
				return
			end
			opts.sources = opts.sources or {}
			opts.sources.default = opts.sources.default or { "lsp", "path", "snippets", "buffer" }
			table.insert(opts.sources.default, "minuet")
			opts.sources.providers = opts.sources.providers or {}
			opts.sources.providers.minuet = {
				name = "minuet",
				module = "minuet.blink",
				async = true,
				timeout_ms = 3000,
				score_offset = 50,
			}
			opts.completion = opts.completion or {}
			opts.completion.trigger =
				vim.tbl_deep_extend("force", opts.completion.trigger or {}, { prefetch_on_insert = false })
			opts.keymap = opts.keymap or {}
			opts.keymap["<A-y>"] = {
				function()
					require("minuet").make_blink_map()
				end,
			}
		end,
	},
}
