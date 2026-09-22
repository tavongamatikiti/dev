local M = {}

local pair_map = { ["{"] = "}", ["("] = ")", ["["] = "]" }
local tag_filetypes = { html = true, xml = true, javascriptreact = true, typescriptreact = true }
local enter_key = vim.api.nvim_replace_termcodes("<CR>", true, false, true)

-- split {} () [] on enter
function M.split_pair()
	local col = vim.fn.col(".")
	local line = vim.api.nvim_get_current_line()
	if pair_map[line:sub(col - 1, col - 1)] == line:sub(col, col) then
		return vim.api.nvim_replace_termcodes("<CR><Esc>ko", true, false, true)
	end
	return nil
end

-- split <div>|</div> on enter
function M.split_tag()
	if not tag_filetypes[vim.bo.filetype] then
		return false
	end
	local col = vim.fn.col(".")
	local line = vim.api.nvim_get_current_line()
	local before, after = line:sub(1, col - 1), line:sub(col)
	if line:sub(col - 1, col - 1) == ">" and line:sub(col, col) == "<" then
		if not before:match("<[^/!][^>]*>$") or not after:match("^</[^>]+>") then
			return false
		end
	elseif col == #line + 1 then
		local open, close = line:match("^(%s*<[^/!][^>]*>)(</[^>]+>)%s*$")
		if not open or not close then
			return false
		end
		before, after = open, close
	else
		return false
	end
	local row = vim.api.nvim_win_get_cursor(0)[1]
	local base = before:match("^%s*") or ""
	local shift = vim.fn.shiftwidth()
	if shift == 0 then
		shift = vim.bo.tabstop
	end
	local unit = vim.bo.expandtab and string.rep(" ", shift) or "\t"
	local inner = base .. unit
	vim.api.nvim_buf_set_lines(0, row - 1, row, false, { before, inner, base .. after })
	vim.api.nvim_win_set_cursor(0, { row + 1, #inner })
	return true
end

-- cmp-aware enter
function M.setup(cmp)
	vim.keymap.set({ "i", "s" }, "<CR>", function()
		if M.split_tag() then
			return
		end
		local keys = M.split_pair() or enter_key
		if keys ~= enter_key then
			vim.api.nvim_feedkeys(keys, "in", false)
			return
		end
		if cmp.visible() then
			cmp.confirm({ select = true })
			return
		end
		vim.api.nvim_feedkeys(enter_key, "in", false)
	end, { silent = true })
end

return M
