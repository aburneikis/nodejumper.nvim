local M = {}

local config = require("nodejumper.config")
local treesitter = require("nodejumper.treesitter")
local labels = require("nodejumper.labels")

-- State for active jump session
M.state = {
  active = false,
  bufnr = nil,
  win = nil,
  label_map = {},
  typed = "",
}

--- Clean up after jump session
local function cleanup()
  if M.state.bufnr then
    labels.clear_labels(M.state.bufnr)
  end

  M.state = {
    active = false,
    bufnr = nil,
    win = nil,
    label_map = {},
    typed = "",
  }

  -- Force redraw to clear visual artifacts
  vim.cmd("redraw")
end

--- Jump to a specific position
---@param node_info table Node info with row, col
local function jump_to(node_info)
  -- Convert from 0-indexed to 1-indexed for cursor position
  vim.api.nvim_win_set_cursor(M.state.win, { node_info.row + 1, node_info.col })
  cleanup()
end

--- Handle a single character input during jump mode
---@param char string The character pressed
local function handle_char(char)
  if not M.state.active then
    return
  end

  local opts = config.options

  -- Check for cancel
  if char == vim.api.nvim_replace_termcodes(opts.advanced.cancel_key, true, false, true) then
    cleanup()
    return
  end

  -- Append to typed sequence
  M.state.typed = M.state.typed .. char

  -- Filter remaining labels that match the typed sequence
  local remaining = labels.filter_labels(M.state.label_map, M.state.typed)
  local count = 0
  for _ in pairs(remaining) do
    count = count + 1
  end

  if count == 0 then
    -- No matches, cancel
    cleanup()
    return
  elseif count == 1 then
    -- Only one match remaining, jump to it
    for _, info in pairs(remaining) do
      jump_to(info)
      return
    end
  else
    -- Multiple matches remain, update display and continue
    labels.update_label_display(M.state.bufnr, M.state.label_map, M.state.typed)
    vim.cmd("redraw")
  end
end

--- Input loop for collecting characters
local function input_loop()
  while M.state.active do
    -- Get a single character
    local ok, char = pcall(vim.fn.getcharstr)
    if not ok or char == "" then
      cleanup()
      return
    end

    handle_char(char)
  end
end

--- Start a jump session
function M.jump()
  local bufnr = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()

  -- Get visible treesitter nodes
  local nodes = treesitter.get_visible_nodes(bufnr)

  if #nodes == 0 then
    vim.notify("No treesitter nodes found", vim.log.levels.INFO)
    return
  end

  -- Initialize state
  M.state = {
    active = true,
    bufnr = bufnr,
    win = win,
    label_map = {},
    typed = "",
  }

  -- Display labels and get mapping (this clears existing extmarks first)
  M.state.label_map = labels.display_labels(bufnr, nodes)

  -- Dim the buffer (after labels, since display_labels clears the namespace)
  if config.options.dim_background then
    labels.dim_buffer(bufnr, win)
  end

  -- Redraw to show labels
  vim.cmd("redraw")

  -- Start input loop
  input_loop()
end

--- Cancel any active jump session
function M.cancel()
  if M.state.active then
    cleanup()
  end
end

--- Check if a jump session is currently active
---@return boolean
function M.is_active()
  return M.state.active
end

return M
