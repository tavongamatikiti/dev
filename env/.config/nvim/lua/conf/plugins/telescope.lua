return {
	"nvim-telescope/telescope.nvim",
	tag = "0.1.5",
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		require("telescope").setup({})
		local builtin = require("telescope.builtin")
		local maps = {
			{ "<leader>pf", builtin.find_files },
			{ "<C-p>", builtin.git_files },
			{ "<leader>vh", builtin.help_tags },
		}
		for _, m in ipairs(maps) do
			vim.keymap.set("n", m[1], m[2], {})
		end
		vim.keymap.set("n", "<leader>pws", function()
			builtin.grep_string({ search = vim.fn.expand("<cword>") })
		end)
		vim.keymap.set("n", "<leader>pWs", function()
			builtin.grep_string({ search = vim.fn.expand("<cWORD>") })
		end)
		vim.keymap.set("n", "<leader>ps", function()
			builtin.grep_string({ search = vim.fn.input("Grep > ") })
		end)
	end,
}
