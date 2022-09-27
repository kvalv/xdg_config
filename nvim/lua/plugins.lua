local map = vim.api.nvim_set_keymap
local utils = require("utils")
local options = { noremap = true }

-- harpoon
require("harpoon").setup({
	menu = {
		width = 85,
	},
    enter_on_sendcmd = true,
})

vim.api.nvim_set_keymap("n", "<leader>hm", ':lua require("harpoon.mark").add_file()<CR>', { noremap = true })
vim.api.nvim_set_keymap("n", "<leader>ha", ':lua require("harpoon.ui").toggle_quick_menu()<CR>', { noremap = true })
vim.api.nvim_set_keymap("n", "<leader>hA", ':lua require("harpoon.cmd-ui").toggle_quick_menu()<CR>', { noremap = true })
vim.api.nvim_set_keymap("n", "<leader>1", ':lua require("harpoon.term").gotoTerminal(1)<CR>', { noremap = true })
vim.api.nvim_set_keymap("n", "<leader>2", ':lua require("harpoon.term").gotoTerminal(2)<CR>', { noremap = true })
vim.api.nvim_set_keymap("n", "<leader>3", ':lua require("harpoon.term").gotoTerminal(3)<CR>', { noremap = true })
vim.api.nvim_set_keymap("n", "<leader>4", ':lua require("harpoon.term").gotoTerminal(4)<CR>', { noremap = true })
vim.api.nvim_set_keymap("n", "<leader>5", ':lua require("harpoon.term").gotoTerminal(5)<CR>', { noremap = true })
vim.api.nvim_set_keymap("n", "<M-1>", ':lua require("harpoon.ui").nav_file(1)  <CR>', { noremap = true })
vim.api.nvim_set_keymap("n", "<M-2>", ':lua require("harpoon.ui").nav_file(2)  <CR>', { noremap = true })
vim.api.nvim_set_keymap("n", "<M-3>", ':lua require("harpoon.ui").nav_file(3)  <CR>', { noremap = true })
vim.api.nvim_set_keymap("n", "<M-4>", ':lua require("harpoon.ui").nav_file(4)  <CR>', { noremap = true })
vim.api.nvim_set_keymap("n", "<M-5>", ':lua require("harpoon.ui").nav_file(5)  <CR>', { noremap = true })
vim.api.nvim_set_keymap("n", "g1", ':lua require("harpoon.term").sendCommand(1, 1)  <CR>', { noremap = true })
vim.api.nvim_set_keymap("n", "g2", ':lua require("harpoon.term").sendCommand(1, 2)  <CR>', { noremap = true })
vim.api.nvim_set_keymap("n", "<F3>", ':lua require("harpoon.term").sendCommand(1, 3)  <CR>', { noremap = true })
vim.api.nvim_set_keymap("n", "<F4>", ':lua require("harpoon.term").sendCommand(1, 4)  <CR>', { noremap = true })
vim.api.nvim_set_keymap("n", "<F5>", ':lua require("harpoon.term").sendCommand(1, 5)  <CR>', { noremap = true })
HARPOON_TERM_ID = HARPOON_TERM_ID or 1  -- if already loaded, we'll keep it, otherwise set to 1 as default

vim.keymap.set("n", "<M-j>", function()
    local line = vim.api.nvim_get_current_line()
    print(line)
    -- local line = "hello world\n"
    require("harpoon.term").sendCommand(HARPOON_TERM_ID, string.format("%s\n", line))
end, { noremap = true })

vim.keymap.set("n", "<M-k>", function()
    utils.vim_motion("yip")
    local lines = vim.split(vim.fn.getreg('"'), "\n")
    for _, line in ipairs(lines) do
        require("harpoon.term").sendCommand(HARPOON_TERM_ID, string.format("%s\n", line))
    end
end, { noremap = true })


-- vim.api.nvim_set_keymap(
-- 	"n",
-- 	"<M-j>",
-- 	':lua require("harpoon.term").sendCommand(1, vim.api.nvim_get_current_line()) <CR>',
-- 	{ noremap = true }
-- )

vim.api.nvim_set_keymap("n", "<M-f>", ":Telescope git_files<CR>", { noremap = true })

-- test-vim
map("n", "t<C-n>", ":TestNearest<CR>", options)
map("n", "t<C-f>", ":TestFile<CR>", options)
map("n", "t<C-s>", ":TestSuite<CR>", options)
map("n", "t<C-l>", ":TestLast<CR>", options)
map("n", "t<C-g>", ":TestVisit<CR>", options)
vim.keymap.set("n", "<leader>,", "<Plug>PlenaryTestFile", options)

