-- title:  game title
-- author: game developer
-- desc:   short description
-- script: lua

---
-- GLOBALS
---
TR_COLOR = 7
CELL = 8
SOLIDS = {[6]=true, [7]=true, [22]=true, [23]=true}

map_w, map_h = 29, 16
map_x, map_y = 0, 0


function map_right() map_x = map_x + map_w end
function map_left() map_x = map_x - map_w end
function map_up() map_y = map_y - map_h end
function map_down() map_y = map_y + map_h end

----
-- INTERNAL STUFF
----
local class = {}
class.__index = class

function class:new() end

function class:extends()
	local cls = {}
	cls["__call"] = class.__call
	cls.__index = cls
	cls.base = self
	setmetatable(cls, self)
	return cls
end

function class:__call(...)
	local inst = setmetatable({}, self)
	inst:new(...)
	return inst
end

-- Entity Manager
local em = class:extends()

function em:new()
	self.entities = {}
end

function em:set_world(world)
  	self.world = world
end

function em:add(ent)
	table.insert(self.entities, ent)
end

function em:update(dt)
	for i = #self.entities, 1, -1 do
		if self.entities[i] ~= nil then
	  		if self.entities[i].remove then
	    		table.remove(self.entities, i)
	  		else
	    		self.entities[i]:update(dt)
	  		end
		end
	end
end

function em:draw()
	for i = #self.entities, 1, -1 do
		self.entities[i]:draw()
	end
end

-- Scene Manager
local sm = {
	current = nil,
	scenes  = {}
}

function sm:add(scenes)
	assert(scenes ~= nil and type(scenes) == "table", "sm:add expects a table")
	for k,v in pairs(scenes) do
		self.scenes[k] = v
	end
end

function sm:switch(scene)
	assert(self.scenes[scene], "Cannot switch to scene '" .. scene .. "' because it doesn't exist")
	self.current = self.scenes[scene]
	self.current:on_enter()
end

function sm:update(dt) self.current:update(dt)  end
function sm:draw()     self.current:draw()      end

-- Scene class
local scene = class:extends()

function scene:new()
  self.entity_mgr = em()
end

function scene:on_enter() end

function scene:update()
  self.entity_mgr:update()
end

function scene:draw()
  self.entity_mgr:draw()
end

-- Entity class

local entity = class:extends()

function entity:new(x, y)
	self.x = x or 0
	self.y = y or 0
	self.speed = 1
	self.dir = 3
	self.visible = true
end

function entity:update()
end

function entity:draw()
	if self.visible then
		spr(self.sprite[1], self.x, self.y, TR_COLOR)
		spr(self.sprite[2], self.x+CELL, self.y, TR_COLOR)
		spr(self.sprite[3], self.x, self.y+CELL, TR_COLOR)
		spr(self.sprite[4], self.x+CELL, self.y+CELL, TR_COLOR)
	end
end
----
-- GAME STUFF
---
local player = entity:extends()
function player:new(...)
	player.base.new(self, ...)
	self.sprite = {256, 257, 272, 273}
end

function player:move(dir)
	-- the true position of our hitbox
	local hitbox_y = self.y+8

	local newx, newy, tile
	-- up
	if dir == 1 then
		newy = hitbox_y - self.speed
		tile = mget(self.x/8, newy/8)
		if not SOLIDS[tile] then self.y = self.y - self.speed end
	-- right
	elseif dir == 2 then
		newx = self.x + self.speed
		tile = mget((newx/8)+2, hitbox_y/8)
		if not SOLIDS[tile] then self.x = newx end
	-- down
	elseif dir == 3 then
		newy = (hitbox_y + self.speed)+CELL
		tile = mget((self.x/8), newy/8)
		if not SOLIDS[tile] then self.y = self.y + self.speed end
	-- left
	elseif dir == 4 then
		newx = self.x - self.speed
		tile = mget((newx/8), hitbox_y/8)
		if not SOLIDS[tile] then self.x = newx end
	end
end

function player:update()
	if btn(0) then self:move(1) end
	if btn(1) then self:move(3) end
	if btn(2) then self:move(4) end
	if btn(3) then self:move(2) end
end

-- Game Scene
local game = scene:extends()

function game:new()
	game.base.new(self)
end

function game:on_enter()
	self.player = player(72, 64)
	self.entity_mgr:add(self.player)
end

function game:update()
	game.base.update(self)
end

function game:draw()
	map(map_x, map_y, 29, 16, 0, 0)
	game.base.draw(self)
end

function LOAD()
	sm:add({ ["game"] = game() })
	sm:switch("game")
end

function TIC()
	cls()
	sm:update()
	sm:draw()
end

LOAD()
