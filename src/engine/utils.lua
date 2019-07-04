-- module

local function utils_deepcopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

local function utils_repr(t)
	local r=""
	for k,v in pairs(t) do
		local tv = type(v)
		if tv ~= "table" then
			if tv == "number"  or tv == "string" then
				r = r .. k .. " " .. v .. ", "
			else
				r = r .. k .. " " .. type(v) .. ", "
			end
		else
			if v ~= t then
				r = r .. k .. " {" .. utils_repr(v) .. "}, "
			else
				r = r .. k .. " {" .. 'self' .. "}, "
			end
		end
	end
	return r
end

local function utils_createGetterSetter(tbl)
	return function(settings)
		local tv = type(settings)
		if tv ~= "table" then
			return tbl[settings]
		else
			for k, v in pairs(settings) do
				tbl[k] = v
			end
		end
	end
end

local function utils_randPercent(rng, value)
	return rng:random(1, 100) - 1 < value
end

local utils = {
	deepcopy = utils_deepcopy
	, repr = utils_repr
	, randPercent = utils_randPercent
	, createGetterSetter = utils_createGetterSetter
}

return utils
