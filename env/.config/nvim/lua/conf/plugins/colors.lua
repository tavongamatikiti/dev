return {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		config = function()
			require("catppuccin").setup({
				flavour = "mocha",
				transparent_background = true,
				show_end_of_buffer = false,
				term_colors = true,
				integrations = {
					treesitter = true,
					cmp = true,
					gitsigns = true,
					native_lsp = { enabled = true },
					telescope = { enabled = true },
				},
				custom_highlights = function(colors)
					return {
						LineNr = { fg = colors.overlay2, bg = "none" }, -- #9399b2 visible on 11111b/0.85
						CursorLineNr = { fg = colors.yellow, bg = "none", style = { "bold" } },
						LineNrAbove = { fg = colors.overlay1, bg = "none" },
						LineNrBelow = { fg = colors.overlay1, bg = "none" },
						SignColumn = { bg = "none" },
						CursorLine = { bg = colors.surface0 },
					}
				end,
			})
			vim.cmd.colorscheme("catppuccin-mocha")
			-- ensure floats/popups also transparent to show ghostty blur (#11111b at 0.85)
			vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
			vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
		end,
	},
}

