-- Personal key mappings, applied on top of AstroNvim's defaults

-- Ctrl+Delete in insert mode: delete up to the next word, like in VS Code and the shell.
-- At the end of a line, join the next line instead (<C-o>dw there would delete the last
-- character, since <C-o> puts the cursor back on it).
local function delete_next_word()
  return vim.fn.col "." > #vim.fn.getline "." and "<Del>" or "<C-o>dw"
end

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    mappings = {
      -- Ctrl+Backspace: delete the previous word (<C-w>). Ghostty and kitty send it as
      -- ^H, which vim reads as <C-h>; terminals using the kitty keyboard protocol send a
      -- distinct <C-BS>. Plain Backspace is unaffected either way.
      i = {
        ["<C-BS>"] = { "<C-w>", desc = "Delete previous word" },
        ["<C-h>"] = { "<C-w>", desc = "Delete previous word" },
        ["<C-Del>"] = { delete_next_word, expr = true, desc = "Delete next word" },
      },
      c = {
        ["<C-BS>"] = { "<C-w>", desc = "Delete previous word" },
        ["<C-h>"] = { "<C-w>", desc = "Delete previous word" },
      },
    },
  },
}
