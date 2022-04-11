local map = vim.api.nvim_set_keymap

-- map the leader key
map("n", "<Space>", "", {})
vim.g.mapleader = " " -- 'vim.g' sets global variables

local options = { noremap = true }

map("n", ";", ":", options)
map("v", ";", ":", options)

map("n", "<C-h>", "<C-W>h", options)
map("n", "<C-j>", "<C-W>j", options)
map("n", "<C-k>", "<C-W>k", options)
map("n", "<C-l>", "<C-w>l", options)

map("n", "<M-Space>", "", options)
map("n", "<leader>w", ":w<CR>", options)
map("n", "<leader>q", ":q<CR>", options)
map("n", "<leader>or", ':jobstart("docker-compose restart -t0 api migrate")<CR>', options)
map("n", "<leader>ow", ':jobstart("docker-compose restart -t0 worker cuda-worker excl-worker")<CR>', options)

-- " terminal mappings
map("t", "<C-x>", "<C-\\><C-n>", options)
map("t", "<C-h>", "<C-\\><C-n><C-w><C-h>", options)
map("t", "<C-k>", "<C-\\><C-n><C-w><C-k>", options)
map("t", "<C-l>", "<C-\\><C-n><C-w><C-l>", options)
map("t", "<C-j>", "<C-\\><C-n><C-w><C-j>", options)
map("t", "<C-o>", "<C-\\><C-n><C-o>", options)
