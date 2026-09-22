return {
	"stevearc/conform.nvim",
	opts = {},
	config = function()
		require("conform").setup({
			format_on_save = { timeout_ms = 5000, lsp_format = "fallback" },
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
			formatters = { clang_format = { command = require("conf.util.toolchain").clang_format() } },
		})
		vim.keymap.set("n", "<leader>f", function()
			require("conform").format({ bufnr = 0 })
		end)
	end,
}
