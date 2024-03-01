-- https://github.com/soimort/translate-shell
local function translate()
    local fname = vim.fn.expand('%:t')
    local languages = {
        ["de-DE.json"] = "de",
        ["nb-NO.json"] = "no",
    }
    local lang = languages[fname]

    vim.cmd('silent! normal! /defaultMessage\r')
    vim.cmd('normal! 2f"')
    vim.cmd.normal('yi"')
    local contents = vim.fn.getreg("@")
    local cmd = "trans -b :" .. lang .. " '" .. contents .. "'"
    local out = vim.fn.system(cmd)
    vim.fn.setreg("a", out)
    vim.cmd.normal('ci"' .. out)

end

vim.keymap.set("n", "<leader>ht", translate, { noremap = true, silent = true })
