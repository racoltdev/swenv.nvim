local M = {}

local get_venvs_paths = function()
  venvs_paths = {vim.fn.expand('~/venvs')}
  cache = require('swenv.cache').get_root()
  if cache then
	  venvs_paths[2] = cache.filename
  end
  return venvs_paths
end

M.settings = {
  -- Should return a list of tables with a `name` and a `path` entry each.
  -- Gets the argument `venvs_path` set below.
  -- By default just lists the entries in `venvs_path`.
 -- get_venvs = function(venvs_path)
 --   return require('swenv.api').get_venvs(venvs_path)
 -- end,
  -- Path passed to `get_venvs`
  venvs_paths = get_venvs_paths(),
  -- Something to do after setting an environment
  post_set_venv = nil,
}

return M
