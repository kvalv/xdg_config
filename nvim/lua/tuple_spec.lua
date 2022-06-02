local Tuple = require("tuple")
describe("tuple comparison", function()
    it("less", function()
        assert.is_true (Tuple.new{1,2,3} < Tuple.new{1,2,5})
        assert.is_false ((Tuple.new{1,2,3} < Tuple.new{1,2,2}))
        assert.is_false ((Tuple.new{1,2,3} < Tuple.new{1,2,3}))
    end)
    it("equal", function()
        assert.is_true (Tuple.new{1,2,3} == Tuple.new{1,2,3})
        assert.is_false ((Tuple.new{1,2,3} == Tuple.new{1,7,1}))
    end)
    it("greater-or-equal", function()
        assert.is_true (Tuple.new{1,2,3} >= Tuple.new{1,2,3})
        assert.is_false ((Tuple.new{1,2,3} == Tuple.new{1,1,3}))
    end)
    it("crashes if tuple lengths are different", function()
        assert.has.errors(function()
            return Tuple.new{1,2,3} == Tuple.new{1,2,3,4,5,6,7,8}
        end)
        assert.has.errors(function()
            return Tuple.new{1,2,3} < Tuple.new{}
        end)
    end)
    it("composite check works", function()

        local t =Tuple.new({79, 12}) < Tuple.new({84, 10})
        assert.is_true(t)

    end)
end)