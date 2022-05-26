local t = require("units.tests.utils")
local units = require("units")
local utils = require("utils")
local Query = require("units.query")

local function printfile()
    print('---- file contents ----')
    print(vim.fn.join(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"))
    print('----    end    ----')
end

describe("query function node", function()
	before_each(function()
		t.init()
		utils.vim_motion("3j")
	end)

	it("returns node if cursor inside of function", function()
		local node = units.get_closest_function()
		assert.equals(node:type(), "function_declaration")
	end)

	it("returns nil if cursor outside of function", function()
		utils.vim_motion("gg")
		local node = units.get_closest_function()
		assert.is.falsy(node)
	end)

	it("returns proper function name", function()
		local node = units.get_closest_function()
		local name = units.get_function_name(node)
		assert.are.same("AddNumbers", name)
	end)
end)

describe("creates test node", function()
	it("appends unit test with go filetype", function()
		t.open_test_file("foo.go")
		utils.vim_motion("3j")
		units.add_unit_test("TestAddNumbers")
		utils.vim_motion("G")
		local test_fn_node = units.get_closest_function()
		assert.truthy(test_fn_node, vim.api.nvim_buf_get_lines(0, 0, -1, false))
		assert.same("TestAddNumbers", units.get_function_name(test_fn_node))
	end)

	it("appends unit test with python filetype", function()
		t.open_test_file("foo.py")
		utils.vim_motion("3j")
		units.add_unit_test("test_add_numbers")
		utils.vim_motion("jjjj")
		local test_fn_node = units.get_closest_function()
		assert.truthy(test_fn_node, vim.api.nvim_buf_get_lines(0, 0, -1, false))
		assert.same("test_add_numbers", units.get_function_name(test_fn_node))
	end)

end)

describe("rust-specific", function()

	it("appends unit test with rust filetype", function()
		t.open_test_file("foo.rs")

		units.add_unit_test("test_add_numbers")
        local test_function_node = Query.exec_query_single_result([[
        (function_item
          name: (identifier) @name
          (#eq? @name "test_add_numbers")
        ) @fn]], nil).fn
        assert.is_not.is_nil(test_function_node)
        assert.equals("test_add_numbers", Query.get_name(test_function_node))

	end)

    it("uses existing tests module", function()
        t.open_test_file("rust_with_existing_mod.rs")
        units.add_unit_test("my_cool_test")
        local function plines()
            vim.api.nvim_buf_get_lines(0, 0, -1, false)
        end
        local test_function_node = Query.exec_query_single_result([[
        (function_item
          name: (identifier) @name
          (#eq? @name "my_cool_test")
        ) @fn]], nil).fn
        assert.equals("my_cool_test", Query.get_name(test_function_node))
        local test_mod = Query.get_name(Query.first_ancestor(test_function_node, "mod_item"))
        assert.equals("tests", test_mod, plines())
    end)

end)
