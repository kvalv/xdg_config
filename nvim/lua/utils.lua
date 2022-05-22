local Path = require("plenary.path")

local M = {}

M.reload = function(name)
    require('plenary.reload').reload_module(name)
    return require(name)
end
_G.reload = M.reload

-- some util functions...
M.tbl_index = function(t, pred)
    for index, v in ipairs(t) do
        if pred(v) then
            return index
        end
    end
    return nil
end
M.join = function(parts, sep)
    local s = ""
    for _, p in ipairs(parts) do
        s = s .. p .. sep
    end
    return s:sub(1, -2)
end

M.partition = function(t, index)
    local out = {}
    for i = index, #t do
        table.insert(out, t[i])
    end
    return out
end

M.log = require("plenary.log").new({
    plugin = "mk",
    level = "warn",
})

-- stolen from https://github.com/ThePrimeagen/refactoring.nvim/blob/master/lua/refactoring/tests/utils.lua
function M.read_file(file)
    return Path:new("lua", "refactoring", "tests", file):read()
end

function M.vim_motion(motion)
    vim.cmd(string.format(':exe "norm! %s\\<esc>"', motion))
end

return M
