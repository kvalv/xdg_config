local ls = require("luasnip")
-- some shorthands...
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local l = require("luasnip.extras").lambda
local rep = require("luasnip.extras").rep
local p = require("luasnip.extras").partial
local m = require("luasnip.extras").match
local n = require("luasnip.extras").nonempty
local dl = require("luasnip.extras").dynamic_lambda
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local types = require("luasnip.util.types")
local conds = require("luasnip.extras.expand_conditions")
local events = require("luasnip.util.events")

local utils = require("utils")
local sv = require("svelte_textobjects")

ls.cleanup()

local g = vim.api.nvim_create_augroup("g", { clear = true })
vim.api.nvim_create_autocmd("BufWritePost", {
	pattern = "snippets.lua",
	callback = function()
		require("utils").reload("snippets")
		print("snippets file has been reloaded")
	end,
	group = g,
	desc = "aaa",
})

types = require("luasnip.util.types")

ls.config.set_config({
	history = true,
	updateevents = "TextChanged,TextChangedI",
	enable_autosnippets = true,
})

vim.keymap.set({ "i", "s" }, "<c-j>", function()
	if ls.expand_or_jumpable() then
		ls.expand_or_jump()
	end
end, {
	silent = true,
})

vim.keymap.set({ "i", "s" }, "<c-k>", function()
	if ls.jumpable(-1) then
		ls.jump(-1)
	end
end, { silent = true })

vim.keymap.set({ "i" }, "<c-l>", function()
	if ls.choice_active() then
		ls.change_choice(1)
	end
end, { silent = true })

vim.keymap.set({ "i" }, "<c-u>", function()
	require("luasnip.extras.select_choice")()
end, { silent = true })

-- If you're reading this file for the first time, best skip to around line 190
-- where the actual snippet-definitions start.

-- Every unspecified option will be set to the default.
ls.config.set_config({
	history = true,
	-- Update more often, :h events for more info.
	update_events = "TextChanged,TextChangedI",
	-- Snippets aren't automatically removed if their text is deleted.
	-- `delete_check_events` determines on which events (:h events) a check for
	-- deleted snippets is performed.
	-- This can be especially useful when `history` is enabled.
	delete_check_events = "TextChanged",
	ext_opts = {
		[types.choiceNode] = {
			active = {
				virt_text = { { "choiceNode", "Comment" } },
			},
		},
	},
	-- treesitter-hl has 100, use something higher (default is 200).
	ext_base_prio = 300,
	-- minimal increase in priority.
	ext_prio_increase = 1,
	enable_autosnippets = true,
	-- mapping for cutting selected text so it's usable as SELECT_DEDENT,
	-- SELECT_RAW or TM_SELECTED_TEXT (mapped via xmap).
	store_selection_keys = "<Tab>",
	-- luasnip uses this function to get the currently active filetype. This
	-- is the (rather uninteresting) default, but it's possible to use
	-- eg. treesitter for getting the current filetype by setting ft_func to
	-- require("luasnip.extras.filetype_functions").from_cursor (requires
	-- `nvim-treesitter/nvim-treesitter`). This allows correctly resolving
	-- the current filetype in eg. a markdown-code block or `vim.cmd()`.
	ft_func = function()
		return vim.split(vim.bo.filetype, ".", true)
	end,
})

-- args is a table, where 1 is the text in Placeholder 1, 2 the text in
-- placeholder 2,...
local function copy(args)
	return args[1]
end

-- 'recursive' dynamic snippet. Expands to some text followed by itself.
local rec_ls
rec_ls = function()
	return sn(
		nil,
		c(1, {
			-- Order is important, sn(...) first would cause infinite loop of expansion.
			t(""),
			sn(nil, { t({ "", "\t\\item " }), i(1), d(2, rec_ls, {}) }),
		})
	)
end

-- Make sure to not pass an invalid command, as io.popen() may write over nvim-text.
local function bash(_, _, command)
	local file = io.popen(command, "r")
	local res = {}
	for line in file:lines() do
		table.insert(res, line)
	end
	return res
end

