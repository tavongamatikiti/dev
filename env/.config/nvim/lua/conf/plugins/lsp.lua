return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		"hrsh7th/cmp-nvim-lsp",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
		"hrsh7th/cmp-cmdline",
		"hrsh7th/nvim-cmp",
		"L3MON4D3/LuaSnip",
		"saadparwaiz1/cmp_luasnip",
		"j-hui/fidget.nvim",
	},

	config = function()
		local cmp = require("cmp")
		local cmp_lsp = require("cmp_nvim_lsp")
		local capabilities = vim.tbl_deep_extend(
			"force",
			{},
			vim.lsp.protocol.make_client_capabilities(),
			cmp_lsp.default_capabilities()
		)

		require("fidget").setup({})
		require("mason").setup()
		-- Only ensure mason-managed servers; clangd is system brew to avoid stuck install
		require("mason-lspconfig").setup({
			ensure_installed = {
				"lua_ls",
				"vtsls",
				"tailwindcss",
				"zls",
			},
			automatic_enable = false,
		})

		-- vim.lsp.config is the new API (nvim 0.11+, avoids lspconfig deprecation)
		local clangd_cmd = vim.fn.executable("/opt/homebrew/opt/llvm@21/bin/clangd") == 1
				and "/opt/homebrew/opt/llvm@21/bin/clangd"
			or vim.fn.executable("/opt/homebrew/bin/clangd") == 1 and "/opt/homebrew/bin/clangd"
			or "clangd"

		vim.lsp.config("lua_ls", {
			capabilities = capabilities,
			settings = {
				Lua = {
					runtime = { version = "LuaJIT" },
					diagnostics = { globals = { "vim" } },
					workspace = {
						library = vim.api.nvim_get_runtime_file("", true),
						checkThirdParty = false,
					},
					format = {
						enable = true,
						defaultConfig = { indent_style = "space", indent_size = "2" },
					},
				},
			},
		})

		vim.lsp.config("vtsls", {
			capabilities = capabilities,
		})

		vim.lsp.config("tailwindcss", {
			capabilities = capabilities,
			filetypes = { "html", "css", "scss", "javascript", "javascriptreact", "typescript", "typescriptreact" },
		})

		vim.lsp.config("zls", {
			capabilities = capabilities,
			cmd = { "zls" },
			filetypes = { "zig", "zon" },
			root_markers = { "build.zig", "build.zig.zon", ".git" },
			settings = {
				zls = {
					zig_exe_path = vim.fn.exepath("zig"),
					enable_build_on_save = true,
					build_on_save_step = "check",
					semantic_tokens = "full",
					enable_autofix = true,
					warn_style = true,
					highlight_global_var_declarations = true,
					inlay_hints_show_builtin = true,
					inlay_hints_exclude_single_argument = true,
				},
			},
		})

		vim.lsp.config("clangd", {
			capabilities = capabilities,
			cmd = {
				clangd_cmd,
				"--background-index",
				"--clang-tidy",
				"--header-insertion=iwyu",
				"--completion-style=detailed",
				"--function-arg-placeholders",
				"--fallback-style=llvm",
			},
			filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
			root_markers = { "compile_commands.json", "compile_flags.txt", ".clangd", ".git", "Makefile" },
			init_options = {
				usePlaceholders = true,
				completeUnimported = true,
				clangdFileStatus = true,
			},
		})

		-- Go 1.27 — system gopls (~/go/bin), default gofmt (not gofumpt)
		local gopls_cmd = vim.fn.exepath("gopls") ~= "" and vim.fn.exepath("gopls") or "gopls"
		vim.lsp.config("gopls", {
			capabilities = capabilities,
			cmd = { gopls_cmd },
			filetypes = { "go", "gomod", "gowork", "gotmpl" },
			root_markers = { "go.mod", "go.work", ".git" },
			settings = {
				gopls = {
					gofumpt = false,
					staticcheck = true,
					usePlaceholders = true,
					analyses = {
						unusedparams = true,
						shadow = true,
						fieldalignment = true,
						nilness = true,
						unusedwrite = true,
					},
					hints = {
						assignVariableTypes = true,
						compositeLiteralFields = true,
						compositeLiteralTypes = true,
						constantValues = true,
						functionTypeParameters = true,
						parameterNames = true,
						rangeVariableTypes = true,
					},
				},
			},
		})

		vim.lsp.enable({ "lua_ls", "vtsls", "tailwindcss", "zls", "clangd", "gopls" })

		-- Zig format-on-save via ZLS (zig fmt) – global, works outside playground too
		vim.api.nvim_create_autocmd("BufWritePre", {
			pattern = { "*.zig", "*.zon" },
			callback = function()
				-- only format if zls is attached
				for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
					if c.name == "zls" then
						vim.lsp.buf.format({ async = false })
						return
					end
				end
			end,
		})

		local cmp_select = { behavior = cmp.SelectBehavior.Select }
		local pair_map = {
			["{"] = "}",
			["("] = ")",
			["["] = "]",
		}
		local tag_filetypes = {
			html = true,
			xml = true,
			javascriptreact = true,
			typescriptreact = true,
		}
		local enter_key = vim.api.nvim_replace_termcodes("<CR>", true, false, true)

		local function split_pair_on_enter()
			local col = vim.fn.col(".")
			local line = vim.api.nvim_get_current_line()
			local prev_char = line:sub(col - 1, col - 1)
			local next_char = line:sub(col, col)

			if pair_map[prev_char] == next_char then
				return vim.api.nvim_replace_termcodes("<CR><Esc>ko", true, false, true)
			end

			return nil
		end

		local function split_tag_on_enter()
			if not tag_filetypes[vim.bo.filetype] then
				return false
			end

			local col = vim.fn.col(".")
			local line = vim.api.nvim_get_current_line()
			local prev_char = line:sub(col - 1, col - 1)
			local next_char = line:sub(col, col)
			local before_cursor = nil
			local after_cursor = nil

			if prev_char == ">" and next_char == "<" then
				before_cursor = line:sub(1, col - 1)
				after_cursor = line:sub(col)

				if not before_cursor:match("<[^/!][^>]*>$") or not after_cursor:match("^</[^>]+>") then
					return false
				end
			elseif col == #line + 1 then
				local open_tag, close_tag = line:match("^(%s*<[^/!][^>]*>)(</[^>]+>)%s*$")
				if not open_tag or not close_tag then
					return false
				end

				before_cursor = open_tag
				after_cursor = close_tag
			else
				return false
			end

			local row = vim.api.nvim_win_get_cursor(0)[1]
			local base_indent = before_cursor:match("^%s*") or ""
			local shift = vim.fn.shiftwidth()
			if shift == 0 then
				shift = vim.bo.tabstop
			end

			local indent_unit = vim.bo.expandtab and string.rep(" ", shift) or "\t"
			local inner_line = base_indent .. indent_unit
			local closing_line = base_indent .. after_cursor

			vim.api.nvim_buf_set_lines(0, row - 1, row, false, { before_cursor, inner_line, closing_line })
			vim.api.nvim_win_set_cursor(0, { row + 1, #inner_line })

			return true
		end

		cmp.setup({
			snippet = {
				expand = function(args)
					require("luasnip").lsp_expand(args.body)
				end,
			},
			mapping = cmp.mapping.preset.insert({
				["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
				["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
				["<C-y>"] = cmp.mapping.confirm({ select = true }),
				["<C-Space>"] = cmp.mapping.complete(),
				["<Tab>"] = cmp.mapping(function(fallback)
					if cmp.visible() then
						cmp.select_next_item()
					else
						fallback()
					end
				end, { "i", "s" }),
				["<S-Tab>"] = cmp.mapping(function(fallback)
					if cmp.visible() then
						cmp.select_prev_item()
					else
						fallback()
					end
				end, { "i", "s" }),
			}),
			sources = cmp.config.sources({
				{ name = "nvim_lsp" },
				{ name = "luasnip" },
				{ name = "path" },
			}, {
				{ name = "buffer" },
			}),
		})

		vim.keymap.set({ "i", "s" }, "<CR>", function()
			if split_tag_on_enter() then
				return
			end

			local keys = split_pair_on_enter() or enter_key
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

		vim.diagnostic.config({
			virtual_text = true,
			update_in_insert = true,
			float = {
				focusable = false,
				style = "minimal",
				border = "rounded",
				source = "always",
				header = "",
				prefix = "",
			},
		})
	end,
}
