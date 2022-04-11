local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
-- local actions = require("telescope.actions")
-- local action_state = require("telescope.actions.state")
local utils = require("utils")
local Path = require("plenary.path")

M = {}

local XDG_CONFIG_HOME = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/" .. ".config")

--- replace `p` to be relative to a new root path
--
-- e.g. `path_relative_to('/foo/bar/baz/ok/cool', 'bar') --> 'baz/ok/cool'`
--
-- if the root is not in the path, nil is returned
local function path_relative_to(p, root)
	local parts = vim.split(p, "/", { plain = true })
	local index = utils.tbl_index(parts, function(e)
		return e == root
	end)
	if index == nil then
		return nil
	end
	return utils.join(utils.partition(parts, index + 1), "/")
end

M.telescope_config_files = function(opts)
	opts = opts or {}
	local lookup_file = XDG_CONFIG_HOME .. "/" .. "files.txt"
	local files = vim.fn.readfile(lookup_file)
	local filtered_files = vim.tbl_filter(function(f)
		if not Path:new(f):exists() then
			utils.log.warn(string.format("file '%s' doesn't exist but is listed in '%s'. Ignoring.", f, lookup_file))
			return false
		end
		return true
	end, files)

	pickers.new(opts, {
		prompt_title = "config files",
		finder = finders.new_table({
			results = filtered_files,
			entry_maker = function(e)
				local display = path_relative_to(e, ".config") or e
				return {
					display = display,
					value = e,
					ordinal = e,
				}
			end,
		}),
		sorter = conf.generic_sorter(opts),
	}):find()
end

-- TODO: I want a telescope for finding lua files ;  -- is the root directory
M.packer_lua_files = function()
	require("telescope.builtin.files").find_files({
		search_dirs = { vim.env.HOME ..  "/.local/share/nvim/site/pack/packer/start" },
		entry_maker = function(e)
			local display = path_relative_to(e, "start") or e
			return {
				display = display,
				value = e,
				ordinal = e,
			}
		end,
	})
end
return M