-- oscyank
vim.keymap.set("v", "<leader>y", ":OSCYank<CR>", { noremap = true })

-- orgmode
require("orgmode").setup_ts_grammar()
require("nvim-treesitter.configs").setup({
	-- If TS highlights are not enabled at all, or disabled via `disable` prop, highlighting will fallback to default Vim syntax highlighting
	highlight = {
		enable = true,
		disable = { "org" }, -- Remove this to use TS highlighter for some of the highlights (Experimental)
		additional_vim_regex_highlighting = { "org" }, -- Required since TS highlighter doesn't support all syntax features (conceal)
	},
	ensure_installed = { "org" }, -- Or run :TSUpdate org
})

OrgInst = require("orgmode").setup({
	org_agenda_files = { "~/notes.org" },
	org_default_notes_file = "~/notes.org",
	org_todo_keywords = { "TODO", "PROGRESS", "REVIEW", "|", "DONE" },
})

-- gutentags
vim.g.gutentags_ctags_auto_set_tags = 0
vim.g.gutentags_file_list_command = "git ls-files"

-- test-vim vim-test
vim.cmd("let test#python#pytest#file_pattern='\\v([^/]+)\\.py$'")
vim.cmd("let test#python#pytest#executable = 'RVS_CONFIG=TEST pytest'")
vim.cmd("let test#strategy = 'harpoon'")
vim.cmd("let test#python#pytest#options = '-s --disable-warnings -vv '")

-- lightbulb
vim.cmd([[autocmd CursorHold,CursorHoldI * lua require'nvim-lightbulb'.update_lightbulb()]])

-- null-ls -- for benthos
local null_ls = require("null-ls")
local helpers = require("null-ls.helpers")

local benthoslint = {
    name = "hello world",
    method = null_ls.methods.DIAGNOSTICS,
    filetypes = { "yaml" },
    -- null_ls.generator creates an async source
    -- that spawns the command with the given arguments and options
    generator = null_ls.generator({
        command = "benthos",
        args = { "-c", "$FILENAME", "lint" },
        to_stdin = true,
        from_stderr = true,
        timeout = 5000,
        to_temp_file = true,
        -- from_temp_file = true,
        -- choose an output format (raw, json, or line)
        format = "line",
        check_exit_code = function(code, stderr)
            local success = code <= 1

            if not success then
              -- can be noisy for things that run often (e.g. diagnostics), but can
              -- be useful for things that run on demand (e.g. formatting)
              print(stderr)
            end

            return success
        end,
        -- use helpers to parse the output from string matchers,
        -- or parse it manually with a function
        on_output = helpers.diagnostics.from_patterns({
            {
                pattern = ".*:? line (%d+): (.*)",
                groups = { "row", "message" },
            },
        }),
    }),
}

wt = require("git-worktree")
wt.setup{
    change_directory_command = "cd",
    update_on_change = true,
    update_on_change_command = "e .",
    clearjumps_on_change = true,
    autopush = false,
}
require("telescope").load_extension("git_worktree")

vim.keymap.set("n", "gws", function() require("telescope").extensions.git_worktree.git_worktrees() end, { noremap = true })
vim.keymap.set("n", "gwc", function() require("telescope").extensions.git_worktree.create_git_worktree() end, { noremap = true })


local id = vim.api.nvim_create_augroup("tagpattern-group", { clear = true })
vim.api.nvim_create_autocmd({"BufWritePost"}, {pattern=".tagpatterns", group=id, callback=function() 
    local Job = require'plenary.job'
    local lines = vim.fn.readfile(".tagpatterns")
    Job:new({
        command = "ctags",
        -- args = require("utils").concat({"-R"}, lines),
        args = {"-R"},
        cwd = "/home/mikael/src/main.old",
        -- on_stderr = function(e)
        --     print(string.format("stderr %s",  e))
        -- end,
        -- on_stdout = function(e)
        --     print(string.format("stdout %s",  e))
        -- end,
        on_exit = function(j ,return_val) 
            P(j)
            print(return_val)
        end
    }):start()


end})


vim.keymap.set({"v", "x"}, "Y", function() 
    vim.cmd("'<,'>w!/tmp/aaa")
    vim.cmd("silent !xclip -sel c /tmp/aaa")
end)
vim.keymap.set("n", "Y", function()
    local line = vim.api.nvim_get_current_line()
    vim.cmd(".w!/tmp/aaa")
    vim.cmd("silent !xclip -sel c /tmp/aaa")
    print("copied to clipboard")
end)
