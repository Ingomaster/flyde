--// Flyde/main.lua //

--// Main configurations

-- I usually don't use pascal case to name my stuff but these are global variables

-- Objects table
Objects = {
	Gui = {
		Rectangle = {Mode = "fill"},
		Ellipse = {Mode = "fill"},
		Text = {},
	};
	Item = {
		Iron = {Owner = nil}, -- don't ask what "Owner" is or means, it will be like the block like a conveyor that the iron sits on or something idk maybe if i think about it
	};
	Entity = {
		Primus = {Speed = 180, Flying = true},
	};
	Block = {
		Drill = {
			Mechanical_Drill = {},
		};
	};
	Ore = {
		Iron_Ore = {},
	};
	Floor = {
		Calcite_Floor = {},
	};
	Wall = {
		Stone_Wall = {},
	};
}

local largeClass = "Block"

-- This massive loop loads the sprites and the classes of each object:

for className, class in next, Objects do for objIndex, obj in next, class do
	if className == largeClass then
		for realObjIndex, realObj in next, obj do
			-- For classes, indexes of 1 mean abstract, 2 is normal and 3 is precise
			realObj.Classes = {className, objIndex, realObjIndex}

			local spriteName = string.lower(realObjIndex)

			realObj.Sprite = {}
			realObj.Sprite = love.graphics.newImage("sprites/" .. string.lower(className) .. "/" .. spriteName .. ".png")
			realObj.Sprite:setFilter("nearest", "nearest")
		end
	else obj.Classes = {className, objIndex}
		local spriteName = string.lower(objIndex)

		if className == "Ore" then
			obj.Sprite = {}
			for i = 1, 3 do
				obj.Sprite[i] = love.graphics.newImage("sprites/" .. string.lower(className) .. "/" .. spriteName .. i .. ".png")
				obj.Sprite[i]:setFilter("nearest", "nearest")
			end
		elseif className ~= "Gui" then
			obj.Sprite = love.graphics.newImage("sprites/" .. string.lower(className) .. "/" .. spriteName .. ".png")
			obj.Sprite:setFilter("nearest", "nearest")
		end
	end
end; end

-- Objects are directly stored within types as tables
Game = {
	Gui = {};
	Item = {};
	Entity = {};
	Block = {
		Drill = {};
	};
	Ore = {};
	Floor = {};
	Wall = {};
}

-- For function paintO
local paintFunks = {
	Rectangle = love.graphics.rectangle;
	Ellipse = love.graphics.ellipse;
	Text = love.graphics.print;
}

--// Optional configurations
local mapSize = 64 -- squared

--// Graphical configurations
local sizeMult = 2
local pixelRes = 32

love.window.setFullscreen(true)
local screenResX, screenResY = love.graphics.getDimensions()

local drawingOrder = { "Floor"; "Wall"; "Ore"; "Block"; "Entity"; "Item"; "Gui" }

--// Funky functions

