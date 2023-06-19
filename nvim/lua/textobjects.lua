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
        vim.notify("highlight active", vim.log.levels.INFO)
    else
        vim.notify("highlight inactive", vim.log.levels.INFO)
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

--- @return table|nil node
local function closest_xml_tag()
    local ft = vim.bo.filetype
    local thisNode = ts_utils.get_node_at_cursor(0)
    if thisNode == nil then
        vim.notify("no node at cursor", vim.log.levels.INFO)
        return
    end
    if ft == "typescriptreact" then
        return Q.first_ancestor(thisNode, { "jsx_element", "jsx_self_closing_element" }, false)
    elseif ft == "svelte" then
        return Q.first_ancestor(thisNode, "element", false)
    else
        vim.notify("not implemented for filetype " .. ft, vim.log.levels.ERROR)
        return
    end
end

--- mutates state; sets NODE to be the parent node
local function parent_node()
    if NODE == nil then
        return
    end
    set_node(NODE:parent())
end

local g = vim.api.nvim_create_augroup("XML-group", { clear = true })
vim.api.nvim_create_autocmd("CursorMoved", {
    group = g,
    pattern = { "*.svelte", "*.tsx" },
    callback = function()
        if highlight_active then
            set_node(closest_xml_tag())
        end
    end,
})

for _, event in pairs({ "BufWritePost", "TextChanged" }) do
    vim.api.nvim_create_autocmd(event, {
        group = g,
        pattern = { "*.svelte", "*.tsx" },
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
    return vim.treesitter.get_node_text(node, 0, { concat = true })
end

-- moves cursor to the node. if atEnd is true, then moves it to the end
-- if colOffset is set, move cursor additionally with that offset
local function cursor(node, atEnd, colOffset)
    local _, _, end_line, end_col = vim.treesitter.get_node_range(node)
    vim.fn.cursor(end_line + 1, end_col + (colOffset or 0))
end

local function indent(text, level, initialOffset)
    if level < 0 then
        local tmp = string.gsub(text, "\n" .. string.rep(" ", -level), "\n")
        return tmp
    end

    local i = string.rep(" ", level)
    local o = string.rep(" ", initialOffset or level)
    return o .. string.gsub(text, "\n", "\n" .. i)
end

-- wraps the current (highlighted) node with a new html element
local function wrap(node)
    local tag = vim.fn.input("tag: ")
    if tag == "" then
        return
    end
    local currentText = vim.treesitter.get_node_text(node, 0, { concat = true })
    local replacement
    local range = ts_utils.node_to_lsp_range(node)
    local offset = range.start.character

    replacement = string.format(
        "%s\n%s\n%s",
        "<" .. tag .. ">",
        indent(currentText, vim.bo.shiftwidth, offset + vim.bo.shiftwidth),
        indent("</" .. tag .. ">", offset)
    )
    node_replace(node, replacement)
end
local function remove_first_line(text)
    return string.gsub(text, "^[^\n]*\n", "")
end
local function remove_last_line(text)
    return string.gsub(text, "\n[^\n]*$", "")
end

local function dedent(text, offset)
    local parts = vim.tbl_map(function(line)
            local p = "^"
            for _ = 1, offset do
                p = p .. "%s?"
            end
            local replaced = string.gsub(line, p, "")
            return replaced
        end,
        vim.split(text, "\n")
    )
    return table.concat(parts, "\n")
end

-- removes the outermost layer of the node
local function peel(node)
    if node == nil then
        return
    end
    local rest = ""
    local function should_remove(c)
        return c:type() == "start_tag" or c:type() == "end_tag" or c:type() == "jsx_opening_element" or
            c:type() == "jsx_closing_element"
    end

    for c in node:iter_children() do
        if should_remove(c) then
            -- node_replace(c, "")
        else
            rest = rest .. node_text(c)
        end
    end

    local res = dedent(remove_first_line(remove_last_line(rest)), vim.bo.shiftwidth)

    local range = ts_utils.node_to_lsp_range(node)
    node_replace(node, res)
    vim.fn.cursor(range.start.line + 1, range.start.character)
    vim.cmd("normal! <<")
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
    if vim.bo.filetype ~= "svelte" then
        vim.notify("only implemented for svelte", vim.log.levels.ERROR)
        return
    end
    if node == nil then
        return
    end

    local tagNode = get_child(node, { nth = 1 })
    if tagNode == nil then
        return
    end
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
vim.keymap.set("n", "<leader>vv", function()
    toggle_highlight()
    set_node(closest_xml_tag())
end)

return M
