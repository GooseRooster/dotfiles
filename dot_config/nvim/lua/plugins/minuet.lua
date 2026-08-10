-- minuet-ai.nvim wired to a local ramalama (llama.cpp) FIM server. Gated on
-- RAMALAMA_FIM_URL — when the env var is unset or empty, the plugin and its
-- blink.cmp override are skipped entirely, so LazyVim's stock completion
-- behavior is unchanged.
--
-- Two frontends are wired up when active:
--   1. `virtualtext` (ghost text) — the primary UX. Triggers on cursor idle
--      after `debounce` ms, so `// fizzbuzz<CR>` and wait actually works.
--      Accept keymaps mirror the README defaults.
--   2. `blink.cmp` source — appears in the normal completion menu when you
--      start typing. Manual invocation is bound to <A-y> in insert mode.
--
-- ramalama serves an OpenAI-compatible /v1/completions endpoint, but the
-- llama.cpp backend does NOT honor the OpenAI `suffix` field for FIM. We
-- therefore build the prompt manually with qwen2.5-coder's FIM special tokens
-- and disable minuet's `suffix` payload (see minuet README > Llama.cpp
-- Qwen-2.5-coder section).

local url = vim.env.RAMALAMA_FIM_URL
local enabled = url ~= nil and url ~= ""
local model = vim.env.RAMALAMA_FIM_MODEL
if model == nil or model == "" then
	model = "qwen2.5-coder:7b"
end

return {
	"milanglacier/minuet-ai.nvim",
	enabled = enabled,
	event = "InsertEnter",
	opts = {
		provider = "openai_fim_compatible",
		-- Local model: one candidate per request keeps CPU/VRAM headroom on a
		-- 32 GB laptop; the frontend still lets us cycle through cached results.
		n_completions = 1,
		-- Prompt-processing time on qwen2.5-coder:7b scales with context length.
		-- 2048 chars (~500 tokens) is a good latency/quality knee for FIM.
		context_window = 2048,
		context_ratio = 0.75,
		throttle = 800, -- min interval between requests (ms)
		debounce = 300, -- wait for typing/cursor to settle (ms)
		-- Full generation on a 7B local model can exceed several seconds; with
		-- streaming enabled a longer timeout lets partial results surface rather
		-- than aborting silently.
		request_timeout = 6,
		-- Bump to "verbose" or "debug" temporarily if completions still don't
		-- surface — minuet will notify each request/response lifecycle event.
		notify = "warn",
		virtualtext = {
			-- Auto-trigger ghost-text suggestions in every filetype. Use
			-- `:Minuet virtualtext disable` per-buffer to opt out.
			auto_trigger_ft = { "*" },
			-- Hide ghost text while the blink menu is open, so the two frontends
			-- don't fight over the same visual space.
			show_on_completion_menu = false,
			keymap = {
				-- Keys chosen to survive Windows Terminal + WSL and macOS
				-- Option-as-Meta quirks (Alt+Shift combos are unreliable there).
				accept = "<Tab>", -- accept whole suggestion (Copilot-style)
				accept_line = "<A-a>", -- accept next line only
				accept_n_lines = "<A-z>", -- prompt for line count
				prev = "<A-[>", -- previous suggestion / manual invoke
				next = "<A-]>", -- next suggestion / manual invoke
				dismiss = "<A-e>",
			},
		},
		provider_options = {
			openai_fim_compatible = {
				-- minuet requires a non-nil env-var name; ramalama ignores auth.
				api_key = "TERM",
				name = "Ramalama",
				end_point = (url or "") .. "/v1/completions",
				model = model,
				stream = true,
				optional = {
					max_tokens = 128,
					top_p = 0.9,
					-- NOTE: do NOT set stop = { "\n\n" } here. qwen2.5-coder's FIM
					-- output frequently begins with a newline, so a "\n\n" stop token
					-- can match the first streamed tokens and truncate the entire
					-- completion to an empty string — visible in ramalama logs as a
					-- successful request with no candidates surfacing in the UI.
				},
				-- llama.cpp backend: no server-side FIM assembly. We inject
				-- qwen2.5-coder's FIM tokens by hand and disable the suffix field.
				-- If you swap RAMALAMA_FIM_MODEL to a non-Qwen family (e.g.
				-- deepseek-coder-v2), update these sentinels accordingly.
				template = {
					prompt = function(prefix, suffix, _)
						return "<|fim_prefix|>" .. prefix .. "<|fim_suffix|>" .. suffix .. "<|fim_middle|>"
					end,
					suffix = false,
				},
			},
		},
	},
}