Script = {
	-- Create a new object
	Create = function(srcName)
		if not srcName then	return; end

		-- Instead of directly shoving src into the create function, i wanted to copy roblox studio instead
		local src
		for className, class in next, Objects do
			for objIndex, obj in next, class do
				if className == largeClass then
					for realObjIndex, realObj in next, obj do if realObjIndex == srcName then src = realObj; end; end
				elseif objIndex == srcName then src = obj; end
			end
		end

		if not src then print(srcName .. " could not be found."); return; end

		local obj = {}

		for k, v in next, src do
			if type(v) == "table" then
				if k == "Sprite" then obj[k] = v[math.random(1, #v)]
				else obj[k] = {}; for k2, v2 in next, v do obj[k][k2] = v2; end; end
			else obj[k] = v; end
		end

		obj.X, obj.Y, obj.SizeX, obj.SizeY = 0, 0, 1, 1

		return obj
	end;

	--(I added this function because I didn't want to store objects I create in variables to change their properties)
	-- Adjust object properties
	Adjust = function(obj, x, y, sizeX, sizeY, text)
		obj.X, obj.Y, obj.SizeX, obj.SizeY, obj.Text = x or 0, y or 0, sizeX or 1, sizeY or 1, text
		return obj
	end;

	-- Assign an object to the right class and name it
	Assign = function(obj, name)
		local branch = Game
		for i = 1, #obj.Classes - 1 do local key = obj.Classes[i]; branch = branch[key]; end

		obj.Name = name or obj.Classes[3] or obj.Classes[2]
		branch[obj.Name] = obj

		-- Return just in case
		return obj
	end;

	-- Delete an object
	Delete = function(obj)
		if type(obj) ~= "table" then return; end

		local tree

		if obj.Name and obj.Classes then tree = {obj.Classes[1], obj.Classes[2], obj.Name}
			if not obj.Classes[3] then tree[2] = tree[3]; tree[3] = nil; end
		end

		for i in next, obj do Script.Delete(obj[i]); obj[i] = nil; end

		if tree then
			local branch = Game
			for i = 1, #tree - 1 do branch = branch[tree[i]]; end
			branch[tree[3] or tree[2]] = nil
		end
	end;

	-- Generate map
	GenMap = function()
		for x = 0, mapSize do
			for y = 0, mapSize do

				local stringX, stringY = tostring(x), tostring(y)
				if x < 10 then stringX = "0" .. stringX; end
				if y < 10 then stringY = "0" .. stringY; end

				Script.Assign(Script.Adjust(Script.Create("Calcite_Floor"), x * pixelRes, y * pixelRes), stringX .. stringY)

				if (x == 0 or x == mapSize) or (y == 0 or y == mapSize) then

					stringX, stringY = tostring(x), tostring(y)
					if x < 10 then stringX = "0" .. stringX; end
					if y < 10 then stringY = "0" .. stringY; end

					Script.Assign(Script.Adjust(Script.Create("Stone_Wall"), x * pixelRes, y * pixelRes), stringX .. stringY)
				else
					if math.random(1, 5) == 3 then

						stringX, stringY = tostring(x), tostring(y)
						if x < 10 then stringX = "0" .. stringX; end
						if y < 10 then stringY = "0" .. stringY; end

						Script.Assign(Script.Adjust(Script.Create("Iron_Ore"), x * pixelRes, y * pixelRes), stringX .. stringY)
					end
				end
			end
		end
	end;

	-- Check collision of two objects
	CheckC = function(obj1, obj2)
		if not obj1 or not obj2 or obj1.Disabled or obj2.Disabled then return false; end
		if not obj1.X or not obj1.Y or not obj2.X or not obj2.Y then return false; end

		local w1, h1 = obj1.Sprite:getWidth() / 2, obj1.Sprite:getHeight() / 2
		local w2, h2 = obj2.Sprite:getWidth() / 2, obj2.Sprite:getHeight() / 2

		return ((obj1.X - w1 < obj2.X + w2) and (obj1.X + w1 > obj2.X - w2)) and
			((obj1.Y - h1 < obj2.Y + h2) and (obj1.Y + h1 > obj2.Y - h2))
	end;

	-- Check collisions between an object and a class, return table or false
	ClassC = function(obj, className)
		if not obj or obj.Disabled then return false; end

		local collisions = {}

		for _, otherObj in next, Game[className] do
			if className == largeClass then
				for _, realOtherObj in next, otherObj do
					if realOtherObj ~= obj and Script.CheckC(obj, realOtherObj) then
						table.insert(collisions, realOtherObj)
					end
				end
			elseif otherObj ~= obj and Script.CheckC(obj, otherObj) then
				table.insert(collisions, otherObj)
			end
		end

		return #collisions > 0 and collisions or false
	end;

	-- Detect collisions from standard colliding classes
	PhysiC = function(obj)
		if not obj or obj.Disabled then return false; end

		local collisions = {}

		local classCols = Script.ClassC(obj, "Wall")
		if classCols then for _, v in next, classCols do table.insert(collisions, v); end; end

		classCols = Script.ClassC(obj, "Block")
		if classCols then for _, v in next, classCols do table.insert(collisions, v); end; end

		classCols = Script.ClassC(obj, "Entity")
		if classCols then for _, v in next, classCols do table.insert(collisions, v); end; end

		return #collisions > 0 and collisions or false
	end;

	-- Move an object
	Move = function(obj, dt, x, y)

		-- Normalize x and y
		if x ~= 0 and y ~= 0 then
			local inv = 1 / math.sqrt(2)
			x, y = x * inv, y * inv
		end

		if x ~= 0 or y ~= 0 then obj.Rotation = math.atan2(y, x) + math.pi / 2; end

		local xIncrement = x * obj.Speed * dt
		local yIncrement = y * obj.Speed * dt

		-- Apply movement
		obj.X = obj.X + xIncrement; obj.Y = obj.Y + yIncrement

		-- Check for collisions and place the player back if detected
		if not obj.Flying and Script.CheckC(obj, "Wall") then obj.X = obj.X - xIncrement; obj.Y = obj.Y - yIncrement; end
	end;

	-- Paint an object from class
	PaintO = function(obj)
		local relativeX, relativeY = Player.X, Player.Y

		if obj.Classes[1] == "Gui" and not obj.Physical then relativeX, relativeY = 0, 0; end

		if obj == Player then relativeX, relativeY =
			obj.X - (screenResX - Player.Sprite:getWidth()) / (2 * sizeMult),
			obj.Y - (screenResY - Player.Sprite:getHeight()) / (2 * sizeMult)
		end

		love.graphics.setColor(1, 1, 1, obj.Opacity or 1)
		if obj == SelectedBlock and not obj.Placeable then love.graphics.setColor(1, 0, 0, obj.Opacity or 1); end

		local paintFunk = paintFunks[obj.Classes[3] or obj.Classes[2]]

		if paintFunk then
			if paintFunk == love.graphics.print then
				love.graphics.setColor(1, 1, 1, obj.Opacity or 1)
				paintFunk(
					obj.Text,
					(obj.X - relativeX) * sizeMult,
					(obj.Y - relativeY) * sizeMult,
					obj.Rotation,
					obj.SizeX * sizeMult,
					obj.SizeY * sizeMult
				)
			else love.graphics.setColor(0, 0, 0, obj.Opacity or 0.5)
				paintFunk(
					obj.Mode,
					(obj.X - relativeX) * sizeMult,
					(obj.Y - relativeY) * sizeMult,
					obj.SizeX * sizeMult,
					obj.SizeY * sizeMult
				)
			end
		else
			love.graphics.draw(
				obj.Sprite,
				(obj.X - relativeX) * sizeMult,
				(obj.Y - relativeY) * sizeMult,
				obj.Rotation or 0,
				obj.SizeX * sizeMult,
				obj.SizeY * sizeMult,
				obj.Sprite:getWidth() / 2,
				obj.Sprite:getHeight() / 2
			)
		end

		love.graphics.setColor(1, 1, 1, 1)
	end;

	-- Easy sound playing function
	PSound = function(soundName, looped)
		local sound = love.audio.newSource("/sounds/" .. string.lower(soundName) .. ".ogg", "stream")
		love.audio.stop(sound); sound:setLooping(looped or false); love.audio.play(sound)
	end;
}

--// Flyde //

function love.load()

	love.window.setTitle("Flyde v1.3")

	Script.PSound("Ambience", true)

	love.graphics.setFont(love.graphics.newFont("font.ttf", 32)) -- no arguments → default font

	-- Global configurations within love.load
	DefaultCursor = love.mouse.newCursor("sprites/other/mouse-cursor.png")

	Player = Script.Assign(Script.Create("Primus"), "Player")
	Player.EntityGroup = "Player"

	SelectedBlock = Script.Assign(Script.Create("Mechanical_Drill"))
	SelectedBlock.Opacity = 0.5


	-- Test UI
	Script.Assign(Script.Adjust(Script.Create("Rectangle"), 0, 0, 100, 100), "MainFrame")
	Script.Assign(Script.Adjust(Script.Create("Text"), 0, 0, 1, 1, "None"), "MainText")


	-- Map generating function call
	Script.GenMap()
end

function love.update(dt)
	-- Move player character
	local x = 0
	local y = 0
	if love.keyboard.isDown("right") or love.keyboard.isDown("d") then x = 1; end
	if love.keyboard.isDown("down") or love.keyboard.isDown("s") then y = 1; end
	if love.keyboard.isDown("left") or love.keyboard.isDown("a") then x = -1; end
	if love.keyboard.isDown("up") or love.keyboard.isDown("w") then y = -1; end

	Script.Move(Player, dt, x, y)

	-- Change mouse cursor icon
	love.mouse.setCursor(DefaultCursor)

	-- SelectedBlock follows mouse
	local mx, my = love.mouse.getPosition()

	-- TODO: Mouse collision => UI displays class
	-- Make this



	local blockSizeX, blockSizeY = SelectedBlock.Sprite:getWidth(), SelectedBlock.Sprite:getHeight()

	Script.Adjust(SelectedBlock,
		math.floor((mx + Player.X * sizeMult) / blockSizeX) * blockSizeX / sizeMult + blockSizeX / 2 / sizeMult,
		math.floor((my + Player.Y * sizeMult) / blockSizeY) * blockSizeY / sizeMult + blockSizeY / 2 / sizeMult
	)

	-- SelectedBlock invalid placement handling
	SelectedBlock.Placeable = true

	if (SelectedBlock.X < 0 or SelectedBlock.X > mapSize * pixelRes * sizeMult) or
		(SelectedBlock.Y < 0 or SelectedBlock.Y > mapSize * pixelRes * sizeMult) then
		SelectedBlock.Placeable = false
	end

	if Script.PhysiC(SelectedBlock) then SelectedBlock.Placeable = false; end
end

function love.mousepressed(_, _, button)

	-- UI block pressed + button 1 = place block
	if button == 1 and SelectedBlock.Placeable and not SelectedBlock.Disabled then
		local x, y = SelectedBlock.X, SelectedBlock.Y
		Script.Assign(Script.Adjust(Script.Create("Mechanical_Drill"), x, y), tostring(x) .. tostring(y))
		Script.PSound("Create")
		return
	end

	if button == 2 then
		local collisions = Script.ClassC(SelectedBlock, "Block")
		if collisions then
			-- Delete the block
			Script.Delete(collisions)
			Script.PSound("Delete")
		end
	end
end

function love.draw()

	for i = 1, #drawingOrder do local className = drawingOrder[i]

		local renderOrder = {}

		if className == largeClass then
			for _, obj in next, Game[className] do
				for _, realObj in next, obj do
					table.insert(renderOrder, realObj)
				end
			end
		else
			for _, obj in next, Game[className] do
				table.insert(renderOrder, obj)
			end
		end

		table.sort(renderOrder, function(a, b) return a.Name < b.Name; end)

		for _, realObj in ipairs(renderOrder) do Script.PaintO(realObj); end
	end

	Script.PaintO(SelectedBlock)
end