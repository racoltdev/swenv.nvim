local M = {}

local update_config = function(opts)
  local config = require('swenv.config')
  opts = opts or {}
  config.settings = vim.tbl_extend('force', config.settings, opts)
end

M.setup = function(opts)
 -- this doesn't save the settings by the time the selector loads
  update_config(opts)
  -- this swaps out the venv before a lang server can load
  --require('swenv.api').init()
end

return M
