local M = {}

-- single right panel layout
local function layout(name)
	return { elements = { { id = name } }, enter = true, size = 40, position = "right" }
end

-- dap ui with one panel at a time
function M.setup(dap, dapui)
	local names = { "repl", "stacks", "scopes", "console", "watches", "breakpoints" }
	local layouts = {}
	local index_of = {}
	for _, name in ipairs(names) do
		table.insert(layouts, layout(name))
		index_of[name] = #layouts
	end
	local open_layout = nil
	local function toggle(name)
		local idx = index_of[name]
		if not idx then
			error(string.format("bad name: %s", name))
		end
		local uis = vim.api.nvim_list_uis()[1]
		if uis ~= nil then
			layouts[idx].size = uis.width
		end
		if open_layout == name then
			pcall(dapui.close)
			open_layout = nil
			return
		end
		pcall(dapui.close)
		pcall(dapui.toggle, idx)
		open_layout = name
	end
	local maps = {
		{ "<leader>dr", "repl", "Debug: toggle repl ui" },
		{ "<leader>ds", "stacks", "Debug: toggle stacks ui" },
		{ "<leader>dw", "watches", "Debug: toggle watches ui" },
		{ "<leader>db", "breakpoints", "Debug: toggle breakpoints ui" },
		{ "<leader>dS", "scopes", "Debug: toggle scopes ui" },
		{ "<leader>dc", "console", "Debug: toggle console ui" },
	}
	for _, m in ipairs(maps) do
		vim.keymap.set("n", m[1], function() toggle(m[2]) end, { desc = m[3] })
	end
	vim.api.nvim_create_autocmd("BufEnter", {
		group = "DapGroup",
		pattern = "*dap-repl*",
		callback = function() vim.wo.wrap = true end,
	})
	local function navigate(args)
		local wid = nil
		for _, win_id in ipairs(vim.api.nvim_list_wins()) do
			if vim.api.nvim_win_get_buf(win_id) == args.buf then
				wid = win_id
			end
		end
		if wid == nil then
			return
		end
		vim.schedule(function()
			if vim.api.nvim_win_is_valid(wid) then
				vim.api.nvim_set_current_win(wid)
			end
		end)
	end
	vim.api.nvim_create_autocmd("BufWinEnter", { group = "DapGroup", pattern = "*dap-repl*", callback = navigate })
	vim.api.nvim_create_autocmd("BufWinEnter", { group = "DapGroup", pattern = "*DAP Watches*", callback = navigate })
	dapui.setup({ layouts = layouts, enter = true })
	dap.listeners.before.event_terminated.dapui_config = function()
		dapui.close()
		open_layout = nil
	end
	dap.listeners.before.event_exited.dapui_config = function()
		dapui.close()
		open_layout = nil
	end
	dap.listeners.after.event_output.dapui_config = function(_, body)
		if body.category == "console" then
			dapui.eval(body.output)
		end
	end
end

return M
