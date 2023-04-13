--

vim.keymap.set("n", "<leader>M", function()
    local varName = vim.fn.input("variable name: ")
    if varName == "" then return end -- stop if user doesn't want to provide the name
    local messagesFile = vim.fn.expand('%:h') .. "/" .. "messages.ts"
    if vim.fn.filereadable(messagesFile) == 1 then
        print("no messages.ts file found")
        return
    end
    -- print("messagefile = " .. messagesFile .. " and it is readable: " .. vim.fn.filereadable(messagesFile))

    vim.cmd("norm mAHmT`A") -- mark where we are right now so we can restore

    vim.cmd(string.format('norm "aca"formatMessage(messages.%s)', varName)) -- store into register a
    vim.cmd("e " .. messagesFile)
    vim.cmd(string.format('norm ggda(uo%s: {\rdefaultMessage: %s,\r},', varName, vim.fn.getreg('a')))
    vim.cmd("norm `Tzt`A") -- restore
end)

vim.keymap.set("n", "<leader>x", function ()
    local out = vim.fn.system('jq', vim.fn.system('base64 --decode', '@a'))
    P(out)
    -- vim.fn.getreg('"')

end)
