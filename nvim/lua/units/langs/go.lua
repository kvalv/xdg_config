return {
	template = function(func_name, _, _)
		return {
			string.format("func %s(t *testing.T) {", func_name),
			"    // TODO",
			"}",
		}
	end,
	node = "function_declaration",
	query = [[
(function_declaration
  name: (identifier) @name
)
        ]],
}
