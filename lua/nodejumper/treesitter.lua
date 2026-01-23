local M = {}

local config = require("nodejumper.config")

--- Get the visible line range in the current window
---@return number start_line (0-indexed)
---@return number end_line (0-indexed)
local function get_visible_range()
  local start_line = vim.fn.line("w0") - 1 -- Convert to 0-indexed
  local end_line = vim.fn.line("w$") - 1
  return start_line, end_line
end

--- Check if a position is within the visible range
---@param row number 0-indexed row
---@param start_line number 0-indexed start line
---@param end_line number 0-indexed end line
---@return boolean
local function is_visible(row, start_line, end_line)
  return row >= start_line and row <= end_line
end

--- Calculate node size in characters
---@param node TSNode
---@param bufnr number Buffer number
---@return number
local function get_node_size(node, bufnr)
  local start_row, start_col, end_row, end_col = node:range()
  if start_row == end_row then
    return end_col - start_col
  end
  -- For multi-line nodes, calculate actual size using line lengths
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
  if #lines == 0 then
    return 0
  end
  local size = 0
  for i, line in ipairs(lines) do
    if i == 1 then
      -- First line: from start_col to end of line
      size = size + (#line - start_col)
    elseif i == #lines then
      -- Last line: from start to end_col
      size = size + end_col
    else
      -- Middle lines: full line length
      size = size + #line
    end
  end
  return size
end

--- Get the length of the word at a specific position in the buffer
---@param bufnr number Buffer number
---@param row number 0-indexed row
---@param col number 0-indexed column
---@return number Length of the word at that position
local function get_word_length_at_position(bufnr, row, col)
  local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
  if not line or col >= #line then
    return 0
  end

  -- Extract word starting at col (alphanumeric and underscore)
  local word_end = col
  while word_end < #line do
    local char = line:sub(word_end + 1, word_end + 1)
    if not char:match("[%w_]") then
      break
    end
    word_end = word_end + 1
  end

  return word_end - col
end

--- Collect all unique positions from visible treesitter nodes
---@param bufnr number Buffer number
---@return table[] Array of {row, col, node} tables
function M.get_visible_nodes(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local opts = config.options

  -- Check if treesitter is available for this buffer
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok or not parser then
    vim.notify("Treesitter parser not available for this buffer", vim.log.levels.WARN)
    return {}
  end

  local start_line, end_line = get_visible_range()
  local seen_positions = {}
  local nodes = {}

  -- Parse the tree
  local trees = parser:parse()
  if not trees or #trees == 0 then
    return {}
  end

  --- Recursively collect nodes from a TSNode
  ---@param node TSNode
  local function collect_nodes(node)
    local start_row, start_col, end_row, end_col = node:range()

    -- Check if the node starts within visible range
    if is_visible(start_row, start_line, end_line) then
      -- Create a unique key for this position
      local pos_key = string.format("%d:%d", start_row, start_col)

      -- Check node size if filtering is enabled
      local include_node = true
      local node_size = get_node_size(node, bufnr)
      if not opts.all_nodes then
        if node_size < opts.min_node_size then
          include_node = false
        end
      end

      -- Check word length at the label position
      if include_node and opts.advanced.min_word_length > 0 then
        local word_length = get_word_length_at_position(bufnr, start_row, start_col)
        if word_length < opts.advanced.min_word_length then
          include_node = false
        end
      end

      -- Only add if we haven't seen this position before
      if include_node and not seen_positions[pos_key] then
        seen_positions[pos_key] = true
        table.insert(nodes, {
          row = start_row,
          col = start_col,
          end_row = end_row,
          end_col = end_col,
          size = node_size,
        })
      end
    end

    -- Recurse into children
    for child in node:iter_children() do
      collect_nodes(child)
    end
  end

  -- Process all trees (there can be multiple for injected languages)
  for _, tree in ipairs(trees) do
    local root = tree:root()
    collect_nodes(root)
  end

  -- Sort by position (top to bottom, left to right)
  table.sort(nodes, function(a, b)
    if a.row == b.row then
      return a.col < b.col
    end
    return a.row < b.row
  end)

  -- Remove nodes that are too close together (minimum spacing)
  -- This prevents label clutter while keeping more jump targets than containment filtering
  local filtered_nodes = {}
  local min_spacing = opts.min_spacing or 2

  for _, node_info in ipairs(nodes) do
    local too_close = false

    -- Check if this node is too close to any previously added node on the same line
    for _, prev_node in ipairs(filtered_nodes) do
      if node_info.row == prev_node.row then
        local distance = math.abs(node_info.col - prev_node.col)
        if distance < min_spacing then
          too_close = true
          break
        end
      end
    end

    if not too_close then
      table.insert(filtered_nodes, node_info)
    end
  end

  nodes = filtered_nodes

  return nodes
end

return M
