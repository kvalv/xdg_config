local o = vim.o
local wo = vim.wo
local bo = vim.bo

o.cmdheight = 1
o.expandtab = true
o.hidden = true
o.ignorecase = true
o.smartcase = true
o.laststatus = 2
o.linebreak = true
o.matchtime = 1
o.modeline = true
o.mouse = "a"
o.breakindent = true
o.backup = false
o.cursorcolumn = false
o.foldenable = false
o.hlsearch = false
o.number = true
o.relativenumber = true
o.swapfile = false
o.numberwidth = 1
o.pumheight = 10
o.scrolloff = 0
o.shiftwidth = 4
o.showcmd = true
o.showmatch = true
o.smartindent = true
o.tabstop = 4
o.undofile = true
o.hidden = true
o.updatetime = 250
wo.signcolumn = "yes"

-- Set completeopt to have a better completion experience
o.completeopt = "menuone,noselect"

-- vim.cmd [[
--   autocmd FileType lua set shiftwidth=2 tabstop=2
-- ]]
