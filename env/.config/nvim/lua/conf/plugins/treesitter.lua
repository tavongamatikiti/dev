local ensure_installed = {
    "vimdoc",
    "javascript",
    "typescript",
    "lua",
    "jsdoc",
    "bash",
    "c",
    "cpp",
    "zig",
    "go",
    "gomod",
    "gowork",
    "gosum",
    "make",
    "cmake",
}

local indent_disabled = {
    javascript = true,
    typescript = true,
    tsx = true,
    typescriptreact = true,
    c = true,
    cpp = true,
    zig = true,
}

local function setup_treesitter_main()
    local treesitter = require("nvim-treesitter")
    local max_filesize = 100 * 1024

    treesitter.setup({})

    local group = vim.api.nvim_create_augroup("TavongaTreesitter", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        callback = function(args)
            local buf = args.buf
            local filetype = vim.bo[buf].filetype

            if not indent_disabled[filetype] then
                local lang = vim.treesitter.language.get_lang(filetype) or filetype
                if pcall(vim.treesitter.language.add, lang) then
                    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                end
            end

            if filetype == "html" then
                return
            end

            local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
            if ok and stats and stats.size > max_filesize then
                vim.notify(
                    "file larger than 100KB treesitter disabled for performance",
                    vim.log.levels.WARN,
                    { title = "treesitter" }
                )
                return
            end

            local started = pcall(vim.treesitter.start, buf)
            if started and filetype == "markdown" then
                vim.bo[buf].syntax = "markdown"
            end
        end,
    })
end

local function setup_treesitter_legacy()
    require("nvim-treesitter.configs").setup({
        ensure_installed = ensure_installed,
        sync_install = false,
        auto_install = true,
        indent = {
            enable = true,
            disable = { "javascript", "typescript", "tsx", "c", "cpp", "zig" },
        },
        highlight = {
            enable = true,
            disable = function(lang, buf)
                if lang == "html" then
                    return true
                end

                local max_filesize = 100 * 1024
                local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
                if ok and stats and stats.size > max_filesize then
                    vim.notify(
                        "file larger than 100KB treesitter disabled for performance",
                        vim.log.levels.WARN,
                        { title = "treesitter" }
                    )
                    return true
                end
            end,
            additional_vim_regex_highlighting = { "markdown" },
        },
    })
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
        dependencies = {
            "nvim-treesitter/nvim-treesitter-textobjects",
        },
        config = function()
            local ok, treesitter = pcall(require, "nvim-treesitter")
            if ok and treesitter.setup and treesitter.install then
                setup_treesitter_main()
                return
            end

            setup_treesitter_legacy()
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter-context",
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
        },
        config = function()
            require("treesitter-context").setup({
                enable = true,
                multiwindow = false,
                max_lines = 0,
                min_window_height = 0,
                line_numbers = true,
                multiline_threshold = 20,
                trim_scope = "outer",
                mode = "cursor",
                separator = nil,
                zindex = 20,
                on_attach = nil,
            })
        end,
    },
}
