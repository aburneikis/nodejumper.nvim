local M = {}

local config = require("nodejumper.config")
local jumper = require("nodejumper.jumper")

--- Setup the plugin with user options
---@param opts table|nil Configuration options
function M.setup(opts)
  config.setup(opts)
  M.setup_keymaps()
  M.setup_commands()
end

--- Setup default keymaps
function M.setup_keymaps()
  local opts = config.options

  -- Set up the jump keymap
  vim.keymap.set({ "n", "x", "o" }, opts.jump_key, function()
    M.jump()
  end, { desc = "Jump to treesitter node" })
end

--- Setup user commands
function M.setup_commands()
  vim.api.nvim_create_user_command("NodejumperJump", function()
    M.jump()
  end, { desc = "Jump to a treesitter node" })

  vim.api.nvim_create_user_command("NodejumperCancel", function()
    M.cancel()
  end, { desc = "Cancel active jump session" })
end

--- Start a treesitter node jump
function M.jump()
  jumper.jump()
end

--- Cancel any active jump session
function M.cancel()
  jumper.cancel()
end

--- Check if a jump session is currently active
---@return boolean
function M.is_active()
  return jumper.is_active()
end

return M
