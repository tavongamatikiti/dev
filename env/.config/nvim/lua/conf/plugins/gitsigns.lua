return {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
        signs = {
            add = { text = "▎" },
            change = { text = "▎" },
            delete = { text = "▁" },
            topdelete = { text = "▔" },
            changedelete = { text = "▎" },
            untracked = { text = "▎" },
        },
        signcolumn = true,
        numhl = false,
        linehl = false,
        word_diff = false,
        watch_gitdir = { follow_files = true },
        attach_to_untracked = true,
        current_line_blame = false,
        current_line_blame_opts = {
            virt_text = true,
            virt_text_pos = "eol",
            delay = 1000,
        },
        on_attach = function(bufnr)
            local gs = package.loaded.gitsigns
            local function map(mode, l, r, desc)
                vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
            end
            -- hunk nav (diff-aware)
            map("n", "]c", function()
                if vim.wo.diff then
                    vim.cmd.normal({ "]c", bang = true })
                else
                    gs.nav_hunk("next")
                end
            end, "Next hunk")
            map("n", "[c", function()
                if vim.wo.diff then
                    vim.cmd.normal({ "[c", bang = true })
                else
                    gs.nav_hunk("prev")
                end
            end, "Prev hunk")
            map("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
            map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
            map("v", "<leader>hs", function()
                gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
            end, "Stage hunk")
            map("v", "<leader>hr", function()
                gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
            end, "Reset hunk")
            map("n", "<leader>hS", gs.stage_buffer, "Stage buffer")
            map("n", "<leader>hu", gs.undo_stage_hunk, "Undo stage hunk")
            map("n", "<leader>hR", gs.reset_buffer, "Reset buffer")
            map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
            map("n", "<leader>hb", function()
                gs.blame_line({ full = true })
            end, "Blame line")
            map("n", "<leader>tb", gs.toggle_current_line_blame, "Toggle blame")
            map("n", "<leader>hd", gs.diffthis, "Diff this")
            map("n", "<leader>hD", function()
                gs.diffthis("~")
            end, "Diff this ~")
            map("n", "<leader>td", gs.toggle_deleted, "Toggle deleted")
            map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Select hunk")
        end,
    },
}
