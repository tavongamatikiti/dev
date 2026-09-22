local M = {}

-- project root from markers
function M.root(markers)
	return vim.fs.root(0, markers)
end

-- true if buffer file exceeds max bytes
function M.is_large_file(buf, max)
	local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
	return ok and stats and stats.size > max
end

-- true if root/name is readable file
function M.has_file(root, name)
	return root and vim.fn.filereadable(root .. "/" .. name) == 1
end

return M
