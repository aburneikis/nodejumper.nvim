local M = {}

M.defaults = {
  -- Labels used for jumping (home row keys first for accessibility)
  labels = "asdfghjklqwertyuiopzxcvbnm",

  -- Key to trigger jump mode
  jump_key = "S",

  -- Minimum node size to show labels (reduces clutter)
  min_node_size = 3,

  -- Minimum spacing between labels on same line
  min_spacing = 2,

  -- Dim background text during jump mode
  dim_background = true,

  -- Include all nodes (even tiny ones) - expert mode
  all_nodes = false,

  -- Advanced options (rarely need to change)
  advanced = {
    cancel_key = "<Esc>",
    min_word_length = 0,
    priority = 1000,
    highlight = {
      label = "NodejumperLabel",
      dim = "NodejumperDim",
    },
  },
}

M.options = M.defaults

M.setup = function(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})

  -- Set up default highlight groups
  M.setup_highlights()
end

M.setup_highlights = function()
  local opts = M.options

  -- Label highlight - bright and visible (default = true allows user overrides)
  vim.api.nvim_set_hl(0, opts.advanced.highlight.label, {
    fg = "#ffffff",
    bg = "#ff007c",
    bold = true,
    default = true,
  })

  -- Dim highlight for background text (default = true allows user overrides)
  vim.api.nvim_set_hl(0, opts.advanced.highlight.dim, {
    fg = "#545c7e",
    default = true,
  })
end

return M
