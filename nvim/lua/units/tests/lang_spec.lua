local LangInfo = require("units.langs")
describe("langinfo", function()
	it("raises exception for illegal config", function()
		assert.has.errors(function()
			local o = LangInfo:new({})
            P(o)
		end)
	end)

    it("doesnt raise exception for config with ok keys", function()
        assert.is.truthy(LangInfo:new({template={}, node="", query=""}))
    end)

    it("correctly validates existing language configs", function()
        LangInfo:new(require("units.langs.python"))
        LangInfo:new(require("units.langs.go"))
    end)
end)
