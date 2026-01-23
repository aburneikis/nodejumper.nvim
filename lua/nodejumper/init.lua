local M = {}

local config = require("nodejumper.config")

--- Setup the plugin with user options
---@param opts table|nil Configuration options
function M.setup(opts)
  config.setup(opts)
end

return M
