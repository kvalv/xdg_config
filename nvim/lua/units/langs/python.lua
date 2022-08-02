return {
	template = function(func_name, node, _)
		local _, _, rowend, _ = node:range()
		local lines = {
			string.format("def %s():", func_name),
			"    pass  # TODO",
		}
		return lines, rowend + 1
	end,

	node = "function_definition",
	query = [[
(function_definition
  name: (identifier) @name
)
        ]],
}
