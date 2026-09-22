local fs = require("conf.util.fs")

local max_filesize = 100 * 1024
local indent_off = { javascript = true, typescript = true, tsx = true, typescriptreact = true, c = true, cpp = true, zig = true }

-- skip treesitter for big files
local function is_big(buf)
	if fs.is_large_file(buf, max_filesize) then
		vim.notify("file larger than 100KB treesitter disabled for performance", vim.log.levels.WARN, { title = "treesitter" })
		return true
	end
	return false
end

return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = function()
			if vim.fn.executable("tree-sitter") == 1 then
				vim.cmd("TSUpdate")
			end
		end,
		dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
		config = function()
			require("nvim-treesitter").setup({})
			local group = vim.api.nvim_create_augroup("TavongaTreesitter", { clear = true })
			vim.api.nvim_create_autocmd("FileType", {
				group = group,
				callback = function(args)
					local buf = args.buf
					local ft = vim.bo[buf].filetype
					if not indent_off[ft] then
						local lang = vim.treesitter.language.get_lang(ft) or ft
						if pcall(vim.treesitter.language.add, lang) then
							vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
						end
					end
					if ft == "html" or is_big(buf) then
						return
					end
					local started = pcall(vim.treesitter.start, buf)
					if started and ft == "markdown" then
						vim.bo[buf].syntax = "markdown"
					end
				end,
			})
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		config = function()
			require("treesitter-context").setup({ enable = true, multiwindow = false, max_lines = 0, min_window_height = 0, line_numbers = true, multiline_threshold = 20, trim_scope = "outer", mode = "cursor", separator = nil, zindex = 20, on_attach = nil })
		end,
	},
}
