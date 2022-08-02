local utils = require("utils")
local Q = require("units.query")
local ts_utils = require("nvim-treesitter.ts_utils")

local usage_namespace = vim.api.nvim_create_namespace("foo-space")
local NODE = nil
local highlight_active = false
local hlgroup = "luaTSComment"

local M = {}

local function describe(node)
	if node == nil then
		vim.notify("node is nil -- cannot print range", vim.log.levels.ERROR)
	end
    local res = Q.exec_query(    "(tag_name) @name", node)
    local text = vim.treesitter.query.get_node_text(res[1].name, 0)

	local r0, c0, r1, c1 = node:range()
    local s = string.format("%s implied range (%s, %s) -> (%s, %s)", text, r0 + 1, c0 - 1, r1 + 1, c1 - 1)
	P(s)
    return s
end
M.describe = describe

local function goto_node(node, goto_end)
    ts_utils.goto_node(node, goto_end or false, true)
end

local function set_node(node)
	local old = NODE
	NODE = node
	if highlight_active and (NODE ~= nil) then
		vim.api.nvim_buf_clear_namespace(0, usage_namespace, 0, -1)
		-- ts_utils.highlight_node(NODE, 0, usage_namespace, "luaTSComment")
		local r0, c0, r1, c1 = NODE:range()
		vim.highlight.range(0, usage_namespace, hlgroup, { 0, 0 }, { r0, c0 })
		vim.highlight.range(0, usage_namespace, hlgroup, { r1, c1 }, { vim.fn.line("$"), 1000 })

		-- ts_utils.highlight_range(NODE, 0, usage_namespace, "luaTSComment")
		-- ts_utils.highlight_node(NODE, 0, usage_namespace, "luaTSComment")
	end
	-- print_range(NODE)
end

local function toggle_highlight()
	highlight_active = not highlight_active
	if highlight_active then
		print("highlight active")
	else
		print("highlight inactive")
	end
	if NODE == nil then
		vim.api.nvim_buf_clear_namespace(0, usage_namespace, 0, -1)
		return
	end
	if highlight_active then
		ts_utils.highlight_node(NODE, 0, usage_namespace, "luaTSComment")
	else
		vim.api.nvim_buf_clear_namespace(0, usage_namespace, 0, -1)
	end
	describe(NODE)
end

local function clear_node()
	set_node(nil)
end

--- @return table tsnode
local function closest_xml_tag()
    return Q.first_ancestor(ts_utils.get_node_at_cursor(0), "element", false)

end

local function delete_node(node)
    -- utils.vim_motion
    local r0, c0, r1, c1 = node:range()
    vim.api.nvim_buf_set_mark(0, "a", r1+1+1, c1, {})
    vim.api.nvim_buf_set_lines(0, r0, r1+1, false, {})
    utils.vim_motion("`a")
end

--- mutates state; sets NODE to be the parent node
local function parent_node()
	local tmp = vim.fn.getpos(".")
	local line, col = tmp[2] - 1, tmp[3] - 1 -- ensure zero-based
	if NODE ~= nil and (not ts_utils.is_in_node_range(NODE, line, col)) then
		P("not in range")
		set_node(closest_xml_tag())
		return
	end

	if NODE == nil then
		set_node(closest_xml_tag())
	else
		set_node(Q.first_ancestor(NODE, "element", true))
	end
    goto_node(NODE)
end

--- @return table tsnode
M.first_xml_element_after_cursor = function ()
    local tmp = vim.fn.getpos('.')
    local lnum = tmp[2] - 1
    local nlines = vim.api.nvim_buf_line_count(0)

    local node -- the node that is right after current cursor position
    local res = Q.exec_query("(element (_ (tag_name) @name)) @elem", Q.get_root(), lnum - 1, nlines + 2)
    for _, r in ipairs(res) do
        local r0, _, _, _ = r.elem:range()
        if r0 > lnum then
            node = r.elem
            break
        end
    end

    return node

end
local function goto_sibling(next)
	if next then
		set_node(NODE:next_sibling())
	else
		set_node(NODE:prev_sibling())
	end
	goto_node(NODE)
end

local function visually_select_current_node()
	local c = vim.v.count1 - 1
	local n = ts_utils.get_node_at_cursor(0)
	local node = Q.first_ancestor(n, "element", false)
	while (c > 0) and (node ~= nil) do
		n = Q.first_ancestor(node, "element", true)
		if n ~= nil then
			node = n
		else
			break
		end
		c = c - 1
	end
	local r0, c0, r1, c1 = node:range()
	vim.fn.cursor(r0 + 1, c0 + 1)
	utils.vim_motion("m<")
	vim.fn.cursor(r1 + 1, c1 + 1)
	utils.vim_motion("m>")
	utils.vim_motion("gv", false)
	NODE = node
end

vim.keymap.set("o", "ib", visually_select_current_node, {})
vim.keymap.set("x", "ib", visually_select_current_node, {})
vim.keymap.set("n", "<space><space>x", visually_select_current_node)
vim.keymap.set("n", "gP", function()
	clear_node()
	parent_node()
end)
vim.keymap.set("n", "]s", function()
	goto_sibling(true)
end)
vim.keymap.set("n", "[s", function()
	goto_sibling(false)
end)
vim.keymap.set("n", "[p", parent_node)
vim.keymap.set("n", "]p", parent_node)
vim.keymap.set("n", "<leader><leader>i", function()
	toggle_highlight()
	set_node(closest_xml_tag())
end)
vim.keymap.set("n", "<leader><leader>p", function()
    local node = M.first_xml_element_after_cursor()
    if not node then
		vim.notify("node is nil", vim.log.levels.ERROR)
    end
    describe(node)
end)

local g = vim.api.nvim_create_augroup("XML-group", { clear = true })
vim.api.nvim_create_autocmd("CursorMoved", {
	group = g,
	pattern = { "*.svelte" },
	callback = function()
		if highlight_active then
			set_node(closest_xml_tag())
		end
	end,
})
vim.keymap.set("n", "dat", function() delete_node(NODE) end)

return M
