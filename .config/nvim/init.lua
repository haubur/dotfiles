-- set leader
vim.keymap.set("n", "<Space>", "<Nop>", { silent = true })
vim.g.mapleader = " "

-- preferences
vim.opt.foldenable = false
vim.opt.wrap = false
vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.vb = true
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.tabstop = 4
vim.opt.expandtab = false

-- plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- plugin manager setup
require("lazy").setup({
	{
		"rockyzhang24/arctic.nvim",
		dependencies = { "rktjmp/lush.nvim" },
		lazy = false, -- load at start
		priority = 1000, -- load first
		config = function()
			vim.cmd([[colorscheme arctic]])
		end
	},
	{
		'notjedi/nvim-rooter.lua',
		config = function()
			require('nvim-rooter').setup()
		end
	},
	{
		"nvimtools/none-ls.nvim",
		lazy = true,
	},
	{
		"nvim-treesitter/nvim-treesitter", 
		branch = 'master', 
		lazy = false, 
		build = ":TSUpdate",
		config = function()
        		require("nvim-treesitter.configs").setup({
            		-- A list of parser names, or "all"
            		ensure_installed = {
                		"python", "rust", "bash",
            		},

            		-- Install parsers synchronously (only applied to `ensure_installed`)
            		sync_install = false,

            		-- Automatically install missing parsers when entering buffer
            		-- Recommendation: set to false if you don"t have `tree-sitter` CLI installed locally
            		auto_install = true,

            		indent = {
                		enable = true
            		},

            		highlight = {
                		-- `false` will disable the whole extension
                		enable = true,
            		},
        		})
		end
	},
    {
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim"
		},
		config = function()
			require('telescope').setup({})
			local builtin = require('telescope.builtin')
			vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
			vim.keymap.set('n', '<C-p>', builtin.git_files, {})
			vim.keymap.set('n', '<leader>pws', function()
				local word = vim.fn.expand("<cword>")
					builtin.grep_string({ search = word })
				end)
			vim.keymap.set('n', '<leader>pWs', function()
				local word = vim.fn.expand("<cWORD>")
					builtin.grep_string({ search = word })
				end)
			vim.keymap.set('n', '<leader>ps', function()
				builtin.grep_string({ search = vim.fn.input("Grep > ") })
			end)
			vim.keymap.set('n', '<leader>vh', builtin.help_tags, {})
		end
	},
})

local null_ls = require("null-ls")

local formatting = null_ls.builtins.formatting

local ruff_formatter = {
  method = null_ls.methods.FORMATTING,
  filetypes = { "python" },
  generator = null_ls.generator({
    command = "ruff",
    args = { "format", "--stdin-filename", "$FILENAME", "-" },
    to_stdin = true,
  }),
}

null_ls.setup({
  sources = {
    ruff_formatter,
    -- other sources like pyright or black can go here
  },
  on_attach = on_attach,
})


local function on_attach(client, bufnr)
  print("LSP attached:", client.name)
  local opts = { noremap = true, silent = true, buffer = bufnr }

  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
  vim.keymap.set('n', 'gl', vim.diagnostic.open_float, opts)
  vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
  vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
  vim.keymap.set('n', '<leader>f', function()
    vim.lsp.buf.format({ async = true })
  end, opts)

  vim.api.nvim_create_autocmd("BufWritePre", {
    buffer = bufnr,
    callback = function()
	vim.lsp.buf.format({
      async = false,
      filter = function(client)
        return client.name == "null-ls"  -- Use ruff via null-ls only
      end,
    })
    end,
  })
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "rust",
  callback = function()
    vim.lsp.start({
      name = "rust-analyzer",
      cmd = { "rust-analyzer" },
      root_dir = function(fname)
        return vim.fs.dirname(
          vim.fs.find({ "Cargo.toml" }, { path = fname, upward = true })[1]
          or fname
        )
      end,
      on_attach = on_attach,
    })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    vim.lsp.start({
      name = "pyright",
      cmd = { "pyright-langserver", "--stdio" },
      root_dir = function(fname)
        return vim.fs.dirname(
          vim.fs.find({ "pyproject.toml", "setup.py", "requirements.txt", ".git" }, {
            path = fname,
            upward = true,
          })[1] or fname
        )
      end,
      on_attach = on_attach,
    })
  end,
})

-- Global diagnostic configuration
vim.diagnostic.config({
  virtual_text = true,      -- Inline diagnostics
  signs = false,             -- Show signs in gutter
  underline = true,         -- Underline problems
  update_in_insert = true, -- Don't update diagnostics in insert mode
  severity_sort = true,     -- Sort diagnostics by severity
})

-- Optional: Show diagnostics on hover
vim.o.updatetime = 250
vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    vim.diagnostic.open_float(nil, { focus = false })
  end,
})

