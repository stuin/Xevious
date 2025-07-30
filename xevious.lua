local colorMap = {
	[" "]=colors.lime,
	["T"]=colors.green,
	["."]=colors.yellow,
	[","]=colors.yellow,
	["~"]=colors.blue,
	["r"]=colors.orange,
	["R"]=colors.red,
	["S"]=colors.lime,
	["F"]=colors.blue,
	["g"]=colors.lime,
	["t"]=colors.green,
	["w"]=colors.blue,
	["@"]=colors.lightGray,
	["#"]=colors.lightGray,
	["p"]=colors.lightGray,
	["H"]=colors.lime,
	["h"]=colors.green,
	["C"]=colors.brown,
	["-"]=colors.lime,
	["0"]=colors.black
}

local world = {}
local fileName = "xevious-map.txt"
file = io.open(fileName, "r")

--Load world from text file
local line = file:read("*line")
while line do
	world[#world+1] = line
	line = file:read("*line")
end
io.close(file)

local entities = {
	{"Player", "^", 7, 16, colors.white},
	{"Crosshair", "+", 7, 12, colors.white},
	nil
}
local maxEntity = 3

local scrollY = #world-17
local bulletTimer = 0
local bomb = 0
local shooting = false
local score = 0
local lives = 3
local playing = true

local speaker = peripheral.find("speaker")
local musicFrame = 1
local music = {
	18, 20, 18, 17, 20, 17, 16, 20, 16, 15, 20, 15
}

local function nextEntity()
	for i=4,maxEntity do
		if entities[i] == nil then
			return i
		end
	end
	maxEntity = maxEntity + 1
	return maxEntity
end

local function drawEntities()
	for i=1,maxEntity do
		if entities[i] ~= nil then
			local x = math.floor(entities[i][3])
			local y = math.floor(entities[i][4])
			term.setCursorPos(17+x, y)
			if world[scrollY+y]:sub(x,x) == nil then
				print(world[scrollY+y]:sub(x,x))
			end
			term.setBackgroundColor(colorMap[world[scrollY+y]:sub(x,x)])
			term.setTextColor(entities[i][5])
			term.write(entities[i][2])
		end
	end
end

local function drawBackground()
	--Row by row
	for y=1,18 do
		term.setCursorPos(18, y)

		--Columns
		for x=1,14 do
			if world[scrollY+y]:sub(x,x) == nil then
				print(world[scrollY+y]:sub(x,x))
			end
			term.setBackgroundColor(colorMap[world[scrollY+y]:sub(x,x)])
			term.write(" ")
		end
		term.setBackgroundColor(colors.black)
	end

	drawEntities()

	--Lives and score
	term.setTextColor(colors.white)
	term.setBackgroundColor(colors.black)
	term.setCursorPos(18, 19)
	term.write("L:"..lives.." S:"..score)
end

local function replaceTile(x, y, c)
	world[scrollY+y] = world[scrollY+y]:sub(1,x-1)..c..world[scrollY+y]:sub(x+1)
end

local function hitBullet(x,y, type)
	for j=4,maxEntity do
		if entities[j] ~= nil and entities[j][1] == type and x==entities[j][3] and
			(y>=entities[j][4] and y<=entities[j][4]+1) then
			return true
		end
	end
	return false
end

local function landBomb(x,y)
	local startScore = score
	if colorMap[world[scrollY+y]:sub(x,x)] == colors.lightGray then
		replaceTile(x,y, "C")
		score = score + 300
	elseif world[scrollY+y]:sub(x,x) == "S" or world[scrollY+y]:sub(x,x) == "F" then
		replaceTile(x,y, "C")
		score = score + 1000
		lives = lives + 1
	end
	if colorMap[world[scrollY+y+1]:sub(x,x)] == colors.lightGray then
		replaceTile(x,y+1, "C")
		score = score + 200
	elseif world[scrollY+y+1]:sub(x,x) == "S" or world[scrollY+y+1]:sub(x,x) == "F" then
		replaceTile(x,y+1, "C")
		score = score + 1000
		lives = lives + 1
	end
	if colorMap[world[scrollY+y-1]:sub(x,x)] == colors.lightGray then
		replaceTile(x,y-1, "C")
		score = score + 200
	elseif world[scrollY+y-1]:sub(x,x) == "S" or world[scrollY+y-1]:sub(x,x) == "F" then
		replaceTile(x,y-1, "C")
		score = score + 1000
		lives = lives + 1
	end
	if colorMap[world[scrollY+y]:sub(x+1,x+1)] == colors.lightGray then
		replaceTile(x+1,y, "C")
		score = score + 200
	end
	if colorMap[world[scrollY+y]:sub(x-1,x-1)] == colors.lightGray then
		replaceTile(x-1,y, "C")
		score = score + 200
	end
	if score ~= startScore and speaker then
		speaker.playNote("pling",1, 20)
	end
end

local function update(scroll)
	--General updates
	for i=4,maxEntity do
		local x,y = 0,0
		local n = ""
		if entities[i] ~= nil then
			x = math.floor(entities[i][3])
			y = math.floor(entities[i][4])
			n = entities[i][1]
		end

		if entities[i] == nil then

		elseif x < 1 or x > 14 or y > 17 then
			--Edges
			entities[i] = nil
		elseif entities[i][1] == "Laser" then
			--Move forward
			entities[i][4] = entities[i][4] - 1
			if entities[i][4] < 1 then
				entities[i] = nil
			end
		elseif n == "Toroid" or n == "Torkan" or n == "Bullet" or n == "Bacura" then
			if hitBullet(x, y, "Laser") and n ~= "Bullet" then
				--Hit by player laser
				if n == "Toroid" then
					score = score + 30
					entities[i] = nil
					if speaker then
						speaker.playNote("pling",1, 24)
					end
				elseif n == "Torkan" then
					score = score + 50
					entities[i] = nil
					if speaker then
						speaker.playNote("pling",1, 24)
					end
				elseif n == "Bacura" then
					for j=4,maxEntity do
						if entities[j] ~= nil and entities[j][1] == "Laser" and x==entities[j][3] and
							(y>=entities[j][4] and y<=entities[j][4]+1) then
							entities[j] = nil
						end
					end
					if speaker then
						speaker.playNote("pling",1, 10)
					end
				end
			elseif x==entities[1][3] and y==entities[1][4] then
				--Hit player
				entities[i] = nil
				lives = lives - 1
				entities[1][2] = "*"
				entities[1][5] = colors.red
				if speaker then
					speaker.playNote("basedrum",1, 6)
				end
			else
				--Up/down
				if scroll then
					entities[i][4] = entities[i][4] + 1
				end
				entities[i][4] = entities[i][4] + entities[i][7]

				--Left/right
				entities[i][3] = entities[i][3] + entities[i][6]
				x = math.floor(entities[i][3])
				y = math.floor(entities[i][4])
				if x < 1 or x > 14 or y > 17 or y < 1 then
					entities[i] = nil
				end

				--Enemy specific AI
				if entities[i] and entities[i][1] == "Toroid" then
					if x == entities[1][3] and entities[i][6] == -0.25 then
						entities[i][6] = 0.3
					elseif x == entities[1][3] and entities[i][6] == 0.25 then
						entities[i][6] = -0.3
					end
				elseif entities[i] and entities[i][1] == "Torkan" then
					if y > 6 and entities[i][7] > 0 then
						entities[i][6] = (entities[i][6] > 7) and -0.3 or 0.3
						entities[i][7] = -0.3

						if entities[i][3] > entities[1][3] then
							entities[nextEntity()] = {"Bullet", "/", x, y, colors.red, -0.8, 0.8}
						else
							entities[nextEntity()] = {"Bullet", "\\", x, y, colors.red, 0.8, 0.8}
						end
						if speaker then
							speaker.playNote("xylophone",1, 20)
						end
					end
				end
			end
		elseif entities[i][1] == "Logram" or entities[i][1] == "Domogram" then
			--Land structures
			if scroll then
				entities[i][4] = entities[i][4] + 1
				y = math.floor(entities[i][4])
			end
			if bomb > 6 and x==entities[3][3] and (y==entities[3][4] or y+1==entities[3][4]) then
				--Hit by bomb
				entities[i] = nil
				score = score + 100
				if speaker then
					speaker.playNote("pling",1, 24)
				end
			elseif (x - entities[1][3]) == (entities[1][4] - y) then
				--Shooting back
				entities[nextEntity()] = {"Bullet", "/", x, y, colors.red, -0.8, 0.8}
				entities[i] = nil
				if speaker then
					speaker.playNote("xylophone",1, 20)
				end
			elseif (entities[1][3] - x) == (entities[1][4] - y) then
				entities[nextEntity()] = {"Bullet", "\\", x, y, colors.red, 0.8, 0.8}
				entities[i] = nil
				if speaker then
					speaker.playNote("xylophone",1, 20)
				end
			elseif entities[1][4] <= y then
				entities[nextEntity()] = {"Bullet", "-", x, y, colors.red, (x > entities[1][3]) and -0.8 or 0.8, 0}
				entities[i] = nil
				if speaker then
					speaker.playNote("xylophone",1, 20)
				end
			elseif entities[1][3] == x and entities[1][4] - y < 4 then
				entities[nextEntity()] = {"Bullet", "|", x, y, colors.red, 0, 0.8}
				entities[i] = nil
				if speaker then
					speaker.playNote("xylophone",1, 20)
				end
			end
		end
	end

	if bomb > 0 and bomb < 8 then
		--Move bomb
		entities[3] = {"Bomb", "*", entities[2][3], entities[2][4]+(8-bomb)/2, colors.red}
		entities[2][5] = colors.cyan
		if scroll then
			entities[2][4] = entities[2][4] + 1
		end
		bomb = bomb + 1
		if bomb == 2 and speaker then
			speaker.playNote("basedrum",1, 24)
		end
	elseif bomb > 0 then
		--Bomb lands
		landBomb(entities[2][3], entities[2][4])

		entities[3] = nil
		entities[2][3] = entities[1][3]
		entities[2][4] = entities[1][4]-4
		entities[2][5] = colors.white
		bomb = 0

		if speaker then
			speaker.playNote("basedrum",0.8, 1)
		end
	else
		--Update crosshair color
		local c = world[scrollY+entities[2][4]]:sub(entities[2][3],entities[2][3])
		if colorMap[c] == colors.lightGray or c == 'S' or c == "F" then
			entities[2][5] = colors.orange
		else
			entities[2][5] = colors.white
		end
	end

	--Spawn laser
	if bulletTimer > 0 then
		bulletTimer = bulletTimer - 1
	elseif shooting and bulletTimer == 0 then
		entities[nextEntity()] = {"Laser", "|", entities[1][3], entities[1][4]-1, colors.cyan}
		bulletTimer = 3

		--if speaker then
		--	speaker.playNote("snare",0.5, 24)
		--	speaker.playNote("xylophone",0.5, 24)
		--end
	end
end

local function spawnEnemies(y)
	for x=1,#world[y] do
		local c = world[y]:sub(x,x)
		if c == 'g' or c == 't' or c == 'w' then
			entities[nextEntity()] = {"Toroid", "0", x, y-scrollY+1, colors.gray, (x > 7) and -0.25 or 0.25, 0.25}
		elseif c == 'h' or c == 'H' then
			entities[nextEntity()] = {"Torkan", "H", x, y-scrollY+1, colors.gray, (x > 7) and -0.3 or 0.3, 0.3}
		elseif c == '@' then
			entities[nextEntity()] = {"Logram", "@", x, y-scrollY, colors.gray, 0, 0}
		elseif c == 'p' then
			entities[nextEntity()] = {"Domogram", "@", x, y-scrollY, colors.gray, 0, 0}
		elseif c == '-' then
			entities[nextEntity()] = {"Bacura", "-", x, y-scrollY+1, colors.gray, 0, 0.3}
		end
	end
end

--Spawn starting enemies
for y=scrollY,#world do
	spawnEnemies(y)
end
term.clear()

--Scrolling loop
while scrollY > 1 and lives > 0 and playing do
	scrollY = scrollY - 1
	spawnEnemies(scrollY)

	local frames = 0
	while frames < 5 and lives > 0 and playing do
		--Queue next frame before draw
		os.startTimer(0.1)
		drawBackground()
		entities[1][2] = "^"
		entities[1][5] = colors.white

		--Wait for next frame
		event, code, mX, mY = os.pullEvent()
		while event ~= "timer" do
			--Input between updates
			if event == "mouse_click" or event == "mouse_drag" then
				--Move player
				if mX > 17 and mX < 18+14 and mY >= 1 and mY < 19 then
					entities[1][3] = mX-17
					entities[1][4] = mY
					if bomb == 0 then
						entities[2][3] = mX-17
						entities[2][4] = mY-4
					end
				end
				--Weapons
				if code == 1 then
					shooting = true
				elseif code == 2 and bomb == 0 then
					bomb = 1
				end
			elseif event == "mouse_up" and code == 1 then
				shooting = false
			elseif event == "key" then
				--Keyboard
				local k = keys.getName(code)
				if k == "space" and bomb == 0 then
					bomb = 1
				elseif k == "q" then
					playing = false
					if speaker then
						speaker.playNote("basedrum",1, 6)
					end
				end
			end
			event, code, mX, mY = os.pullEvent()
		end
		frames = frames + 1

		update(not (frames < 5))

		--Play music
		if speaker then
			if musicFrame % 2 == 0 then
				speaker.playNote("harp", 0.7, music[musicFrame / 2])
			end
			musicFrame = musicFrame + 1
			if musicFrame / 2 > #music then
				musicFrame = 1
			end
		end
	end
end

--Game end
entities[2][2] = " "
if lives == 0 or not playing then
	entities[1][2] = "*"
	entities[1][5] = colors.red
else
	while entities[1][4] > 0 do
		drawBackground()
		entities[1][4] = entities[1][4] - 1
		os.sleep(0.3)
	end
	entities[1] = nil
end
drawBackground()