local M = {}

M.defaults = {
  -- Labels used for jumping (home row keys first for accessibility)
  labels = "asdfghjklqwertyuiopzxcvbnm",

  -- Key to trigger jump mode
  jump_key = "S",

  -- Whether to set the default keymap (set to false for custom mappings)
  set_default_keymap = true,

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

M.options = vim.deepcopy(M.defaults)

--- Validate configuration options
---@param options table Configuration to validate
---@return boolean valid
---@return string|nil error_message
local function validate_config(options)
  -- Validate labels
  if type(options.labels) ~= "string" or #options.labels == 0 then
    return false, "labels must be a non-empty string"
  end

  -- Validate min_node_size
  if type(options.min_node_size) ~= "number" or options.min_node_size < 0 then
    return false, "min_node_size must be a non-negative number"
  end

  -- Validate min_spacing
  if type(options.min_spacing) ~= "number" or options.min_spacing < 0 then
    return false, "min_spacing must be a non-negative number"
  end

  -- Validate jump_key
  if type(options.jump_key) ~= "string" or #options.jump_key == 0 then
    return false, "jump_key must be a non-empty string"
  end

  -- Validate advanced.priority
  if options.advanced and type(options.advanced.priority) ~= "number" then
    return false, "advanced.priority must be a number"
  end

  return true, nil
end

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})

  -- Validate configuration
  local valid, err = validate_config(M.options)
  if not valid then
    vim.notify("nodejumper: invalid config - " .. err, vim.log.levels.ERROR)
    M.options = vim.deepcopy(M.defaults)
    return
  end

  -- Set up default highlight groups
  M.setup_highlights()
end

function M.setup_highlights()
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
