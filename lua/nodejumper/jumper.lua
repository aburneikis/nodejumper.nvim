local M = {}

local config = require("nodejumper.config")
local treesitter = require("nodejumper.treesitter")
local labels = require("nodejumper.labels")

-- State for active jump session (local to prevent external modification)
local state = {
  active = false,
  bufnr = nil,
  win = nil,
  label_map = {},
  typed = "",
  cancel_key = nil, -- Cached termcode for cancel key
}

--- Clean up after jump session
local function cleanup()
  if state.bufnr and vim.api.nvim_buf_is_valid(state.bufnr) then
    labels.clear_labels(state.bufnr)
  end

  -- Clear fields instead of reassigning table to avoid race conditions
  -- with any callbacks that might hold a reference to state
  state.active = false
  state.bufnr = nil
  state.win = nil
  state.label_map = {}
  state.typed = ""
  state.cancel_key = nil

  -- Force redraw to clear visual artifacts
  vim.cmd("redraw")
end

--- Jump to a specific position
---@param node_info table Node info with row, col
local function jump_to(node_info)
  -- Validate window and buffer are still valid
  if not vim.api.nvim_win_is_valid(state.win) or not vim.api.nvim_buf_is_valid(state.bufnr) then
    cleanup()
    return
  end

  -- Convert from 0-indexed to 1-indexed for cursor position
  local target_row = node_info.row + 1
  local target_col = node_info.col

  -- Bounds check: ensure row is within buffer line count
  local line_count = vim.api.nvim_buf_line_count(state.bufnr)
  if target_row > line_count then
    target_row = line_count
  end

  -- Bounds check: ensure column is within line length
  local line = vim.api.nvim_buf_get_lines(state.bufnr, target_row - 1, target_row, false)[1]
  if line and target_col > #line then
    target_col = math.max(0, #line - 1)
  end

  vim.api.nvim_win_set_cursor(state.win, { target_row, target_col })
  cleanup()
end

--- Handle a single character input during jump mode
---@param char string The character pressed
local function handle_char(char)
  if not state.active then
    return
  end

  -- Check for cancel (using cached termcode)
  if char == state.cancel_key then
    cleanup()
    return
  end

  -- Append to typed sequence
  state.typed = state.typed .. char

  -- Filter remaining labels that match the typed sequence
  local remaining = labels.filter_labels(state.label_map, state.typed)
  local count = vim.tbl_count(remaining)

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
    labels.update_label_display(state.bufnr, state.label_map, state.typed)
    vim.cmd("redraw")
  end
end

--- Input loop for collecting characters
--- Note: This uses a synchronous loop with getcharstr(), which is the standard
--- pattern for modal input in Neovim (used by flash.nvim, leap.nvim, etc.).
--- While it blocks the event loop, this is intentional to capture all input
--- during jump mode. Alternatives like vim.on_key() have their own trade-offs.
local function input_loop()
  while state.active do
    -- Get a single character
    local ok, char = pcall(vim.fn.getcharstr)
    if not ok or not char or char == "" then
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

  -- Initialize state (set fields individually to preserve table reference)
  state.active = true
  state.bufnr = bufnr
  state.win = win
  state.label_map = {}
  state.typed = ""
  state.cancel_key = vim.api.nvim_replace_termcodes(config.options.advanced.cancel_key, true, false, true)

  -- Display labels and get mapping (this clears existing extmarks first)
  state.label_map = labels.display_labels(bufnr, nodes)

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
  if state.active then
    cleanup()
  end
end

--- Check if a jump session is currently active
---@return boolean
function M.is_active()
  return state.active
end

return M
