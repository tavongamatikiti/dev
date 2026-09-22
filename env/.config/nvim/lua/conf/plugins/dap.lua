return {
	{
		"mfussenegger/nvim-dap",
		lazy = false,
		config = function()
			local dap = require("dap")
			dap.set_log_level("DEBUG")
			local maps = {
				{ "<F8>", dap.continue, "Debug: Continue" },
				{ "<F10>", dap.step_over, "Debug: Step Over" },
				{ "<F11>", dap.step_into, "Debug: Step Into" },
				{ "<F12>", dap.step_out, "Debug: Step Out" },
				{ "<leader>b", dap.toggle_breakpoint, "Debug: Toggle Breakpoint" },
			}
			for _, m in ipairs(maps) do
				vim.keymap.set("n", m[1], m[2], { desc = m[3] })
			end
			vim.keymap.set("n", "<leader>B", function()
				dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
			end, { desc = "Debug: Set Conditional Breakpoint" })
		end,
	},
	{
		"rcarriga/nvim-dap-ui",
		dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
		config = function()
			vim.api.nvim_create_augroup("DapGroup", { clear = true })
			require("conf.dap.ui").setup(require("dap"), require("dapui"))
		end,
	},
	{
		"jay-babu/mason-nvim-dap.nvim",
		dependencies = { "williamboman/mason.nvim", "mfussenegger/nvim-dap", "neovim/nvim-lspconfig" },
		config = function()
			require("mason-nvim-dap").setup({
				ensure_installed = { "js-debug-adapter", "codelldb" },
				automatic_installation = true,
				handlers = { function(config) require("mason-nvim-dap").default_setup(config) end },
			})
			require("conf.dap.adapters").setup(require("dap"))
		end,
	},
}
