local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local Files = require("orgmode.parser.files")

local M = {}

local clock_in_selected_item = function()
	local item = action_state.get_selected_entry().value
	local active_headline = Files.get_clocked_headline()
	if active_headline == nil then
		-- P(item.value)
		item:clock_in()
		print("OK clocked in '" .. item.title .. "'")
	else
		if active_headline:is_clocked_in() then
			active_headline:clock_out()
		end
		item:clock_in()
		print("OK clocked in '" .. item.title .. "'")
	end
end

M.telescope_select_todo = function(opts)
	opts = opts or {}
	local items = require("orgmode.agenda.views.todos"):new():build().items
	pickers.new(opts, {
		prompt_title = "pls pick a color",
		finder = finders.new_table({
			results = items,
			entry_maker = function(entry)
				-- P(entry.todo_keyword)
				return {
					value = entry,
					ordinal = entry.title,
					display = string.format("%s %s", entry.todo_keyword.value, entry.title),
				}
			end,
		}),
		sorter = conf.generic_sorter(opts),
		attach_mappings = function(prompt_bufnr, map)
			map("i", "<c-i>", clock_in_selected_item)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				vim.cmd("edit " .. vim.fn.fnameescape(selection.value.file))
				vim.fn.cursor(selection.value.range.start_line, 0)
				selection.value:clock_in()
			end)
			return true
		end,
	}):find()
end

vim.api.nvim_set_keymap(
	"n",
	"st",
	[[<cmd>lua require('org_utils').telescope_select_todo(require("telescope.themes").get_ivy({}))<CR>]],
	{ noremap = true, silent = true }
)
-- M.telescope_select_todo()
return M
