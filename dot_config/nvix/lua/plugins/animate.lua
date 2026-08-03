-- Animations — mini.animate (scroll/resize/window) + smear-cursor (cursor trail).
-- Kept in ALL profiles, containers included (no host-gating), per the pruning
-- decision. Reproduced from LazyVim's ui.mini-animate + ui.smear-cursor extras.
return {
  -- mini.animate owns scroll/resize/window animation, so turn off snacks.scroll
  {
    "folke/snacks.nvim",
    opts = { scroll = { enabled = false } },
  },

  {
    "nvim-mini/mini.animate",
    event = "VeryLazy",
    cond = vim.g.neovide == nil, -- neovide has its own animations
    opts = function(_, opts)
      -- don't animate when scrolling with the mouse
      local mouse_scrolled = false
      for _, scroll in ipairs({ "Up", "Down" }) do
        local key = "<ScrollWheel" .. scroll .. ">"
        vim.keymap.set({ "", "i" }, key, function()
          mouse_scrolled = true
          return key
        end, { expr = true })
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "grug-far",
        callback = function()
          vim.b.minianimate_disable = true
        end,
      })

      -- scheduled so it overrides the default mapping from keymaps.lua
      vim.schedule(function()
        Snacks.toggle({
          name = "Mini Animate",
          get = function()
            return not vim.g.minianimate_disable
          end,
          set = function(state)
            vim.g.minianimate_disable = not state
          end,
        }):map("<leader>ua")
      end)

      local animate = require("mini.animate")
      return vim.tbl_deep_extend("force", opts, {
        resize = {
          timing = animate.gen_timing.linear({ duration = 50, unit = "total" }),
        },
        scroll = {
          timing = animate.gen_timing.linear({ duration = 150, unit = "total" }),
          subscroll = animate.gen_subscroll.equal({
            predicate = function(total_scroll)
              if mouse_scrolled then
                mouse_scrolled = false
                return false
              end
              return total_scroll > 1
            end,
          }),
        },
      })
    end,
  },

  {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    cond = vim.g.neovide == nil,
    opts = {
      hide_target_hack = true,
      cursor_color = "none",
    },
    specs = {
      -- smear owns the cursor, so disable mini.animate's cursor animation
      {
        "nvim-mini/mini.animate",
        optional = true,
        opts = { cursor = { enable = false } },
      },
    },
  },
}
