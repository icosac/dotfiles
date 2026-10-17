-- Personal vim options, applied on top of AstroNvim's defaults

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    options = {
      opt = {
        number = true, -- absolute line numbers...
        relativenumber = false, -- ...that don't change with the cursor (AstroNvim default: relative)
        -- y/p/d stay in vim's registers; the system clipboard only via "+y / "+p
        -- (or Ctrl+Shift+V in the terminal). AstroNvim default: "unnamedplus"
        clipboard = "",
      },
    },
  },
}
