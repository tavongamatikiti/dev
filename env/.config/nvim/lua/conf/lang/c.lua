local fs = require("conf.util.fs")

local M = {}

-- collect -I include dirs upward
function M.include_flags()
	local flags = ""
	local dir = vim.fn.expand("%:p:h")
	for _ = 1, 4 do
		if vim.fn.isdirectory(dir .. "/include") == 1 then
			flags = flags .. " -I" .. vim.fn.shellescape(dir .. "/include")
		end
		if dir == "/" or dir == "" then break end
		dir = vim.fn.fnamemodify(dir, ":h")
	end
	return flags
end

-- cmake build then run
function M.cmake_run(root)
	local build_dir = root .. "/build"
	if vim.fn.isdirectory(build_dir) == 0 then
		vim.cmd("!cmake -S " .. vim.fn.shellescape(root) .. " -B " .. vim.fn.shellescape(build_dir) .. " -DCMAKE_BUILD_TYPE=Debug")
	end
	local bin = root .. "/bin/nave"
	vim.cmd("!cmake --build " .. vim.fn.shellescape(build_dir) .. " && ( " .. vim.fn.shellescape(bin) .. " || " .. vim.fn.shellescape(build_dir .. "/nave") .. " || " .. vim.fn.shellescape(build_dir .. "/test_nave") .. " )")
end

-- single file fallback
function M.single_run(root, file)
	local out = "/tmp/nvim-c-" .. vim.fn.expand("%:t:r")
	local srcs = vim.fn.shellescape(file)
	local nave_src = root and (root .. "/src/nave.c") or ""
	if nave_src ~= "" and vim.fn.filereadable(nave_src) == 1 and file:match("main%.c$") then
		srcs = srcs .. " " .. vim.fn.shellescape(nave_src)
	end
	vim.cmd("!clang -std=c23 -Wall -Wextra -g -O0" .. M.include_flags() .. " " .. srcs .. " -o " .. vim.fn.shellescape(out) .. " && " .. vim.fn.shellescape(out))
end

-- smart compile and run
function M.run()
	vim.cmd("w")
	local file = vim.fn.expand("%:p")
	local root = fs.root({ "CMakeLists.txt", "Makefile", ".git" })
	if fs.has_file(root, "CMakeLists.txt") then
		M.cmake_run(root)
		return
	end
	if fs.has_file(root, "Makefile") then
		vim.cmd("!make -C " .. vim.fn.shellescape(root) .. " run 2>&1 | head -40")
		return
	end
	M.single_run(root, file)
end

-- build only
function M.build()
	vim.cmd("w")
	local root = fs.root({ "CMakeLists.txt", "Makefile", ".git" })
	if fs.has_file(root, "CMakeLists.txt") then
		vim.cmd("!cmake -S " .. vim.fn.shellescape(root) .. " -B " .. vim.fn.shellescape(root .. "/build") .. " -DCMAKE_BUILD_TYPE=Debug && cmake --build " .. vim.fn.shellescape(root .. "/build") .. " 2>&1 | tail -20")
		return
	end
	vim.cmd("!bear -- make 2>&1 | head -20")
end

-- c/cpp opts and maps
function M.setup()
	vim.api.nvim_create_autocmd("FileType", {
		pattern = { "c", "cpp" },
		callback = function()
			vim.opt_local.tabstop = 2
			vim.opt_local.shiftwidth = 2
			vim.opt_local.softtabstop = 2
			vim.opt_local.expandtab = true
			vim.opt_local.cindent = true
			vim.opt_local.autoindent = true
			vim.opt_local.smartindent = false
			vim.opt_local.indentexpr = ""
			vim.opt_local.cinoptions = "l1,g0,N-s,E-s"
			vim.keymap.set("n", "<leader>rr", M.run, { buffer = true, desc = "C: compile & run (smart)" })
			vim.keymap.set("n", "<leader>rb", M.build, { buffer = true, desc = "C: build (CMake or bear)" })
		end,
	})
end

return M
