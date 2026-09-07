return {
    "nvim-lualine/lualine.nvim",
    config = function()
        local filetype_map = {
            javascript = "js",
            typescript = "ts",
            javascriptreact = "jsx",
            typescriptreact = "tsx",
            python = "py",
            lua = "lua",
            bash = "sh",
            json = "json",
            css = "css",
            html = "html",
        }

        require("lualine").setup({
            options = {
                theme = "catppuccin-mocha",
                component_separators = { left = "|", right = "|" },
                section_separators = { left = "", right = "" },
                globalstatus = true,
                icons_enabled = false,
            },
            sections = {
                lualine_a = { "mode" },
                lualine_b = { "branch", "diff", "diagnostics" },
                lualine_c = { { "filename", path = 1 } },
                lualine_x = {
                    {
                        function()
                            local ft = vim.bo.filetype
                            return filetype_map[ft] or ft
                        end,
                    },
                },
                lualine_y = { "progress" },
                lualine_z = { "location" },
            },
        })
    end,
}