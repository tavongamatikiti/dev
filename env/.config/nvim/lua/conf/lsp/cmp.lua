local M = {}

-- completion setup
function M.setup()
	local cmp = require("cmp")
	local select = { behavior = cmp.SelectBehavior.Select }
	cmp.setup({
		snippet = { expand = function(args) require("luasnip").lsp_expand(args.body) end },
		mapping = cmp.mapping.preset.insert({
			["<C-p>"] = cmp.mapping.select_prev_item(select),
			["<C-n>"] = cmp.mapping.select_next_item(select),
			["<C-y>"] = cmp.mapping.confirm({ select = true }),
			["<C-Space>"] = cmp.mapping.complete(),
			["<Tab>"] = cmp.mapping(function(fallback)
				if cmp.visible() then cmp.select_next_item() else fallback() end
			end, { "i", "s" }),
			["<S-Tab>"] = cmp.mapping(function(fallback)
				if cmp.visible() then cmp.select_prev_item() else fallback() end
			end, { "i", "s" }),
		}),
		sources = cmp.config.sources({ { name = "nvim_lsp" }, { name = "luasnip" }, { name = "path" } }, { { name = "buffer" } }),
	})
	require("conf.util.pair").setup(cmp)
end

return M
