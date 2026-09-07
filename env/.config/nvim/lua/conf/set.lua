vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.signcolumn = "yes"

vim.diagnostic.config({
  signs = false
})

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
    callback = function()
        vim.opt_local.tabstop = 2
        vim.opt_local.shiftwidth = 2
        vim.opt_local.softtabstop = 2
    end,
})

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

vim.opt.colorcolumn = "130"

-- allow per-project .nvim.lua (playground .nvim.lua maps) – secure
vim.o.exrc = true
vim.o.secure = true

-- C / Zig: sane global defaults outside playgrounds
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "c", "cpp" },
    callback = function()
        vim.opt_local.tabstop = 2
        vim.opt_local.shiftwidth = 2
        vim.opt_local.softtabstop = 2
        vim.opt_local.expandtab = true
        -- use cindent (treesitter indent disabled for c/cpp – buggy, see treesitter.lua)
        vim.opt_local.cindent = true
        vim.opt_local.autoindent = true
        vim.opt_local.smartindent = false
        vim.opt_local.indentexpr = ""
        -- sane cino: indent after {, keep case labels etc
        vim.opt_local.cinoptions = "l1,g0,N-s,E-s"
        -- <leader>rr : smart compile & run (CMake > Makefile > single-file)
        vim.keymap.set("n", "<leader>rr", function()
            vim.cmd("w")
            local file = vim.fn.expand("%:p")
            -- Find project root (git, CMake, Makefile)
            local root = vim.fs.root(0, { "CMakeLists.txt", "Makefile", ".git" })
            local has_cmake = root and vim.fn.filereadable(root .. "/CMakeLists.txt") == 1
            local has_make = root and vim.fn.filereadable(root .. "/Makefile") == 1
            -- Collect -I include dirs upward from file (for single-file #include "nave/...")
            local inc_flags = ""
            local dir = vim.fn.expand("%:p:h")
            for _ = 1, 4 do
                if vim.fn.isdirectory(dir .. "/include") == 1 then
                    inc_flags = inc_flags .. " -I" .. vim.fn.shellescape(dir .. "/include")
                end
                if dir == "/" or dir == "" then break end
                dir = vim.fn.fnamemodify(dir, ":h")
            end
            if has_cmake then
                -- nave / any CMake project: build and run bin/<name>
                local build_dir = root .. "/build"
                if vim.fn.isdirectory(build_dir) == 0 then
                    vim.cmd("!cmake -S " .. vim.fn.shellescape(root) .. " -B " .. vim.fn.shellescape(build_dir) .. " -DCMAKE_BUILD_TYPE=Debug")
                end
                local bin = root .. "/bin/nave"
                if vim.fn.filereadable(root .. "/CMakeLists.txt") == 1 then
                    -- generic: build all, then try bin/<project> then build/<target>
                    vim.cmd("!cmake --build " .. vim.fn.shellescape(build_dir) .. " && ( " .. vim.fn.shellescape(bin) .. " || " .. vim.fn.shellescape(build_dir .. "/nave") .. " || " .. vim.fn.shellescape(build_dir .. "/test_nave") .. " )")
                else
                    vim.cmd("!cmake --build " .. vim.fn.shellescape(build_dir) .. " && " .. vim.fn.shellescape(bin))
                end
                return
            elseif has_make then
                vim.cmd("!make -C " .. vim.fn.shellescape(root) .. " run 2>&1 | head -40")
                return
            end
            -- Fallback single-file (playground, standalone)
            local out = "/tmp/nvim-c-" .. vim.fn.expand("%:t:r")
            local srcs = vim.fn.shellescape(file)
            -- If nave-style lib: also compile src/nave.c if exists and needed
            local nave_src = root and (root .. "/src/nave.c") or ""
            if nave_src ~= "" and vim.fn.filereadable(nave_src) == 1 and file:match("main%.c$") then
                srcs = srcs .. " " .. vim.fn.shellescape(nave_src)
            end
            local cmd = string.format("clang -std=c23 -Wall -Wextra -g -O0%s %s -o %s && %s", inc_flags, srcs, vim.fn.shellescape(out), vim.fn.shellescape(out))
            vim.cmd("!" .. cmd)
        end, { buffer = true, desc = "C: compile & run (smart)" })
        vim.keymap.set("n", "<leader>rb", function()
            vim.cmd("w")
            local root = vim.fs.root(0, { "CMakeLists.txt", "Makefile", ".git" })
            if root and vim.fn.filereadable(root .. "/CMakeLists.txt") == 1 then
                vim.cmd("!cmake -S " .. vim.fn.shellescape(root) .. " -B " .. vim.fn.shellescape(root .. "/build") .. " -DCMAKE_BUILD_TYPE=Debug && cmake --build " .. vim.fn.shellescape(root .. "/build") .. " 2>&1 | tail -20")
                return
            end
            vim.cmd("!bear -- make 2>&1 | head -20")
        end, { buffer = true, desc = "C: build (CMake or bear)" })
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "zig" },
    callback = function()
        vim.opt_local.tabstop = 4
        vim.opt_local.shiftwidth = 4
        vim.opt_local.expandtab = true
        -- zig: treesitter indent disabled, use smartindent
        vim.opt_local.cindent = false
        vim.opt_local.smartindent = true
        vim.opt_local.autoindent = true
        vim.opt_local.indentexpr = ""
        -- <leader>rr: zig run (single file) or zig build run (project)
        vim.keymap.set("n", "<leader>rr", function()
            vim.cmd("w")
            if vim.fn.filereadable("build.zig") == 1 then
                vim.cmd("!zig build run")
            else
                vim.cmd("!zig run " .. vim.fn.shellescape(vim.fn.expand("%:p")))
            end
        end, { buffer = true, desc = "Zig: run" })
        vim.keymap.set("n", "<leader>tt", function()
            vim.cmd("w")
            if vim.fn.filereadable("build.zig") == 1 then
                vim.cmd("!zig build test --summary all")
            else
                vim.cmd("!zig test " .. vim.fn.shellescape(vim.fn.expand("%:p")))
            end
        end, { buffer = true, desc = "Zig: test" })
    end,
})

