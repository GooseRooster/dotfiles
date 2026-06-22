return {
  "ckob/lazydotnet.nvim",
  cmd = "LazyDotnet",
  init = function()
    -- Toggle the UI in both normal and terminal modes
    vim.keymap.set({ "n", "t" }, "<C-.>", "<Cmd>LazyDotnet<CR>", { desc = "Toggle LazyDotnet" })
  end,
}
