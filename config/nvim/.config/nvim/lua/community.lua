-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.

---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  -- Copilot ghost text while typing. <Tab> accepts, <C-l> accepts one word,
  -- <C-j> one line, <C-x>/<C-z> cycle suggestions, <C-e> dismisses.
  -- Sign in once with :Copilot auth
  { import = "astrocommunity.completion.copilot-lua-cmp" },
  -- Multiple cursors, VS Code style: <C-d> selects the word and then each next
  -- occurrence (replaces half-page scroll), <C-S-l> selects all occurrences.
  -- In multi-cursor mode: q skips the current one, Q removes it, <Esc> exits.
  { import = "astrocommunity.editing-support.vim-visual-multi" },
  {
    "mg979/vim-visual-multi",
    init = function()
      vim.g.VM_maps = {
        ["Find Under"] = "<C-d>",
        ["Find Subword Under"] = "<C-d>",
        ["Select All"] = "<C-S-l>",
        ["Visual All"] = "<C-S-l>",
      }
    end,
  },
  -- import/override with your plugins folder
}
