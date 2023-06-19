--

vim.keymap.set("n", "<leader>M", function()
    local varName = vim.fn.input("variable name: ")
    if varName == "" then return end -- stop if user doesn't want to provide the name

    -- find messages.ts file by going up the directory tree
    local dir = vim.fn.expand('%:h')
    local messagesFile = ""
    local maxdepth = 10
    local depth = 0
    while depth < maxdepth and dir ~= "/" and vim.fn.filereadable(messagesFile) == 0 do
        print(dir)
        depth = depth + 1
        messagesFile = dir .. "/messages.ts"
        dir = vim.fn.fnamemodify(dir, ":h")
    end
    if vim.fn.filereadable(messagesFile) == 0 then
        print("no messages.ts file found")
        return
    end

    vim.cmd("norm mAHmT`A") -- mark where we are right now so we can restore

    vim.cmd(string.format('norm "aca"formatMessage(messages.%s)', varName)) -- store into register a
    vim.cmd("e " .. messagesFile)
    vim.cmd(string.format('norm ggda(uo%s: {\rdefaultMessage: %s,\rid: "%s"},', varName, vim.fn.getreg('a'), varName))
    vim.cmd("norm `Tzt`A") -- restore
end)

vim.keymap.set("n", "<leader>x", function ()
    local out = vim.fn.system('jq', vim.fn.system('base64 --decode', '@a'))
    P(out)
    -- vim.fn.getreg('"')

end)
