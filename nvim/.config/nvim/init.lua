--[[
  Kickstart.nvim - Customized for IR/DevOps workflow
  
  Based on: https://github.com/nvim-lua/kickstart.nvim
  
  LSP: Python, Bash, Terraform, Lua, YAML, JSON
  File Explorer: netrw (built-in)
  
  Leader: Space
  
  Quick reference:
    <leader>e    - Open netrw file explorer
    <leader>E    - Toggle netrw sidebar
    <leader>pr   - Run Python file (or selected code)
    <leader>pi   - Python REPL
    <leader>pc   - Close Python terminal
    <leader>pf   - Format Python with black
    <leader>pt   - Run pytest
    <leader>sf   - Search files
    <leader>sg   - Search grep (live)
    <leader>sb   - Search buffers
    <leader>ff   - Find files
    <leader>w    - Save file
    <leader>q    - Quit
    <leader>x    - Save and quit
    gd           - Go to definition
    gr           - Go to references
    K            - Hover documentation
    <leader>ca   - Code action
    <leader>rn   - Rename symbol
--]]

-- Set leader key (must be before lazy)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- =============================================================================
-- Netrw Configuration (file explorer)
-- =============================================================================
vim.g.netrw_banner = 0 -- Hide banner
vim.g.netrw_liststyle = 3 -- Tree view
vim.g.netrw_browse_split = 4 -- Open files in previous window
vim.g.netrw_altv = 1 -- Split to right
vim.g.netrw_winsize = 25 -- 25% width

-- Netrw autocommands
vim.api.nvim_create_augroup("NetrwConfig", { clear = true })

-- Auto-open netrw sidebar on startup (if no files specified)
vim.api.nvim_create_autocmd("VimEnter", {
	group = "NetrwConfig",
	callback = function()
		if vim.fn.argc() == 0 then
			vim.cmd("Vexplore")
			-- Mark the netrw window
			vim.w.is_netrw_window = true
		end
	end,
})

-- Keep netrw at fixed size
vim.api.nvim_create_autocmd("BufEnter", {
	group = "NetrwConfig",
	pattern = "*",
	callback = function()
		if vim.bo.filetype == "netrw" then
			vim.cmd("vertical resize 25")
		end
	end,
})

-- Enhanced file/directory creation in netrw
vim.api.nvim_create_autocmd("FileType", {
	group = "NetrwConfig",
	pattern = "netrw",
	callback = function()
		-- Create file in right pane (%)
		vim.keymap.set("n", "%", function()
			local current_dir = vim.b.netrw_curdir or vim.fn.getcwd()
			local filename = vim.fn.input("New file: ")
			if filename == "" then
				return
			end
			local full_path = current_dir .. "/" .. filename

			-- Find non-netrw window
			local target_win = nil
			for _, win in ipairs(vim.api.nvim_list_wins()) do
				local is_netrw = pcall(function()
					return vim.api.nvim_win_get_var(win, "is_netrw_window")
				end)

				if not is_netrw then
					target_win = win
					break
				end
			end

			if target_win then
				vim.api.nvim_set_current_win(target_win)
				vim.cmd("edit " .. vim.fn.fnameescape(full_path))

				-- Return to netrw window and refresh
				local netrw_win = vim.fn.bufwinnr("NetrwTreeListing")
				if netrw_win ~= -1 then
					vim.cmd(netrw_win .. "wincmd w")
					vim.cmd("edit .")
				end
			else
				vim.cmd("vsplit " .. vim.fn.fnameescape(full_path))
			end
		end, { buffer = true, desc = "Create new file" })

		-- Create directory (d)
		vim.keymap.set("n", "d", function()
			local current_dir = vim.b.netrw_curdir or vim.fn.getcwd()
			local dirname = vim.fn.input("New directory: ")
			if dirname == "" then
				return
			end
			local full_path = current_dir .. "/" .. dirname
			vim.fn.mkdir(full_path, "p")
			vim.cmd("edit .")
		end, { buffer = true, desc = "Create new directory" })
	end,
})

-- =============================================================================
-- Basic Options
-- =============================================================================
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.showmode = false -- Mode shown in statusline
vim.opt.clipboard = "unnamedplus" -- System clipboard
vim.opt.breakindent = true
vim.opt.undofile = true -- Persistent undo
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.opt.inccommand = "split" -- Preview substitutions
vim.opt.cursorline = true
vim.opt.scrolloff = 10