-- Returns a snippet_node wrapped around an insert_node whose initial
-- text value is set to the current date in the desired format.
local date_input = function(args, snip, old_state, fmt)
	local fmt = fmt or "%Y-%m-%d"
	return sn(nil, i(1, os.date(fmt)))
end

--- returns a function that creates input nodes for each argument
--this can be used in a dynamic node: `d(1, param_split(), {2})`
local function node_split(pattern)
	return function(args)
		local _, count = string.gsub(args[1][1], pattern, pattern)
		if #args[1][1] > 0 then
			count = count + 1
		end
		local nodes = {}
		for idx = 1, count do
			table.insert(nodes, i(idx, "v"))
			if idx ~= count then
				table.insert(nodes, t(", "))
			end
		end
		if #nodes == 0 then
			return sn(nil, { t("empty...") })
		end
		return sn(nil, nodes)
	end
end

--- @param trig string | table passed in to s()
local function fmt_add(ft, trig, opts, nodes, format_str)
	ls.add_snippets(ft, { s(trig, fmt(format_str, nodes)) }, opts)
end

--- adds a comment as virtual text when the node is active
-- returns a table, you might want to do tbl_deep_extend if you also
-- have other options passed to a node
--
-- example: `i(1, "hello", node_describe"this is a nice description for the node")`
local function node_describe(text)
	return { node_ext_opts = { active = { virt_text = { { text, "Comment" } } } } }
end

fmt_add(
	"lua",
	"fori",
	{},
	{ i(1, "i"), i(2, "lower", node_describe("inclusive")), i(3, "upper", node_describe("inclusive")), i(4, "body...") },
	[[
for {}={},{} do
    {}
end
]]
)

fmt_add(
	"sql",
	"fn",
	{ callbacks = { [2] = {
		[events.leave] = function(node)
			print("2!!!")
		end,
	} } },
	{
		c(1, { t("FUNCTION"), t("OR REPLACE FUNCTION") }),
		i(2, "fn_name", node_describe("remember () at end, e.g. 'myfunction()'")),
		c(3, { t("void"), t("TRIGGER"), t("record"), i(nil, "return_type") }),
		i(4, "--body..."),
		-- i(3, "Surname"),
		-- name = i(1, "name"),
	},
	[[
CREATE {1} {2} RETURNS {3}
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
    {4}
END;
$$;
]]
)
fmt_add(
	"sql",
	{ trig = "trigger", dscr = "create a new trigger" },
	{},
	{
		i(1, "name"),
		c(2, { t("BEFORE"), t("AFTER"), t("INSTEAD OF") }),
		c(3, { t("INSERT"), t("UPDATE"), t("DELETE"), t("TRUNACTE") }),
		i(4, "table_name"),
		c(5, { t("FOR EACH ROW"), t("FOR EACH STATEMENT"), t("") }),
		i(6, "function_name"),
		i(7, "arguments"),
	},
	[[
CREATE OR REPLACE TRIGGER {1} {2} {3} ON {4}
{5}
EXECUTE FUNCTION {6}({7})
]]
)

fmt_add(
	"sql",
	"if",
	{},

	{
		i(1, "condition..."),
		i(2, "body.."),
	},
	[[
IF {1} THEN
    {2}
END IF;
]]
)

fmt_add(
	"sql",
	"fk",
	{},
	{
		i(1, "type_name", node_describe("e.g. order_id integer")),
		i(2, "foreign_table"),
		i(3, "id"),
	},
	[[
{} REFERENCES {} ({})
]]
)

fmt_add(
	"sql",
	"ctable",
	{},
	{
		i(1, "table_name"),
	},
	[[
CREATE TABLE {} (

);
    ]]
)

fmt_add(
	"sql",
	"insert",
	{},
	{
		i(1, "table_name"),
		i(2, "params"),
		-- i(3, "todo"),
		d(3, node_split(","), { 2 }),
	},
	[[
INSERT INTO {} ({})
VALUES ({});
]]
)

fmt_add(
	"sql",
	"update",
	{},
	{
		i(1, "table_name"),
		i(2, "", node_describe("column_name = expression [...]")),
		c(3, { { t("WHERE "), i(1, "condition") }, t("") }),
	},
	[[
UPDATE {} SET {}
{}
]]
)

