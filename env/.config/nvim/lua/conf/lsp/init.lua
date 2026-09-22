local M = {}

-- mason + servers + cmp + diagnostics
function M.setup()
	local cmp_lsp = require("cmp_nvim_lsp")
	local capabilities = vim.tbl_deep_extend("force", {}, vim.lsp.protocol.make_client_capabilities(), cmp_lsp.default_capabilities())
	require("fidget").setup({})
	require("mason").setup()
	require("mason-lspconfig").setup({ ensure_installed = { "lua_ls", "vtsls", "tailwindcss", "zls" }, automatic_enable = false })
	require("conf.lsp.servers").setup(capabilities)
	require("conf.lsp.cmp").setup()
	vim.diagnostic.config({
		virtual_text = true,
		update_in_insert = true,
		float = { focusable = false, style = "minimal", border = "rounded", source = "always", header = "", prefix = "" },
	})
end

return M
