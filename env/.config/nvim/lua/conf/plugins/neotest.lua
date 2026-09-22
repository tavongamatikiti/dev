return {
	"nvim-neotest/neotest",
	dependencies = { "nvim-neotest/nvim-nio", "nvim-lua/plenary.nvim", "antoinemadec/FixCursorHold.nvim", "nvim-treesitter/nvim-treesitter", "marilari88/neotest-vitest" },
	config = function()
		local neotest = require("neotest")
		neotest.setup({ adapters = { require("neotest-vitest") } })
		local maps = {
			{ "<leader>tr", function() neotest.run.run() end, "Debug: run nearest test" },
			{ "<leader>tv", function() neotest.summary.toggle() end, "Debug: summary toggle" },
			{ "<leader>ts", function() neotest.run.run({ suite = true }) end, "Debug: run test suite" },
			{ "<leader>td", function() neotest.run.run({ strategy = "dap" }) end, "Debug: debug nearest test" },
			{ "<leader>to", function() neotest.output.open() end, "Debug: open test output" },
			{ "<leader>ta", function() neotest.run.run(vim.fn.getcwd()) end, "Debug: run all tests" },
		}
		for _, m in ipairs(maps) do
			vim.keymap.set("n", m[1], m[2], { desc = m[3] })
		end
	end,
}
