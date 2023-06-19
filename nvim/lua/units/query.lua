local utils = require("utils")
local Tuple = require("tuple")
local ts_utils = require("nvim-treesitter.ts_utils")
local Query = {}
Query.__index = Query

function Query.get_root(bufnr, filetype)
    local parser = vim.treesitter.get_parser(bufnr or 0, filetype)
    return parser:parse()[1]:root()
end

local function ft()
    local f = vim.bo.filetype
    if f == "typescriptreact" then
        f = "tsx"
    end
    return f
end

--- return a table where keys are capture name and values is the captured nodes
Query.pluck_query = function(node, query, start, stop)
    local out = {}
    local nqueries = 0
    for _, matches, _ in query:iter_matches(node, 0, start, stop) do
        nqueries = nqueries + 1
        for id, n in pairs(matches) do
            local capture_name = query.captures[id]
            -- local text = vim.treesitter.query.get_node_text(n, 0)
            out[capture_name] = n
        end
    end
    if nqueries == 0 then
        error("no query result found")
    elseif nqueries > 1 then
        error("expected a single query, but found " .. nqueries .. " queries.")
    end
    return out
end

--- runs a query starting on 'node' and return a single table with captures.
---@param query_str string the query to execute
---@param node table tsnode or null; if null, the root node of the current buffer is used
Query.exec_query_single_result = function(query_str, node, start, stop)
    local r = Query.get_root(0, ft()) -- refresh..
    local q = vim.treesitter.query.parse(ft(), query_str)
    -- local q = vim.treesitter.query.parse_query(vim.bo.filetype, query_str)
    return Query.pluck_query(node or r, q, start, stop)
end

--- runs a query starting on 'node' and return a list of captures.
---@param query_str string the query to execute
---@param node table tsnode or null; if null, the root node of the current buffer is used
Query.exec_query = function(query_str, node, start, stop)
    local r = Query.get_root(0, ft())
    -- local q = vim.treesitter.query.parse_query(vim.bo.filetype, query_str)
    local q = vim.treesitter.query.parse(ft(), query_str)
    local items = {}
    for _, matches, _ in q:iter_matches(node or r, 0, start, stop) do
        local o = {}
        for id, n in pairs(matches) do
            local capture_name = q.captures[id]
            o[capture_name] = n
        end
        table.insert(items, o)
    end
    return items
end

--- returns the 'smallest' tsnode covering the visual selection
---@returns table tsnode
--if no active visual selection ,then the most recent visual selection
--(registers < and >) are used.
Query.node_covering_visual_selection = function()
    -- borrow 'a' register to store current location. We'll put back the
    -- original content (stored in 'a'
    local row = vim.fn.line(".")
    local col = vim.fn.col(".")
    local mark_a = vim.api.nvim_buf_get_mark(0, "a")
    vim.api.nvim_buf_set_mark(0, "a", row, col, {})

    if vim.api.nvim_buf_get_mark(0, "<")[1] == 0 then
        vim.notify("visual selection not set. Cannot select node.", 3)
        return
    end

    utils.vim_motion("`<") -- goto start of visual selection
    local a = vim.api.nvim_buf_get_mark(0, "<")
    local b = vim.api.nvim_buf_get_mark(0, ">")
    local visual_selection = { start = { row = a[1], col = a[2] }, stop = { row = b[1], col = b[2] } }

    local function covers_visual_selection(node, vs)
        local r0, c0, r1, c1 = node:range()
        local start = { row = r0, col = c0 }
        local stop = { row = r1, col = c1 }
        local t = Tuple.new

        if
            (t({ start.row, start.col }) <= t({ vs.start.row, vs.start.col }))
            and (t({ vs.stop.row, vs.stop.col }) <= t({ stop.row, stop.col }))
        then
            return true
        end
        return false
    end

    local node = ts_utils.get_node_at_cursor(0)
    while node ~= nil and not covers_visual_selection(node, visual_selection) do
        node = node:parent()
    end
    utils.vim_motion("`ah")
    if mark_a[1] ~= 0 then
        vim.api.nvim_buf_set_mark(0, "a", mark_a[1], mark_a[2], {})
    else
        vim.api.nvim_buf_del_mark(0, "a") -- leave no trace...
    end

    return node
end

--- finds first ancestor of a given type
---@param node table tsnode
---@param node_type (string | string[]) the node type
---@param skip_current boolean whether to skip current node if it is of matching type
---@return table|nil tsnode or nil if it didn't find any of that type
Query.first_ancestor = function(node, node_type, skip_current)
    skip_current = skip_current == nil and false or skip_current
    if node == nil then
        return nil
    end
    local t = node:type()
    if type(node_type) == "table" then
        for _, v in ipairs(node_type) do
            if t == v then
                return node
            end
        end
    end
    if (t == node_type) and not skip_current then
        return node
    end
    return Query.first_ancestor(node:parent(), node_type, false)
end

Query.get_name = function(node)
    local captures = Query.exec_query_single_result(string.format("(%s name: (identifier) @name)", node:type()), node)
    local id_node = captures.name
    return vim.treesitter.query.get_node_text(id_node, 0)
end

return Query
