local ls = require("luasnip")
local ts_utils = require("nvim-treesitter.ts_utils")
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

-- dlete from here

-- scans upwards until it finds a node of specific type
local function get_node(type)
    local node = ts_utils.get_node_at_cursor()
    if node == nil then
        error("node not found", 2)
        return
    end
    while node ~= nil do
        if node:type() == type then
            return node
        end
        node = node:parent()
    end
end

-- finds a child node of particular type
local function get_child_node(node, name)
    for child, childName in node:iter_children() do
        if childName == name then
            return child
        end
    end
    return nil
end

-- return a table of strings; the return types, e.g. {"*int", "error"}
local function getReturnTypes(functionNode)
    local resultNode = get_child_node(functionNode, "result")
    if resultNode == nil then
        vim.notify("did not find result node", 3)
        return
    end
    -- if strats with * --then it's a pointer
    -- if it's an error, then return the error
    local returnTypes = {}
    if resultNode:type() == "type_identifier" then
        local text = ts_utils.get_node_text(resultNode)
        P("will return text", text, text[1])
        return { text[1] }
    end
    -- otherwise it's a list of return types, e.g. (int, error)
    for child in resultNode:iter_children() do
        local type = ts_utils.get_named_children(child)[1]
        local text = ts_utils.get_node_text(type)
        if #text > 0 then
            table.insert(returnTypes, text[1])
        end
    end
    return returnTypes
    -- print(vim.inspect(ts_utils.get_node_text(resultNode)))
end

-- returns the default type for various go types
local function typeToDefault(name)
    if vim.startswith(name, "*") then
        return "nil"
    end
    if name == "int" then
        return "0"
    end
    if name == "string" then
        return [[""]]
    end
    if name == "error" then
        return "err" -- here we would return a certain node
    end
    return name .. "{}" -- assume struct
end

local function mymain()
    local node = get_node("function_declaration") or get_node("method_declaration")
    if node == nil then
        vim.notify("did not find node", 3)
        return
    end
    local returnTypes = getReturnTypes(node)
    local nodes = {}
    for index, gotype in ipairs(returnTypes) do
        local default = typeToDefault(gotype)
        local v = nil
        P("default", default, "returnTypes", returnTypes)
        
        if gotype == "error" then
            v = c(1, {
                fmt([[fmt.Errorf("{}: %w", err)]], i(1, "something bad happened")),
                t(default),
            })
        else
            v = t(default)
        end
        table.insert(nodes, v)
        -- are we at the last argument? if not, add separator
        if index < #returnTypes then
            table.insert(nodes, t(", "))
        end
    end
    return nodes
    -- return table.concat(vim.tbl_map(typeToDefault, names), ", ")
end

ls.add_snippets("go", {
    s(
        {trig="ife", priority=1000000},
        fmt(
            [[if err != nil {
    return <retvals>
}
]]           ,
            {
                retvals = d(1, function()
                    return sn(nil, mymain())
                end),
            },
            {
                delimiters = "<>",
            }
        )
    ),
})

vim.keymap.set({ "n" }, "<leader>x", function()
    mymain()
end, {
    silent = true,
})

ls.add_snippets("all", {
    s(
        "curtime",
        f(function()
            return os.date("%D - %H:%M")
        end)
    ),
})

-- fmt_add("svelte", { trig = "input" }, {}, {
-- 	i(1),
-- }, '<input type="{}"/>')

-- fmt_add(
-- 	"svelte",
-- 	{ trig = "finput" },
-- 	{},
-- 	{
-- 		i(1),
-- 		i(2),
-- 		i(3),
-- 	},
-- 	[[
-- <form>
--     {}
--     <input type="{}" {}/>
-- </form>
-- ]]
-- )

-- ls.add_snippets("svelte", {
-- 	s("<@", fmt("<{}>", { i(1, "") }), {
-- 		condition = function()
-- 			local node = sv.first_xml_element_after_cursor()
-- 			local r0, c0, r1, c1 = node:range()
-- 			vim.api.nvim_buf_set_mark(0, "a", r0 + 1, c0, {})
-- 			vim.api.nvim_buf_set_mark(0, "b", r1 + 1, c1, {})
-- 			-- sv.describe(node)

-- 			return true
-- 		end,
-- 		callbacks = {
-- 			[1] = {
-- 				[events.leave] = function(x)
-- 					local tagname = string.match(x:get_text()[1], "(%a+)%s*%a*")
-- 					utils.vim_motion("`a>`b")
-- 					local row1 = vim.api.nvim_buf_get_mark(0, "b")[1]
-- 					local text = string.format(
-- 						"%s%s",
-- 						string.rep(" ", vim.fn.indent(row1)),
-- 						string.format("</%s>", tagname)
-- 					)

-- 					vim.api.nvim_buf_set_lines(0, row1, row1, false, { text })
-- 					utils.vim_motion("g;<<")
-- 				end,
-- 			},
-- 		},
-- 	}),
-- }, {
-- 	type = "autosnippets",
-- })

-- fmt_add("svelte", { trig = "<!" }, { type = "autosnippets" }, {
-- 	f(function()
-- 		local text = vim.fn.getreg(".")
-- 		text, _ = string.gsub(text, "[<>]", "")

-- 		return text
-- 	end, {}, {}),
-- }, "</{}>")
