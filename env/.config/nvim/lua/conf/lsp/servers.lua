local toolchain = require("conf.util.toolchain")

local M = {}

-- server configs
function M.setup(capabilities)
	local clangd_cmd = toolchain.clangd()
	vim.lsp.config("lua_ls", {
		capabilities = capabilities,
		settings = {
			Lua = {
				runtime = { version = "LuaJIT" },
				diagnostics = { globals = { "vim" } },
				workspace = { library = vim.api.nvim_get_runtime_file("", true), checkThirdParty = false },
				format = { enable = true, defaultConfig = { indent_style = "space", indent_size = "2" } },
			},
		},
	})
	vim.lsp.config("vtsls", { capabilities = capabilities })
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
		cmd = { clangd_cmd, "--background-index", "--clang-tidy", "--header-insertion=iwyu", "--completion-style=detailed", "--function-arg-placeholders", "--fallback-style=llvm" },
		filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
		root_markers = { "compile_commands.json", "compile_flags.txt", ".clangd", ".git", "Makefile" },
		init_options = { usePlaceholders = true, completeUnimported = true, clangdFileStatus = true },
	})
	vim.lsp.config("gopls", {
		capabilities = capabilities,
		cmd = { toolchain.gopls() },
		filetypes = { "go", "gomod", "gowork", "gotmpl" },
		root_markers = { "go.mod", "go.work", ".git" },
		settings = {
			gopls = {
				gofumpt = false,
				staticcheck = true,
				usePlaceholders = true,
				analyses = { unusedparams = true, shadow = true, fieldalignment = true, nilness = true, unusedwrite = true },
				hints = { assignVariableTypes = true, compositeLiteralFields = true, compositeLiteralTypes = true, constantValues = true, functionTypeParameters = true, parameterNames = true, rangeVariableTypes = true },
			},
		},
	})
	vim.lsp.enable({ "lua_ls", "vtsls", "tailwindcss", "zls", "clangd", "gopls" })
end

return M
