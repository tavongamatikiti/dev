local group = vim.api.nvim_create_augroup("Tavonga", {})

-- highlight yank
vim.api.nvim_create_autocmd("TextYankPost", {
	group = group,
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- js/ts use 2 spaces
vim.api.nvim_create_autocmd("FileType", {
	group = group,
	pattern = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
	callback = function()
		vim.opt_local.tabstop = 2
		vim.opt_local.shiftwidth = 2
		vim.opt_local.softtabstop = 2
	end,
})
