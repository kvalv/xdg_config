ls = require("luasnip")

types = require("luasnip.util.types")

ls.config.set_config({
	history = true,
	updateevents = "TextChanged,TextChangedI",
	enable_autosnippets = true,
})

vim.keymap.set({ "i", "s" }, "Q", function()
	print("called")
	if ls.expand_or_jumpable() then
		ls.expand_or_jump()
	end
end, {
	silent = true,
})
-- vim.keymap.set('i', "q", function() if ls.expand_or_jumpable() then ls.expand_or_jump() end end, {silent=true})

vim.keymap.set({ "i", "s" }, "<c-j>", function()
	if ls.jumpable(-1) then
		ls.jump(-1)
	end
end, { silent = true })

vim.keymap.set({ "i" }, "<c-l>", function()
	if ls.choice_active() then
		ls.change_choice(1)
	end
end, { silent = true })

vim.keymap.set("n", "<leader><leader>s", "<cmd>source ~/.config/nvim/after/plugin/luasnip.lua<CR>")
