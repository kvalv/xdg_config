local Query = require("units.query")
local ts_utils = require("nvim-treesitter.ts_utils")
local locals = require("nvim-treesitter.locals")
local LangInfo = require("units.langs")

local M = {}

-- a lookup table that contain important information for each filetype
local lookup = {}

--- register a language
---@param name string the language name
---@param lang_info table will create a LangInfo instance from it
local function add_language(name, lang_info)
	local o = LangInfo:new(lang_info)
	lookup[name] = o
end

M.get_treesitter = function(bufnr)
	local parser = vim.treesitter.get_parser(bufnr or 0, vim.bo.filetype)
	local tree = parser:parse()
end

--- returns the closest node of "function_declaration" type (or node_type if specified)
-- returns nil if it doesnt exist
function M.get_closest_function(bufnr)
	Query.get_root(0, vim.bo.filetype) -- TODO: don't want to call this? update parser??
	local node = ts_utils.get_node_at_cursor()
	local nt = lookup[vim.bo.filetype].node
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

--- returns name for a given function node.
-- raises an error if the node is not a function node
M.get_function_name = function(function_node, filetype)
    return Query.get_name(function_node)
end

M.read_file = function(file)
	return vim.fn.readfile(file)
end

M.add_unit_test = function(func_name)
    local root_node = Query.get_root()
	local function_node = M.get_closest_function()
	if function_node == nil then
		error("node is not a function node; received nil")
	end

	-- local name = M.get_function_name(function_node)
    local name = Query.get_name(function_node)
	local _, _, rowend, _ = function_node:range()
	local lines = lookup[vim.bo.filetype].template(func_name or ("test_" .. name), function_node, root_node)
	vim.api.nvim_buf_set_lines(0, rowend + 1, rowend + 1, false, lines)
	Query.get_root(0, vim.bo.filetype) -- TODO: don't want to call this? update parser??
end

local function setup_keymaps()
	vim.keymap.set("n", "<leader>ut", function()
		local ft = vim.bo.filetype -- must be go
		if not vim.tbl_contains(vim.tbl_keys(lookup), ft) then
            vim.notify("not supported filetype: " .. ft, 3)
            return
		end
		vim.ui.input({ prompt = "Unit test function name: " }, function(name)
			if name == nil then
				return
			end
			M.add_unit_test(name)
		end)
	end, {})
end

M.init = function()
	-- TODO: would be nice to scan the directory and insert languages without having
	-- to update this function
	add_language("go", require("units.langs.go"))
	add_language("python", require("units.langs.python"))
	add_language("rust", require("units.langs.rust"))

	setup_keymaps()
end

return M
