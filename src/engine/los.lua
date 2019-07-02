-- imported modules
local map = require 'engine.map'
local elements = require 'engine.elements'
local Vec = require 'hump.vector'

-- module

local function checkVisibility(shadowObjects, pt, initialPos)
	local Seg = pt - initialPos

	local norm = Seg:len()
	for k,v in ipairs(shadowObjects) do
		if v.d < norm then
			-- what we're calculating is  len_p = abs(DOT(Seg, cr)) / len(Seg)
			local t = math.abs(Seg * v.pos) / norm

			-- and now since len_p = DOT(Seg, p) / len(Seg), so
			-- p = len_p * Seg / len(Seg), which is what we calculate below
			if t >= norm then
				return 1
			end
			local p = (t * Seg) / norm

			if (p.x > v.pos.x - 0.5 and p.x < v.pos.x + 0.5) and (p.y > v.pos.y - 0.5 and p.y < v.pos.y + 0.5) then
				return 0
			end
			--print(Seg_X, Seg_Y, ' and ', v.x, v.y, ' -> ', v.d, norm) --t, norm, p_x, p_y)
		end
	end

	return 1
end

-- todo: add parameter for max-d
local function calcVismapSquare(pos, vismap, incX, incY, r2)
	local s = pos:clone()

	local initialPos = s:clone()
	-- print("x: ", sx, sx+ax*12, " y:", sy, sy+ay*12)

	local shadowObjects = {}
	local f = math.floor
	for d=1, 15 do
		local cur = Vec(s.x, s.y + incY*d)
		for i=0, f(d / 2) do
			if map.inside(cur) and (cur - s):len2() < r2 then
				local idx = cur.y * map.width() + cur.x
				local v = map.notPassLight(idx) or elements.notPassLight(idx)
				vismap[idx] = checkVisibility(shadowObjects, cur, initialPos)
				if v then
					table.insert(shadowObjects, { pos = cur - s, d = (cur - s):len() })
				end
			end
			cur.x = cur.x + incX
			cur.y = cur.y - incY
		end
	end

	-- for k,v in ipairs(shadowObjects) do
	-- 	print('shadow ' .. tostring(v.pos))
	-- end

	shadowObjects={}
	for d=1, 15 do
		local cur = Vec(s.x + incX * f(d / 2), s.y + incY * (d - f(d / 2)))

		for i=f(d / 2), d do
			if map.inside(cur) and (cur - s):len2() < r2 then
				local idx = cur.y * map.width() + cur.x
				local v = map.notPassLight(idx) or elements.notPassLight(idx)
				vismap[idx] = checkVisibility(shadowObjects, cur, initialPos)
				if v then
					table.insert(shadowObjects, {pos = cur - s, d = (cur - s):len()})
				end
			end
			cur.x = cur.x + incX
			cur.y = cur.y - incY
		end
	end

end

local los = {
	calcVismapSquare = calcVismapSquare
}

return los