-- Indentation
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true

-- =============================================================================
-- Keymaps - General
-- =============================================================================
local map = vim.keymap.set

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Save / Quit
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit" })
map("n", "<leader>x", "<cmd>x<CR>", { desc = "Save and quit" })
map("n", "<leader>Q", "<cmd>qa!<CR>", { desc = "Quit all (force)" })

-- Netrw file explorer
map("n", "<leader>e", "<cmd>Explore<CR>", { desc = "Open netrw explorer" })
map("n", "<leader>E", "<cmd>Lexplore<CR>", { desc = "Toggle netrw sidebar" })

-- Buffer navigation
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })
map("n", "<leader>bb", "<cmd>e #<CR>", { desc = "Switch to other buffer" })

-- Window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to below window" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to above window" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Window resize
map("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase window height" })
map("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease window height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease window width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase window width" })

-- Move lines up/down
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Keep cursor centered
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Better indenting (stay in visual mode)
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Better paste (don't yank replaced text)
map("v", "p", '"_dP', { desc = "Paste without yanking" })

-- Diagnostic keymaps
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic" })
map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Show diagnostic message" })
map("n", "<leader>dl", vim.diagnostic.setloclist, { desc = "Open diagnostic list" })

-- Terminal
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Quickfix
map("n", "<leader>co", "<cmd>copen<CR>", { desc = "Open quickfix" })
map("n", "<leader>cc", "<cmd>cclose<CR>", { desc = "Close quickfix" })
map("n", "[q", "<cmd>cprev<CR>", { desc = "Previous quickfix" })
map("n", "]q", "<cmd>cnext<CR>", { desc = "Next quickfix" })

-- =============================================================================
-- Python-specific keymaps
-- =============================================================================

-- Python: Run current file
map("n", "<leader>pr", function()
	vim.cmd("w")
	local current_buf = vim.api.nvim_get_current_buf()
	local python_window = nil
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_get_buf(win) == current_buf then
			python_window = win
			break
		end
	end
	if python_window then
		vim.api.nvim_set_current_win(python_window)
		vim.cmd("belowright vsplit | terminal python3 #" .. current_buf)
		vim.cmd("wincmd =")
		vim.cmd("startinsert")
	end
end, { desc = "[P]ython [R]un file" })

-- Python: Run selected code
map("v", "<leader>pr", function()
	vim.cmd("y")
	local python_window = nil
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "netrw" then
			python_window = win
			break
		end
	end
	if python_window then
		vim.api.nvim_set_current_win(python_window)
		local code = vim.fn.getreg('"'):gsub('"', '\\"'):gsub("\n", "\\n")
		vim.cmd('belowright vsplit | terminal python3 -c "' .. code .. '"')
		vim.cmd("wincmd =")
		vim.cmd("startinsert")
	end
end, { desc = "[P]ython [R]un selected code" })

-- Python: Interactive REPL
map("n", "<leader>pi", function()
	local python_window = nil
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "netrw" then
			python_window = win
			break
		end
	end
	if python_window then
		vim.api.nvim_set_current_win(python_window)
		vim.cmd("belowright vsplit | terminal python3")
		vim.cmd("wincmd =")
		vim.cmd("startinsert")
	end
end, { desc = "[P]ython [I]nteractive REPL" })

-- Python: Close terminal
map("n", "<leader>pc", function()
	vim.cmd("bdelete!")
	-- Restore netrw size
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "netrw" then
			vim.api.nvim_win_set_width(win, 25)
			break
		end
	end
end, { desc = "[P]ython [C]lose terminal" })

-- Python: Format with black
map("n", "<leader>pf", function()
	vim.cmd("w")
	vim.cmd("!black %")
	vim.cmd("e")
end, { desc = "[P]ython [F]ormat with black" })

-- Python: Run pytest
map("n", "<leader>pt", function()
	vim.cmd("w")
	vim.cmd("belowright vsplit | terminal python3 -m pytest % -v")
	vim.cmd("wincmd =")
	vim.cmd("startinsert")
end, { desc = "[P]ython run [T]ests" })

-- Python: Select virtual environment
map("n", "<leader>pv", function()
	local venv_dirs = { ".venv", "venv", "env", ".env" }
	local found_venv = nil

	for _, dir in ipairs(venv_dirs) do
		local venv_path = vim.fn.getcwd() .. "/" .. dir
		if vim.fn.isdirectory(venv_path) == 1 then
			found_venv = venv_path
			break
		end
	end

	if found_venv then
		vim.g.python3_host_prog = found_venv .. "/bin/python3"
		print("Using virtual environment: " .. found_venv)
	else
		print("No virtual environment found")
	end
end, { desc = "[P]ython select [V]env" })

-- =============================================================================
-- Lazy.nvim Bootstrap
-- =============================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- =============================================================================
-- Plugins
-- =============================================================================
require("lazy").setup({
	-- Detect tabstop and shiftwidth automatically
	"tpope/vim-sleuth",

	-- Git signs in gutter
	{
		"lewis6991/gitsigns.nvim",
		opts = {
			signs = {
				add = { text = "+" },
				change = { text = "~" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
			},
			on_attach = function(bufnr)
				local gs = package.loaded.gitsigns
				local function map(mode, l, r, opts)
					opts = opts or {}
					opts.buffer = bufnr
					vim.keymap.set(mode, l, r, opts)
				end
				-- Navigation
				map("n", "]c", function()
					if vim.wo.diff then
						return "]c"
					end
					vim.schedule(function()
						gs.next_hunk()
					end)
					return "<Ignore>"
				end, { expr = true, desc = "Next hunk" })
				map("n", "[c", function()
					if vim.wo.diff then
						return "[c"
					end
					vim.schedule(function()
						gs.prev_hunk()
					end)
					return "<Ignore>"
				end, { expr = true, desc = "Previous hunk" })
				-- Actions
				map("n", "<leader>hs", gs.stage_hunk, { desc = "Stage hunk" })
				map("n", "<leader>hr", gs.reset_hunk, { desc = "Reset hunk" })
				map("n", "<leader>hS", gs.stage_buffer, { desc = "Stage buffer" })
				map("n", "<leader>hu", gs.undo_stage_hunk, { desc = "Undo stage hunk" })
				map("n", "<leader>hR", gs.reset_buffer, { desc = "Reset buffer" })
				map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview hunk" })
				map("n", "<leader>hb", function()
					gs.blame_line({ full = true })
				end, { desc = "Blame line" })
				map("n", "<leader>hd", gs.diffthis, { desc = "Diff this" })
			end,
		},
	},

	-- Which-key: shows pending keybinds
	{
		"folke/which-key.nvim",
		event = "VimEnter",
		config = function()
			require("which-key").setup()
			require("which-key").add({
				{ "<leader>c", group = "[C]ode" },
				{ "<leader>d", group = "[D]iagnostics" },
				{ "<leader>h", group = "Git [H]unk" },
				{ "<leader>s", group = "[S]earch" },
				{ "<leader>f", group = "[F]ind" },
				{ "<leader>b", group = "[B]uffer" },
				{ "<leader>p", group = "[P]ython" },
				{ "<leader>t", group = "[T]oggle" },
			})
		end,
	},

	-- Telescope: fuzzy finder
	{
		"nvim-telescope/telescope.nvim",
		event = "VimEnter",
		branch = "0.1.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
				cond = function()
					return vim.fn.executable("make") == 1
				end,
			},
			{ "nvim-telescope/telescope-ui-select.nvim" },
			{ "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
		},
		config = function()
			require("telescope").setup({
				defaults = {
					mappings = {
						i = {
							["<C-j>"] = require("telescope.actions").move_selection_next,
							["<C-k>"] = require("telescope.actions").move_selection_previous,
						},
					},
				},
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown(),
					},
				},
			})
			pcall(require("telescope").load_extension, "fzf")
			pcall(require("telescope").load_extension, "ui-select")

			local builtin = require("telescope.builtin")
			map("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
			map("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
			map("n", "<leader>sf", builtin.find_files, { desc = "[S]earch [F]iles" })
			map("n", "<leader>ss", builtin.builtin, { desc = "[S]earch [S]elect Telescope" })
			map("n", "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
			map("n", "<leader>sg", builtin.live_grep, { desc = "[S]earch by [G]rep" })
			map("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
			map("n", "<leader>sr", builtin.resume, { desc = "[S]earch [R]esume" })
			map("n", "<leader>s.", builtin.oldfiles, { desc = "[S]earch Recent Files" })
			map("n", "<leader>sb", builtin.buffers, { desc = "[S]earch [B]uffers" })
			map("n", "<leader>ff", builtin.find_files, { desc = "[F]ind [F]iles" })
			map("n", "<leader>fg", builtin.git_files, { desc = "[F]ind [G]it files" })
			map("n", "<leader>/", function()
				builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
					winblend = 10,
					previewer = false,
				}))
			end, { desc = "[/] Fuzzily search in current buffer" })
		end,
	},

	-- LSP Configuration
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			{ "j-hui/fidget.nvim", opts = {} },
			{ "folke/neodev.nvim", opts = {} },
		},
		config = function()
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
				callback = function(event)
					local map = function(keys, func, desc)
						vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
					end

					-- Navigation
					map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
					map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
					map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
					map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
					map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")
					map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
					map(
						"<leader>ws",
						require("telescope.builtin").lsp_dynamic_workspace_symbols,
						"[W]orkspace [S]ymbols"
					)

					-- Actions
					map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
					map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
					map("K", vim.lsp.buf.hover, "Hover Documentation")

					-- Highlight references on cursor hold
					local client = vim.lsp.get_client_by_id(event.data.client_id)
					if client and client.server_capabilities.documentHighlightProvider then
						vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
							buffer = event.buf,
							callback = vim.lsp.buf.document_highlight,
						})
						vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
							buffer = event.buf,
							callback = vim.lsp.buf.clear_references,
						})
					end
				end,
			})

			-- LSP capabilities with nvim-cmp
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

			-- =======================================================================
			-- LSP Servers - IR/DevOps focused
			-- =======================================================================
			local servers = {
				-- Python
				pyright = {
					settings = {
						python = {
							analysis = {
								typeCheckingMode = "basic",
								autoSearchPaths = true,
								useLibraryCodeForTypes = true,
							},
						},
					},
				},
				-- Bash
				bashls = {},
				-- Terraform
				terraformls = {},
				-- YAML (for Ansible, K8s, etc.)
				yamlls = {
					settings = {
						yaml = {
							schemas = {
								["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
								["https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/ansible.json"] = "playbook*.yml",
							},
							validate = true,
							completion = true,
						},
					},
				},
				-- JSON
				jsonls = {},
				-- Lua (for nvim config)
				lua_ls = {
					settings = {
						Lua = {
							completion = { callSnippet = "Replace" },
							diagnostics = { disable = { "missing-fields" } },
						},
					},
				},
				-- Docker
				dockerls = {},
				-- Docker Compose
				docker_compose_language_service = {},
			}

			require("mason").setup()

			local ensure_installed = vim.tbl_keys(servers or {})
			vim.list_extend(ensure_installed, {
				"stylua", -- Lua formatter
				"black", -- Python formatter
				"isort", -- Python import sorter
				"shfmt", -- Shell formatter
				"shellcheck", -- Shell linter
			})
			require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

			require("mason-lspconfig").setup({
				handlers = {
					function(server_name)
						local server = servers[server_name] or {}
						server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
						require("lspconfig")[server_name].setup(server)
					end,
				},
			})
		end,
	},

	-- Autoformat
	{
		"stevearc/conform.nvim",
		lazy = false,
		keys = {
			{
				"<leader>cf",
				function()
					require("conform").format({ async = true, lsp_fallback = true })
				end,
				mode = "",
				desc = "[C]ode [F]ormat",
			},
		},
		opts = {
			notify_on_error = false,
			format_on_save = function(bufnr)
				local disable_filetypes = { c = true, cpp = true }
				return {
					timeout_ms = 500,
					lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
				}
			end,
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "isort", "black" },
				sh = { "shfmt" },
				bash = { "shfmt" },
				terraform = { "terraform_fmt" },
				tf = { "terraform_fmt" },
				json = { "jq" },
				yaml = { "yamlfmt" },
			},
		},
	},

	-- Autocompletion
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			{
				"L3MON4D3/LuaSnip",
				build = (function()
					if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
						return
					end
					return "make install_jsregexp"
				end)(),
				dependencies = {
					{
						"rafamadriz/friendly-snippets",
						config = function()
							require("luasnip.loaders.from_vscode").lazy_load()
						end,
					},
				},
			},
			"saadparwaiz1/cmp_luasnip",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-buffer",
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			luasnip.config.setup({})

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				completion = { completeopt = "menu,menuone,noinsert" },
				mapping = cmp.mapping.preset.insert({
					["<C-n>"] = cmp.mapping.select_next_item(),
					["<C-p>"] = cmp.mapping.select_prev_item(),
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-y>"] = cmp.mapping.confirm({ select = true }),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					["<C-Space>"] = cmp.mapping.complete({}),
					["<C-l>"] = cmp.mapping(function()
						if luasnip.expand_or_locally_jumpable() then
							luasnip.expand_or_jump()
						end
					end, { "i", "s" }),
					["<C-h>"] = cmp.mapping(function()
						if luasnip.locally_jumpable(-1) then
							luasnip.jump(-1)
						end
					end, { "i", "s" }),
				}),
				sources = {
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "buffer" },
					{ name = "path" },
				},
			})
		end,
	},

	-- Colorscheme
	{
		"folke/tokyonight.nvim",
		priority = 1000,
		init = function()
			vim.cmd.colorscheme("tokyonight-night")
			vim.cmd.hi("Comment gui=none")
		end,
	},

	-- Todo comments
	{
		"folke/todo-comments.nvim",
		event = "VimEnter",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = { signs = false },
	},

	-- Mini.nvim collection
	{
		"echasnovski/mini.nvim",
		config = function()
			-- Better Around/Inside textobjects
			-- Examples:
			--  - va)  - Visually select Around paren
			--  - yinq - Yank Inside Next quote
			--  - ci'  - Change Inside quote
			require("mini.ai").setup({ n_lines = 500 })

			-- Add/delete/replace surroundings
			-- - saiw) - Surround Add Inner Word with Paren
			-- - sd'   - Surround Delete quotes
			-- - sr)'  - Surround Replace ) with '
			require("mini.surround").setup()

			-- Statusline
			local statusline = require("mini.statusline")
			statusline.setup({ use_icons = vim.g.have_nerd_font })
			statusline.section_location = function()
				return "%2l:%-2v"
			end
		end,
	},

	-- Treesitter: syntax highlighting
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		opts = {
			ensure_installed = {
				"bash",
				"c",
				"diff",
				"html",
				"lua",
				"luadoc",
				"markdown",
				"vim",
				"vimdoc",
				"python",
				"terraform",
				"hcl",
				"yaml",
				"json",
				"dockerfile",
				"regex",
				"toml",
			},
			auto_install = true,
			highlight = {
				enable = true,
				additional_vim_regex_highlighting = { "ruby" },
			},
			indent = { enable = true, disable = { "ruby" } },
		},
	},

	-- Comment toggle
	{ "numToStr/Comment.nvim", opts = {} },

	-- Autopairs
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = true,
	},
}, {
	ui = {
		icons = vim.g.have_nerd_font and {} or {
			cmd = "⌘",
			config = "🛠",
			event = "📅",
			ft = "📂",
			init = "⚙",
			keys = "🗝",
			plugin = "🔌",
			runtime = "💻",
			require = "🌙",
			source = "📄",
			start = "🚀",
			task = "📌",
			lazy = "💤 ",
		},
	},
})

-- =============================================================================
-- Filetype-specific settings
-- =============================================================================
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "python" },
	callback = function()
		vim.opt_local.tabstop = 4
		vim.opt_local.shiftwidth = 4
		vim.opt_local.expandtab = true

		-- Auto-detect virtual environment
		local venv_dirs = { ".venv", "venv", "env" }
		for _, dir in ipairs(venv_dirs) do
			local venv_path = vim.fn.getcwd() .. "/" .. dir
			if vim.fn.isdirectory(venv_path) == 1 then
				vim.g.python3_host_prog = venv_path .. "/bin/python3"
				vim.env.VIRTUAL_ENV = venv_path
				vim.env.PATH = venv_path .. "/bin:" .. vim.env.PATH
				break
			end
		end
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "terraform", "hcl" },
	callback = function()
		vim.opt_local.tabstop = 2
		vim.opt_local.shiftwidth = 2
		vim.opt_local.expandtab = true
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "yaml", "json" },
	callback = function()
		vim.opt_local.tabstop = 2
		vim.opt_local.shiftwidth = 2
		vim.opt_local.expandtab = true
	end,
})

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
