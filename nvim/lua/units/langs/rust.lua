local Query = require("units.query")

return {
	template = function(func_name, node, root)

        local captures = Query.exec_query([[
        (mod_item
            name: (identifier) @name
            (#eq? @name "tests")
        )
        ]], root)
        if table.len(captures) == 0 then
            -- 
        end

        -- TODO: we want to insert at existing mod tests if it eixsts, otherwise create it
        local lines = {}

		local testline = string.format("fn %s() {", func_name)
		local function indent(s)
			return "    " .. s
		end
		return {
			"mod tests {",
			indent("#[test]"),
			indent(testline),
			indent("    // TODO"),
			indent("}"),
			"}",
		}
	end,
	node = "function_item",
	query = [[
(function_item
  name: (identifier) @name
)
        ]],
}
