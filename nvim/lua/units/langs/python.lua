return {
	template = function(func_name)
		return {
			string.format("def %s():", func_name),
			"    pass  # TODO",
		}
	end,

	node = "function_definition",
	query = [[
(function_definition
  name: (identifier) @name
)
        ]],
}
