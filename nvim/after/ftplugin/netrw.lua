local function search_current_netrw_directory()
    local cwd = vim.b.netrw_curdir
    local tail = vim.fn.fnamemodify(cwd, ":t")
    local input = vim.fn.input("Rg " .. tail .. " > ")
    if input == "" then
        return
    end
    -- call normal command 'Rg <input>'
    vim.cmd("Rg " .. input .. " " .. cwd)
end
-- autocmd this

vim.keymap.set("n", "<leader>s", search_current_netrw_directory, { nowait = true, buffer = 0 })
