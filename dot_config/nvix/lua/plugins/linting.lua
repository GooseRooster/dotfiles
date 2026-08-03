-- Linting — nvim-lint. Reproduced from LazyVim's linting.lua (LazyVim.warn ->
-- Util.warn, LazyFile -> standard file events). linters_by_ft is extended by
-- language specs; the resolver mirrors nvim-lint's ft-splitting + `_`/`*` fallbacks.

local lazy_file = { "BufReadPost", "BufNewFile", "BufWritePre" }

return {
  {
    "mfussenegger/nvim-lint",
    event = lazy_file,
    opts = {
      events = { "BufWritePost", "BufReadPost", "InsertLeave" },
      linters_by_ft = {
        fish = { "fish" },
        -- '*' = run on all filetypes, '_' = fallback for fts with no linter
      },
      ---@type table<string,table>
      linters = {},
    },
    config = function(_, opts)
      local M = {}

      local lint = require("lint")
      for name, linter in pairs(opts.linters) do
        if type(linter) == "table" and type(lint.linters[name]) == "table" then
          lint.linters[name] = vim.tbl_deep_extend("force", lint.linters[name], linter)
          if type(linter.prepend_args) == "table" then
            lint.linters[name].args = lint.linters[name].args or {}
            vim.list_extend(lint.linters[name].args, linter.prepend_args)
          end
        else
          lint.linters[name] = linter
        end
      end
      lint.linters_by_ft = opts.linters_by_ft

      function M.debounce(ms, fn)
        local timer = vim.uv.new_timer()
        return function(...)
          local argv = { ... }
          timer:start(ms, 0, function()
            timer:stop()
            vim.schedule_wrap(fn)(unpack(argv))
          end)
        end
      end

      function M.lint()
        local names = lint._resolve_linter_by_ft(vim.bo.filetype)
        names = vim.list_extend({}, names)
        if #names == 0 then
          vim.list_extend(names, lint.linters_by_ft["_"] or {})
        end
        vim.list_extend(names, lint.linters_by_ft["*"] or {})

        local ctx = { filename = vim.api.nvim_buf_get_name(0) }
        ctx.dirname = vim.fn.fnamemodify(ctx.filename, ":h")
        names = vim.tbl_filter(function(name)
          local linter = lint.linters[name]
          if not linter then
            Util.warn("Linter not found: " .. name, { title = "nvim-lint" })
          end
          return linter and not (type(linter) == "table" and linter.condition and not linter.condition(ctx))
        end, names)

        if #names > 0 then
          lint.try_lint(names)
        end
      end

      vim.api.nvim_create_autocmd(opts.events, {
        group = vim.api.nvim_create_augroup("nvix_nvim_lint", { clear = true }),
        callback = M.debounce(100, M.lint),
      })
    end,
  },
}