fmt_add(
	"sql",
	"foo",
	{},
	{
		i(1, "x"),
		d(2, node_split(","), { 1 }),
	},
	[[
text: {}
copy: {}
    ]]
)

fmt_add(
	"sql",
	{ trig = "pr", dscr = "print a notification / error" },
	{},
	{ c(1, { t("INFO"), t("DEBUG"), t("LOG"), t("NOTICE"), t("WARNING"), t("EXCEPTION") }), i(2, "text...") },
	"RAISE {1} '{2}';"
)

fmt_add(
	"sql",
	{ trig = "enable rls", dscr = "enable row level security for table" },
	{},
	{ i(1, "table_name") },
	"ALTER TABLE {} ENABLE ROW LEVEL SECURITY;"
)

fmt_add(
	"sql",
	{ trig = "create policy" },
	{},

	{
		i(1, "description", node_describe("prefer to use a sentence here, not a single word")),
		i(2, "table_name"),
		c(3, { t("ALL"), t("SELECT"), t("INSERT"), t("UPDATE"), t("DELETE") }),
		c(4, { t("PUBLIC"), i(nil, "role_name", node_describe("e.g. 'admin'")) }),
		i(5, "using_expression", node_describe("use WITH CHECK (...) if INSERT/UPDATE")),
	},
	[[
CREATE POLICY {} ON {}
FOR {}
TO {}
USING ({})
]]
)

fmt_add("sql", { trig = "cc", dscr = "add column constraint" }, {}, {
	c(1, {
		t("NOT NULL"),
		sn(nil, { t("CHECK ("), i(1, "expr"), t(")") }),
		sn(nil, { t("REFERENCES "), i(1, "reftable"), c(2, { fmt("({})", i(1, "ids")), t("") }) }),
	}),
}, "{}")

fmt_add(
	"typescript",
	{ trig = "fn_get", dscr = "makes a get endpoint" },
	{},
	{
		f(function()
			return vim.fn.expand("%:t:r") -- # /foo/id/[aa].ts -> [aa]
			-- return vim.fn.expand("%")
		end, {}),
		i(0),
	},
	[[
/** @type {{import('./__types/{}').RequestHandler}} */
export async function get() {{
  return {{
    status: 200,
    body: {{
      {}
    }}
  }};
}}
]]
)

fmt_add("svelte", { trig = "input" }, {}, {
	i(1),
}, '<input type="{}"/>')

fmt_add(
	"svelte",
	{ trig = "finput" },
	{},
	{
		i(1),
		i(2),
		i(3),
	},
	[[
<form>
    {}
    <input type="{}" {}/>
</form>
]]
)

fmt_add("svelte", { trig = "bind" }, {}, {
	i(1),
	i(2),
}, "bind:{}={{{}}}")

fmt_add("svelte", { trig = "class" }, {}, {
	i(1),
}, 'class="{}"')

ls.add_snippets("svelte", {
	s("<@", fmt("<{}>", { i(1, "") }), {
		condition = function()
			local node = sv.first_xml_element_after_cursor()
			local r0, c0, r1, c1 = node:range()
			vim.api.nvim_buf_set_mark(0, "a", r0 + 1, c0, {})
			vim.api.nvim_buf_set_mark(0, "b", r1 + 1, c1, {})
			-- sv.describe(node)

			return true
		end,
		callbacks = {
			[1] = {
				[events.leave] = function(x)
					local tagname = string.match(x:get_text()[1], "(%a+)%s*%a*")
					utils.vim_motion("`a>`b")
					local row1 = vim.api.nvim_buf_get_mark(0, "b")[1]
					local text = string.format(
						"%s%s",
						string.rep(" ", vim.fn.indent(row1)),
						string.format("</%s>", tagname)
					)

					vim.api.nvim_buf_set_lines(0, row1, row1, false, { text })
					utils.vim_motion("g;<<")
				end,
			},
		},
	}),
}, {
	type = "autosnippets",
})

fmt_add("svelte", { trig = "<!" }, { type = "autosnippets" }, {
	f(function()
		local text = vim.fn.getreg(".")
		text, _ = string.gsub(text, "[<>]", "")

		return text
	end, {}, {}),
}, "</{}>")
