local M = {}

-- clangd from brew llvm or PATH
function M.clangd()
	if vim.fn.executable("/opt/homebrew/opt/llvm@21/bin/clangd") == 1 then
		return "/opt/homebrew/opt/llvm@21/bin/clangd"
	end
	if vim.fn.executable("/opt/homebrew/bin/clangd") == 1 then
		return "/opt/homebrew/bin/clangd"
	end
	return "clangd"
end

-- clang-format from PATH or keg-only llvm
function M.clang_format()
	if vim.fn.executable("clang-format") == 1 then
		return "clang-format"
	end
	return "/opt/homebrew/opt/llvm@21/bin/clang-format"
end

-- codelldb from mason or lldb-dap fallback
function M.codelldb()
	local mason = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/adapter/codelldb"
	if vim.fn.executable(mason) == 1 then
		return mason
	end
	if vim.fn.executable("/opt/homebrew/opt/llvm@21/bin/lldb-dap") == 1 then
		return "/opt/homebrew/opt/llvm@21/bin/lldb-dap"
	end
	if vim.fn.executable("lldb-dap") == 1 then
		return "lldb-dap"
	end
	return "codelldb"
end

-- delve from PATH or GOPATH bin, nil if missing
function M.dlv()
	local path = vim.fn.exepath("dlv")
	if path ~= "" then
		return path
	end
	local gopath = vim.fn.trim(vim.fn.system("go env GOPATH"))
	if gopath ~= "" and vim.fn.executable(gopath .. "/bin/dlv") == 1 then
		return gopath .. "/bin/dlv"
	end
	return nil
end

-- gopls from PATH
function M.gopls()
	local path = vim.fn.exepath("gopls")
	return path ~= "" and path or "gopls"
end

return M
