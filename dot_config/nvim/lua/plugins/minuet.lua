-- minuet-ai.nvim wired to a local ramalama (llama.cpp) FIM server, exposed to
-- blink.cmp as an additional source. Gated on RAMALAMA_FIM_URL — when the env
-- var is unset or empty, neither the plugin nor the blink.cmp override loads,
-- so LazyVim's default completion behavior is unchanged.
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

local specs = {}

specs[#specs + 1] = {
    "milanglacier/minuet-ai.nvim",
    enabled = enabled,
    event = "InsertEnter",
    opts = {
      provider = "openai_fim_compatible",
      -- Local model: one candidate per request keeps CPU/VRAM headroom on a
      -- 32 GB laptop; blink still lets us cycle through cached suggestions.
      n_completions = 1,
      -- Prompt-processing time on qwen2.5-coder:7b scales with context length.
      -- 2048 chars (~500 tokens) is a good latency/quality knee for FIM.
      context_window = 2048,
      context_ratio = 0.75,
      throttle = 800, -- min interval between requests (ms)
      debounce = 300, -- wait for typing to settle (ms)
      request_timeout = 3, -- seconds; streaming keeps partials useful
      notify = "warn",
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
            stop = { "\n\n" },
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

-- Only extend blink.cmp when minuet is actually active. Merging an
-- `enabled = false` spec fragment into the main blink.cmp spec can disable
-- blink itself (lazy.nvim merges the flag across fragments), so we simply
-- omit the override entirely when RAMALAMA_FIM_URL is unset.
if enabled then
  specs[#specs + 1] = {
    "saghen/blink.cmp",
    opts = {
      sources = {
        default = { "lsp", "path", "snippets", "buffer", "minuet" },
        providers = {
          minuet = {
            name = "minuet",
            module = "minuet.blink",
            async = true,
            -- Should be >= minuet.request_timeout * 1000.
            timeout_ms = 3000,
            -- Bumps minuet above other sources when it does respond.
            score_offset = 50,
          },
        },
      },
      -- Avoids firing an LLM request on every keystroke burst.
      completion = { trigger = { prefetch_on_insert = false } },
    },
  }
end

return specs
