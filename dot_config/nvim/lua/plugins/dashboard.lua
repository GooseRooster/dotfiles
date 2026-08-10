return {
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        preset = {
          header = [[ 
                                     
           =.            =           
         ===--           ===         
       =====---          =====       
     -=+====----         ++++++.     
     ===+===-----        +++++++     
     ====+========:      +++++++     
     ++++++=========     +++++++     
     +++++++=========    +++++++     
     +++++++     ========+******     
     +++++++      =======++*****     
     +++++++        =====+++****     
     =++++++         ====++++**+     
       *****          ===+++++       
         ***           +++++         
           *            :*           
                                     
          ]],
          -- stylua: ignore
       ---@type snacks.dashboard.Item[]
       keys = {
         { icon = " ", key = "p", desc = "Projects", action = ":lua Snacks.picker.projects()" },
         { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
         { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
         { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
         { icon = " ", key = "q", desc = "Quit", action = ":qa" },
       },
        },
      },
    },
  },
}
