return {
	template = function(func_name, node, _)
		local _, _, rowend, _ = node:range()
		local lines = {
			string.format("func %s(t *testing.T) {", func_name),
			"    // TODO",
			"}",
		}
        return lines, rowend + 1
	end,
	node = "function_declaration",
	query = [[
(function_declaration
  name: (identifier) @name
)
        ]],
}
