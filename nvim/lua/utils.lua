local Path = require("plenary.path")

local M = {}
M.tuple = require("tuple") -- re-export...

M.reload = function(name)
	require("plenary.reload").reload_module(name)
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

M.printf = function(s, ...)
	return print(string.format(s, ...))
end

-- stolen from https://github.com/ThePrimeagen/refactoring.nvim/blob/master/lua/refactoring/tests/utils.lua
function M.read_file(file)
	return Path:new("lua", "refactoring", "tests", file):read()
end

function M.concat(arr1, arr2)
    local out = {}
    for _, elem in ipairs(arr1) do
        table.insert(out, elem)
    end
    for _, elem in ipairs(arr2) do
        table.insert(out, elem)
    end
    return out
end
function M.vim_motion(motion, escape)
	local s
	if (escape == nil) or escape then
		s = string.format(':exe "norm! %s\\<esc>"', motion)
	else
		s = string.format(':exe "norm! %s"', motion)
	end
	vim.cmd(s)
end

--- sets mark `mark` at cursor position and returns a callback function to restore to the original mark
-- this can be convenient when a scripts needs to store location of current position and go somewhere
-- else
--- @param mark string the mark
M.borrow_mark = function(mark)
	local m = vim.api.nvim_get_mark(mark, {})
	vim.api.nvim_buf_set_mark(0, mark, vim.fn.line("."), vim.fn.col("."), {})
	M.vim_motion("H")
	local s = vim.api.nvim_get_mark("S", {})
	vim.api.nvim_buf_set_mark(0, "S", vim.fn.line("."), vim.fn.col("."), {})
	local function restore()
		print("restoring", m[1], m[2])
		-- M.vim_motion('`' .. mark)
		M.vim_motion(string.format("`Szt`%s", mark))

		if s[1] == 0 then
			-- mark was not set in first place...
			vim.api.nvim_buf_del_mark(0, "S")
		else
			vim.api.nvim_buf_set_mark(0, "S", s[1], s[2], {})
		end
		if m[1] == 0 then
			-- mark was not set in first place...
			vim.api.nvim_buf_del_mark(0, mark)
		else
			vim.api.nvim_buf_set_mark(0, mark, m[1], m[2], {})
		end
	end

	return restore
end

M.reverse_highlight = function(node, timeout, namespace)
	local usage_namespace = namespace or vim.api.nvim_create_namespace("foo-space")
	local hlgroup = "luaTSComment"
	vim.api.nvim_buf_clear_namespace(0, usage_namespace, 0, -1)
	local r0, c0, r1, c1 = node:range()
	vim.highlight.range(0, usage_namespace, hlgroup, { 0, 0 }, { r0, c0 })
	vim.highlight.range(0, usage_namespace, hlgroup, { r1, c1 }, { vim.fn.line("$"), 1000 })

	if timeout ~= nil then
		vim.defer_fn(function()
			vim.api.nvim_buf_clear_namespace(0, usage_namespace, 0, -1)
		end, timeout)
	end
end


local id = vim.api.nvim_create_augroup("MyGroup", { clear = false })
M.do_frequent_writes = function()
    local bufnr = vim.fn.bufnr("%")
    print(bufnr)
    vim.api.nvim_create_autocmd({"TextChanged", "InsertLeave"}, {buffer=bufnr, callback=function() require("utils").vim_motion(":w") end})
end

M.dont_frequent_writes = function()
    vim.api.nvim_clear_autocmds({group=id})
    -- vim.api.nvim_del_augroup_by_id(id)
end

local id2 =  vim.api.nvim_create_augroup("MyGroup", { clear = false })
M.on_save = function(callback)
    if callback then
        vim.api.nvim_create_autocmd("BufWritePost", {buffer=vim.fn.bufnr("%"), callback=callback, group=id2})
    else
        vim.api.nvim_del_augroup_by_id(id)
    end
end

M.get_visual_selection = function()
    local vstart = vim.fn.getpos("'<")
    local vend = vim.fn.getpos("'>")
    local col_start = vstart[3]
    local col_end = vend[3]
    local line_start = vstart[2]
    local line_end = vend[2]
    local lines = vim.fn.getline(line_start, line_end)
    -- strip first line and last line
    lines[1] = lines[1]:sub(col_start)
    lines[#lines] = lines[#lines]:sub(1, col_end)
    local text = table.concat(lines, "\n")
    text = text:gsub("\\$", "")
    return text

end

return M
