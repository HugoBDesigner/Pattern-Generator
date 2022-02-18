resetFiles = false
userLog = ""
version = "1.2b"
function love.load()
	--=================--
	-- WINDOW PREPPING --
	--=================--
	
	-- Remote console for myself
	console = false
	if love.filesystem.exists("console.txt") then
		local s = love.filesystem.read("console.txt")
		if s == "true" then
			if love._openConsole then
				love._openConsole()
				console = true
			end
		end
	end
	
	if love.filesystem.exists("seed.txt") then
		local s = love.filesystem.read("seed.txt")
		if tonumber(s) then
			math.randomseed(tonumber(s))
		end
	else
		math.randomseed(os.time())
	end
	
	require "class"
	love.window.setTitle("Pattern Generator v" .. version)
--	require "HBDlib"
	love.graphics.setBackgroundColor(205, 205, 205)
	love.window.setIcon( love.image.newImageData("images/icon.png") )
	windowW, windowH = 850, 650
	love.window.setMode(windowW, windowH)
--	love.filesystem.setIdentity("PatternGen")
	love.filesystem.createDirectory("images")
	love.filesystem.createDirectory("patterns")
	love.filesystem.createDirectory("logs")
	
	
	--==================--
	-- FONTS AND IMAGES --
	--==================--
	gothic = {}
	for i = 12, 96, 4 do
		gothic[tostring(i)] = love.graphics.newFont("GOTHICB.TTF", i)
	end
	
	noImage = love.graphics.newImage("images/noImage.png")
	refresh = love.graphics.newImage("images/refresh.png")
	
	
	--================--
	-- GRADIENT IMAGE --
	--================--
	grad = love.image.newImageData(256, 256)
	grad:mapPixel(function(x, y, r, g, b, a)
		return 255, 255, 255, math.min(math.max(0, (256-y)), 255)
	end)
	grad = love.graphics.newImage(grad)
	
	
	--=====================--
	-- NOTIFICATION SYSTEM --
	--=====================--
	notifications = {}
	newNotice = function(t)
		table.insert(notifications, {text = t, timer = 0, maxtimer = 5, moveTimer = 1})
	end
	
	
	--==================--
	-- PATTERNS LOADING --
	--==================--
	patterns = love.filesystem.getDirectoryItems("patterns")
	local delete = {}
	for i, v in ipairs(patterns) do
		if string.sub(v, -4, -1) == ".lua" then
			local ok, err = pcall(love.filesystem.load, "patterns/" .. v)
			if ok then
				local pat = love.filesystem.load("patterns/" .. v)()
				local name = "\"" .. v .. "\""
				if type(pat) == "table" then
					if pat.name then name = "\"" .. pat.name .. "\" (" .. v .. ")" end
					
					if pat.variables then
						for j, w in pairs(pat.variables) do
							if w.extra == "image" then
								w.value = love.graphics.newImage("images/noImage.png")
							end
						end
					end
					
					local ok2, err2 = pcall(pat.draw, 1, 1, 32, 32, 1, {255, 255, 255, 255})
					if not ok2 then
						ok = false
						newNotice("Error: failed to draw pattern " .. name)
						newLog("Pattern \"" .. v .. "\" error: " .. tostring(err2))
					end
					
					if pat.setRate then
						local ok2, err2 = pcall(pat.setRate, 32, 32, 1)
						if not ok2 then
							ok = false
							newNotice("Error: failed to set rate of pattern " .. name)
							newLog("Pattern \"" .. v .. "\" error: " .. tostring(err2))
						end
					end
					
					if ok then
						patterns[i] = love.filesystem.load("patterns/" .. v)()
						if not patterns[i].name then
							patterns[i].name = string.sub(v, 1, -5)
						end
						
						if patterns[i].variables then
							for j, w in pairs(patterns[i].variables) do
								if w.extra == "image" then
									w.value = love.graphics.newImage("images/noImage.png")
								end
							end
						end
					else
						table.insert(delete, i)
					end
				else
					newNotice("Error: failed to load pattern " .. name)
					newLog("Pattern \"" .. v .. "\" error: " .. tostring(err2))
					table.insert(delete, i)
				end
			else
				newNotice("Error: pattern \"" .. v .. "\" failed to load!")
				newLog("Pattern \"" .. v .. "\" error: Returned " .. tostring(pat) .. " (a " .. type(pat) .. " value)\r\n\r\n" .. tostring(err))
				table.insert(delete, i)
			end
		else
			table.insert(delete, i)
		end
	end
	
	if #delete >= 1 then
		for i = #delete, 1, -1 do
			table.remove(patterns, delete[i])
		end
	end
	
	collectgarbage()
	
	
	--===================--
	-- LOADING VARIABLES --
	--===================--
	selectedPattern = 1
	patternWidth = 640
	patternHeight = 480
	patternSize = 1
	patternColor = {205, 235, 255, 255}
	backColor = {255, 255, 255, 255}
	
	
	--===================--
	-- PATTERNS PREVIEWS --
	--===================--
	previewSizes = {sizes = {{96, 96}, {96*.75, 96*.75}, {96*.5, 96*.5}}, spacing = 8, animspeed = .5, angle = math.rad(90)}
	
	previews = {}
	options = {}
	randomOptions = {}
	for i, v in ipairs(patterns) do
		previews[i] = love.graphics.newCanvas(96, 96)
		love.graphics.setCanvas(previews[i])
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.rectangle("fill", 0, 0, 96, 96)
		local c = {unpack(patternColor)}
		for a = 1, 3 do
			c[a] = c[a]*.5
		end
		love.graphics.setColor(c)
		local success = true
		if v.setIcon then
			if type(v.setIcon) == "function" then
				local ok, err = pcall(v.setIcon, 96, 96, c)
				if ok then
					v.setIcon(96, 96, c)
				else
					success = err
				end
			else
				success = "setIcon error: function expected, got " .. type(v.setIcon)
			end
		else
			drawPattern(96/patternSize, 96/patternSize, patterns[i])
		end
		if success ~= true then
			drawPattern(96/patternSize, 96/patternSize, patterns[i])
			newNotice("Error: failed to draw pattern \"" .. v.name .. "\" icon")
			newLog("Pattern " .. v.name .. " error: " .. success)
		end
		love.graphics.setCanvas()
	end
	selector = require("selector")
	
	
	--========================--
	-- RANDOMIZATION SETTINGS --
	--========================--
	
	--Had to be moved up here for data saving purposes
	settings_random = {
		[1] = {t = "Randomize pattern", value = true},
		[2] = {t = "Randomize size", value = true},
		[3] = {t = "Randomize colors", value = true},
		[4] = {t = "Randomize canvas size", value = true},
		[5] = {t = "Randomize custom settings", value = true}
	}
	
	
	--===============--
	-- LOAD SETTINGS --
	--===============--
	if not resetFiles then
		local ok, err = pcall(loadSettings)
		if ok then
			loadSettings()
		else
			newNotice("Failed to load settings!")
			newLog("Settings loading error: " .. err)
		end
	end
	
	selector.load(previewSizes.sizes, previewSizes.spacing, previews, previewSizes.animspeed, selectedPattern, #patterns, previewSizes.angle)
	
	
	--================--
	-- PATTERN CANVAS --
	--================--
	patternCanvas = love.graphics.newCanvas(640-256, 256)
	patternPreview = false
	while selectedPattern > 1 and not patterns[selectedPattern] do
		selectedPattern = selectedPattern - 1
	end
	changePatternSize(0)
	
	
	--==============--
	-- FANCY HEADER --
	--==============--
	headerPattern = love.graphics.newCanvas(800, 512)
	love.graphics.setCanvas(headerPattern)
	love.graphics.clear(255, 255, 255, 0)
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.rectangle("fill", 0, 0, 800, 512)
	for x = 1, math.ceil(800/32) do
		for y = 1, math.ceil(512/32) do
			local size = 1
			local color = {205, 235, 255, 255}
			local rate = 32
			local xx, yy, ww, hh = (x-1)*rate*size, (y-1)*rate*size, rate*size, rate*size
			
			local alpha = {unpack(color)}
			local dark = {unpack(color)}
			for i = 1, 3 do dark[i] = dark[i]*.9 end
			alpha[4] = 255*.75
			
			local mult = 1
			if size < 1 then
				mult = 1/(1/size)
			end
			
			love.graphics.setLineWidth(2*mult)
			
			love.graphics.dashedLine(xx, yy+hh, xx+ww, yy+hh, 6*mult) --bottom
			love.graphics.dashedLine(xx+ww, yy, xx+ww, yy+hh, 6*mult) --right
			
			if math.mod(x+3, 4) == 0 then
				love.graphics.setColor(dark)
				love.graphics.setLineWidth(3*mult)
			end
			love.graphics.dashedLine(xx, yy, xx, yy+hh, 6*mult) --top
			
			love.graphics.setColor(color)
			love.graphics.setLineWidth(2*mult)
			if math.mod(y+3, 4) == 0 then
				love.graphics.setColor(dark)
				love.graphics.setLineWidth(3*mult)
			end
			love.graphics.dashedLine(xx, yy, xx+ww, yy, 6*mult) --left
			
			love.graphics.setColor(alpha)
			
			love.graphics.setLineWidth(2*mult)
			love.graphics.dashedLine(xx+ww, yy, xx, yy+hh, 3*mult)
			love.graphics.dashedLine(xx, yy, xx+ww, yy+hh, 3*mult)
		end
	end
	love.graphics.setCanvas()
	
	
	--=========--
	-- BUTTONS --
	--=========--
	--(x, y, w, h, clickfunc, clickargs, text)
	local off = 20
	local top = 240
	local wx, wy, ww, wh = off+640, windowH-off-256, windowW-640-off, 256
	
	require "button"
	buttons = {}
	--Select pattern above
	buttons["uppat"] = button:new(wx+4, wy, ww-8, 32, function()
		selectedPattern = selector.select(-1)
		changePatternSize(0)
		scrolls["left"].value = 0
		if patterns[selectedPattern].variables then
			scrolls["left"].barsize = scrolls["left"].height
			local n = 0
			for i, v in pairs(patterns[selectedPattern].variables) do
				n = n+1
				if type(v.extra) == "number" and type(v.value) == "table" then
					n = n+1
				end
			end
			if n > 9 then
				scrolls["left"].barsize = math.max(scrolls["left"].height/8, scrolls["left"].height / (n/9))
			end
		else
			scrolls["left"].barsize = scrolls["left"].height
		end
	end)
	buttons.uppat.holdmode = true
	buttons.uppat.color = {0, 0, 0, 55}
	buttons.uppat.outline = {0, 0, 0, 155}
	buttons.uppat.outhover = {0, 0, 0, 155}
	buttons.uppat.outclick = {0, 0, 0, 155}
	buttons.uppat.hovercolor = {0, 0, 0, 75}
	buttons.uppat.clickcolor = {0, 0, 0, 95}
	--Select pattern below
	buttons["downpat"] = button:new(wx+4, wy+wh-32, ww-8, 32, function()
		selectedPattern = selector.select(1)
		changePatternSize(0)
		scrolls["left"].value = 0
		if patterns[selectedPattern].variables then
			scrolls["left"].barsize = scrolls["left"].height
			local n = 0
			for i, v in pairs(patterns[selectedPattern].variables) do
				n = n+1
				if type(v.extra) == "number" and type(v.value) == "table" then
					n = n+1
				end
			end
			if n > 9 then
				scrolls["left"].barsize = math.max(scrolls["left"].height/8, scrolls["left"].height / (n/9))
			end
		else
			scrolls["left"].barsize = scrolls["left"].height
		end
	end)
	buttons.downpat.holdmode = true
	buttons.downpat.color = {0, 0, 0, 55}
	buttons.downpat.hovercolor = {0, 0, 0, 75}
	buttons.downpat.clickcolor = {0, 0, 0, 95}
	buttons.downpat.outline = {0, 0, 0, 155}
	buttons.downpat.outhover = {0, 0, 0, 155}
	buttons.downpat.outclick = {0, 0, 0, 155}
	--Preview image
	buttons["previewsave"] = button:new(windowW/2-gothic["24"]:getWidth("Save as image")/2-8, windowH/2+320/2+12-4-math.floor(gothic["24"]:getHeight()/2), gothic["24"]:getWidth("Save as image")+16, gothic["24"]:getHeight()+8, previewMode, {"save"})
	buttons.previewsave.active = false
	buttons.previewsave.clickmode = false
	buttons.previewsave.color = {205, 235, 255, 255}
	buttons.previewsave.hovercolor = {155, 205, 255, 255}
	buttons.previewsave.clickcolor = {105, 175, 255, 255}
	--Randomize settings
	love.graphics.setFont(gothic["24"])
	local y = 10+gothic["48"]:getHeight()*.75 + gothic["24"]:getHeight()
	buttons["random"] = button:new(windowW-off, y + off + #settings_random*(16+7), false, false, "randomFunc", false, "Randomize settings")
	buttons.random.x = buttons.random.x - buttons.random.width
	buttons.random.color = {205, 215, 235, 255}
	buttons.random.hovercolor = {235, 235, 255, 255}
	buttons.random.clickcolor = {105, 155, 235, 255}
	buttons.random.outline = {55, 55, 55, 255}
	buttons.random.outhover = {75, 75, 75, 255}
	buttons.random.outclick = {25, 25, 25, 255}
	buttons.random.innerline = {255, 255, 255, 105}
	buttons.random.textshadow = {0, 0, 0, 105}
	
	--=========--
	-- SCROLLS --
	--=========--
	local y = 10+gothic["48"]:getHeight()*.75 + gothic["24"]:getHeight() + off
	require "scroll"
	scrolls = {}
	
	--Pattern settings scroll
	scrolls["left"] = scroll:new(256-off-12, y, 12, windowH-y-off*3-256)
	scrolls["left"].barsize = scrolls["left"].height
	local n = 0
	if patterns[selectedPattern].variables then
		for i, v in pairs(patterns[selectedPattern].variables) do
			n = n+1
			if type(v.extra) == "number" and type(v.value) == "table" then
				n = n+1
			end
		end
	end
	if n > 9 then
		scrolls["left"].barsize = math.max(scrolls["left"].height/8, scrolls["left"].height / (n/9))
	end
	scrolls.left.lastclick = true
	
	
	--==============--
	-- COLOR WHEELS --
	--==============--
	require "color"
	colors = {}
	--Pattern color
	colors["pattern"] = color:new(windowW/2, windowH/2, 128, 24, function(r, g, b, a) patternColor = {r, g, b, a}; settings[2].value = patternColor; changePatternSize(0) end)
	colors["pattern"].active = false
	colors["pattern"]:setColor(patternColor)
	--Pattern background color
	colors["patternBack"] = color:new(windowW/2, windowH/2, 128, 24, function(r, g, b, a) backColor = {r, g, b, a}; settings[3].value = backColor; changePatternSize(0) end)
	colors["patternBack"].active = false
	colors["patternBack"]:setColor(backColor)
	
	
	--======================--
	-- OPTIONS AND SETTINGS --
	--======================--
	--Main settings
	editMode = false
	settings = {
		[1] = {t = "Size", value = patternSize, extra = {.4, 10, .1}, var = "patternSize"},
		[2] = {t = "Color", value = patternColor, extra = "color", gui = colors["pattern"]},
		[3] = {t = "Background", value = backColor, extra = "color", gui = colors["patternBack"]},
		[4] = {t = "Pattern's width", value = patternWidth, extra = {4, 6000, 1}, var = "patternWidth"},
		[5] = {t = "Pattern's height", value = patternHeight, extra = {4, 6000, 1}, var = "patternHeight"}
	}
	
	
	--Navigation and preview settings
	settings_under = {
		[1] = {t = "Preview/\nGenerate image", value = function() previewMode() end},
		[2] = {t = "Open images\n folder", value = function() love.system.openURL(love.filesystem.getSaveDirectory() .. "/images"); newLog("Redirecting to images folder", "log") end},
		[3] = {t = "Open patterns\nfolder", value = function() love.system.openURL(love.filesystem.getSaveDirectory() .. "/patterns"); newLog("Redirecting to patterns folder", "log") end},
		[4] = {t = "Reset all\nsettings", value = function() resetMode.active = true end}
	}
	settings_under[1].color = {215, 235, 205, 255}
	settings_under[1].clickcolor = {155, 235, 105, 255}
	settings_under[1].hovercolor = {235, 255, 235, 255}
	
	settings_under[4].color = {235, 215, 205, 255}
	settings_under[4].clickcolor = {235, 155, 105, 255}
	settings_under[4].hovercolor = {255, 235, 235, 255}
	
	
	--Canvas size preset buttons
	canvas_presets = {
		[1] = {t = "A4", value = "A4 (300ppi) - portrait", w = 2480, h = 3508},
		[2] = {t = "A4", value = "A4 (300ppi) - landscape", w = 3508, h = 2480},
		[3] = {t = "A3", value = "A3 (300ppi) - portrait", w = 3508, h = 4960},
		[4] = {t = "A3", value = "A3 (300ppi) - landscape", w = 4960, h = 3508},
		[5] = {t = "8x6", value = "800 x 600", w = 800, h = 600},
		[6] = {t = "VGA", value = "480p", w = 640, h = 480},
		[7] = {t = "HD", value = "720p", w = 1280, h = 720},
		[8] = {t = "fHD", value = "1080p", w = 1920, h = 1080},
		[9] = {t = "4k", value = "4x 1080p", w = 3840, h = 2160},
		[9] = {t = "64²", value = "64p²", w = 64, h = 64}
	}
	
	
	--Reset settings
	resetMode = {active = false}
	local text = "Reset all settings"
	resetMode.button = button:new(windowW/2 - gothic["24"]:getWidth(text)/2 - gothic["24"]:getHeight()/2,
		windowH/2+gothic["24"]:getHeight(), gothic["24"]:getWidth(text)+gothic["24"]:getHeight(),
		gothic["24"]:getHeight(), function() love.filesystem.remove("save.dat"); resetFiles = true; love.load(); newNotice("Settings successfully reset"); newLog("Settings reset", "log") end)
	resetMode.button.clickmode = false
	resetMode.button.color = {205, 235, 255, 255}
	resetMode.button.hovercolor = {155, 205, 255, 255}
	resetMode.button.clickcolor = {105, 175, 255, 255}
	
	
	--Color guis for custom pattern settings
	for i, v in pairs(patterns) do
		if v.variables and type(v.variables) ~= "table" then
			newNotice("Error: failed to load variables from \"" .. v.name .. "\"")
			newLog("Pattern " .. v.name .. " error: variables error: table expected, got " .. type(v.variables))
		elseif v.variables then
			local n = 0
			for j, w in pairs(v.variables) do
				n = n+1
				if type(v.extra) == "number" and type(v.value) == "table" then
					n = n+1
				end
				if type(w.value) == "table" and w.extra == "color" then
					table.insert(colors, color:new(windowW/2, windowH/2, 128, 24, function(r, g, b, a) w.value = {r, g, b, a}; changePatternSize(0) end))
					w.gui = colors[#colors]
					w.gui:setColor(w.value)
					w.gui.active = false
					w.gui.autoupdate = w
				end
			end
			v.varheight = n
		end
	end
	
--	local sx, sy, sh, ss = 256, y, 32, 4
	
	--===============--
	-- RANDOMIZATION --
	--===============--
	function randomFunc()
		--settings_random
		--[1] = {t = "Randomize colors", value = true},
		--[2] = {t = "Randomize canvas size", value = true},
		--[3] = {t = "Randomize custom settings", value = true}
		
		if settings_random[1].value then
			selectedPattern = math.random(#patterns)
			selector.selection = selectedPattern
		end
		
		local function run(i, v)
			if type(v.value) == "table" and v.extra == "color" then
				v.value = {math.random(255), math.random(255), math.random(255), 255}
				
				if v.var then
					_G[v.var] = v.value
				end
				
				v.gui:setColor(v.value)
				v.gui.func(unpack(v.value))
			elseif type(v.value) == "boolean" then
				local s = math.random(2)
				if s == 1 then
					v.value = true
				else
					v.value = false
				end
				if v.var then
					_G[v.var] = v.value
				end
			elseif type(v.value) == "number" and type(v.extra) == "table" then
				local n = v.extra[1]
				local t = (v.extra[2] - v.extra[1]) / (v.extra[3] or 1) + 1
				n = n + (math.random(t) - 1) * (v.extra[3] or 1)
				
				v.value = n
				if v.var then
					_G[v.var] = v.value
				end
			elseif type(v.extra) == "number" and type(v.value) == "table" then
				v.extra = math.random(#v.value)
				
				if v.var then
					_G[v.var] = v.value[v.extra]
				end
			end
		end
		
		for i, v in ipairs(settings) do
			local can = true
			if i == 1 and settings_random[2].value == false then
				can = false
			elseif (i == 2 or i == 3) and settings_random[3].value == false then
				can = false
			elseif (i == 4 or i == 5) and settings_random[4].value == false then
				can = false
			end
			
			if can then
				run(i, v)
			end
		end
		
		if patterns[selectedPattern].variables and settings_random[5].value then
			for i, v in pairs(patterns[selectedPattern].variables) do
				run(i, v)
			end
		end
		
		changePatternSize(0)
	end
	
	local n = os.date("*t")
	newLog("Pattern Generator v" .. version .. " loaded", (resetFiles == true and "reset" or "login"))
	resetFiles = false
end

function love.update(dt)
	--HBD:updateRecording(dt)
	
	--Notifications timer
	local delete = {}
	for i, v in ipairs(notifications) do
		v.timer = v.timer + dt
		if v.timer >= v.maxtimer then
			table.insert(delete, i)
		end
	end
	if #delete >= 1 then
		for i = #delete, 1, -1 do
			table.remove(notifications, delete[i])
		end
	end
	
	--Color guis
	for i, v in pairs(colors) do
		if v:update(dt) then
			return
		end
	end
	
	--Pattern selector
	selector.update(dt)
	if patternPreview then
		buttons.previewsave:update(dt)
		return
	end
	
	--Reset settings mode
	if resetMode.active then
		resetMode.button:update(dt)
		return
	end
	
	--=======================================--
	-- MOUSE HOVERING DETECTION FOR SETTINGS --
	--=======================================--
	local size = patternSize
	local off = 20
	local top = 240
	local wx, wy, ww, wh = off, windowH-off-256, 640, 256
	local sx, sy, sh, ss = 256, 10+gothic["48"]:getHeight()*.75 + gothic["24"]:getHeight() + off, 32, 4
	local n = 0
	local x, y = love.mouse.getPosition()
	local function run(i, v, n, sx, sy, sh, ss, shad, w)
		if v.extra ~= "image" then
			v.hovering = false
		end
		local font = gothic["12"]
		if shad == true then
			font = gothic["24"]
		elseif shad == "20" then
			font = gothic["20"]
			shad = true
		end
		n = n+1
		local s = i
		if v.t then s = v.t end
		local w = w or font:getWidth(s)+font:getHeight()
		
		sy = sy + (n-1)*(sh+ss)
		if v.extra == "image" then -- IMAGES LOADER
			sx = sx + font:getWidth(s .. ": ")
			if inside(x, y, 0, 0, sx+8.5, sy, sh, sh) then
				v.hovering = true
			else
				v.hovering = false
			end
		elseif type(v.value) == "function" then -- BUTTON
			if inside(x, y, 0, 0, sx+font:getHeight()/2, sy, w, sh) then
				v.hovering = true
			end
		elseif type(v.value) == "boolean" then -- CHECKBOX
			local recw = sh/3*2.5
			if distance(x, y, sx+sh-recw/2, sy+sh/2) <= sh/3 then
				v.hovering = true
			elseif distance(x, y, sx+sh+recw/2, sy+sh/2) <= sh/3 then
				v.hovering = true
			elseif inside(x, y, 0, 0, sx+sh-recw/2, sy+sh/2-sh/3, recw, 2*sh/3) then
				v.hovering = true
			end
		elseif type(v.value) == "number" and type(v.extra) == "table" then -- NUMERICAL UI
			sx = sx + font:getWidth(s .. ": ")
			if inside(x, y, 0, 0, sx+8.5, sy+sh/4, sh/2, sh/2) then
				v.hovering = 1
			end
			local smax = v.extra[2]
			if math.mod(v.extra[3] or 1, 1) ~= 0 then
				smax = smax+math.mod(v.extra[3] or 1, 1)
			end
			sx = math.floor(sx + ss+1.5+sh + font:getWidth(smax))
			if not shad then sx = sx - 3*sh/8 end
			
			if inside(x, y, 0, 0, sx+8.5, sy+sh/4, sh/2, sh/2) then
				v.hovering = 2
			end
		elseif type(v.extra) == "number" and type(v.value) == "table" then -- ITEM SELECTION UI
			n = n+1
			sy = sy + sh+ss
			sx = sx + sh
			
			if inside(x, y, 0, 0, sx+8.5, sy+sh/4, sh/2, sh/2) then
				v.hovering = 1
			end
			local smax = ""
			for i, v in ipairs(v.value) do
				if font:getWidth(v) > font:getWidth(smax) then
					smax = v
				end
			end
			
			sx = math.floor(sx + ss+1.5+sh + font:getWidth(smax))
			if not shad then sx = sx - 3*sh/8 end
			
			if inside(x, y, 0, 0, sx+8.5, sy+sh/4, sh/2, sh/2) then
				v.hovering = 2
			end
		end
	end
	local sx, sy, sh, ss = 256, 10+gothic["48"]:getHeight()*.75 + gothic["24"]:getHeight() + off, 28, 2
	local n = 0
	
	--Main settings
	for i, v in ipairs(settings) do
		run(i, v, n, sx, sy, sh, ss, "20")
		if type(v.extra) == "number" and type(v.value) == "table" then n = n + 1 end
		n = n + 1
	end
	
	--Canvas size presets
	sy = sy + #settings*(sh+ss) + sh/2
	local bw, bs = 32, 8
	for i, v in ipairs(canvas_presets) do
		local xx = sx + (i-1)*(bw+bs)
		
		local sc = math.min(bw/v.w, bw/v.h)
		if inside(x, y, 0, 0, xx + bw/2 - v.w*sc/2, sy + bw/2 - v.h*sc/2, v.w*sc, v.h*sc) then
			v.high = true
		else
			v.high = false
		end
	end
	
	
	--Navigation and Preview settings
	n = 0
	sx, sy, sh, ss = (256-off-12)/2, wy-off, 64, 7
	local w = 0
	for i, v in ipairs(settings_under) do
		local s = i
		if v.t then s = v.t end
		w = math.max(w, gothic["24"]:getWidth(s)+gothic["24"]:getHeight())
	end
	local xx = sx - w/2
	for i, v in ipairs(settings_under) do
		run(i, v, n, xx, sy, sh, ss, true, w)
		n = n + 1
	end
	
	
	-- Randomization settings
	n = 0
	sy, sh, ss = buttons["random"].y, 16, 7
	for i, v in ipairs(settings_random) do
		sy = sy - sh - ss
	end
	
	for i, v in ipairs(settings_random) do
		local xx = buttons["random"].x--windowW - off - gothic["12"]:getWidth(v.t) - sh - off
		run(i, v, n, xx, sy, sh, ss, false)
		n = n + 1
	end
	
	--Custom pattern settings
	local sx, sy, sh, ss = off, 3+(10+gothic["48"]:getHeight()*.75 + gothic["24"]:getHeight())+off, 16, 4
	if patterns[selectedPattern].variables then
		n = 0
		if patterns[selectedPattern].varheight > 9 then
			y = y-6+(scrolls["left"].value*(6+(patterns[selectedPattern].varheight-1)*(ss+sh)-(windowH-sy-off*4-256)))
		end
		for i, v in pairs(patterns[selectedPattern].variables) do
			run(i, v, n, sx, sy, sh, ss)
			if type(v.extra) == "number" and type(v.value) == "table" then n = n + 1 end
			n = n + 1
		end
	end
	
	
	--Input editing mode for numerical UIs
	if editMode then
		editMode[4][1] = editMode[4][1] + dt
		if editMode[4][1] >= editMode[4][2] then
			editMode[4][1] = 0
		end
	end
	
	--======================================--
	-- MOUSE HOLDING DETECTION FOR SETTINGS --
	--======================================--
	
	--Main settings
	for i, v in ipairs(settings) do
		if v.clicking then
			if not v.timer then v.timer = .5; v.looptimer = .25 end
			v.timer = v.timer - dt
			if v.timer <= 0 then
				if v.timer <= -v.looptimer then
					v.timer = 0
					v.looptimer = math.max(1/180, v.looptimer * .95)
					if type(v.value) == "number" and type(v.extra) == "table" then --NUMERICAL UI
						if v.clicking == 1 then
							v.value = math.max(v.extra[1], v.value-(v.extra[3] or 1))
							
							if v.var then
								_G[v.var] = v.value
							end
						elseif v.clicking == 2 then
							v.value = math.min(v.extra[2], v.value+(v.extra[3] or 1))
							
							if v.var then
								_G[v.var] = v.value
							end
						end
						if size ~= patternSize then
							changePatternSize(0)
						end
					end
				end
			end
		elseif v.timer then
			v.timer = false
			v.looptimer = false
		end
	end
	
	--Custom pattern settings
	if patterns[selectedPattern].variables then
		for i, v in pairs(patterns[selectedPattern].variables) do
			if v.clicking then
				if not v.timer then v.timer = .5; v.looptimer = .25 end
				v.timer = v.timer - dt
				if v.timer <= 0 then
					if v.timer <= -v.looptimer then
						v.timer = 0
						v.looptimer = math.max(1/180, v.looptimer * .95)
						if type(v.value) == "number" and type(v.extra) == "table" then --NUMERICAL UI
							if v.clicking == 1 then
								v.value = math.max(v.extra[1], v.value-(v.extra[3] or 1))
								
								if v.var then
									_G[v.var] = v.value
								end
							elseif v.clicking == 2 then
								v.value = math.min(v.extra[2], v.value+(v.extra[3] or 1))
								
								if v.var then
									_G[v.var] = v.value
								end
							end
							changePatternSize(0)
						elseif type(v.extra) == "number" and type(v.value) == "table" then --ITEM SELECTION UI
							v.looptimer = math.max(1/5, v.looptimer)
							if v.clicking == 1 then
								v.extra = v.extra - 1
								if v.extra == 0 then
									v.extra = #v.value
								end
							end
							sx = math.floor(sx + ss+1.5+sh + gothic["12"]:getWidth(v.value[v.extra]))
							if not shad then sx = sx - 3*sh/8 end
							
							if v.clicking == 2 then
								v.extra = v.extra + 1
								if v.extra > #v.value then
									v.extra = 1
								end
							end
							changePatternSize(0)
						end
					end
				end
			elseif v.timer then
				v.timer = false
				v.looptimer = false
			end
		end
	end
	
	
	--UIs
	for i, v in pairs(buttons) do
		v:update(dt)
	end
	for i, v in pairs(scrolls) do
		v:update(dt)
	end
end

function love.draw()
	--===============--
	-- WINDOW HEADER --
	--===============--
	local off = 20
	local top = 240
	local wx, wy, ww, wh = off, windowH-off-256, 640, 256
	
	love.graphics.setBackgroundColor(205, 205, 205, 255)
	
	local y = 10+gothic["48"]:getHeight()*.75 + gothic["24"]:getHeight()
	love.graphics.setColor(205, 215, 235, 255)
	love.graphics.rectangle("fill", 0, 0, windowW, y)
	
	love.graphics.setFont(gothic["48"])
	love.graphics.setColor(0, 0, 0, 155)
	for i = 1, 2 do
		love.graphics.print("Pattern Generator", 5+(2-i)*2, (2-i)*2)
		love.graphics.setColor(105, 155, 0, 255)
	end
	
	love.graphics.setFont(gothic["24"])
	love.graphics.setColor(0, 0, 0, 155)
	for i = 1, 2 do
		love.graphics.print("by HugoBDesigner", 5+gothic["48"]:getWidth("Pattern Generator")-gothic["24"]:getWidth("by HugoBDesigner")+(2-i)*2, gothic["48"]:getHeight()*.75+(2-i)*2)
		love.graphics.setColor(0, 155, 205, 255)
	end
	
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.setScissor(15+gothic["48"]:getWidth("Pattern Generator"), 0, windowW-(15+gothic["48"]:getWidth("Pattern Generator")), y)
	love.graphics.draw(headerPattern, 15+gothic["48"]:getWidth("Pattern Generator"), 0, math.rad(30), 1, 1, 400, 256)
	love.graphics.setScissor()
	love.graphics.setColor(205, 215, 235, 255)
	love.graphics.draw(grad, 15+gothic["48"]:getWidth("Pattern Generator"), y, -math.pi/2, y/256, (2*y)/256)
	
	love.graphics.setColor(55, 55, 55, 205)
	love.graphics.setFont(gothic["12"])
	love.graphics.print("Version " .. version, windowW - gothic["12"]:getWidth("Version " .. version), y-gothic["12"]:getHeight())
	
	love.graphics.setFont(gothic["24"])
	love.graphics.setColor(105, 105, 105, 255)
	love.graphics.setLineWidth(1)
	love.graphics.line(0, y, windowW, y)
	
	-- Custom Pattern Name
	love.graphics.setColor(235, 255, 205, 255)
	love.graphics.draw(grad, 256, wy-off, -math.pi/2, (gothic["24"]:getHeight()+4)/256, (windowW-(256+4))/256)
	love.graphics.setColor(0, 0, 0, 105)
	
	for a = 1, 2 do
		love.graphics.print(patterns[selectedPattern].name, 256-(a-2)*2+4, wy-off-gothic["24"]:getHeight()-4-(a-2)*2)
		love.graphics.setColor(55, 105, 0, 255)
	end
	
	
	
	-- Canvas Display
	love.graphics.setColor(235, 245, 255, 255)
	love.graphics.rectangle("fill", 256, wy-off, windowW-256, windowH-(wy-off))
	
	love.graphics.setColor(0, 0, 0, 255)
	love.graphics.setLineWidth(2)
	love.graphics.line(256, wy-off, windowW, wy-off)
	love.graphics.line(256, wy-off, 256, windowH)
	
	
	-- Refresh button
	local high = inside(love.mouse.getX(), love.mouse.getY(), 0, 0, windowW-refresh:getWidth()-2, wy-off-3-refresh:getHeight(), refresh:getWidth(), refresh:getHeight())
	love.graphics.setColor(205, 205, 205, 255)
	if high then
		love.graphics.setColor(255, 255, 255, 255)
	end
	love.graphics.draw(refresh, windowW-refresh:getWidth()-2, wy-off-3-refresh:getHeight())
	-- "Refresh code" popup
	if high then
		--scissor(off+2, y+off+2, 256-off*2-12-4, windowH-y-off*4-256-4)
		local t = "Refresh program/code"
		local toff = 2
		local recx = (windowW-refresh:getWidth()-4)-gothic["12"]:getWidth(t)-toff*2
		local recy = love.mouse.getY() - ((gothic["12"]:getHeight()-toff*2)/2) -.5
		local recw = gothic["12"]:getWidth(t) + toff*2
		local rech = gothic["12"]:getHeight() + toff*2
		
		love.graphics.setColor(255, 255, 155, 205)
		love.graphics.rectangle("fill", recx, recy, recw, rech)
		love.graphics.setColor(55, 55, 0, 255)
		love.graphics.rectangle("line", recx, recy, recw, rech)
		love.graphics.setFont(gothic["12"])
		love.graphics.print(t, recx+toff, recy+toff)
		love.graphics.setFont(gothic["24"])
	end
	
	
	-- Custom Pattern Settings Display
	love.graphics.setColor(235, 235, 235, 255)
	love.graphics.rectangle("fill", off, y+off, 256-off*2-12, windowH-y-off*4-256)
	
	love.graphics.setColor(0, 0, 0, 255)
	love.graphics.setLineWidth(1)
	love.graphics.rectangle("line", off, y+off, 256-off*2-12, windowH-y-off*4-256)
	
	
	--=========================--
	-- PATTERN'S MAIN SETTINGS --
	--=========================--
	
	local imageDrop = false
	local function run(i, v, n, sx, sy, sh, ss, shad, w)
		local font = love.graphics.getFont()
		love.graphics.setColor(0, 0, 0, 105)
		love.graphics.setLineWidth(2)
		if not shad then
			love.graphics.setLineWidth(1)
		end
		n = n+1
		--love.graphics.line(sx, sy+(n-1)*(sh+ss), sx, sy+n*(sh+ss)-ss)
		local s = i
		if v.t then s = v.t end
		local w = w or font:getWidth(s) + font:getHeight()
		
		sy = sy + (n-1)*(sh+ss)
		if type(v.value) ~= "function" and type(v.value) ~= "boolean" then --SETTING NAME
			for a = 1, 2 do
				if (shad and a == 1) or a == 2 then
					love.graphics.print(s .. ":", sx+ss+(2-a)*1.5, sy+(2-a)*1.5)
				end
				love.graphics.setColor(55, 55, 55, 255)
			end
		elseif type(v.value) == "function" then --BUTTON
			love.graphics.setColor(v.color or {205, 215, 235, 255})
			if v.clicking then
				love.graphics.setColor(v.clickcolor or {105, 155, 235, 255})
			elseif v.hovering then
				love.graphics.setColor(v.hovercolor or {235, 235, 255, 255})
			end
			
			love.graphics.rectangle("fill", sx+font:getHeight()/2, sy, w, sh)
			love.graphics.setColor(255, 255, 255, 105)
			love.graphics.rectangle("line", sx+font:getHeight()/2+2, sy+2, w-4, sh-4)
			love.graphics.setColor(55, 55, 55, 255)
			love.graphics.rectangle("line", sx+font:getHeight()/2, sy, w, sh)
			
			local t = {""}
			for a = 1, string.len(s) do
				if string.sub(s, a, a) == "\n" then
					table.insert(t, "")
				else
					t[#t] = t[#t] .. string.sub(s, a, a)
				end
			end
			for tt = 1, #t do
				love.graphics.setColor(0, 0, 0, 105)
				for a = 1, 2 do
					if (shad and a == 1) or a == 2 then
						love.graphics.print(t[tt], sx+font:getHeight()/2+(2-a)*1.5+ w/2 - font:getWidth(t[tt])/2, sy+(2-a)*1.5 + (tt-1)*font:getHeight())
					end
					love.graphics.setColor(55, 55, 55, 255)
				end
			end
		elseif type(v.value) == "boolean" then --CHECKBOX
			love.graphics.setColor(0, 0, 0, 105)
			for a = 1, 2 do
				if (shad and a == 1) or a == 2 then
					love.graphics.print(s, sx+ss+(2-a)*1.5+sh*2, sy+(2-a)*1.5)
				end
				love.graphics.setColor(55, 55, 55, 255)
			end
			love.graphics.setColor(205, 235, 255, 255)
			if v.hovering then
				love.graphics.setColor(235, 235, 255, 255)
			end
			
			if v.value == true then
				love.graphics.setColor(0, 155, 255, 255)
				if v.hovering then
					love.graphics.setColor(55, 205, 255, 255)
				end
			end
			
			local recw = sh/3*2.5
			love.graphics.circle("fill", sx+sh-recw/2, sy+sh/2, sh/3, 32)
			love.graphics.circle("fill", sx+sh+recw/2, sy+sh/2, sh/3, 32)
			love.graphics.rectangle("fill", sx+sh-recw/2, sy+sh/2-sh/3, recw, 2*sh/3)
			love.graphics.rectangle("line", sx+sh-recw/2, sy+sh/2-sh/3, recw, 2*sh/3)
			
			love.graphics.setColor(55, 55, 55, 255)
			love.graphics.setScissor(sx+sh-recw/2-sh/3 - 2, sy+sh/2-sh/3 - 2, sh/3 + 2, 2*sh/3 + 4)
			love.graphics.circle("line", sx+sh-sh/3-.5, sy+sh/2, sh/3, 32)
			love.graphics.setScissor()
			
			love.graphics.setScissor(sx+sh + recw/2, sy+sh/2-sh/3 - 2, sh/3 + 2, 2*sh/3 + 4)
			love.graphics.circle("line", sx+sh+sh/3+.5, sy+sh/2, sh/3, 32)
			love.graphics.setScissor()
			
			love.graphics.line(sx+sh-recw/2, sy+sh/2-sh/3, sx+sh+recw/2, sy+sh/2-sh/3)
			love.graphics.line(sx+sh-recw/2, sy+sh/2+sh/3, sx+sh+recw/2, sy+sh/2+sh/3)
			
			love.graphics.setColor(205-55, 235-55, 255-55, 255)
			local px = sx+sh-recw/2
			if v.value == true then px = px + recw end
			
			love.graphics.circle("fill", px, sy+sh/2, sh/3*.5, 32)
			love.graphics.setColor(55, 55, 55, 255)
			love.graphics.circle("line", px, sy+sh/2, sh/3*.5, 32)
			--[[
			love.graphics.circle("fill", sx+sh, sy+sh/2, sh/2, 32)
			love.graphics.setColor(255, 255, 255, 155)
			love.graphics.circle("line", sx+sh, sy+sh/2, sh/2-2, 32)
			love.graphics.setColor(55, 55, 55, 255)
			love.graphics.circle("line", sx+sh, sy+sh/2, sh/2, 32)
			if v.value == true then
				love.graphics.setColor(0, 155, 255, 255)
				love.graphics.circle("fill", sx+sh, sy+sh/2, sh/4, 32)
				love.graphics.circle("line", sx+sh, sy+sh/2, sh/4, 32)
			end]]
		end
		sx = sx + font:getWidth(s .. ": ")
		if not shad then
			love.graphics.setLineWidth(1)
		end
		if v.extra == "image" then --IMAGE LOADER
			love.graphics.setColor(205, 215, 235, 255)
			if v.hovering then
				love.graphics.setColor(235, 235, 255, 255)
			end
			love.graphics.draw(noImage, sx+8.5, sy, 0, sh/noImage:getWidth(), sh/noImage:getHeight())
			
			love.graphics.setColor(55, 55, 55, 255)
			love.graphics.rectangle("line", sx+8.5, sy, sh, sh)
			
			if v.hovering then
				imageDrop = true
			end
		elseif type(v.value) == "table" and v.extra == "color" then --COLOR SETTING
			love.graphics.setColor(v.value)
			love.graphics.rectangle("fill", sx+8, sy, font:getHeight()*1.5, font:getHeight())
			love.graphics.setColor(255, 255, 255, 105)
			love.graphics.rectangle("line", sx+8.5+2, sy+2, font:getHeight()*1.5-4, font:getHeight()-4)
			love.graphics.setColor(55, 55, 55, 255)
			love.graphics.rectangle("line", sx+8.5, sy, font:getHeight()*1.5, font:getHeight())
		elseif type(v.value) == "number" and type(v.extra) == "table" then --NUMERICAL UI
			love.graphics.setColor(205, 215, 235, 255)
			if v.clicking == 1 then
				love.graphics.setColor(105, 155, 235, 255)
			elseif v.hovering == 1 then
				love.graphics.setColor(235, 235, 255, 255)
			end
			love.graphics.rectangle("fill", sx+8.5, sy+sh/4, sh/2, sh/2)
			love.graphics.setColor(255, 255, 255, 105)
			love.graphics.rectangle("line", sx+8.5+2, sy+sh/4+2, sh/2-4, sh/2-4)
			love.graphics.setColor(55, 55, 55, 255)
			love.graphics.rectangle("line", sx+8.5, sy+sh/4, sh/2, sh/2)
			love.graphics.line(sx+8.5+3*sh/8, sy+sh/4+sh/8, sx+8.5+sh/8, sy+sh/2)
			love.graphics.line(sx+8.5+3*sh/8, sy+sh/4+3*sh/8, sx+8.5+sh/8, sy+sh/2)
			
			love.graphics.setColor(255, 255, 255, 105)
			local smax = v.extra[2]
			if math.mod(v.extra[3] or 1, 1) ~= 0 then
				smax = smax+math.mod(v.extra[3] or 1, 1)
			end
			
			local news = v.value
			local edit = false
			if editMode and editMode[1] == i and editMode[2] == v then
				news = editMode[3]
				edit = true
			end
			for a = 1, 2 do
				if (shad and a == 1) or a == 2 then
					love.graphics.print(news, sx+ss+(2-a)*1.5+sh + font:getWidth(smax)/2 - font:getWidth(news)/2, sy+(2-a)*1.5)
					
					if edit and editMode[4][1] <= editMode[4][2]/2 then
						love.graphics.line(sx+ss+(2-a)*1.5+sh + font:getWidth(smax)/2 + font:getWidth(news)/2, sy+(2-a)*1.5, sx+ss+(2-a)*1.5+sh + font:getWidth(smax)/2 + font:getWidth(news)/2, sy+(2-a)*1.5 + font:getHeight())
					end
				end
				love.graphics.setColor(55, 85, 105, 255)
			end
			
			sx = math.floor(sx + ss+1.5+sh + font:getWidth(smax))
			if not shad then sx = sx - 3*sh/8 end
			
			love.graphics.setColor(205, 215, 235, 255)
			if v.clicking == 2 then
				love.graphics.setColor(105, 155, 235, 255)
			elseif v.hovering == 2 then
				love.graphics.setColor(235, 235, 255, 255)
			end
			love.graphics.rectangle("fill", sx+8.5, sy+sh/4, sh/2, sh/2)
			love.graphics.setColor(255, 255, 255, 105)
			love.graphics.rectangle("line", sx+8.5+2, sy+sh/4+2, sh/2-4, sh/2-4)
			love.graphics.setColor(55, 55, 55, 255)
			love.graphics.rectangle("line", sx+8.5, sy+sh/4, sh/2, sh/2)
			love.graphics.line(sx+8.5+sh/8, sy+sh/4+sh/8, sx+8.5+3*sh/8, sy+sh/2)
			love.graphics.line(sx+8.5+sh/8, sy+sh/4+3*sh/8, sx+8.5+3*sh/8, sy+sh/2)
			
		elseif type(v.extra) == "number" and type(v.value) == "table" then --ITEM SELECTION UI
			n = n+1
			sy = sy + sh+ss
			sx = sx - font:getWidth(s .. ": ") + sh
			
			love.graphics.setColor(205, 215, 235, 255)
			if v.clicking == 1 then
				love.graphics.setColor(105, 155, 235, 255)
			elseif v.hovering == 1 then
				love.graphics.setColor(235, 235, 255, 255)
			end
			love.graphics.rectangle("fill", sx+8.5, sy+sh/4, sh/2, sh/2)
			love.graphics.setColor(255, 255, 255, 105)
			love.graphics.rectangle("line", sx+8.5+2, sy+sh/4+2, sh/2-4, sh/2-4)
			love.graphics.setColor(55, 55, 55, 255)
			love.graphics.rectangle("line", sx+8.5, sy+sh/4, sh/2, sh/2)
			love.graphics.line(sx+8.5+3*sh/8, sy+sh/4+sh/8, sx+8.5+sh/8, sy+sh/2)
			love.graphics.line(sx+8.5+3*sh/8, sy+sh/4+3*sh/8, sx+8.5+sh/8, sy+sh/2)
			
			local smax = ""
			for a, b in ipairs(v.value) do
				if font:getWidth(b) > font:getWidth(smax) then
					smax = b
				end
			end
			
			love.graphics.setColor(255, 255, 255, 105)
			for a = 1, 2 do
				if (shad and a == 1) or a == 2 then
					love.graphics.print(v.value[v.extra], sx+ss+(2-a)*1.5+sh + font:getWidth(smax)/2 - font:getWidth(v.value[v.extra])/2, sy+(2-a)*1.5)
				end
				love.graphics.setColor(55, 85, 105, 255)
			end
			
			sx = math.floor(sx + ss+1.5+sh + font:getWidth(smax))
			if not shad then sx = sx - 3*sh/8 end
			
			love.graphics.setColor(205, 215, 235, 255)
			if v.clicking == 2 then
				love.graphics.setColor(105, 155, 235, 255)
			elseif v.hovering == 2 then
				love.graphics.setColor(235, 235, 255, 255)
			end
			love.graphics.rectangle("fill", sx+8.5, sy+sh/4, sh/2, sh/2)
			love.graphics.setColor(255, 255, 255, 105)
			love.graphics.rectangle("line", sx+8.5+2, sy+sh/4+2, sh/2-4, sh/2-4)
			love.graphics.setColor(55, 55, 55, 255)
			love.graphics.rectangle("line", sx+8.5, sy+sh/4, sh/2, sh/2)
			love.graphics.line(sx+8.5+sh/8, sy+sh/4+sh/8, sx+8.5+3*sh/8, sy+sh/2)
			love.graphics.line(sx+8.5+sh/8, sy+sh/4+3*sh/8, sx+8.5+3*sh/8, sy+sh/2)
		end
	end
	
	local sx, sy, sh, ss = 256, 10+gothic["48"]:getHeight()*.75 + gothic["24"]:getHeight() + off, 28, 2
	local n = 0
	
	--Main settings
	love.graphics.setFont(gothic["20"])
	for i, v in ipairs(settings) do
		run(i, v, n, sx, sy, sh, ss, true)
		if type(v.extra) == "number" and type(v.value) == "table" then n = n + 1 end
		n = n + 1
	end
	
	--Canvas size presets
	love.graphics.setFont(gothic["12"])
	sy = sy + #settings*(sh+ss) + sh/2
	local bw, bs = 32, 8
	for i, v in ipairs(canvas_presets) do
		local xx = sx + (i-1)*(bw+bs)
		
		local sc = math.min(bw/v.w, bw/v.h)
		love.graphics.setColor(205, 235, 255, 255)
		if v.high then
			love.graphics.setColor(235, 245, 255, 255)
		end
		if v.down then
			love.graphics.setColor(155, 205, 255, 255)
		end
		love.graphics.rectangle("fill", xx + bw/2 - v.w*sc/2, sy + bw/2 - v.h*sc/2, v.w*sc, v.h*sc)
		
		love.graphics.setColor(55, 55, 55, 255)
		love.graphics.rectangle("line", xx + bw/2 - v.w*sc/2, sy + bw/2 - v.h*sc/2, v.w*sc, v.h*sc)
		love.graphics.print(v.t, xx + bw/2 - gothic["12"]:getWidth(v.t)/2, sy + bw/2 - gothic["12"]:getHeight()/2)
		
		if v.high then
			local res = "[" .. v.w .. "x" .. v.h .. "]   "
			love.graphics.print(v.value, sx + gothic["12"]:getWidth(res), sy+bw+bs/2)
			
			love.graphics.setColor(0, 0, 0, 105)
			love.graphics.print(res, sx+.5, sy+bw+bs/2+1)
			love.graphics.setColor(55, 75, 105, 255)
			love.graphics.print(res, sx, sy+bw+bs/2)
		end
	end
	
	--Navigation and Preview settings
	love.graphics.setFont(gothic["24"])
	n = 0
	sx, sy, sh, ss = (256-off-12)/2, wy-off, 64, 7
	local w = 0
	for i, v in ipairs(settings_under) do
		local s = i
		if v.t then s = v.t end
		w = math.max(w, gothic["24"]:getWidth(s)+gothic["24"]:getHeight())
	end
	local xx = sx - w/2
	for i, v in ipairs(settings_under) do
		run(i, v, n, xx, sy, sh, ss, true, w)
		n = n + 1
	end
	
	--Randomization settings
	n = 0
	sy, sh, ss = buttons["random"].y, 16, 7
	for i, v in ipairs(settings_random) do
		sy = sy - sh - ss
	end
	
	love.graphics.setFont(gothic["12"])
	for i, v in ipairs(settings_random) do
		local xx = buttons["random"].x--windowW - off - gothic["12"]:getWidth(v.t) - sh - off
		run(i, v, n, xx, sy, sh, ss, false)
		n = n + 1
	end
	
		love.graphics.push()
		love.graphics.setScissor(off+2, y+off+2, 256-off*2-12-4, windowH-y-off*4-256-4)
	
	love.graphics.setFont(gothic["12"])
	local sx, sy, sh, ss = off, y+off+3, 16, 4
	if patterns[selectedPattern].variables then
		if patterns[selectedPattern].varheight > 9 then
			love.graphics.translate(0, 3-(scrolls["left"].value*(6+patterns[selectedPattern].varheight*(ss+sh)-(windowH-y-off*4-256))))
		end
		n = 0
		for i, v in pairs(patterns[selectedPattern].variables) do
			run(i, v, n, sx, sy, sh, ss)
			if type(v.extra) == "number" and type(v.value) == "table" then n = n + 1 end
			n = n + 1
		end
	end
	
	
	--"Drop an image" popup
	if imageDrop then
		--scissor(off+2, y+off+2, 256-off*2-12-4, windowH-y-off*4-256-4)
		local t = "Drop an image file to load"
		local toff = 2
		local recx = math.max(off+2+toff, math.min(love.mouse.getX(), (256-off*2-12-4)-gothic["12"]:getWidth(t)-toff*2))
		local recy = math.max(y+off+2+toff, math.min(love.mouse.getY()+20, (windowH-y-off*4-256-4)-gothic["12"]:getHeight()-toff*2))
		local recw = gothic["12"]:getWidth(t) + toff*2
		local rech = gothic["12"]:getHeight() + toff*2
		
		love.graphics.setColor(255, 255, 155, 205)
		love.graphics.rectangle("fill", recx, recy, recw, rech)
		love.graphics.setColor(55, 55, 0, 255)
		love.graphics.rectangle("line", recx, recy, recw, rech)
		love.graphics.print(t, recx+toff, recy+toff)
	end
	
		love.graphics.setScissor()
		love.graphics.pop()
	
	
	--==================--
	-- PATTERN SELECTOR --
	--==================--
	
	love.graphics.push()
	love.graphics.setFont(gothic["12"])
	local wx, wy, ww, wh = off+ww, windowH-off-256, windowW-ww-off, 256
	love.graphics.setScissor(wx, wy, ww, wh)
	love.graphics.translate(wx, wy)
	
	selector.draw(ww/2, wh/2, function(x, y, w, h, s, i)
		love.graphics.setColor(0, 35, 55, 255)
		if i == 1 then
			love.graphics.setColor(0, 55, 155, 255)
		end
		love.graphics.setLineWidth(3*(#previewSizes.sizes/i))
		love.graphics.rectangle("line", x, y, w, h)
	end)
	
	love.graphics.setColor(205, 205, 205, 255)
	love.graphics.draw(grad, 0, 0, 0, ww/256, 64/256)
	love.graphics.draw(grad, ww, wh, math.pi, ww/256, 64/256)
	
	love.graphics.setScissor()
	love.graphics.pop()
	
	
	--=================--
	-- PATTERN PREVIEW --
	--=================--
	local wx, wy, ww, wh = off+256, windowH-off-256, 640-256, 256
	love.graphics.setLineWidth(3)
	love.graphics.setColor(0, 0, 0, 255)
	love.graphics.rectangle("line", wx, wy, ww, wh)
	love.graphics.setScissor(wx, wy, ww, wh)
	love.graphics.push()
	love.graphics.translate(wx, wy)
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.rectangle("fill", 0, 0, ww, wh)
	love.graphics.draw(patternCanvas, 0, 0)
	love.graphics.pop()
	love.graphics.setScissor()
	
	
	--==============--
	-- GUI ELEMENTS --
	--==============--
	love.graphics.setLineWidth(2)
	for i, v in pairs(buttons) do
		v:draw()
	end
	love.graphics.setColor(255, 255, 255, 155)
	local v = buttons.uppat
	love.graphics.polygon("fill", v.x+v.width/2, v.y+v.height/4, v.x+v.width/2-v.width/8, v.y+v.height/4*3, v.x+v.width/2+v.width/8, v.y+v.height/4*3)
	love.graphics.setColor(0, 0, 0, 255)
	love.graphics.polygon("line", v.x+v.width/2, v.y+v.height/4, v.x+v.width/2-v.width/8, v.y+v.height/4*3, v.x+v.width/2+v.width/8, v.y+v.height/4*3)
	
	love.graphics.setColor(255, 255, 255, 155)
	local v = buttons.downpat
	love.graphics.polygon("fill", v.x+v.width/2, v.y+v.height/4*3, v.x+v.width/2-v.width/8, v.y+v.height/4, v.x+v.width/2+v.width/8, v.y+v.height/4)
	love.graphics.setColor(0, 0, 0, 255)
	love.graphics.polygon("line", v.x+v.width/2, v.y+v.height/4*3, v.x+v.width/2-v.width/8, v.y+v.height/4, v.x+v.width/2+v.width/8, v.y+v.height/4)
	
	love.graphics.setLineWidth(1)
	for i, v in pairs(scrolls) do
		v:draw()
	end
	
	for i, v in pairs(colors) do
		v:draw()
	end
	
	
	
	--========================--
	-- PREVIEW AND SAVE POPUP --
	--========================--
	if patternPreview and patternPreview ~= "false" then
		
		--Background darkness
		love.graphics.setColor(0, 0, 0, 155)
		love.graphics.rectangle("fill", 0, 0, windowW, windowH)
		love.graphics.draw(grad, 0, 0, 0, windowW/256, windowH/2/256)
		love.graphics.draw(grad, windowW, windowH, math.pi, windowW/256, windowH/2/256)
		
		local width, height = 480, 400
		--Popup whiteness
		love.graphics.setColor(255, 255, 255, 105)
		love.graphics.rectangle("fill", windowW/2-width/2, windowH/2-height/2, width, height)
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.setLineWidth(2)
		love.graphics.rectangle("line", windowW/2-width/2, windowH/2-height/2, width, height)
		love.graphics.draw(grad, windowW/2-width/2, windowH/2, 0, width/256, height/2/256)
		love.graphics.draw(grad, windowW/2-width/2, windowH/2, 0, width/256, height/2/256)
		love.graphics.draw(grad, windowW/2+width/2, windowH/2, math.pi, width/256, height/2/256)
		love.graphics.draw(grad, windowW/2+width/2, windowH/2, math.pi, width/256, height/2/256)
		
		local w, h = patternPreview:getWidth(), patternPreview:getHeight()
		local factor = 320/math.max(w, h)
		love.graphics.draw(patternPreview, windowW/2-factor*w/2, windowH/2-factor*h/2-12-8, 0, (factor*w)/w, (factor*h)/h)
		love.graphics.setColor(0, 0, 0, 255)
		love.graphics.setLineWidth(3)
		love.graphics.rectangle("line", windowW/2-factor*w/2, windowH/2-factor*h/2-12-8, factor*w, factor*h)
		
		love.graphics.setColor(255, 255, 255, 255)
		buttons.previewsave:draw()
		love.graphics.setColor(0, 35, 55, 255)
		love.graphics.setFont(gothic["24"])
		love.graphics.print("Save as image", windowW/2-gothic["24"]:getWidth("Save as image")/2, windowH/2+320/2+10-math.floor(gothic["24"]:getHeight()/2))
	end
	
	
	--======================--
	-- RESET SETTINGS POPUP --
	--======================--
	if resetMode.active == true then
		love.graphics.setColor(0, 0, 0, 155)
		love.graphics.rectangle("fill", 0, 0, windowW, windowH)
		love.graphics.draw(grad, 0, 0, 0, windowW/256, windowH/2/256)
		love.graphics.draw(grad, windowW, windowH, math.pi, windowW/256, windowH/2/256)
		
		local width, height = 600, 300
		--Popup whiteness
		love.graphics.setColor(255, 255, 255, 105)
		love.graphics.rectangle("fill", windowW/2-width/2, windowH/2-height/2, width, height)
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.setLineWidth(2)
		love.graphics.rectangle("line", windowW/2-width/2, windowH/2-height/2, width, height)
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.draw(grad, windowW/2-width/2, windowH/2, 0, width/256, height/2/256)
		love.graphics.draw(grad, windowW/2-width/2, windowH/2, 0, width/256, height/2/256)
		love.graphics.draw(grad, windowW/2+width/2, windowH/2, math.pi, width/256, height/2/256)
		love.graphics.draw(grad, windowW/2+width/2, windowH/2, math.pi, width/256, height/2/256)
		love.graphics.setLineWidth(3)
		resetMode.button:draw()
		love.graphics.setColor(0, 35, 55, 255)
		love.graphics.setFont(gothic["24"])
		local t = "Are you sure you want to reset all settings?"
		love.graphics.print(t, windowW/2-gothic["24"]:getWidth(t)/2, windowH/2-gothic["24"]:getHeight()*2)
		t = "This action cannot be undone!"
		love.graphics.print(t, windowW/2-gothic["24"]:getWidth(t)/2, windowH/2-gothic["24"]:getHeight())
		love.graphics.print("Reset all settings", windowW/2-gothic["24"]:getWidth("Reset all settings")/2, windowH/2+gothic["24"]:getHeight())
	end
	
	
	--===============--
	-- NOTIFICATIONS --
	--===============--
	love.graphics.setFont(gothic["16"])
	love.graphics.setLineWidth(2)
	local font = gothic["16"]
	local off = 4
	local yy = 0
	for i, v in ipairs(notifications) do
		local x = windowW - font:getWidth(v.text) - font:getHeight()-off
		local y = off*2 + yy
		if v.timer <= v.moveTimer then
			y = (yy + font:getHeight()+off*2) * (v.timer/v.moveTimer) - font:getHeight()
		elseif v.timer >= v.maxtimer - v.moveTimer then
			y = (yy + font:getHeight()+off*2) * (1 - (v.timer - (v.maxtimer-v.moveTimer))/v.moveTimer) - font:getHeight()
		end
		y = y-off
		
		love.graphics.setColor(55, 55, 55, 255)
		love.graphics.rectangle("fill", x, y, font:getWidth(v.text) + font:getHeight(), font:getHeight()+off)
		love.graphics.setColor(155, 155, 155, 255)
		love.graphics.rectangle("line", x, y, font:getWidth(v.text) + font:getHeight(), font:getHeight()+off)
		love.graphics.setColor(105, 205, 255, 155)
		for a = 1, 2 do
			love.graphics.print(v.text, x+font:getHeight()/2+(2-a)*2, y+off/2+(2-a)*2)
			love.graphics.setColor(235, 235, 235, 255)
		end
		yy = y + font:getHeight()+off
	end
end

function drawPattern(w, h, v)
	local c = {love.graphics.getColor()}
	local endx, endy
	if not v.rateX then v.rateX = 32 end
	if not v.rateY then v.rateY = 32 end
	
	if v.rateX <= 0 then
		endx = 1
	elseif v.rateX <= 1 then
		endx = 1/v.rateX
	else
		endx = math.ceil(w/v.rateX)
	end
	
	if v.rateY <= 0 then
		endy = 1
	elseif v.rateY <= 1 then
		endy = 1/v.rateY
	else
		endy = math.ceil(h/v.rateY)
	end
	
	if v.setRate then
		endx, endy = v.setRate(w, h, patternSize)
	end
		
	for x = 1, math.ceil(endx*(1/patternSize)) do
		for y = 1, math.ceil(endy*(1/patternSize)) do
			love.graphics.setLineWidth(1)
			love.graphics.setColor(c)
			v.draw(x, y, w, h, patternSize, c)
		end
	end
end

function love.keypressed(key)
	if key == "kp." then key = "."
	elseif string.sub(key, 1, 2) == "kp" and tonumber(string.sub(key, 3, -1)) then
	key = tonumber(string.sub(key, 3, -1)) end
	
	for i, v in pairs(colors) do
		if v:keypressed(key) then
			return
		end
	end
	if editMode then
		local i, v, val, timer = unpack(editMode)
		
		local function getNumber(s)
			local s = s or ""
			if string.sub(s, -1, -1) == "." then
				s = string.sub(s, 1, -2)
			end
			
			if not tonumber(s) then
				return v.extra[2]
			else
				local n = tonumber(s)
				local f = 1/v.extra[1]
				
				local md = n*f-v.extra[1]*f
				--print("n-ex1 = " .. md)
				local md2 = (v.extra[3] or 1)*f
				--print("ex3 = " .. md2)
				
				local md3 = (md/md2)
				--print("md/md2 = " .. md3)
				--print("floor = " .. math.floor(md3))
				md3 = md3 - math.floor(md3)
				if md3 <= 0 or md3 == 1 then md3 = 0 end
				--print("mod = " .. md3)
				
				--print("n = " .. n)
				if n < v.extra[1] then
					n = v.extra[1]
				elseif n > v.extra[2] then
					n = v.extra[2]
				elseif md3 ~= 0 then
					n = math.max(v.extra[1], n-v.extra[1] - md3 + v.extra[1])
				end
				
				return n
			end
		end
		
		local maxs = v.extra[2] + ( (v.extra[3] or 1) - math.floor(v.extra[3] or 1) )
		if key == "backspace" then
			if string.len(val) > 1 then
				val = string.sub(val, 1, -2)
			else
				val = ""
			end
		elseif key == "enter" or key == "return" or key == "kpenter" then
			v.value = getNumber(val)
			if v.var then
				_G[v.var] = getNumber(val)
			end
			changePatternSize(0)
			editMode = false
			v.clicking = false
		elseif key == "escape" then
			if v.var then
				_G[v.var] = v.value
			end
			changePatternSize(0)
			editMode = false
			v.clicking = false
		elseif tonumber(key) and string.len(val) < string.len(maxs) then
			val = val .. key
		elseif key == "." and string.len(val) < string.len(maxs) then
			local can = true
			if string.len(val) >= 1 then
				for a = 1, string.len(val) do
					if string.sub(val, a, a) == "." then
						can = false
					end
				end
			end
			
			if can then
				val = val .. key
			end
		end
		
		if editMode then
			editMode[3] = val
			
			if v.var then
				_G[v.var] = getNumber(val)
				changePatternSize(0)
			end
		end
		
		return
	end
	--HBD:keypressed(key)
	if key == "escape" then
		previewMode(true)
		resetMode.active = false
		return
	end
	
	--[[if key == "down" then
		selectedPattern = selector.select(1)
		changePatternSize(0)
	elseif key == "up" then
		selectedPattern = selector.select(-1)
		changePatternSize(0)
	elseif key == "left" then
		changePatternSize(-2)
		settings[1].value = patternSize
	elseif key == "right" then
		changePatternSize(2)
		settings[1].value = patternSize
	elseif key == "enter" or key == "return" or key == "kpenter" then
		previewMode()
	end]]
end

function love.quit()
	saveSettings()
	
	local n = os.date("*t")
	newLog("Pattern Generator v" .. version .. " exited", "logout")
end

function love.mousepressed(x, y, button)
	-- Color GUIs
	for i, v in pairs(colors) do
		if v:mousepressed(x, y, button) then
			return
		end
	end
	
	-- Pattern Preview and Save Popup
	if patternPreview and patternPreview ~= "false" then
		buttons.previewsave:mousepressed(x, y, button)
		local width, height = 480, 400
		if button == 1 and not inside(x, y, 0, 0, windowW/2-width/2, windowH/2-height/2, width, height) then
			previewMode(true)
			patternPreview = "false"
		end
		return
	end
	if resetMode.active then
		if inside(x, y, 0, 0, windowW/2-300, windowH/2-150, 600, 300) then
			resetMode.button:mousepressed(x, y, button)
		else
			resetMode.active = "false"
		end
		return
	end
	
	local off = 20
	local top = 240
	local wx, wy, ww, wh = off, windowH-off-256, 640, 256
	local sx, sy, sh, ss = 256, 10+gothic["48"]:getHeight()*.75 + gothic["24"]:getHeight() + off, 32, 4
	local n = 0
	
	local tm = {0, 1}
	local wasEdit = false
	if editMode then
		tm = editMode[4]
		wasEdit = editMode[3]
	end
	editMode = false
	local function run(i, v, n, sx, sy, sh, ss, shad, yy, w)
		local font = gothic["12"]
		local yy = yy or y
		if shad == true then
			font = gothic["24"]
		elseif shad == "20" then
			font = gothic["20"]
			shad = true
		end
		n = n+1
		local s = i
		if v.t then s = v.t end
		local w = w or font:getWidth(s)+font:getHeight()
		
		sy = sy + (n-1)*(sh+ss)
		if type(v.value) == "function" then --BUTTON
			if inside(x, yy, 0, 0, sx+font:getHeight()/2, sy, w, sh) then
				v.clicking = true
				v.value()
			end
		elseif type(v.value) == "boolean" then --CHECKBOX
			local recw = sh/3*2.5
			if distance(x, y, sx+sh-recw/2, sy+sh/2) <= sh/3 then
				v.value = not v.value
			elseif distance(x, y, sx+sh+recw/2, sy+sh/2) <= sh/3 then
				v.value = not v.value
			elseif inside(x, y, 0, 0, sx+sh-recw/2, sy+sh/2-sh/3, recw, 2*sh/3) then
				v.value = not v.value
			end
		end
		sx = sx + font:getWidth(s .. ": ")
		if type(v.value) == "table" and v.extra == "color" then --COLOR SETTING
			if inside(x, yy, 0, 0, sx+8, sy, font:getHeight()*1.5, font:getHeight()) then
				v.gui.active = true
			end
		elseif type(v.value) == "number" and type(v.extra) == "table" then --NUMERICAL UI
			local wasClick = false
			if v.clicking == 3 then
				v.clicking = false
				wasClick = true
			end
			if inside(x, yy, 0, 0, sx+8.5, sy+sh/4, sh/2, sh/2) then
				v.clicking = 1
				v.value = math.max(v.extra[1], v.value-(v.extra[3] or 1))
				
				if v.var then
					_G[v.var] = v.value
				end
			end
			
			local smax = v.extra[2]
			if math.mod(v.extra[3] or 1, 1) ~= 0 then
				smax = smax+math.mod(v.extra[3] or 1, 1)
			end
			
			local function getNumber(s)
				local s = s or ""
				if string.sub(s, -1, -1) == "." then
					s = string.sub(s, 1, -2)
				end
				
				if not tonumber(s) then
					return v.extra[2]
				else
					local n = tonumber(s)
					local f = 1/v.extra[1]
					
					local md = n*f-v.extra[1]*f
					--print("n-ex1 = " .. md)
					local md2 = (v.extra[3] or 1)*f
					--print("ex3 = " .. md2)
					
					local md3 = (md/md2)
					--print("md/md2 = " .. md3)
					--print("floor = " .. math.floor(md3))
					md3 = md3 - math.floor(md3)
					if md3 <= 0 or md3 == 1 then md3 = 0 end
					--print("mod = " .. md3)
					
					--print("n = " .. n)
					if n < v.extra[1] then
						n = v.extra[1]
					elseif n > v.extra[2] then
						n = v.extra[2]
					elseif md3 ~= 0 then
						n = math.max(v.extra[1], n-v.extra[1] - md3 + v.extra[1])
					end
					
					return n
				end
			end
			
			
			if inside(x, yy, 0, 0, sx+ss+sh, sy+sh/2-font:getHeight()/2, font:getWidth(smax), font:getHeight()) then
				v.clicking = 3
				editMode = {i, v, v.value, {0, 1}}
			elseif v.clicking == 3 then
				v.clicking = false
				v.value = getNumber(wasEdit)
				if v.var then
					_G[v.var] = v.value
				end
				changePatternSize(0)
				editMode = false
			end
			
			local sx = math.floor(sx + ss+1.5+sh + font:getWidth(smax))
			if not shad then sx = sx - 3*sh/8 end
			
			if inside(x, yy, 0, 0, sx+8.5, sy+sh/4, sh/2, sh/2) then
				v.clicking = 2
				v.value = math.min(v.extra[2], v.value+(v.extra[3] or 1))
				
				if v.var then
					_G[v.var] = v.value
				end
			end
			
			if v.clicking == false and wasClick then
				--if editMode and editMode[1] == i and editMode[2] == v then
					v.value = getNumber(wasEdit)
					if v.var then
						_G[v.var] = v.value
					end
					changePatternSize(0)
					editMode = false
				--end
			end
		elseif type(v.extra) == "number" and type(v.value) == "table" then --ITEM SELECTION UI
			n = n+1
			sy = sy + sh+ss
			sx = sx - font:getWidth(s .. ": ") + sh
			
			if inside(x, yy, 0, 0, sx+8.5, sy+sh/4, sh/2, sh/2) then
				v.clicking = 1
				v.extra = v.extra - 1
				if v.extra == 0 then
					v.extra = #v.value
				end
			end
			
			local smax = ""
			for a, b in ipairs(v.value) do
				if font:getWidth(b) > font:getWidth(smax) then
					smax = b
				end
			end
			sx = math.floor(sx + ss+1.5+sh + font:getWidth(smax))
			if not shad then sx = sx - 3*sh/8 end
			
			if inside(x, yy, 0, 0, sx+8.5, sy+sh/4, sh/2, sh/2) then
				v.clicking = 2
				v.extra = v.extra + 1
				if v.extra > #v.value then
					v.extra = 1
				end
			end
		end
	end
	if editMode then
		editMode[4] = tm
	end
	local sx, sy, sh, ss = 256, 10+gothic["48"]:getHeight()*.75 + gothic["24"]:getHeight() + off, 28, 2
	local n = 0
	
		if button == 1 then
	
	for i, v in ipairs(settings) do
		run(i, v, n, sx, sy, sh, ss, "20")
		if type(v.extra) == "number" and type(v.value) == "table" then n = n + 1 end
		n = n + 1
	end
	
	
	sy = sy + #settings*(sh+ss) + sh/2
	local bw, bs = 32, 8
	for i, v in ipairs(canvas_presets) do
		if button == 1 then
			
			local xx = sx + (i-1)*(bw+bs)
			
			local sc = math.min(bw/v.w, bw/v.h)
			if inside(x, y, 0, 0, xx + bw/2 - v.w*sc/2, sy + bw/2 - v.h*sc/2, v.w*sc, v.h*sc) then
				settings[4].value = v.w
				if settings[4].var then
					_G[settings[4].var] = v.w
				end
				settings[5].value = v.h
				if settings[5].var then
					_G[settings[5].var] = v.h
				end
				
				v.down = true
			end
			
		end
	end
	
	
	n = 0
	sx, sy, sh, ss = (256-off-12)/2, wy-off, 64, 7
	local w = 0
	for i, v in ipairs(settings_under) do
		local s = i
		if v.t then s = v.t end
		w = math.max(w, gothic["24"]:getWidth(s)+gothic["24"]:getHeight())
	end
	local xx = sx - w/2
	for i, v in ipairs(settings_under) do
		run(i, v, n, xx, sy, sh, ss, true, false, w)
		n = n + 1
	end
	
	n = 0
	sy, sh, ss = buttons["random"].y, 16, 7
	for i, v in ipairs(settings_random) do
		sy = sy - sh - ss
	end
	
	for i, v in ipairs(settings_random) do
		local xx = buttons["random"].x--windowW - off - gothic["12"]:getWidth(v.t) - sh - off
		run(i, v, n, xx, sy, sh, ss, false)
		n = n + 1
	end
	
	local sx, sy, sh, ss = off, 3+(10+gothic["48"]:getHeight()*.75 + gothic["24"]:getHeight())+off, 16, 4
	if patterns[selectedPattern].variables and inside(x, y, 0, 0, off, sy, 256-off*2-12, windowH-sy-off*3-256) then
		n = 0
		local yy = y
		if patterns[selectedPattern].varheight > 9 then
			yy = y+(scrolls["left"].value*((patterns[selectedPattern].varheight-1)*(ss+sh)-(windowH-sy-off*4-256)))
		end
		for i, v in pairs(patterns[selectedPattern].variables) do
			run(i, v, n, sx, sy, sh, ss, false, yy)
			if type(v.extra) == "number" and type(v.value) == "table" then n = n + 1 end
			n = n + 1
		end
	end
	changePatternSize(0)
	
	-- Refresh button
	if inside(love.mouse.getX(), love.mouse.getY(), 0, 0, windowW-refresh:getWidth()-2, wy-off-3-refresh:getHeight(), refresh:getWidth(), refresh:getHeight()) then
		if not editMode and not resetMode.active and not patternPreview then
			saveSettings()
			love.load()
			newNotice("Reloaded successfully")
			newLog("Program reloaded by user", "log")
			return
		end
	end
	
		end
	
	
	for i, v in pairs(buttons) do
		v:mousepressed(x, y, button)
	end
	for i, v in pairs(scrolls) do
		local lc = v.lastclick
		v:mousepressed(x, y, button)
		if v.lastclick ~= lc then
			
			for j, w in pairs(scrolls) do
				if j ~= i and w.lastclick then
					w.lastclick = false
				end
			end
			
		end
	end
end

function love.mousereleased(x, y, button)
	for i, v in pairs(colors) do
		if v:mousereleased(x, y, button) then
			return
		end
	end
	
	for i, v in ipairs(canvas_presets) do
		if button == 1 then
			v.down = false
		end
	end
	
	if button == 1 then
		for i, v in ipairs(settings) do
			if v.clicking ~= 3 then
				v.clicking = false
			end
		end
		for i, v in ipairs(settings_under) do
			v.clicking = false
		end
		for i, v in ipairs(settings_random) do
			v.clicking = false
		end
		if patterns[selectedPattern].variables then
			for i, v in pairs(patterns[selectedPattern].variables) do
				v.clicking = false
			end
		end
	end
	
	if resetMode.active then
		resetMode.button:mousereleased(x, y, button)
		if resetMode.active == "false" then
			resetMode.active = false
		end
		return
	end
	
	if patternPreview then
		buttons.previewsave:mousereleased(x, y, button)
		if patternPreview == "false" then
			patternPreview = false
		end
		return
	end
	
	for i, v in pairs(buttons) do
		v:mousereleased(x, y, button)
	end
	for i, v in pairs(scrolls) do
		v:mousereleased(x, y, button)
	end
end

function love.wheelmoved(x, y)
	for i, v in pairs(colors) do
		if v:wheelmoved(x, y) then
			return
		end
	end
	
	for i, v in pairs(buttons) do
		v:wheelmoved(x, y)
	end
	for i, v in pairs(scrolls) do
		local lc = v.lastclick
		v:wheelmoved(x, y)
		if v.lastclick ~= lc then
			
			for j, w in pairs(scrolls) do
				if j ~= i and w.lastclick then
					w.lastclick = false
				end
			end
			
		end
	end
end

function love.filedropped(file)
	newLog("File \"" .. file:getFilename() .. "\" dropped", "log")
	if patterns[selectedPattern].variables then
		for i, v in pairs(patterns[selectedPattern].variables) do
			
			if v.hovering and v.extra == "image" then
				local path = file:getFilename()
				local forms = {".png", ".tga"}
				local can = false
				for a = 1, #forms do
					if string.sub(string.lower(path), -string.len(forms[a]), -1) == forms[a] then
						can = forms[a]
						break
					end
				end
				
				if can then
					love.filesystem.write("temp" .. can, tostring( file:read() ))
					v.value = love.image.newImageData("temp" .. can)
					v.value = love.graphics.newImage(v.value)
					love.filesystem.remove("temp" .. can)
					
					changePatternSize(0)
				end
			end
			
		end
	end
end

function love.directorydropped(directory)
	newLog("Directory \"" .. directory .. "\" dropped", "log")
end

function changePatternSize(i)
	patternSize = math.min(5, math.max(.2, patternSize+.1*i))
	love.graphics.setCanvas(patternCanvas)
	love.graphics.clear(255, 255, 255, 0)
	love.graphics.setColor(backColor)
	love.graphics.rectangle("fill", 0, 0, 640-256, 256)
	love.graphics.setColor(patternColor)
	drawPattern(640-256, 256, patterns[selectedPattern])
	love.graphics.setCanvas()
end

function love.graphics.dashedLine(x1, y1, x2, y2, pointyness) --Pointyness should be a word, it sounds so funny :P
	local pointyness = pointyness or 10
	local a = math.atan2(y2-y1, x2-x1)
	
	local size = distance(x1, y1, x2, y2)
	
	for i = 1, math.ceil(size/pointyness) do
		local p1x, p1y = math.cos(a)*(i-1)*pointyness, math.sin(a)*(i-1)*pointyness
		local p2x, p2y = math.cos(a)*i*pointyness, math.sin(a)*i*pointyness
		
		if i == math.ceil(size/pointyness) then
			p2x = x2-x1
			p2y = y2-y1
		end
		
		if math.mod(i, 2) ~= 0 then
			love.graphics.line(p1x+x1, p1y+y1, p2x+x1, p2y+y1)
		end
	end
end

function love.graphics.dashedRectangle(x, y, w, h, pointyness)
	love.graphics.dashedLine(x, y, x + w, y, pointyness)
	love.graphics.dashedLine(x, y, x, y + h, pointyness)
	love.graphics.dashedLine(x + w, y, x + w, y + h, pointyness)
	love.graphics.dashedLine(x, y + h, x + w, y + h, pointyness)
end

function distance(x1, y1, x2, y2)
	return math.sqrt(math.abs(x1-x2)^2 + math.abs(y1-y2)^2)
end

--[[function loadIcon() --OBSOLETE, but might reuse some day
	love.graphics.clear()
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.rectangle("fill", 0, 0, 32, 32)
	love.graphics.setColor(155, 205, 255, 255)
	love.graphics.setLineWidth(3)
	love.graphics.dashedRectangle(0, 0, 32, 32, 4)
	love.graphics.setLineWidth(1)
	love.graphics.setColor(155, 205, 255, 128)
	love.graphics.dashedLine(0, 0, 32, 32, 4)
	love.graphics.dashedLine(32, 0, 0, 32, 4)
	local ic = love.graphics.newScreenshot()
	love.graphics.present()
	love.graphics.clear()
	love.graphics.present()
	
	local nic = love.image.newImageData(32, 32)
	nic:paste(ic, 0, 0, 0, 0, 32, 32)
	love.window.setIcon(nic)
end]]

function table.contains(t, e) --Iterates through table and find the first matching item, returning its index
	for i, v in pairs(t) do
		if v == e then
			return i
		end
	end
	return false
end

--===============--
-- LOAD SETTINGS --
--===============--
function loadSettings()
	--[[
		
		This function is in charge of saving all the data we feel is necessary to make pattern-loading easier
		and more convenient. This functin saves anything related to how a certain pattern is displayed, so that
		if the user quits the program and opens it up again, it'll be exactly as he left it. I also made it so
		that it'd be easier to read the save.dat file, as well as give myself room to add new features. This
		resulted in a pretty complicated code (that works), so I'll try my best to explain all this...
		
	]]
	
	if love.filesystem.exists("save.dat") then
		-- This part reads the variables from the file and translate them into their
		-- "real names", as we're using fake ones to make save.dat easier to read
		local vars = {"SelectedPattern", "ImageWidth", "ImageHeight", "PatternSize", "PatternColor", "PatternsOptions", "PatternBackground", "RandomOptions"}
		local vals = {"selectedPattern", "patternWidth", "patternHeight", "patternSize", "patternColor", "options", "backColor", "randomOptions"}
		
		local s = love.filesystem.read("save.dat")
		for v in string.gmatch(s,'[^\n]+') do --iterate through each line of the save file
			
			local n = string.find(v, " = ")
			local e = table.contains(vars, string.sub(v, 1, n-1))
			if e then --detects if the variable is listed
				local s2 = string.sub(v, n+3, -1)
				_G[ vals[e] ] = toVar(s2) --changes the value of the variable mentioned
			end
		end
	end
	
	--Settings for randomization. Just for convenience.
	if randomOptions then
		for i, v in ipairs(randomOptions) do
			settings_random[i].value = v
		end
	end
	
	--This part takes care of custom options from each pattern file that contains it
	for i, v in ipairs(options) do
		local t = {""}
		--[[
			Options are stored in a custom data 'encryption'. That means we can save multiple data in a single
			string. To decode it, we must 'decrypt' that. In my method, different items are separated by a ';'
			but, to allow the user to have ';' in their variable names, I replace them with '!;' (much like the
			backslash method built in, but for this specific case only).
		]]
		for j = 1, string.len(v) do
			local lc = ""
			if j > 1 then lc = string.sub(v, j-1, j-1) end
			local c = string.sub(v, j, j)
			if c == ";" and lc ~= "!" then
				table.insert(t, "")
			else
				t[#t] = t[#t] .. c
			end
		end
		local p
		for a, b in ipairs(patterns) do
			if b.name == t[1] then
				p = a
			end
		end
		
		
		for j, w in ipairs(t) do
			if j == 1 or w == "nil" then
				--ignore, this is the option's name
			else
				local f = 1
				for c = 1, string.len(w) do
					--[[
						Same situation as above, but with a collon instead. Plus, an extra security measure for cases like '!!;', where the last
						character is the special one. Doesn't count for cases like '!!!;' (!; in-text), but that'd require a very specific detector
						for such a tiny probability. I may change this in the future if I feel like it can cause problems...
					]]
					if string.sub(w, c, c) == ":" and c > 1 and not (string.sub(w, c-1, c-1) == "!" and c > 2 and string.sub(w, c-2, c-2) ~= "!") then
						f = c
						break
					end
				end
				-- Here we define from the separator which string is the name and which string is the value
				local var = string.sub(w, 1, f-1)
				local val = string.sub(w, f+1, -1)
				
				-- Here we replace the special characters we set earlier in the 'encryption'
				var = string.gsub(var, "!!", "!")
				var = string.gsub(var, "!\\\"", "\"")
				var = string.gsub(var, "!:", ":")
				var = string.gsub(var, "!;", ";")
				var = string.gsub(var, "!\\", "\\")
				
				if patterns[p]["variables"][var] == nil then
					if tonumber(var) then
						var = tonumber(var)
					end
				end
				
				if patterns[p]["variables"][var] ~= nil then -- Old option files may contain obsolete variables, but we take care of that
					var = patterns[p]["variables"][var]
					if string.sub(val, 1, 1) == "N" then 				--options table
						var.extra = tonumber(string.sub(val, 2, -1))
					elseif tonumber(val) then 							--number
						var.value = tonumber(val)
					elseif val == "true" then 							--toggle
						var.value = true
					elseif val == "false" then 							--toggle
						var.value = false
					elseif val == "image" then							--image
						var.value = love.graphics.newImage("images/noImage.png")
					else												--color table
						local t = {""}
						
						-- Here we split the table contents, since they're separated by a hyphen in the 'encrypted' mode
						for a = 1, string.len(val) do
							local lc = ""
							if a > 1 then lc = string.sub(val, a-1, a-1) end
							local c = string.sub(val, a, a)
							if c == "-" then
								table.insert(t, "")
							else
								t[#t] = t[#t] .. c
							end
						end
						var.value = {unpack(t)}
					end
				end
			end
		end
		
	end
	
	newLog("Settings loaded", "log")
end

function toVar(s) --Converts strings to variables. It's not very advanced, but it works for basic values:
	if string.sub(s, 1, 1) == "\"" then --it's a string.
		return string.sub(s, 2, -2)
	elseif tonumber(s) then --it's a number
		return tonumber(s)
	elseif s == "false" then --it's a boolean
		return false
	elseif s == "true" then --it's a boolean
		return true
	elseif string.sub(s, 1, 1) == "{" then --it's a table
		local t = {""}
		local ignore = 0
		local isstring = false
		for i = 2, string.len(s)-1 do
			local c = string.sub(s, i, i)
			if c == "\"" and string.sub(s, i-1, i) ~= "\\\"" then --detect quotes and not quotes-inside-quotes
				isstring = not isstring
				t[#t] = t[#t] .. "\""
			elseif isstring then --string inside table
				t[#t] = t[#t] .. c
			elseif c == "{" then --table inside table
				ignore = ignore + 1
			elseif c == "}" then --table inside table
				ignore = ignore - 1
			elseif string.sub(s, i, i+1) == ", " and ignore == 0 then --new item on the table
				table.insert(t, "")
				ignore = -1
			elseif ignore <= 0 then --add character to the content
				if ignore == 0 then
					t[#t] = t[#t] .. c
				end
				ignore = math.min(0, ignore+1)
			end
		end
		for i, v in pairs(t) do --converts all items into variables
			t[i] = toVar(v)
		end
		return t
	end
	
	return nil --includes the string "nil" as well, so bonus!
end

--===============--
-- SAVE SETTINGS --
--===============--
function saveSettings()
	--[[
		This is also a little bit complicated, but not much. It's extremely similar to
		the loadSettings function, as both use the same 'encryption' and 'decryption'
		methods, and both deal with the same variables/values/save file.
	]]
	
	-- This part makes the save.dat file easier to read, as we're replacing the variables names with some fancier ones
	local vars = {"SelectedPattern", "ImageWidth", "ImageHeight", "PatternSize", "PatternColor", "PatternBackground"}
	local vals = {selectedPattern, patternWidth, patternHeight, patternSize, patternColor, backColor}
	
	-- Converts variables into strings before saving them
	local s = ""
	for i, v in ipairs(vals) do
		s = s .. vars[i] .. " = "
		if type(v) == "string" then
			s = s .. "\"" .. string.gsub(v, "\"", "\\\"") .. "\""
		elseif type(v) == "table" then
			s = s .. "{" .. table.concat(v, ", ") .. "}"
		else
			s = s .. tostring(v)
		end
		s = s .. "\r\n"
	end
	
	s = s .. "RandomOptions = {"
	for i, v in ipairs(settings_random) do
		s = s .. tostring(v.value)
		if i < #settings_random then
			s = s .. ", "
		end
	end
	s = s .. "}\r\n"
	
	-- Convert the custom options from patterns into string
	s = s .. "PatternsOptions = {"
	for i, v in ipairs(patterns) do
		s = s .. "\"" .. v.name
		if v.variables == nil then
			s = s .. ";nil-"
		else
			s = s .. ";"
			for j, w in pairs(v.variables) do
				-- Dealing again with special characters so that variables have more options of naming
				local name = string.gsub(j, "!", "!!")
				name = string.gsub(name, "\"", "!\\\"")
				name = string.gsub(name, ":", "!:")
				name = string.gsub(name, ";", "!;")
				name = string.gsub(name, "\\", "!\\")
				s = s .. name .. ":"
				
				-- Conver the variable values into strings
				if type(w.value) == "number" or w.value == true or w.value == false then
					s = s .. tostring(w.value)
				elseif w.extra == "image" then
					s = s .. "image"
				elseif type(w.value) == "table" then
					if w.extra == "color" then
						local ns = ""
						for i, v in ipairs(w.value) do
							ns = ns .. tostring(math.floor(v)) .. "-"
						end
						s = s .. string.sub(ns, 1, -2)
					elseif type(w.extra) == "number" then
						s = s .. "N" .. tostring(w.extra)
					end
				end
				s = s .. ";"
			end
		end
		s = string.sub(s, 1, -2) .. "\", "
	end
	s = string.sub(s, 1, -3) .. "}"
	
	love.filesystem.write("save.dat", s)
	newLog("Settings saved", "log")
end

function renderImage(save) --Converts the patterns with all their settings into images, then save them
	local can = love.graphics.newCanvas(patternWidth, patternHeight)
	love.graphics.setCanvas(can)
	love.graphics.setColor(backColor)
	love.graphics.rectangle("fill", 0, 0, patternWidth, patternHeight) --setBackgroundColor creates weird transparency issues
	
	love.filesystem.createDirectory("images")
	love.graphics.setColor(patternColor)
	drawPattern(patternWidth, patternHeight, patterns[selectedPattern])
	love.graphics.setCanvas()
	
	local img = can:newImageData()
	if save then
		local imgn = 1
		local function addzero(n)
			local n = tostring(n)
			while string.len(n) < 3 do
				n = "0" .. n
			end
			return n
		end
		if love.filesystem.exists("images/001.png") then
			
			while love.filesystem.exists("images/" .. addzero(imgn) .. ".png") do
				imgn = imgn + 1
			end
		end
		img:encode("png", "images/" .. addzero(imgn) .. ".png")
		if love.filesystem.exists("images/" .. addzero(imgn) .. ".png") then
			newNotice("Image saved successfully!")
			newLog("New pattern image succesfully saved at \"" .. love.filesystem.getSaveDirectory() .. "/images/" .. addzero(imgn) .. ".png\"", "image")
		end
	else
		patternPreview = love.graphics.newImage(img)
	end
end

function inside(x1, y1, w1, h1, x2, y2, w2, h2)
	if x1 >= x2 and x1+w1 <= x2+w2 and y1 >= y2 and y1+h1 <= y2+h2 then
		return true
	end
	return false
end

function previewMode(quit)
	local quit = quit or false
	if quit then
		patternPreview = false
		buttons.previewsave.active = false
		if quit == "save" then
			renderImage(true)
			previewMode(true)
		end
	else
		renderImage()
		buttons.previewsave.active = true
	end
end

function round(n, d)
	local d = d or 2
	return math.floor(n*10^d)/10^d
end

function love.graphics.customarc(mode, x, y, radius, a1, a2, segments)
	local points = {}
	for i = 1, segments+1 do
		local dif = math.abs(a1-a2)
		local m = math.min(a1, a2)
		m = m + (i-1)/segments*dif
		table.insert(points, x + math.cos(m)*radius)
		table.insert(points, y - math.sin(m)*radius)
	end
	
	if mode == "line" then
		for i = 1, #points-3, 2 do
			love.graphics.line(points[i], points[i+1], points[i+2], points[i+3])
		end
	else
		love.graphics.polygon(mode, unpack(points))
	end
end

local function error_printer(msg, layer)
	print((debug.traceback("Error: " .. tostring(msg), 1+(layer or 1)):gsub("\n[^\n]+$", "")))
end
 
function love.errhand(msg)
	msg = tostring(msg)
 
	error_printer(msg, 2)
 
	if not love.window or not love.graphics or not love.event then
		return
	end
 
	if not love.graphics.isCreated() or not love.window.isCreated() then
		local success, status = pcall(love.window.setMode, 800, 600)
		if not success or not status then
			return
		end
	end
 
	-- Reset state.
	if love.mouse then
		love.mouse.setVisible(true)
		love.mouse.setGrabbed(false)
	end
	if love.joystick then
		-- Stop all joystick vibrations.
		for i,v in ipairs(love.joystick.getJoysticks()) do
			v:setVibration()
		end
	end
	if love.audio then love.audio.stop() end
	love.graphics.reset()
	local font = love.graphics.setNewFont(math.floor(love.window.toPixels(14)))
 
	local sRGB = select(3, love.window.getMode()).srgb
	if sRGB and love.math then
		love.graphics.setBackgroundColor(love.math.gammaToLinear(89, 157, 220))
	else
		love.graphics.setBackgroundColor(89, 157, 220)
	end
 
	love.graphics.setColor(255, 255, 255, 255)
 
	local trace = debug.traceback()
 
	love.graphics.clear()
	love.graphics.origin()
 
	local err = {}
 
	table.insert(err, "Error\n")
	table.insert(err, msg.."\n\n")
 
	for l in string.gmatch(trace, "(.-)\n") do
		if not string.match(l, "boot.lua") then
			l = string.gsub(l, "stack traceback:", "Traceback\n")
			table.insert(err, l)
		end
	end
 
	local p = table.concat(err, "\n")
 
	p = string.gsub(p, "\t", "")
	p = string.gsub(p, "%[string \"(.-)\"%]", "%1")
	
	local pos = 0
	for i = 1, string.len(msg) do
		if string.sub(msg, i, i) == ":" then
			if pos ~= 0 then
				pos = i
				break
			end
			pos = i
		end
	end
	
	newLog(p, "error", true)
	
	buttons = {
		{t = "Open logs folder", f = function() love.system.openURL(love.filesystem.getSaveDirectory() .. "/logs") end, down = false, high = false},
		{t = "Copy error to clipboard", f = function() love.system.setClipboardText(p) end, down = false, high = false},
		{t = "Report error online", f = function() love.system.openURL("https://love2d.org/forums/viewtopic.php?f=5&t=81186") end, down = false, high = false}
	}
	
	local function draw()
		love.graphics.clear()
		
		
		--==============--
		-- ERROR HEADER --
		--==============--
		local y = 10+gothic["48"]:getHeight()*.75 + gothic["24"]:getHeight()
		
		love.graphics.setColor(205, 215, 235, 255)
		love.graphics.rectangle("fill", 0, 0, windowW, y)
		
		love.graphics.setColor(0, 0, 155, 105)
		love.graphics.draw(grad, windowW, 0, math.pi*0.5, y/256, windowW/256)
		
		love.graphics.setFont(gothic["48"])
		love.graphics.setColor(0, 0, 0, 155)
		for i = 1, 2 do
			love.graphics.print("Broken Generator", 5+(2-i)*2, (2-i)*2)
			love.graphics.setColor(105, 155, 0, 255)
		end
		
		love.graphics.setFont(gothic["24"])
		love.graphics.setColor(0, 0, 0, 155)
		for i = 1, 2 do
			love.graphics.print("by HugoBDesigner", 5+gothic["48"]:getWidth("Pattern Generator")-gothic["24"]:getWidth("by HugoBDesigner")+(2-i)*2, gothic["48"]:getHeight()*.75+(2-i)*2)
			love.graphics.setColor(0, 155, 205, 255)
		end
		
		
		--============--
		-- ERROR BODY --
		--============--
		
		love.graphics.setColor(255, 255, 255, 105)
		love.graphics.draw(grad, 0, y, 0*math.pi, windowW/256, 64/256)
		love.graphics.draw(grad, windowW, y, 0.5*math.pi, (windowH-y)/256, 64/256)
		love.graphics.draw(grad, windowW, windowH, 1*math.pi, windowW/256, 64/256)
		love.graphics.draw(grad, 0, windowH, 1.5*math.pi, (windowH-y)/256, 64/256)
		
		love.graphics.setColor(0, 0, 0, 255)
		love.graphics.setLineWidth(2)
		love.graphics.line(0, y, windowW, y)
		
		
		--==============--
		-- ERROR WINDOW --
		--==============--
		love.graphics.setColor(155, 255, 205, 105)
		local off = 64
		local w, h = windowW/3*2-off*2, windowH-off*2-y
		love.graphics.rectangle("fill", windowW/3+off, y+off, w, h)
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.setLineWidth(3)
		love.graphics.rectangle("line", windowW/3+off, y+off, w, h)
		
		love.graphics.setColor(55, 55, 55, 255)
		love.graphics.push()
		love.graphics.setScissor(windowW/3+off, y+off, w, h)
		love.graphics.translate(math.ceil(windowW/3+off), math.ceil(y+off))
		
		off = off + 4
		love.graphics.setFont(font)
		love.graphics.print(string.sub(msg, 1, pos), 8, 8)
		
		love.graphics.setFont(gothic["16"])
		love.graphics.print(string.sub(msg, pos+1, -1), 8+font:getWidth(string.sub(msg, 2, pos+1) .. ": "), 8-2)
		love.graphics.setLineWidth(1)
		love.graphics.line(6, 32, w-6, 32)
		love.graphics.setColor(0, 0, 0, 255)
		love.graphics.setFont(font)
		love.graphics.printf( p, 8, 8*2+32, w-32, "left" )
		
		love.graphics.setScissor()
		love.graphics.pop()
		
		love.graphics.setFont(gothic["20"])
		local smax = 0
		for i, v in ipairs(buttons) do
			if gothic["20"]:getWidth(v.t) > smax then
				smax = gothic["20"]:getWidth(v.t)
			end
		end
		
		love.graphics.setLineWidth(3)
		for i, v in ipairs(buttons) do
			love.graphics.setColor(205, 205, 235, 255)
			if v.down then
				love.graphics.setColor(205, 235, 255, 255)
			elseif v.high then
				love.graphics.setColor(235, 235, 255, 255)
			end
			love.graphics.rectangle("fill", 64, y+64+(i-1)*(32 + gothic["20"]:getHeight() + 16), smax+16, gothic["20"]:getHeight() + 16)
			
			love.graphics.setColor(55, 55, 55, 255)
			love.graphics.rectangle("line", 64, y+64+(i-1)*(32 + gothic["20"]:getHeight() + 16), smax+16, gothic["20"]:getHeight() + 16)
			
			love.graphics.print(v.t, 64+(16/2)+smax/2 - gothic["20"]:getWidth(v.t)/2, y+64+(16/2)+(i-1)*(32 + gothic["20"]:getHeight() + 16))
		end
		
		
		love.graphics.present()
	end
	
	while true do
		local mx, my = love.mouse.getPosition()
		
		local smax = 0
		for i, v in ipairs(buttons) do
			if gothic["20"]:getWidth(v.t) > smax then
				smax = gothic["20"]:getWidth(v.t)
			end
		end
		
		local y = 10+gothic["48"]:getHeight()*.75 + gothic["24"]:getHeight()
		for i, v in ipairs(buttons) do
			v.high = false
			if inside(mx, my, 1, 1, 64, y+64+(i-1)*(32 + gothic["20"]:getHeight() + 16), smax+16, gothic["20"]:getHeight() + 16) then
				v.high = true
			end
		end
		love.event.pump()
 
		for e, a, b, c in love.event.poll() do
			if e == "mousepressed" then
				for i, v in ipairs(buttons) do
					if inside(a, b, 1, 1, 64, y+64+(i-1)*(32 + gothic["20"]:getHeight() + 16), smax+16, gothic["20"]:getHeight() + 16) and c == 1 then
						v.down = true
						if v.f then
							v.f()
						end
					end
				end
			end
			if e == "mousereleased" and c == 1 then
				for i, v in ipairs(buttons) do
					v.down = false
				end
			end
			if e == "quit" then
				return
			end
			if e == "keypressed" and a == "escape" then
				return
			end
		end
 
		draw()
 
		if love.timer then
			love.timer.sleep(0.1)
		end
	end
end

function love.window.getWidth()
	local ww, hh = love.window.getMode()
	return ww
end

function love.window.getHeight()
	local ww, hh = love.window.getMode()
	return hh
end

function getDate()
	local n = os.date("*t")
	
	local function addzero(s, l)
		local l = l or 2
		local s = tostring(s)
		while string.len(s) < l do
			s = "0" .. s
		end
		return s
	end
	
	local s = addzero(n.year, 4) .. "-" .. addzero(n.month) .. "-" .. addzero(n.day)
	s = s .. "-" .. addzero(n.hour) .. "-" .. addzero(n.min) .. "-" .. addzero(n.sec) --nsec
	return s
end

function newLog(msg, tp, errhand)
	local tp = tp or "error"
	
	
	msg = string.gsub(msg, "\r\n", "\n")
	msg = string.gsub(msg, "\n", "\r\n")
	
	if tp == "error" then
		userLog = userLog .. "\r\n[" .. getDate() .. "] " .. (tp == "log" and "" or "[" .. tp .. "] ") .. "An error was found and a new diagnostic log was created"
		
	else
		userLog = userLog .. "\r\n[" .. getDate() .. "] " .. (tp == "log" and "" or "[" .. tp .. "] ") .. msg
	end
	if tp == "logout" then
		tp = "userlog"
		userLog = string.sub(userLog, 2, -1) --removes initial line break
		msg = userLog
	end
	
	
	if tp == "error" or tp == "userlog" then
		love.filesystem.write("logs/" .. getDate() .. " [" .. tp .. "].txt", tostring(msg))
		if console and tp == "error" and not errhand then
			error(tostring( string.gsub(msg, "\r\n", "\n") )) --Myself only
		end
	end
end

newLog("Pattern Generator v" .. version .. " initialized", "boot")