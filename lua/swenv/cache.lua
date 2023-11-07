local M = {}

M.get_root = function(scanHeight)
	local Path = require('plenary.path')
	local scandir = require'plenary.scandir'.scan_dir

	local scan = scandir('.', { add_dirs = true, hidden = true, depth = 2 })
	local root_file = nil
	local root_dir = nil
	local root_markers = {".git", ".venv", "venv", "pyrightconfig.json"}
	for _, f in ipairs(scan) do
		local path = vim.split(f, '/')
		local i = table.getn(path)
		local file_name = path[i]
		for _, marker in ipairs(root_markers) do
			if file_name == marker then
				root_file = f
			end
		end
	end
	if root_file ~= nil then
		root_dir = Path:new(root_file):parent()
	end
	return root_dir
end

return M
