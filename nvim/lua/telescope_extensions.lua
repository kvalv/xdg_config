local pickers = require("telescope.pickers")
local sorters = require "telescope.sorters"
local actions = require("telescope.actions")
local previewers = require "telescope.previewers"
local make_entry = require "telescope.make_entry"
local finders = require("telescope.finders")
local conf = require("telescope.config").values
-- local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
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
    opts.cwd = XDG_CONFIG_HOME

    opts.entry_maker = function(e)
        local display = path_relative_to(e, ".config") or e
        return {
            display = display,
            value = opts.cwd .. "/" .. e,
            ordinal = e,
        }
    end
    pickers.new(opts, {
        prompt_title = "config files",
        finder = finders.new_oneshot_job({ "git", "-C", XDG_CONFIG_HOME, "ls-files" }, opts),
        previewer = conf.file_previewer(opts),
        sorter = conf.generic_sorter(opts),
    }):find()
end

-- TODO: I want a telescope for finding lua files ;  -- is the root directory
M.packer_lua_files = function()
    require("telescope.builtin").find_files({
        search_dirs = { vim.env.HOME .. "/.local/share/nvim/site/pack/packer/start", "/usr/share/nvim/runtime/lua" },
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

M.special_files = function(opts)
    opts = opts or {}
    opts.cwd = "/home/mikael/src/main.git/elastic-fields"

    local patterns = {
        services = {
            pat = "./**/service/models.go",
        },
        django = {
            pat = './**/models.py',
            -- display = function(e) return vim.fn.fnamemodify(e, ":h:t") end,
        }
    }

    local entry = patterns.django

    -- opts.bufnr = vim.fn.bufnr('%')
    -- opts.entry_maker = make_entry.gen_from_ctags(opts)
    opts.entry_maker = function(e)
        local j = vim.fn.json_decode(e)
        if (j._type == "ptag") then
            return nil
        end
        -- P(j)
        return {
            display = string.format("%-50s %s", j.name, j.path),
            value = e,
            ordinal = j.name,
            lnum = j.line,
            path = j.path,
            scode = j.pattern,
        }

    end

    local command_list = vim.split("cat mytags", " ")
    pickers.new(opts, {
        prompt_title = "service files",
        finder = finders.new_oneshot_job(command_list, opts),
        previewer = require('telescope.config').values.grep_previewer({}),
        -- previewer = conf.file_previewer(opts),
        sorter = conf.generic_sorter(opts),
    }):find()
end

local key = "branch" -- store here to keep value between calls
M.git_diffed_files = function()
    local opts = {}
    local commands = {
        dirty = "git diff --name-only --diff-filter=AM",
        -- branch-files is defined as `git log origin/master.. --name-only | tac | awk '/^$/ { exit; } {print $0}'`
        branch = "git branch-files"
    }
    local command_list = vim.split(commands[key], " ")
    opts.layout_strategy = "vertical"
    local TOPD = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
    opts.entry_maker = function(e)
        return {
            display = e,
            value = TOPD .. "/" .. e,
            ordinal = e,
        }
    end
    pickers.new(opts, {
        prompt_title = key,
        finder = finders.new_oneshot_job(command_list, opts),
        previewer = require("telescope.previewers.term_previewer").new_termopen_previewer({ get_command = function(entry)
            return "git diff origin/master  " .. entry.value
        end }),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, map)
            map("i", "<tab>", function()
                if key == "dirty" then
                    key = "branch"
                else
                    key = "dirty"
                end
                local p = action_state.get_current_picker(prompt_bufnr)
                p:refresh(finders.new_oneshot_job(vim.split(commands[key], " "), opts))
            end)
            return true
        end,
    }):find()
end
vim.keymap.set("n", "<leader>d", function()
    M.git_diffed_files()
end)
vim.keymap.set("n", "<leader>hm", function()
    local branch = vim.fn.systemlist("git rev-parse --abbrev-ref HEAD")[1]
    local path = vim.fn.expand("%")
    vim.fn.writefile({ branch .. " " .. path }, vim.env.HOME .. "/.cache/branch-files", "a")
end)


local function live_grep_git_files(opts)
    opts = opts or {}
    opts.cwd = opts.cwd and vim.fn.expand(opts.cwd) or vim.loop.cwd()
    local files = vim.fn.systemlist("git branch-files")
    local live_grepper = finders.new_job(function(prompt)
        P("prompt", prompt, "files", files)
        if not prompt or prompt == "" then
            return nil
        end
        return vim.tbl_flatten { prompt, files }
    end, opts.entry_maker or make_entry.gen_from_file(opts), opts.max_results, opts.cwd)
    pickers
        .new(opts, {
            prompt_title = "git branch-files",
            finder = live_grepper,
            previewer = conf.grep_previewer(opts),
            -- TODO: It would be cool to use `--json` output for this
            -- and then we could get the highlight positions directly.
            sorter = sorters.highlighter_only(opts),
            attach_mappings = function(_, map)
                map("i", "<c-space>", actions.to_fuzzy_refine)
                return true
            end,
        })
        :find()
end

vim.keymap.set("n", "<leader>sd", function() live_grep_git_files() end, { noremap = true, silent = true, })

M.git_checkout = function()
    local opts = {}
    pickers.new(opts, {
        finder = finders.new_oneshot_job(vim.split("ig mine", " "), opts),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                local line = selection[1]
                local branch = vim.split(line, " ")[1]
                vim.cmd("Git checkout " .. branch)
            end)
            return true
        end
    }):find()
end
vim.keymap.set("n", "<leader>gc", function()
    M.git_checkout()
end)


-- TODO: I want a telescope for finding lua files ;  -- is the root directory
M.py3rdpartyfiles = function()
    require("telescope.builtin").find_files({
        find_command = vim.split("rg --smart-case --files --color never ", " "),
        search_dirs = { vim.env.VIRTUAL_ENV },
        entry_maker = function(e)
            local display = path_relative_to(e, vim.env.VIRTUAL_ENV) or e
            display = e
            return {
                display = display,
                value = e,
                ordinal = e,
            }
        end,
    })
end


vim.keymap.set("n", "zl", function()
    require("utils").vim_motion(":write")
    require("utils").reload("telescope_extensions")
    M.special_files()
end)

return M
