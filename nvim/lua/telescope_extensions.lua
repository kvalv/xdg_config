local pickers = require("telescope.pickers")
local sorters = require "telescope.sorters"
local actions = require("telescope.actions")
local previewers = require "telescope.previewers"
local finders = require("telescope.finders")
local conf = require("telescope.config").values
-- local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local utils = require("utils")

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

local function telescope_config_files(opts)
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
local function packer_lua_files()
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


local function remove_cache_entry(branch, fname, cachefile)
    local entry = string.format("%s %s", branch, fname)
    local modified = vim.tbl_filter(function(line) return line ~= entry end, vim.fn.readfile(cachefile))
    vim.fn.writefile(modified, cachefile)
end
local function ignore_cache_entry(branch, fname, cachefile)
    local entry = string.format("%s %s -", branch, fname)
    remove_cache_entry(branch, fname, cachefile)
    vim.fn.writefile({ entry }, cachefile, "a")
end
local function add_cache_entry(branch, fname, cachefile)
    local entry = string.format("%s %s", branch, fname)
    remove_cache_entry(branch, fname, cachefile) -- ensure it's gone first...
    vim.fn.writefile({ entry }, cachefile, "a")
    -- vim.fn.writefile({ branch .. " " .. path }, vim.env.HOME .. "/.cache/branch-files", "a")
end
local cachefile = vim.env.HOME .. "/.cache/branch-files"

local key = "branch" -- store here to keep value between calls
local function git_diffed_files()
    local opts = {}
    local commands = {
        dirty = "git diff --name-only --diff-filter=AM",
        -- branch-files
        -- is defined as `git log origin/master.. --name-only | tac | awk '/^$/ { exit; } {print $0}'`
        branch = "git branch-files"
    }
    local command_list = vim.split(commands[key], " ")
    opts.layout_strategy = "vertical"
    local branch = vim.fn.systemlist("git rev-parse --abbrev-ref HEAD")[1]
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
        previewer = require("telescope.previewers.term_previewer").new_termopen_previewer({
            get_command = function(entry)
                return "git diff origin/master  " .. entry.value
            end
        }),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, map)
            map("i", "<del>", function()
                local fname = action_state.get_selected_entry().value
                local relative_path = string.sub(fname, #TOPD + 2)
                ignore_cache_entry(branch, relative_path, cachefile)
            end)
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
    git_diffed_files()
end)
vim.keymap.set("n", "<leader>hm", function()
    local branch = vim.fn.systemlist("git rev-parse --abbrev-ref HEAD")[1]
    local path = vim.fn.expand("%")
    add_cache_entry(branch, path, cachefile)
    -- vim.fn.writefile({ branch .. " " .. path }, vim.env.HOME .. "/.cache/branch-files", "a")
end)


local function live_grep_git_files(opts)
    opts = opts or {}
    opts.cwd = opts.cwd and vim.fn.expand(opts.cwd) or vim.loop.cwd()
    opts.layout_strategy = opts.layout_strategy or "vertical"

    local finder = finders.new_job(function(prompt) return { "live-grep-branch", prompt } end,
        function(line)
            -- keys: file, line, text
            local data = vim.json.decode(line)
            local displayFile = string.gsub(data.file, "^" .. opts.cwd .. "/", "")
            if string.len(displayFile) > 50 then
                displayFile = "..." .. string.sub(displayFile, -50)
            end

            return {
                valid = true,
                value = line,
                ordinal = line,
                path = data.file,
                lnum = data.line,
                display = displayFile .. ":" .. data.line .. "  " .. data.text,
            }
        end,
        opts.cwd
    )

    pickers
        .new(opts, {
            prompt_title = "git branch-files",
            finder = finder,
            previewer = previewers.vimgrep.new(opts),
            sorter = sorters.highlighter_only(opts),
            attach_mappings = function(_, map)
                map("i", "<c-space>", actions.to_fuzzy_refine)
                return true
            end,
        })
        :find()
end

vim.keymap.set("n", "<leader>sd", function() live_grep_git_files() end, { noremap = true, silent = true, })

local function git_checkout()
    local opts = {}
    pickers.new(opts, {
        finder = finders.new_oneshot_job(vim.split("ig mine", " "), opts),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr)
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
    git_checkout()
end)


vim.keymap.set("n", "zl", function()
    require("utils").vim_motion(":write")
    require("utils").reload("telescope_extensions")
end)

vim.keymap.set("n", "<leader>g", function()
    local topd = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
    if topd == nil then
        vim.notify("not a git repo", vim.log.levels.ERROR)
        return
    end
    local fname = string.gsub(vim.fn.expand("%"), topd .. "/", "")
    local modified = string.gsub(string.gsub(fname, "/", "\\/"), ".", "\\.")
    require("utils").vim_motion(":G")
    vim.cmd("only")
    -- -- replace / with \/ in fname
    vim.pretty_print("will go to: " .. modified)
    require("utils").vim_motion("/" .. modified)

    vim.fn.timer_start(100, function()
        require("utils").vim_motion("=")
    end)
end, { nowait = true })

vim.keymap.set("n", "<leader>sc", function()
    telescope_config_files()
end, {
    noremap = true,
    silent = true,
})
vim.keymap.set("n", "<leader>sl", function()
    packer_lua_files()
end, {
    noremap = true,
    silent = true,
})
