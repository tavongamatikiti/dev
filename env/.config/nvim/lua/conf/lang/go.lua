local fs = require("conf.util.fs")

local M = {}

-- go run file or module
function M.run()
	vim.cmd("w")
	local root = fs.root({ "go.mod", "go.work", ".git" })
	if fs.has_file(root, "go.mod") or fs.has_file(root, "go.work") then
		vim.cmd("!go run . 2>&1 | head -100")
	else
		vim.cmd("!go run " .. vim.fn.shellescape(vim.fn.expand("%:p")) .. " 2>&1 | head -100")
	end
end

-- go test
function M.test()
	vim.cmd("w")
	vim.cmd("!go test ./... 2>&1 | tail -30")
end

-- go build
function M.build()
	vim.cmd("w")
	vim.cmd("!go build -o /tmp/nvim-go-build 2>&1 | tail -20")
end

-- go opts and maps
function M.setup()
	vim.api.nvim_create_autocmd("FileType", {
		pattern = { "go", "gomod", "gowork", "gosum" },
		callback = function()
			vim.opt_local.tabstop = 4
			vim.opt_local.shiftwidth = 4
			vim.opt_local.softtabstop = 4
			vim.opt_local.expandtab = false
			vim.opt_local.smartindent = true
			vim.opt_local.autoindent = true
			vim.keymap.set("n", "<leader>rr", M.run, { buffer = true, desc = "Go: run" })
			vim.keymap.set("n", "<leader>tt", M.test, { buffer = true, desc = "Go: test" })
			vim.keymap.set("n", "<leader>rb", M.build, { buffer = true, desc = "Go: build" })
		end,
	})
end

return M
