-- imported modules
local entities = require 'engine.entities'
local los = require 'engine.los'
local map = require 'engine.map'

-- module
local fov = {}

fov.name = 'fov'

-- max LoS radius, modify if required
-- every entity must have los below this value
local Max_Los_Radius = 24
local Max_Los_Radius_2 = Max_Los_Radius * Max_Los_Radius

function fov.init(ent)
	ent.vismap = {}
	ent.seemap = {}
end

function fov.recalcVisMap(ent)
	if not ent.doRecalc then
		return
	end

	--print('calc' .. ent.name)

	local r = ent.losRadius
	local r2 = r*r

	local idx = ent.pos.y * map.width() + ent.pos.x

	ent.vismap = {}
	ent.vismap[idx] = 1

	los.calcVismapSquare(ent.pos, ent.vismap, -1,  1, r2)
	los.calcVismapSquare(ent.pos, ent.vismap, -1, -1, r2)
	los.calcVismapSquare(ent.pos, ent.vismap, 1,  1, r2)
	los.calcVismapSquare(ent.pos, ent.vismap, 1, -1, r2)
end

-- NOTE: seemap only contains ents in seeDist range, not all ents
function fov.checkEntVis(ent, oth, dist)
	if dist <= ent.seeDist then
		local idx = oth.pos.y * map.width() + oth.pos.x
		--console.log(' vis ' .. tostring(ent) .. ' -- ' .. tostring(oth) .. " " .. idx .. " : " .. tostring(ent.vismap[idx]))
		if ent.vismap[idx] and ent.vismap[idx] > 0 then
			ent.seemap[oth] = 1
		else
			ent.seemap[oth] = nil
		end
	else
		if ent.seemap[oth] then
			ent.seemap[oth] = nil
		end
	end
end

function fov.recalcSeeMap(ent)
	if not ent.doRecalc then
		return
	end

	-- TODO: should there be some Attr?
	--console.log('recalc for: ' .. ent.name)
	for _,e in pairs(entities.all()) do
		if e ~= ent then
			local d2 = (e.pos - ent.pos):len2()
			-- entity can go out of distance, so need to make it larger...
			if d2 < Max_Los_Radius_2 then
				local d = math.sqrt(d2)
				fov.checkEntVis(ent, e, d)
				fov.checkEntVis(e, ent, d)
			end
		end
	end

	ent.doRecalc = false
end

return fov
