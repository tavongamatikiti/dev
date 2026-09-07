return {
    "ziglang/zig.vim",
    ft = { "zig", "zon" },
    -- Codeberg mirror is auto-handled via lazy's url fallback, but use explicit url for clarity
    url = "https://codeberg.org/ziglang/zig.vim",
    init = function()
        -- Use ZLS for formatting, not zig.vim's autosave
        vim.g.zig_fmt_parse_errors = 0
        vim.g.zig_fmt_autosave = 0
    end,
}
