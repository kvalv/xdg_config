-- Install packer
local install_path = vim.fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"

if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
    vim.fn.execute("!git clone https://github.com/wbthomason/packer.nvim " .. install_path)
end

vim.cmd([[
  augroup Packer
    autocmd!
    autocmd BufWritePost init.lua PackerCompile
  augroup end
]])

local use = require("packer").use
require("packer").startup(function()
    use("itchyny/vim-qfedit") -- quickfix
    use("jremmen/vim-ripgrep")
    use("wbthomason/packer.nvim") -- Package manager
    use("tpope/vim-fugitive") -- Git commands in nvim
    use("tpope/vim-vinegar") -- netrw
    use("tpope/vim-rhubarb") -- Fugitive-companion to interact with github
    use("tpope/vim-commentary") -- "gc" to comment visual regions/lines
    use("tpope/vim-unimpaired") -- for [<space> and friends
    use("tpope/vim-surround")
    use("lambdalisue/suda.vim")
    use("ThePrimeagen/git-worktree.nvim")
    use("ludovicchabant/vim-gutentags") -- Automatic tags management
    use("nvim-treesitter/nvim-treesitter-context") -- sticky context
    -- UI to select things (files, grep results, open buffers...)
    use({ "nvim-telescope/telescope.nvim", requires = { "nvim-lua/plenary.nvim" } })
    use("joshdick/onedark.vim") -- Theme inspired by Atom
    use({ "nvim-lualine/lualine.nvim", requires = { "kyazdani42/nvim-web-devicons", opt = true } }) -- Fancier statusline
    -- Add indentation guides even on blank lines
    use("lukas-reineke/indent-blankline.nvim")
    -- Add git related info in the signs columns and popups
    use({ "lewis6991/gitsigns.nvim", requires = { "nvim-lua/plenary.nvim" } })
    -- Highlight, edit, and navigate code using a fast incremental parsing library
    use("nvim-treesitter/nvim-treesitter")
    -- Additional textobjects for treesitter
    use("nvim-treesitter/nvim-treesitter-textobjects")
    use("nvim-treesitter/playground")
    use("neovim/nvim-lspconfig") -- Collection of configurations for built-in LSP client
    use("jose-elias-alvarez/null-ls.nvim") -- formatting
    use("williamboman/nvim-lsp-installer")
    use("hrsh7th/nvim-cmp") -- Autocompletion plugin
    use("hrsh7th/cmp-nvim-lsp")
    use("kosayoda/nvim-lightbulb")
    use("hrsh7th/cmp-buffer")
    use("hrsh7th/cmp-path")
    use("hrsh7th/cmp-cmdline")
    use("saadparwaiz1/cmp_luasnip")
    use("L3MON4D3/LuaSnip") -- Snippets plugin
    use("ThePrimeagen/harpoon")
    use("ojroques/vim-oscyank")
    use("vim-test/vim-test")
    use("nvim-orgmode/orgmode")
    use("lukas-reineke/headlines.nvim")
    use("JoosepAlviste/nvim-ts-context-commentstring")
    use({
        "akinsho/org-bullets.nvim",
        config = function()
            require("org-bullets").setup({
                symbols = { "◉", "○", "✸", "✿" },
            })
        end,
    })
    use("nanotee/sqls.nvim")
    use("phaazon/mind.nvim")
    use("rafi/awesome-vim-colorschemes")
    use("github/copilot.vim")
end)

--Set colorscheme (order is important here)
vim.o.termguicolors = true
vim.g.onedark_terminal_italics = 2
-- vim.cmd([[colorscheme onedark]])
-- vim.cmd([[colorscheme carbonized-light]])
-- vim.cmd([[colorscheme gruvbox]])
vim.cmd([[colorscheme nord]])
-- vim.cmd "colorscheme schekaur"

local function gitstatus()
    local gs = vim.b.gitsigns_status_dict
    local added = gs.added or 0
    local changed = gs.changed or 0
    local removed = gs.removed or 0
    return string.format("%s/%s/%s", added, changed, removed)
end

-- vim.b.gitsigns_status_dict

require("lualine").setup({
    options = {
        theme = "papercolor_light",
        globalstatus = true,
    },
    sections = {
        lualine_a = { "mode", { "filename", path = 1 } },
        lualine_b = {},
        lualine_c = {
            { "diagnostics", always_visible = true, symbols = { error = "E", warn = "W", info = "I", hint = "H" } },
            -- { "diff" },
        },
        lualine_x = {},
        lualine_y = { gitstatus },
        lualine_z = {},
    },
})

--Remap space as leader key
vim.api.nvim_set_keymap("", "<Space>", "<Nop>", { noremap = true, silent = true })
vim.g.mapleader = " "
vim.g.maplocalleader = " "

--Remap for dealing with word wrap
vim.api.nvim_set_keymap("n", "k", "v:count == 0 ? 'gk' : 'k'", { noremap = true, expr = true, silent = true })
vim.api.nvim_set_keymap("n", "j", "v:count == 0 ? 'gj' : 'j'", { noremap = true, expr = true, silent = true })

-- Highlight on yank
vim.cmd([[
  augroup YankHighlight
    autocmd!
    autocmd TextYankPost * silent! lua vim.highlight.on_yank()
  augroup end
]])

--Map blankline
vim.g.indent_blankline_char = "┊"
vim.g.indent_blankline_filetype_exclude = { "help", "packer" }
vim.g.indent_blankline_buftype_exclude = { "terminal", "nofile" }
vim.g.indent_blankline_show_trailing_blankline_indent = false

-- Gitsigns
require("gitsigns").setup({
    signs = {
        add = { hl = "GitGutterAdd", text = "+" },
        change = { hl = "GitGutterChange", text = "~" },
        delete = { hl = "GitGutterDelete", text = "_" },
        topdelete = { hl = "GitGutterDelete", text = "‾" },
        changedelete = { hl = "GitGutterChange", text = "~" },
    },
    on_attach = function(bufnr)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map('n', ']w', function()
            if vim.wo.diff then return ']w' end
            vim.schedule(function() gs.next_hunk() end)
            return '<Ignore>'
        end, { expr = true })

        map('n', '[w', function()
            if vim.wo.diff then return '[w' end
            vim.schedule(function() gs.prev_hunk() end)
            return '<Ignore>'
        end, { expr = true })

        -- Actions
        map({ 'n', 'v' }, '<leader>hs', ':Gitsigns stage_hunk<CR>')
        map({ 'n', 'v' }, '<leader>hr', ':Gitsigns reset_hunk<CR>')
        map('n', '<leader>hu', gs.undo_stage_hunk)
        map('n', '<leader>hR', gs.reset_buffer)
        map('n', '<leader>hd', gs.preview_hunk)
        map('n', '<leader>gb', function() gs.blame_line { full = true } end)
        map('n', '[g', gs.prev_hunk)
        map('n', ']g', gs.next_hunk)
        map("n", "<leader>hD", gs.setqflist) -- make a qflist of this buffer

        -- Text object
        map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>')
    end
})


require("telescope").setup({
    extensions = {
    },
    defaults = {
        mappings = {
            i = {
                ["<C-u>"] = false,
                ["<C-d>"] = false,
            },
        },
    },
})
-- vim.keymap.set("
--Add leader shortcuts

vim.keymap.set("n", "<leader>f", function()
    require("telescope.builtin").find_files({ previewer = false })
end, {
    noremap = true,
    silent = true,
})
vim.keymap.set("n", "<leader>sb", function()
    require("telescope.builtin").current_buffer_fuzzy_find()
end, {
    noremap = true,
    silent = true,
})
vim.keymap.set("n", "<leader>sh", function()
    require("telescope.builtin").help_tags()
end, {
    noremap = true,
    silent = true,
})
vim.keymap.set("n", "<leader>t", function()
    -- vim.fn.tagfiles() gives a bunch of stupid names that start with term
    -- if the current buffer is the terminal. Let's filter those out before
    -- passing it into the picker
    local candidates = vim.fn.tagfiles()
    table.insert(candidates, 1, string.format("%s/tags", vim.fn.getcwd()))

    local tagfiles = vim.tbl_filter(function(fname)
        return not vim.startswith(fname, "term")
    end, candidates)

    if #tagfiles > 1 then
        print(
            "warning: found more than one tagfile. Using only first one. This might give unexpected results (lack of tags)"
        )
    elseif #tagfiles == 0 then
        print("No tag files found")
        return
    end
    local ctags_file = tagfiles[1]

    require("telescope.builtin").tags({ ctags_file = ctags_file, only_sort_tags = true })
end, {
    noremap = true,
    silent = true,
})

vim.keymap.set("n", "<leader>sp", function()
    local opts = {}
    if vim.b.netrw_curdir then
        opts.cwd = vim.b.netrw_curdir
    end
    require("telescope.builtin").live_grep(opts)
end, {
    noremap = true,
    silent = true,
})

vim.keymap.set("n", "<leader>so", function()
    require("telescope.builtin").tags({ only_current_buffer = true })
end, {
    noremap = true,
    silent = true,
})
vim.keymap.set("n", "<leader>?", function()
    require("telescope.builtin").oldfiles()
end, {
    noremap = true,
    silent = true,
})
vim.keymap.set("n", "<leader>sc", function()
    require("telescope_extensions").telescope_config_files()
end, {
    noremap = true,
    silent = true,
})
vim.keymap.set("n", "<leader>sl", function()
    require("telescope_extensions").packer_lua_files()
end, {
    noremap = true,
    silent = true,
})

-- Treesitter configuration
-- Parsers must be installed manually via :TSInstall
require("nvim-treesitter.configs").setup({
    highlight = {
        enable = true, -- false will disable the whole extension
    },
    incremental_selection = {
        enable = true,
        keymaps = {
            init_selection = "gnn",
            node_incremental = "grn",
            scope_incremental = "grc",
            node_decremental = "grm",
        },
    },
    indent = {
        enable = true,
    },
    textobjects = {
        select = {
            enable = true,
            lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
            keymaps = {
                -- You can use the capture groups defined in textobjects.scm
                ["af"] = "@function.outer",
                ["if"] = "@function.inner",
                ["ac"] = "@class.outer",
                ["ic"] = "@class.inner",
            },
        },
        move = {
            enable = true,
            set_jumps = true, -- whether to set jumps in the jumplist
            goto_next_start = {
                ["]m"] = "@function.outer",
                ["]]"] = "@class.outer",
            },
            goto_next_end = {
                ["]M"] = "@function.outer",
                ["]["] = "@class.outer",
            },
            goto_previous_start = {
                ["[m"] = "@function.outer",
                ["[["] = "@class.outer",
            },
            goto_previous_end = {
                ["[M"] = "@function.outer",
                ["[]"] = "@class.outer",
            },
        },
    },
    context_commentstring = {
        enable = true,
    },
})
require("nvim-treesitter.configs").setup({
    query_linter = {
        enable = true,
        use_virtual_text = true,
        lint_events = { "BufWrite", "CursorHold" },
    },
})

local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
parser_config.sql = {
    install_info = {
        url = "/tmp/tree-sitter-sql", -- local path or git repo
        files = { "src/parser.c" },
        -- optional entries:
        branch = "main", -- default branch in case of git repo if different from master
        generate_requires_npm = false, -- if stand-alone parser without npm dependencies
        requires_generate_from_grammar = false, -- if folder contains pre-generated src/parser.c
    },
    -- filetype = "sql", -- if filetype does not match the parser name
}

-- LSP settings
local lspconfig = require("lspconfig")
local on_attach = function(_, bufnr)
    local opts = { noremap = true, silent = true }
    vim.api.nvim_buf_set_keymap(bufnr, "n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>D", "<cmd>lua vim.lsp.buf.type_definition()<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>e", "<cmd>lua vim.diagnostic.open_float()<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "]d", "<cmd>lua vim.diagnostic.goto_next()<CR>", opts)
    vim.api.nvim_buf_set_keymap(
        bufnr,
        "n",
        "<leader>so",
        [[<cmd>lua require('telescope.builtin').lsp_document_symbols()<CR>]],
        opts
    )
    vim.api.nvim_buf_set_keymap(bufnr, "n", "sw", [[<cmd>lua vim.lsp.buf.format({async = true})<CR>]], opts)
end

-- nvim-cmp supports additional completion capabilities
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

-- Enable the following language servers
local servers = { "clangd", "rust_analyzer", "pyright", "tsserver", "gopls", "bashls", "yamlls", "jsonls" }
for _, lsp in ipairs(servers) do
    lspconfig[lsp].setup({
        on_attach = on_attach,
        capabilities = capabilities,
    })
end

-- Example custom server
-- Make runtime files discoverable to the server
local runtime_path = vim.split(package.path, ";")
table.insert(runtime_path, "lua/?.lua")
table.insert(runtime_path, "lua/?/init.lua")
table.insert(runtime_path, "/tmp/nvim/?.lua")
table.insert(runtime_path, "/tmp/nvim/lua/?.lua")

lspconfig.pyright.setup({
    -- cmd = { vim.env.HOME .. "/.local/share/nvim/lsp_servers/python/node_modules/.bin/pyright-langserver", "--stdio" },
    on_attach = on_attach,
    capabilities = capabilities,
})

lspconfig.lua_ls.setup({
    on_attach = on_attach,
    capabilities = capabilities,
    settings = {
        Lua = {
            runtime = {
                -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
                version = "LuaJIT",
                -- Setup your lua path
                path = runtime_path,
            },
            diagnostics = {
                -- Get the language server to recognize the `vim` global
                globals = { "vim" },
            },
            workspace = {
                -- Make the server aware of Neovim runtime files
                library = vim.api.nvim_get_runtime_file("", true),
                checkThirdParty = false,
            },
            -- Do not send telemetry data containing a randomized but unique identifier
            telemetry = {
                enable = false,
            },
        },
    },
})

lspconfig.rust_analyzer.setup({
    -- cmd = { vim.env.HOME .. "/.local/share/nvim/lsp_servers/rust/rust-analyzer" },
    on_attach = on_attach,
    capabilities = capabilities,
    settings = {
        ["rust-analyzer"] = {
            -- https://users.rust-lang.org/t/how-to-disable-rust-analyzer-proc-macro-warnings-in-neovim/53150/6
            diagnostics = {
                enable = true,
                disabled = { "unresolved-proc-macro" },
                enableExperimental = true,
            },
            assist = {
                importGranularity = "module",
                importPrefix = "by_self",
            },
            cargo = {
                loadOutDirsFromCheck = true,
            },
            procMacro = {
                enable = true,
            },
        },
    },
})

-- lspconfig.tailwindcss.setup({})
lspconfig.svelte.setup({
    on_attach = on_attach,
    capabilities = capabilities,
    filetypes = { "svelte" },
    settings = {
        plugin = {
            html = { completions = { enable = true, emmet = false } },
            svelte = { completions = { enable = true, emmet = false } },
            css = { completions = { enable = true, emmet = true } },
        },
    },
})

-- luasnip setup
local luasnip = require("luasnip")

-- nvim-cmp setup
local cmp = require("cmp")
cmp.setup({
    snippet = {
        expand = function(args)
            luasnip.lsp_expand(args.body)
        end,
    },
    mapping = {
        ["<C-p>"] = cmp.mapping.select_prev_item(),
        ["<C-n>"] = cmp.mapping.select_next_item(),
        ["<C-d>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-e>"] = cmp.mapping.close(),
        ["<CR>"] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Insert,
            select = true,
        }),
    },
    sources = {
        { name = "luasnip", priority = 700 },
        { name = "nvim_lsp", priority = 100 },
        -- { name = "buffer", priority = 10 },
    },
})
vim.keymap.set({ "i", "s" }, "<C-l>", function()
    if luasnip.choice_active() then
        luasnip.change_choice(1)
    end
end)
vim.keymap.set({ "i", "s" }, "<C-h>", function()
    if luasnip.choice_active() then
        luasnip.change_choice(-1)
    end
end)

