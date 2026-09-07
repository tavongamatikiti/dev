return {
    "folke/trouble.nvim",
    config = function()
        require("trouble").setup({})

        -- toggle trouble window
        vim.keymap.set("n", "<leader>tt", function()
            require("trouble").toggle("diagnostics")
        end)

        -- jump to next item
        vim.keymap.set("n", "[t", function()
            require("trouble").next({ skip_groups = true, jump = true })
        end)

        -- jump to previous item
        vim.keymap.set("n", "]t", function()
          require("trouble").prev({ skip_groups = true, jump = true })
        end)
    end,
}