local Query = {}
Query.__index = Query

function Query.get_root(bufnr, filetype)
	local parser = vim.treesitter.get_parser(bufnr or 0, filetype)
	return parser:parse()[1]:root()
end

--- return a table where keys are capture name and values is the captured nodes
Query.pluck_query = function(node, query)
	local out = {}
	local nqueries = 0
	for _, matches, _ in query:iter_matches(node, 0) do
		nqueries = nqueries + 1
		for id, n in pairs(matches) do
			local capture_name = query.captures[id]
			-- local text = vim.treesitter.query.get_node_text(n, 0)
			out[capture_name] = n
		end
	end
	if nqueries ~= 1 then
		error("expected a single query, but found " .. nqueries .. " queries.")
	end
	return out
end

--- runs a query starting on 'node' and return a single table with captures.
---@param query_str string the query to execute
---@param node table tsnode or null; if null, the root node of the current buffer is used
Query.exec_query_single_result = function(query_str, node)
	local r = Query.get_root() -- refresh..
	local q = vim.treesitter.query.parse_query(vim.bo.filetype, query_str)
	-- print("doing query on node of type .. " .. (node or r):type())
	return Query.pluck_query(node or r, q)
end

--- runs a query starting on 'node' and return a list of captures.
---@param query_str string the query to execute
---@param node table tsnode or null; if null, the root node of the current buffer is used
Query.exec_query = function(query_str, node)
	local r = Query.get_root()
	local q = vim.treesitter.query.parse_query(vim.bo.filetype, query_str)
	local items = {}
	for _, matches, _ in q:iter_matches(node or r, 0) do
		local o = {}
		for id, n in pairs(matches) do
			local capture_name = q.captures[id]
			o[capture_name] = n
		end
		table.insert(items, o)
	end
	return items
end

--- finds first ancestor of a given type
---@param node table tsnode
---@param node_type string the node type
---@return table tsnode or nil if it didn't find any of that type
Query.first_ancestor = function(node, node_type)
	if node == nil then
		return nil
	end
	if node:type() == node_type then
		return node
	end
	return Query.first_ancestor(node:parent(), node_type)
end

Query.get_name = function(node)
	local captures = Query.exec_query_single_result(string.format("(%s name: (identifier) @name)", node:type()), node)
	local id_node = captures.name
	return vim.treesitter.query.get_node_text(id_node, 0)
end

return Query