local formatting_sources = {}
-- if vim.fn.executable("stylua") == 1 then
--     table.insert(formatting_sources, require("null-ls").builtins.formatting.stylua)
-- end
if vim.fn.executable("eslint") == 1 then
    table.insert(formatting_sources, require("null-ls").builtins.formatting.eslint_d)
end
require("null-ls").setup({
    debug = true,
    sources = {
        require("null-ls").builtins.formatting.eslint,
    },
})

vim.keymap.set("n", "<leader>R", function()
    -- special case; do we reload the vimrc lua file?
    if vim.env.MYVIMRC == vim.fn.expand("%") then
        print(string.format("reloading vimrc file '%s'.", vim.fn.expand("%:t")))
        vim.cmd("source " .. vim.env.MYVIMRC)
        return
    end

    local base = vim.fn.fnamemodify(vim.fn.expand("$MYVIMRC"), ":h") .. "/lua"
    local Path = require("plenary.path")
    local p = Path:new(vim.fn.expand("%:p")):make_relative(base)
    local modname, _ = string.gsub(vim.fn.fnamemodify(p, ":r"), "/", ".")

    if vim.endswith(modname, "init") then
        -- foo.bar.baz.init -> foo.bar.baz
        modname, _ = string.gsub(modname, "%.init$", "")
    end

    print(string.format("reloading module '%s'", modname))
    require("utils").reload(modname)
end, {
    nowait = true,
})
P = vim.pretty_print
require("maps")
require("settings")
require("plugins")
require("org_utils")
require("snippets")
require("telescope_extensions")
require("textobjects")
require("work")

