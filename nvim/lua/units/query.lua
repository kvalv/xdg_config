local locals = require("nvim-treesitter.locals")
local ts_utils = require("nvim-treesitter.ts_utils")

local Query = {}
Query.__index = Query

function Query.get_root(bufnr, filetype)
	local parser = vim.treesitter.get_parser(bufnr or 0, filetype)
	return parser:parse()[1]:root()
end

local FunctionNodeTypes = {
	go = { node = "function_declaration", query = [[
(function_declaration
  name: (identifier) @name
)
        ]] },
	python = { node = "function_definition", query = [[
(function_definition
  name: (identifier) @name
)
        ]] },
}

--- returns the closest node of "function_declaration" type (or node_type if specified)
-- returns nil if it doesnt exist
function Query.get_closest_function(bufnr)
    Query.get_root(0, vim.bo.filetype) -- TODO: don't want to call this? update parser??
	local node = ts_utils.get_node_at_cursor()
    local nt = FunctionNodeTypes[vim.bo.filetype].node
    if node:type() == nt then
        return node
    end
	local scopes = locals.get_scope_tree(node, bufnr or 0)

	for _, value in ipairs(scopes) do
		if value:type() == nt then
			return value
		end
	end
	return nil
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

--- returns name for a given function node.
-- raises an error if the node is not a function node
Query.get_function_name = function(node, filetype)
    local t = FunctionNodeTypes[vim.bo.filetype].node
	if node:type() ~= t then
        error(string.format("expected node to be of type %s but got %s", t, node:type()))
	end
    local ft = filetype or vim.bo.filetype
	local query = vim.treesitter.query.parse_query(
		ft,
		FunctionNodeTypes[ft].query
	)

	local identifier_node = Query.pluck_query(node, query).name
	return vim.treesitter.query.get_node_text(identifier_node, 0)
end

return Query
