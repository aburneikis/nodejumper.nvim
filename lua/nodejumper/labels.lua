local M = {}

local config = require("nodejumper.config")

-- Namespace for extmarks
M.ns = vim.api.nvim_create_namespace("nodejumper")

--- Generate labels for a given count of items
--- If ≤26: use single chars. If 27-676: all two chars. If >676: all three chars.
---@param count number Number of labels needed
---@return string[] Array of label strings
function M.generate_labels(count)
  local opts = config.options
  local chars = opts.labels
  local labels = {}
  local char_count = #chars

  -- Determine label length based on count
  if count <= char_count then
    -- Single character labels
    for i = 1, count do
      table.insert(labels, chars:sub(i, i))
    end
  elseif count <= char_count * char_count then
    -- Two character labels
    for i = 1, char_count do
      for j = 1, char_count do
        if #labels >= count then
          return labels
        end
        local label = chars:sub(i, i) .. chars:sub(j, j)
        table.insert(labels, label)
      end
    end
  else
    -- Three character labels
    for i = 1, char_count do
      for j = 1, char_count do
        for k = 1, char_count do
          if #labels >= count then
            return labels
          end
          local label = chars:sub(i, i) .. chars:sub(j, j) .. chars:sub(k, k)
          table.insert(labels, label)
        end
      end
    end
  end

  return labels
end

--- Display labels on the buffer using extmarks
---@param bufnr number Buffer number
---@param nodes table[] Array of node info tables with {row, col, ...}
---@return table Map of label -> node info
function M.display_labels(bufnr, nodes)
  local opts = config.options
  local labels = M.generate_labels(#nodes)
  local label_map = {}

  -- Clear any existing extmarks
  M.clear_labels(bufnr)

  for i, node_info in ipairs(nodes) do
    local label = labels[i]
    if label then
      label_map[label] = node_info

      -- Create extmark with virtual text overlay
      vim.api.nvim_buf_set_extmark(bufnr, M.ns, node_info.row, node_info.col, {
        virt_text = { { label, opts.advanced.highlight.label } },
        virt_text_pos = "overlay",
        priority = opts.advanced.priority,
      })
    end
  end

  return label_map
end

--- Clear all labels from the buffer
---@param bufnr number Buffer number
function M.clear_labels(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, M.ns, 0, -1)
end

--- Apply dim highlight to all visible lines except label positions
---@param bufnr number Buffer number
---@param win number Window handle
function M.dim_buffer(bufnr, win)
  local opts = config.options
  local start_line = vim.fn.line("w0", win) - 1
  local end_line = vim.fn.line("w$", win)

  for line = start_line, end_line - 1 do
    local line_content = vim.api.nvim_buf_get_lines(bufnr, line, line + 1, false)[1]
    if line_content and #line_content > 0 then
      vim.api.nvim_buf_set_extmark(bufnr, M.ns, line, 0, {
        end_col = #line_content,
        hl_group = opts.advanced.highlight.dim,
        priority = opts.advanced.priority - 1,
      })
    end
  end
end

--- Filter labels based on typed prefix
---@param label_map table Current label map
---@param prefix string Typed prefix
---@return table Filtered label map with only matching labels
function M.filter_labels(label_map, prefix)
  local filtered = {}
  for label, node_info in pairs(label_map) do
    if vim.startswith(label, prefix) then
      filtered[label] = node_info
    end
  end
  return filtered
end

--- Update displayed labels to show only those matching the prefix
--- Also updates the visual appearance to show remaining characters
---@param bufnr number Buffer number
---@param label_map table Original label map
---@param prefix string Current typed prefix
function M.update_label_display(bufnr, label_map, prefix)
  local opts = config.options

  -- Clear current labels but keep dim
  local marks = vim.api.nvim_buf_get_extmarks(bufnr, M.ns, 0, -1, { details = true })
  for _, mark in ipairs(marks) do
    local details = mark[4]
    if details.virt_text then
      vim.api.nvim_buf_del_extmark(bufnr, M.ns, mark[1])
    end
  end

  -- Redraw matching labels
  for label, node_info in pairs(label_map) do
    if vim.startswith(label, prefix) then
      -- Show only the remaining part of the label
      local remaining = label:sub(#prefix + 1)
      if #remaining > 0 then
        vim.api.nvim_buf_set_extmark(bufnr, M.ns, node_info.row, node_info.col, {
          virt_text = { { remaining, opts.advanced.highlight.label } },
          virt_text_pos = "overlay",
          priority = opts.advanced.priority,
        })
      else
        -- For exact matches (no remaining chars), show a highlight indicator
        vim.api.nvim_buf_set_extmark(bufnr, M.ns, node_info.row, node_info.col, {
          virt_text = { { "●", opts.advanced.highlight.label } },
          virt_text_pos = "overlay",
          priority = opts.advanced.priority,
        })
      end
    end
  end
end

return M
