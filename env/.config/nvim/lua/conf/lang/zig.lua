local M = {}

-- zig run
function M.run()
	vim.cmd("w")
	if vim.fn.filereadable("build.zig") == 1 then
		vim.cmd("!zig build run")
	else
		vim.cmd("!zig run " .. vim.fn.shellescape(vim.fn.expand("%:p")))
	end
end

-- zig test
function M.test()
	vim.cmd("w")
	if vim.fn.filereadable("build.zig") == 1 then
		vim.cmd("!zig build test --summary all")
	else
		vim.cmd("!zig test " .. vim.fn.shellescape(vim.fn.expand("%:p")))
	end
end

-- zig fmt on save via zls
function M.format()
	for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
		if c.name == "zls" then
			vim.lsp.buf.format({ async = false })
			return
		end
	end
end

-- zig opts and maps
function M.setup()
	vim.api.nvim_create_autocmd("FileType", {
		pattern = { "zig" },
		callback = function()
			vim.opt_local.tabstop = 4
			vim.opt_local.shiftwidth = 4
			vim.opt_local.expandtab = true
			vim.opt_local.cindent = false
			vim.opt_local.smartindent = true
			vim.opt_local.autoindent = true
			vim.opt_local.indentexpr = ""
			vim.keymap.set("n", "<leader>rr", M.run, { buffer = true, desc = "Zig: run" })
			vim.keymap.set("n", "<leader>tt", M.test, { buffer = true, desc = "Zig: test" })
		end,
	})
	vim.api.nvim_create_autocmd("BufWritePre", {
		pattern = { "*.zig", "*.zon" },
		callback = M.format,
	})
end

return M
