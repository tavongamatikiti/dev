return {
	"stevearc/conform.nvim",
	opts = {},
	config = function()
		require("conform").setup({
			format_on_save = {
				timeout_ms = 5000,
				lsp_format = "fallback",
			},
			formatters_by_ft = {
				lua = { "stylua" },
				javascript = { "biome" },
				javascriptreact = { "biome" },
				typescript = { "biome" },
				typescriptreact = { "biome" },
				json = { "biome" },
				css = { "biome" },
				c = { "clang_format" },
				cpp = { "clang_format" },
				zig = { "zigfmt" },
				go = { "gofmt" },
			},
			-- Fallback if llvm@21 is keg-only and not linked
			formatters = {
				clang_format = {
					command = vim.fn.executable("clang-format") == 1 and "clang-format"
						or "/opt/homebrew/opt/llvm@21/bin/clang-format",
				},
			},
		})

		vim.keymap.set("n", "<leader>f", function()
			require("conform").format({ bufnr = 0 })
		end)
	end,
}
