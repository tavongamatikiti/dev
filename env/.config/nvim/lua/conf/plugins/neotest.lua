return {
    "nvim-neotest/neotest",
    dependencies = {
        "nvim-neotest/nvim-nio",
        "nvim-lua/plenary.nvim",
        "antoinemadec/FixCursorHold.nvim",
        "nvim-treesitter/nvim-treesitter",
        "marilari88/neotest-vitest",
    },
    config = function()
        require("neotest").setup({
            adapters = {
                require("neotest-vitest"),
            },
        })

        -- run nearest test
        vim.keymap.set("n", "<leader>tr", function()
            require("neotest").run.run()
        end, { desc = "Debug: run nearest test" })

        -- toggle summary
        vim.keymap.set("n", "<leader>tv", function()
            require("neotest").summary.toggle()
        end, { desc = "Debug: summary toggle" })

        -- run test suite
        vim.keymap.set("n", "<leader>ts", function()
            require("neotest").run.run({ suite = true })
        end, { desc = "Debug: run test suite" })

        -- debug nearest test
        vim.keymap.set("n", "<leader>td", function()
            require("neotest").run.run({ strategy = "dap" })
        end, { desc = "Debug: debug nearest test" })

        -- open test output
        vim.keymap.set("n", "<leader>to", function()
            require("neotest").output.open()
        end, { desc = "Debug: open test output" })

        -- run all tests in cwd
        vim.keymap.set("n", "<leader>ta", function()
            require("neotest").run.run(vim.fn.getcwd())
        end, { desc = "Debug: run all tests" })
    end,
}