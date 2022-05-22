---@class LangInfo
---@field template function that returns a list of strings
---@field node string
---@field query string
local LangInfo = {}
LangInfo.__index = LangInfo

function LangInfo:validate_setting(setting)
    if self[setting] == nil then
        error(string.format("Error when validating LangInfo field. Field '%s' is missing on LangInfo object", setting))
    end
end

function LangInfo:validate()
    self:validate_setting("template")
    self:validate_setting("node")
    self:validate_setting("query")
end

function LangInfo:new(opts)
    local o = {}

    local obj = vim.tbl_extend("force", o, opts)
    setmetatable(obj, LangInfo)
    obj:validate()
    return obj

end


return LangInfo
