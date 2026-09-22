local toolchain = require("conf.util.toolchain")

local M = {}

-- js/ts debug configs
function M.setup_js(dap)
	for _, lang in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
		dap.adapters[lang] = {
			type = "server",
			host = "localhost",
			port = "${port}",
			executable = { command = "node", args = { vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js", "${port}" } },
		}
		dap.configurations[lang] = {
			{ type = lang, request = "launch", name = "launch file", program = "${file}", cwd = "${workspaceFolder}", sourceMaps = true },
			{ type = lang, request = "attach", name = "attach to process", port = 9229, cwd = "${workspaceFolder}", sourceMaps = true },
		}
	end
end

-- c/cpp/zig configs
function M.setup_c(dap)
	dap.adapters.codelldb = { type = "server", port = "${port}", executable = { command = toolchain.codelldb(), args = { "--port", "${port}" } } }
	dap.adapters.lldb = dap.adapters.codelldb
	for _, lang in ipairs({ "c", "cpp", "zig" }) do
		if not dap.configurations[lang] then
			dap.configurations[lang] = {}
		end
		table.insert(dap.configurations[lang], { name = "Launch (codelldb)", type = "codelldb", request = "launch", program = function() return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/zig-out/bin/", "file") end, cwd = "${workspaceFolder}", stopOnEntry = false })
		table.insert(dap.configurations[lang], { name = "Launch current file (cc/zig run)", type = "codelldb", request = "launch", program = "${file}", cwd = "${workspaceFolder}", stopOnEntry = false })
	end
end

-- go configs
function M.setup_go(dap)
	local dlv = toolchain.dlv()
	if not dlv then
		return
	end
	dap.adapters.delve = { type = "server", port = "${port}", executable = { command = dlv, args = { "dap", "-l", "127.0.0.1:${port}" } } }
	dap.adapters.go = dap.adapters.delve
	dap.configurations.go = {
		{ type = "delve", name = "Debug (go run .)", request = "launch", program = "${workspaceFolder}" },
		{ type = "delve", name = "Debug current file", request = "launch", program = "${file}" },
		{ type = "delve", name = "Debug test (go test)", request = "launch", mode = "test", program = "${file}" },
	}
end

-- all adapters
function M.setup(dap)
	M.setup_js(dap)
	M.setup_c(dap)
	M.setup_go(dap)
end

return M
