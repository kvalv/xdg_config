local M = {}
M.init = function()
	vim.cmd("e ~/.config/nvim/lua/units/tests/inputs/foo.go")
end

M.open_test_file = function(name)
	vim.cmd("e ~/.config/nvim/lua/units/tests/inputs/" .. name)
end

return M
