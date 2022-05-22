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

return Query
