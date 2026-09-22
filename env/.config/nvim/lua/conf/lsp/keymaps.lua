local M = {}

-- lsp keymaps on attach
function M.setup()
	local group = vim.api.nvim_create_augroup("Tavonga", { clear = false })
	vim.api.nvim_create_autocmd("LspAttach", {
		group = group,
		callback = function(e)
			local opts = { buffer = e.buf }
			local maps = {
				{ "n", "gd", vim.lsp.buf.definition },
				{ "n", "K", vim.lsp.buf.hover },
				{ "n", "<leader>vws", vim.lsp.buf.workspace_symbol },
				{ "n", "<leader>vd", vim.diagnostic.open_float },
				{ "n", "<leader>vca", vim.lsp.buf.code_action },
				{ "n", "<leader>vrr", vim.lsp.buf.references },
				{ "n", "<leader>vrn", vim.lsp.buf.rename },
				{ "i", "<C-h>", vim.lsp.buf.signature_help },
				{ "n", "[d", vim.diagnostic.goto_next },
				{ "n", "]d", vim.diagnostic.goto_prev },
			}
			for _, m in ipairs(maps) do
				vim.keymap.set(m[1], m[2], m[3], opts)
			end
		end,
	})
end

return M
