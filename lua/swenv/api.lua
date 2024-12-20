local M = {}

local settings = require('swenv.config').settings

local ORIGINAL_PATH = vim.fn.getenv('PATH')

local current_venv = nil

local update_path = function(path)
  vim.fn.setenv('PATH', path .. '/bin' .. ':' .. ORIGINAL_PATH)
end


local find_cache = function(dir)
	local Path = require('plenary.path')
	local cache = Path:new(dir.filename .. '/.cachedVenv')
	if cache:is_file() then
		return cache
	else
		return nil
	end
end

local write_cache = function(env_path)
	local root = require("swenv.cache").get_root()
	local Path = require('plenary.path')
	local cache = Path:new(root.filename .. '/.cachedVenv')
	if not cache:is_file() then
		cache:touch()
	end
	cache:write(env_path, 'w', 438)
end

local set_venv = function(venv)
  if venv.source == 'conda' then
    vim.fn.setenv('CONDA_PREFIX', venv.path)
    vim.fn.setenv('CONDA_DEFAULT_ENV', venv.name)
    vim.fn.setenv('CONDA_PROMPT_MODIFIER', '(' .. venv.name .. ')')
  else
    vim.fn.setenv('VIRTUAL_ENV', venv.path)
  end

  current_venv = venv

  -- TODO: remove old path
  update_path(venv.path)

  if settings.post_set_venv then
    settings.post_set_venv(venv)
  end
  write_cache(venv.path)
end

select_cached = function()
	local Path = require('plenary.path')
	local root_dir  = require('swenv.cache').get_root()
	-- Project root found
	if root_dir then
		print('Project root directory found: ' .. root_dir.filename)
		local cache = find_cache(root_dir)
		-- .cachedVenv exists
		if cache then
			local env = cache:readlines()[1]
			-- check that there is an entry in .cacheVenvs
			if env then
				local env_path = Path:new(env)
				local env_root = env_path:parent()
				local env_name = env_path:make_relative(env_path:parent().filename)
				local env_root_list = {env_root.filename}
				local env_objs = get_venvs(env_root_list)
				for _, e in ipairs(env_objs) do
					if e.name == env_name then
						print('Automatically sourcing '..env..' from venv cache')
						set_venv(e)
						return
					end
				end
				print('Could not find valid venv in cache')
			end
		-- cache does not exist
		else
			pick_venv()
		end
	else
		print('Project root could not be found. Please manually source or edit swenv config')
	end
	return
end

---
---Checks who appears first in PATH. Returns `true` if `first` appears first and `false` otherwise
---
---@param first string|nil
---@param second string|nil
---@return boolean
local has_high_priority_in_path = function (first, second)
  if first == nil or first == vim.NIL then
    return false
  end

  if second == nil or second == vim.NIL then
    return true
  end

  return string.find(ORIGINAL_PATH, first) < string.find(ORIGINAL_PATH, second)
end

M.init = function()
  local success, Path = pcall(require, 'plenary.path')
  if not success then
    vim.notify('Could not require plenary: ' .. Path, vim.log.levels.WARN)
    return
  end
  local venv

  local venv_env = vim.fn.getenv('VIRTUAL_ENV')
  if venv_env ~= vim.NIL then
	parent = Path:new(venv_env):parent()
    venv = {
      name = Path:new(venv_env):make_relative(parent.filename),
      path = venv_env,
      source = 'venv',
    }
  end

  local conda_env = vim.fn.getenv('CONDA_DEFAULT_ENV')
  if conda_env ~= vim.NIL and has_high_priority_in_path(conda_env, venv_env) then
    venv = {
      name = conda_env,
      path = vim.fn.getenv('CONDA_PREFIX'),
      source = 'conda'
    }
  end

  if venv then
    current_venv = venv
  end
  select_cached()
end

get_current_venv = function()
  return current_venv
end

get_venvs = function(venvs_paths)
  local success, Path = pcall(require, 'plenary.path')
  if not success then
    vim.notify('Could not require plenary: ' .. Path, vim.log.levels.WARN)
    return
  end
  local scan_dir = require('plenary.scandir').scan_dir

  local venvs = {}

  -- CONDA
  local conda_exe = vim.fn.getenv('CONDA_EXE')
  if conda_exe ~= vim.NIL then
    local conda_env_path = Path:new(conda_exe):parent():parent() .. '/envs'
    local conda_paths = scan_dir(conda_env_path, { depth = 1, only_dirs = true, silent = true })

    for _, path in ipairs(conda_paths) do
      table.insert(venvs, {
        name = Path:new(path):make_relative(conda_env_path),
        path = path,
        source = 'conda',
      })
    end
  end

  -- VENV
  for _, venvs_path in ipairs(venvs_paths) do
  	local paths = scan_dir(venvs_path, { depth = 1, only_dirs = true, hidden = true, silent = true })
  	for _, path in ipairs(paths) do
		local potential_dir_name = Path:new(path):make_relative(venvs_path)
		if Path:new(path .. "/pyvenv.cfg"):exists() then
			table.insert(venvs, {
  	    		-- TODO how does one get the name of the file directly?
  	    		name = potential_dir_name,
				path = path,
  	    		source = 'venv',
  			})
		end
  	end
  end
  return venvs
end

pick_venv = function()
  paths = settings.venvs_paths
  vim.ui.select(get_venvs(settings.venvs_paths), {
    prompt = 'Select python venv',
    format_item = function(item)
      return string.format('%s (%s) [%s]', item.name, item.path, item.source)
    end,
  }, function(choice)
    if not choice then
      return
    end
    set_venv(choice)
  end)
end

return M
