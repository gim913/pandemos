-- imported modules
local action = require 'engine.action'
local class = require 'engine.oop'
local entities = require 'engine.entities'
local fontManager = require 'engine.fm'
local map = require 'engine.map'
local Vec = require 'hump.vector'
local batch = require 'batch'
local Camera = require 'Camera'
local Level = require 'Level'
local Player = require 'Player'
local S = require 'settings'

-- class
local Game = class('Game')

local player = nil

local function addLevel(levels, rng, depth)
	local l = Level:new(rng, depth)
	table.insert(levels, l)
	return l
end

function Game:ctor(rng)
	self.rng = rng
	self.seed = 0
	self.fatFont = fontManager.get(32)

	self.at = love.graphics.newImage("player.png")

	self.levels = {}
	for depth = 1, S.game.DEPTH do
		addLevel(self.levels, self.rng, depth)
	end

	self.depthLevel = 1
	self.updateLevel = false
	self.doActions = false

	batch.prepare()
	local level = self.levels[self.depthLevel]
	map.init(level.w, level.h)

	local f = math.floor
	player = Player:new(Vec(f(map.width() / 2), map.height()-29))
	entities.add(player)

	camera = Camera:new()
	camera:follow(player)
	camera:update()

	batch.update(camera.followedEnt, camera.pos.x - camera.rel.x, camera.pos.y - camera.rel.y)
end

function Game:handleInput(key)
	local nextAct=action.Action.Blocked, nPos
	if #(player.actions) == 0 then
		if key == "up" or key == "kp8" then
			nextAct,nPos = player:wantGo(Vec( 0,-1))
		elseif key == "kp7" then
			nextAct,nPos = player:wantGo(Vec(-1,-1))
		elseif key == "kp9" then
			nextAct,nPos = player:wantGo(Vec( 1,-1))
		elseif key == "down" or key == "kp2" then
			nextAct,nPos = player:wantGo(Vec( 0, 1))
		elseif key == "kp1" then
			nextAct,nPos = player:wantGo(Vec(-1, 1))
		elseif key == "kp3" then
			nextAct,nPos = player:wantGo(Vec( 1, 1))
		elseif key == "left" or key == "kp4" then
			nextAct,nPos = player:wantGo(Vec(-1, 0))
		elseif key == "right" or key == "kp6" then
			nextAct,nPos = player:wantGo(Vec( 1, 0))
		elseif key == "." or key == "kp5" then
			nextAct,nPos = player:wantGo(Vec( 0, 0))
		end
	end

	if nextAct ~= action.Action.Blocked then
		print('action ', nextAct)
		if nextAct == action.Action.Attack then
			action.queue(player.actions, Player.Bash_Speed, action.Action.Attack, nPos)
		else
			action.queue(player.actions, Player.Base_Speed, action.Action.Move, nPos)
		end
		self.doActions = true
	end
end

function Game:startLevel()
	local level = self.levels[self.depthLevel]
	if not level.visited then
		level:initializeGenerator()
		self.updateLevel = true
	end
end

function Game:update(dt)
	-- keep running level update, until level generation is done
	if self.updateLevel then
		local level = self.levels[self.depthLevel]
		self.updateLevel = level:update(dt)
	end
end

local tileSize = 30

function Game:show()
	if self.updateLevel then
		local level = self.levels[self.depthLevel]
		level:show()
	else
		batch.draw()

		love.graphics.setColor(0.25, 0.25, 0.25, 1.0)

		local scaleFactor = tileSize / self.at:getWidth()
		-- TODO: draw only entities in range
		for _,ent in pairs(entities.all()) do
			local rx = ent.pos.x - camera.pos.x + camera.rel.x
			local ry = ent.pos.y - camera.pos.y + camera.rel.y
			love.graphics.draw(self.at, rx * (tileSize + 1), ry * (tileSize + 1), 0, scaleFactor, scaleFactor)
		end
	end
end

return Game