local null_ls = require("null-ls")
local Path = require("plenary.path")
local ts_utils = require("nvim-treesitter.ts_utils")
local Query = require("units.query")

local M = {}

M.get_treesitter = function(bufnr)
	local parser = vim.treesitter.get_parser(bufnr or 0, vim.bo.filetype)
	local tree = parser:parse()
	P(tree)
end

M.get_function_name = function()
	local node = ts_utils.get_node_at_cursor()
	if node:type() ~= "identifier" then
		error("node must be identifier, this is type " .. node:type())
	end
end

M.read_file = function(file)
	return vim.fn.readfile(file)
end

local replacementCode = {
	go = function(func_name)
		return {
			string.format("func %s(t *testing.T) {", func_name or string.format("Test%s", name)),
			"    // TODO",
			"}",
		}
	end,
	python = function(func_name)
		return {
			string.format("def %s():", func_name),
			"    pass  # TODO",
		}
	end,
}

M.add_test_function = function(func_name)
	local function_node = Query.get_closest_function()
	if function_node == nil then
		error("node is not a function node; received nil")
	end

	local name = Query.get_function_name(function_node)
	local _, _, rowend, _ = function_node:range()
	local lines = replacementCode[vim.bo.filetype](func_name or ("test_" .. name))
	vim.api.nvim_buf_set_lines(0, rowend + 1, rowend + 1, false, lines)
	Query.get_root(0, vim.bo.filetype) -- TODO: don't want to call this? update parser??
end

M.init = function()
	vim.keymap.set("n", "<leader>ut", function()
		local ft = vim.bo.filetype -- must be go
		if not vim.tbl_contains({ "python", "go" }, ft) then
			error("not supported filetype " .. ft)
		end
		vim.ui.input({ prompt = "Unit test function name: " }, function(name)
			if name == nil then
				return
			end
			M.add_test_function(name)
		end)
	end, {})
end

-- local frozen_string_actions = {
-- 	method = null_ls.methods.CODE_ACTION,
-- 	filetypes = { "text", "go", "lua" },
-- 	generator = {
-- 		fn = function(ctx)

-- 			return {
-- 				{
-- 					title = "create unit test for function",
-- 					action = function()
-- 						-- vim.api.nvim_buf_set_lines(ctx.bufnr, ctx.row, ctx.row, false, { "something nice", "!!!" })

--                         -- local params = vim.lsp.util.make_position_params()
--                         -- vim.lsp.buf_request(0, 'textDocument/implementation', params, function(err, result, ctx, config)
--                         --     P(err)
--                         --     P(result)
--                         --     P(ctx)
--                         --     P(config)
--                         -- end)

-- 					end,
-- 				},
-- 			}
-- 		end,
-- 	},
-- }
-- null_ls.register(frozen_string_actions)
return M
