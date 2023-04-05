local utils = require("utils")
local Q = require("units.query")
local ts_utils = require("nvim-treesitter.ts_utils")

local usage_namespace = vim.api.nvim_create_namespace("foo-space")
local NODE = nil
local highlight_active = false
local hlgroup = "Comment"

local M = {}

local function goto_node(node, goto_end)
	ts_utils.goto_node(node, goto_end or false, true)
end

local function set_node(node)
	NODE = node
	if highlight_active and (NODE ~= nil) then
		vim.api.nvim_buf_clear_namespace(0, usage_namespace, 0, -1)
		-- ts_utils.highlight_node(NODE, 0, usage_namespace, "luaTSComment")
		local r0, c0, r1, c1 = NODE:range()
		vim.highlight.range(0, usage_namespace, hlgroup, { 0, 0 }, { r0, c0 })
		vim.highlight.range(0, usage_namespace, hlgroup, { r1, c1 }, { vim.fn.line("$"), 1000 })
	end
	return NODE
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
		print("highlighte nod")
		ts_utils.highlight_node(NODE, 0, usage_namespace, "Comment")
	else
		vim.api.nvim_buf_clear_namespace(0, usage_namespace, 0, -1)
	end
end

local function clear_node()
	set_node(nil)
end

--- @return table tsnode
local function closest_xml_tag()
	return Q.first_ancestor(ts_utils.get_node_at_cursor(0), "element", false)
end

--- mutates state; sets NODE to be the parent node
local function parent_node()
	if NODE == nil then
		return
	end
	set_node(NODE:parent())
end

--- @return table tsnode
M.first_xml_element_after_cursor = function()
	local tmp = vim.fn.getpos(".")
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

for _, event in pairs({ "BufWritePost", "TextChanged" }) do
	vim.api.nvim_create_autocmd(event, {
		group = g,
		pattern = { "*.svelte" },
		callback = function()
			if highlight_active then
				set_node(closest_xml_tag())
			end
		end,
	})
end

-- replace content with text
local function node_replace(node, text)
	local range = ts_utils.node_to_lsp_range(node)
	local edit = { range = range, newText = text }
	vim.lsp.util.apply_text_edits({ edit }, 0, "utf-8")
end
local function node_text(node)
	return vim.treesitter.query.get_node_text(node, 0, { concat = true })
end

-- moves cursor to the node. if atEnd is true, then moves it to the end
-- if colOffset is set, move cursor additionally with that offset
local function cursor(node, atEnd, colOffset)
	local _, _, end_line, end_col = ts_utils.get_node_range(node)
	vim.fn.cursor(end_line + 1, end_col + (colOffset or 0))
end

local function indent(text, level)
	local i = string.rep(" ", level)
	return i .. string.gsub(text, "\n", "\n" .. i)
end

--
-- wraps the current (highlighted) node with a new html element
local function wrap(node)
	local tag = vim.fn.input("tag: ")
	if tag == "" then
		return
	end
	local currentText = vim.treesitter.query.get_node_text(node, 0, { concat = true })
	local containsNewline = string.match(currentText, "\n") ~= nil
	local replacement
	if containsNewline then
		local range = ts_utils.node_to_lsp_range(node)
		local offset = range.start.character

		replacement = string.format(
			"%s\n%s\n%s",
			indent("<" .. tag .. ">", 0),
			"    " .. currentText,
			indent("</" .. tag .. ">", offset)
		)
	else
		replacement = string.format("<%s>%s</%s>", tag, currentText, tag)
	end
	node_replace(node, replacement)
end

-- removes the outermost layer of the node
local function peel(node)
	if node == nil then
		return
	end
	for c in node:iter_children() do
		if c:type() == "start_tag" or c:type() == "end_tag" then
			node_replace(c, "")
		end
	end
	-- node_replace(node, "peeled!")
	-- node, go through direct children, and
	-- remove start_tag and end_tag
	set_node(closest_xml_tag())
end

local function get_child(node, opts)
	if node == nil then
		return nil
	end
	local n = 1
	for c in node:iter_children() do
		if opts.type == c:type() then
			return c
		end
		if opts.nth == n then
			return c
		end
		n = n + 1
	end
	return nil
end

local function edit_class(node)
	if node == nil then
		return
	end

	local tagNode = get_child(node, { nth = 1 })
	local caps = Q.exec_query(
		[[(attribute (attribute_name) @name (quoted_attribute_value) @value (#match? @name "class"))]],
		tagNode
	)
	if #caps == 0 then
		local n = Q.exec_query([[(start_tag (tag_name)@tagname)]], node)[1].tagname
		node_replace(n, string.format([[%s class=""]], node_text(n)))
		cursor(n, true)
	else
		local valueNode = caps[1].value
		cursor(valueNode, true)
	end
	vim.fn.execute("startinsert")
end

vim.keymap.set({ "n" }, "<leader>vw", function()
	wrap(closest_xml_tag())
end, {
	silent = true,
})

vim.keymap.set({ "n" }, "<leader>vd", function()
	local node = NODE or set_node(closest_xml_tag())
	peel(node)
end, {
	silent = true,
})

vim.keymap.set("n", "<leader>vc", function()
	-- edit class of current node
	-- local node = NODE or set_node(closest_xml_tag())
	edit_class(closest_xml_tag())
end, { silent = true })

vim.keymap.set("n", "<Down>", function()
	set_node(NODE:next_sibling())
	cursor(NODE)
end)
vim.keymap.set("n", "<Up>", function()
	set_node(NODE:prev_sibling())
	cursor(NODE)
end)

vim.keymap.set("n", "<Left>", function()
	parent_node()
	goto_node(NODE)
	cursor(NODE)
end)
vim.keymap.set("n", "<Right>", function()
	local c = get_child(NODE, { nth = 1 })
	if c ~= nil then
		set_node(c)
		cursor(c)
		return
	end
end)
vim.keymap.set("n", "<leader>vh", function()
	toggle_highlight()
	set_node(closest_xml_tag())
end)

return M
