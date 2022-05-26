local Tuple = {}

Tuple.mt = {}

Tuple.new = function(o)
    local out = vim.tbl_extend("keep", o, {})
    setmetatable(out, Tuple.mt)
    return out
end

local function ensure_matching_tuple_lengths(arr1, arr2)
    if #arr1 ~= #arr2 then
        error(string.format("expected same tuple length, got %s and %s", arr1, arr2))
    end
end
Tuple.mt.__lt = function(arr1, arr2)
    ensure_matching_tuple_lengths(arr1, arr2)
    for i = 1, #arr1 do
        if arr1[i] < arr2[i] then
            return true
        end
        if arr1[i] > arr2[i] then
            return false
        end
    end
    if arr1[#arr1] == arr2[#arr2] then
        return false
    end
    return true
end

Tuple.mt.__gt = function(arr1, arr2)
    ensure_matching_tuple_lengths(arr1, arr2)
    for i = 1, #arr1 do
        if arr1[i] < arr2[i] then
            return false
        end
    end
    if arr1[#arr1] == arr2[#arr2] then
        return false
    end
    return true
end

Tuple.mt.__eq = function(arr1, arr2)
    ensure_matching_tuple_lengths(arr1, arr2)
    for i = 1, #arr1 do
        if arr1[i] ~= arr2[i] then
            return false
        end
    end
    return true
end

Tuple.mt.__le = function(arr1, arr2)
    return (arr1 < arr2) or (arr1 == arr2)
end

Tuple.mt.__ge = function(arr1, arr2)
    return (arr1 > arr2) or (arr1 == arr2)
end




return Tuple
