-- File tree (neo-tree) overrides on top of AstroNvim's defaults

---@type LazySpec
return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      -- `nvim .` opens the tree docked on the left, like VS Code's explorer, and it
      -- stays there when you open a file (AstroNvim default: "open_current", which
      -- shows the tree in the main window and replaces it with the file)
      hijack_netrw_behavior = "open_default",
    },
  },
}
