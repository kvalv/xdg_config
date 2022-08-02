local Query = require("units.query")

return {
	template = function(func_name, node, root)
		local startrow
		local captures = Query.exec_query(
			[[
        (mod_item
            name: (identifier) @name
            (#eq? @name "tests")
        ) @mod
        ]],
			root
		)

		local s
		if #captures == 0 then
			s = string.format(
				[[
mod tests {
    #[test]
    fn %s() {
        // TODO: implement
    }
}
]],
				func_name
			)

			local _, _, rowend, _ = node:range()
			startrow = rowend + 1
		elseif #captures == 1 then
			-- use this one
			s = string.format(
				[[
    #[test]
    fn %s() {
        // TODO: implement
    }
]],
				func_name
			)
			local mod = captures[1].mod
			local _, _, rowend, _ = mod:range()
			startrow = rowend
			print("found module with length 1")
		end

		return vim.split(s, "\n"), startrow
	end,
	node = "function_item",
	query = [[
(function_item
  name: (identifier) @name
)
        ]],
}