-- Go 1.27: default gofmt (tabs), accessible from any folder, GOPATH ~/go
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "go", "gomod", "gowork", "gosum" },
    callback = function()
        vim.opt_local.tabstop = 4
        vim.opt_local.shiftwidth = 4
        vim.opt_local.softtabstop = 4
        vim.opt_local.expandtab = false -- gofmt uses tabs
        vim.opt_local.smartindent = true
        vim.opt_local.autoindent = true
        -- <leader>rr: go run (file or module)
        vim.keymap.set("n", "<leader>rr", function()
            vim.cmd("w")
            local file = vim.fn.expand("%:p")
            -- if go.mod/go.work exists, run module; else run single file
            local root = vim.fs.root(0, { "go.mod", "go.work", ".git" })
            local has_mod = root and (vim.fn.filereadable(root .. "/go.mod") == 1 or vim.fn.filereadable(root .. "/go.work") == 1)
            if has_mod then
                vim.cmd("!go run . 2>&1 | head -100")
            else
                vim.cmd("!go run " .. vim.fn.shellescape(file) .. " 2>&1 | head -100")
            end
        end, { buffer = true, desc = "Go: run" })
        vim.keymap.set("n", "<leader>tt", function()
            vim.cmd("w")
            vim.cmd("!go test ./... 2>&1 | tail -30")
        end, { buffer = true, desc = "Go: test" })
        vim.keymap.set("n", "<leader>rb", function()
            vim.cmd("w")
            vim.cmd("!go build -o /tmp/nvim-go-build 2>&1 | tail -20")
        end, { buffer = true, desc = "Go: build" })
    end,
})