U = require("utils")
require("units").init()

vim.opt.grepprg = "rg --vimgrep --no-heading --smart-case"
vim.keymap.set("n", "<leader>g", ":silent grep<Space>")

vim.keymap.set("n", "<leader>F", function()
    local opts = {}
    local base = string.gsub(vim.fn.system("git rev-parse --show-toplevel"), "\n", "")
    local toml = base .. "/.files.toml"
    if vim.v.shell_error ~= 0 then
        vim.notify("not a git repo", vim.log.levels.ERROR)
        return
    end
    -- if vim.b.netrw_curdir then
    --     opts.cwd = vim.b.netrw_curdir
    if vim.fn.getfperm(toml) ~= "" then
        opts.search_dirs = vim.tbl_filter(function(line)
            return (not vim.startswith(line, '#')) and (not vim.startswith(line, "[")) and line ~= ""
        end, vim.fn.readfile(toml))
    end
    require("telescope.builtin").find_files(opts)
end)

vim.keymap.set("n", "<leader>r", function()
    require("telescope.builtin").tags { ctags_file = vim.env.service .. '/tags' }
end, { nowait = true })




vim.keymap.set("n", "gW", function()
    require("telescope.builtin").find_files { cwd = vim.env.service }
end)


vim.keymap.set("n", "<Up>", "<C-u>", { nowait = true })
vim.keymap.set("n", "<Down>", "<C-d>", { nowait = true })
vim.keymap.set("n", "<Right>", "<C-d>", { nowait = true })

vim.keymap.set("n", "<leader>w", function()
    vim.cmd.write()
end, { nowait = true })

require "mind".setup()
