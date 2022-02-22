color = class:new()

function color:init(x, y, radius, thickness, func)
	self.active = true
	self.x = x
	self.y = y
	self.radius = radius
	self.thickness = thickness or 12
	self.selectionangle = math.pi/2
	self.saturangle = 0
	self.brightangle = 0
	self.clicking = false
	self.saturclicking = false
	self.brightclicking = false
	self.func = func or false
	self.lastColor = false
	self.autoupdate = false
	
	local offset = 8
	self.inputs = {
		["r"] = 	{t = "", x = self.x-self.radius+gothic["12"]:getHeight()*1.5, y = self.y+self.radius+offset},
		["g"] = 	{t = "", x = self.x-self.radius+gothic["12"]:getHeight()*1.5, y = self.y+self.radius+offset*2+gothic["12"]:getHeight()},
		["b"] = 	{t = "", x = self.x-self.radius+gothic["12"]:getHeight()*1.5, y = self.y+self.radius+offset*3+gothic["12"]:getHeight()*2},
		["hue"] = 	{t = "", x = self.x+self.radius-gothic["12"]:getHeight()*2.5, y = self.y+self.radius+offset},
		["sat"] = 	{t = "", x = self.x+self.radius-gothic["12"]:getHeight()*2.5, y = self.y+self.radius+offset*2+gothic["12"]:getHeight()},
		["bri"] = 	{t = "", x = self.x+self.radius-gothic["12"]:getHeight()*2.5, y = self.y+self.radius+offset*3+gothic["12"]:getHeight()*2},
		["hex"] = 	{t = "", x = self.x-gothic["12"]:getHeight()*1.5, y = self.y+self.radius+offset+gothic["12"]:getHeight()}
	}
	self.inputs.hex.rec = {self.x-gothic["12"]:getHeight()*2, self.y+self.radius+offset+gothic["12"]:getHeight()-offset/4, gothic["12"]:getHeight()*4, gothic["12"]:getHeight()+offset/2}
	local t = {{"r", "g", "b"}, {"hue", "sat", "bri"}}
	for i = 1, 3 do
		self.inputs[ t[1][i] ].rec = {self.x-self.radius+gothic["12"]:getHeight(), self.y+self.radius+offset*i+gothic["12"]:getHeight()*(i-1)-offset/4, gothic["12"]:getHeight()*3, gothic["12"]:getHeight()+offset/2}
		self.inputs[ t[2][i] ].rec = {self.x+self.radius-gothic["12"]:getHeight()*3, self.y+self.radius+offset*i+gothic["12"]:getHeight()*(i-1)-offset/4, gothic["12"]:getHeight()*3, gothic["12"]:getHeight()+offset/2}
	end
	
	self.lastinput = false
	
	
	self.image = love.image.newImageData(self.radius*2, self.radius*2)
	self.image:mapPixel(function(x, y, r, g, b, a)
		local r, g, b, a = 1, 1, 1, 0
		if distance(x, y, self.radius, self.radius) >= self.radius-self.thickness and distance(x, y, self.radius, self.radius) <= self.radius then
			r, g, b, a = 0, 0, 0, 1
			
			local an = math.atan2(y-self.radius, x-self.radius)
			an = an + math.pi/2
			while an >= math.pi do
				an = an - math.pi*2
			end
			while an <= -math.pi do
				an = an + math.pi*2
			end
			--[[an = an - math.pi/2
			an = -an
			while an < 0 do an = an + math.pi*2 end
			while an >= math.pi*2 do an = an - math.pi*2 end]]
			
			local aa = math.pi*2/3
			
			if an <= aa and an >= -aa then
				if an <= -aa/2 then
					r = 1-math.abs((an+aa/2)/(aa-aa/2))
				elseif an > -aa/2 and an < aa/2 then
					r = 1
				else
					r = 1-math.abs((an-aa/2)/(aa-aa/2))
				end
			end
			
			an = an + aa
			while an >= math.pi do
				an = an - math.pi*2
			end
			while an <= -math.pi do
				an = an + math.pi*2
			end
			
			if an <= aa and an >= -aa then
				if an <= -aa/2 then
					g = 1-math.abs((an+aa/2)/(aa-aa/2))
				elseif an > -aa/2 and an < aa/2 then
					g = 1
				else
					g = 1-math.abs((an-aa/2)/(aa-aa/2))
				end
			end
			
			an = an + aa
			while an >= math.pi do
				an = an - math.pi*2
			end
			while an <= -math.pi do
				an = an + math.pi*2
			end
			
			if an <= aa and an >= -aa then
				if an <= -aa/2 then
					b = 1-math.abs((an+aa/2)/(aa-aa/2))
				elseif an > -aa/2 and an < aa/2 then
					b = 1
				else
					b = 1-math.abs((an-aa/2)/(aa-aa/2))
				end
			end
		end
		if r >= 1 then r = 1 elseif r <= 0 then r = 0 end
		if g >= 1 then g = 1 elseif g <= 0 then g = 0 end
		if b >= 1 then b = 1 elseif b <= 0 then b = 0 end
		return r, g, b, a
	end)
	
	self.image = love.graphics.newImage(self.image)
	
	local aa = math.pi/2
	local a1, a2 = math.pi/2+aa/3, math.pi+aa/3*2
	local d1, d2 = self.radius/2, self.radius/2+self.thickness
	local s1 = d2*2
	local s2 = -math.sin(a2)*d2*2
	
	self.saturimage = love.image.newImageData(s1, s2)
	self.saturimage:mapPixel(function(x, y, r, g, b, a)
		local r, g, b, a = 1, 1, 1, 0
		if distance(x, y, s1/2, s2/2) <= d2 and distance(x, y, s1/2, s2/2) >= d1 then
			local an = math.atan2(y-s2/2, x-s1/2)
			an = an + aa
			if an < -math.pi then an = an + math.pi*2
			elseif an > math.pi then an = an - math.pi*2 end
			
			if an <= -aa/3 and an >= -math.pi+aa/3 then
				local f = -an
				f = f-aa/3
				f = f/(aa/3*4)
				if f <= 0 then f = 0 elseif f >= 1 then f = 1 end
				r = 1
				g = 1
				b = 1
				a = f
			elseif an >= aa/3 and an <= math.pi-aa/3 then
				local f = an-aa/3
				f = f/(aa/3*4)
				if f <= 0 then f = 0 elseif f >= 1 then f = 1 end
				r, g, b = 0, 0, 0
				a = f
			end
		end
		return r, g, b, a
	end)
	self.saturimage = love.graphics.newImage(self.saturimage)
	
	self.saturback = love.image.newImageData(s1, s2)
	self.saturback:mapPixel(function(x, y, r, g, b, a)
		local r, g, b, a = 1, 1, 1, 0
		if distance(x, y, s1/2, s2/2) <= d2 and distance(x, y, s1/2, s2/2) >= d1 then
			local an = math.atan2(y-s2/2, x-s1/2)
			an = an + aa
			if an < -math.pi then an = an + math.pi*2
			elseif an > math.pi then an = an - math.pi*2 end
			if (an <= -aa/3 and an >= -math.pi+aa/3) or (an >= aa/3 and an <= math.pi-aa/3) then
				a = 1
			end
		end
		return r, g, b, a
	end)
	self.saturback = love.graphics.newImage(self.saturback)
	
	local r, g, b, a = self:getColor()
	
	self.inputs.r.t = math.ceil(r)
	self.inputs.g.t = math.ceil(g)
	self.inputs.b.t = math.ceil(b)
	local an = math.floor(self.selectionangle/(math.pi*2)*360)
	an = an - 90
	if an < 0 then an = an + 360 end
	self.inputs.hue.t = an
	self.inputs.sat.t = math.ceil((1-self.saturangle)*100)
	self.inputs.bri.t = math.ceil((1-self.brightangle)*100)
	self.inputs.hex.t = self:hexrgb(math.ceil(r), math.ceil(g), math.ceil(b))
	
	self.okay = button:new(self.x-gothic["24"]:getWidth(" OK ")/2, self.y+self.radius+gothic["24"]:getHeight()*1.5+offset/4, gothic["24"]:getWidth(" OK "), gothic["24"]:getHeight())
	self.okay.color = {255/255, 255/255, 255/255, 255/255}
	self.okay.clickcolor = {215/255, 255/255, 205/255, 255/255}
	self.okay.hovercolor = {240/255, 245/255, 235/255, 255/255}
	self.okay.outline = {55/255, 55/255, 55/255, 255/255}
	self.okay.outclick = {65/255, 105/255, 55/255, 255/255}
	self.okay.outhover = {80/255, 85/255, 75/255, 255/255}
end

function color:update(dt)
	if not self.active then return end
	if self.active and not self.lastColor then
		if self.autoupdate then
			self:setColor(self.autoupdate.value)
		end
		self.lastColor = {self:getColor()}
	end
	local x, y = love.mouse.getPosition()
	local an = math.atan2(y-self.y, x-self.x)
	local aa = math.pi/2
	local a1, a2 = math.pi/2+aa/3, math.pi+aa/3*2
	local d1, d2 = self.radius/2, self.radius/2+self.thickness
	local s1 = d2*2
	local s2 = -math.sin(a2)*d2*2
	if self.clicking then
		self.selectionangle = -an
		if self.selectionangle < 0 then
			self.selectionangle = self.selectionangle + math.pi*2
		end
		if self.selectionangle <= 0 then self.selectionangle = 0 end
	end
	
	an = an + aa
	if an < -math.pi then an = an + math.pi*2
	elseif an > math.pi then an = an - math.pi*2 end
	
	if an < -aa/3 and an > -math.pi+aa/3 and self.saturclicking then
		local f = -an
		f = f-aa/3-aa/12
		f = f/((aa/3-aa/24)*4)
		if f <= 0 then f = 0 elseif f >= 1 then f = 1 end
		self.saturangle = f
	elseif an > aa/3 and an < math.pi-aa/3 and self.brightclicking then
		local f = an-aa/3-aa/12
		f = f/((aa/3-aa/24)*4)
		if f <= 0 then f = 0 elseif f >= 1 then f = 1 end
		self.brightangle = f
	elseif an <= 0 and self.saturclicking then
		if an > -aa then self.saturangle = 0
		else self.saturangle = 1 end
	elseif an >= 0 and self.brightclicking then
		if an < aa then self.brightangle = 0
		else self.brightangle = 1 end
	end
	
	local r, g, b, a = self:getColor()
	if self.lastinput == false or self.lastinput[2] ~= 1 then
		self.inputs.r.t = math.ceil(r)
		self.inputs.g.t = math.ceil(g)
		self.inputs.b.t = math.ceil(b)
	end
	
	if self.lastinput == false or self.lastinput[2] ~= 2 then
		local an = math.floor(self.selectionangle/(math.pi*2)*360)
		an = an - 90
		if an < 0 then an = an + 360 end
		self.inputs.hue.t = an
		self.inputs.sat.t = math.ceil((1-self.saturangle)*100)
		self.inputs.bri.t = math.ceil((1-self.brightangle)*100)
	end
	
	if self.lastinput == false or self.lastinput[2] ~= 3 then
		self.inputs.hex.t = self:hexrgb(math.ceil(r), math.ceil(g), math.ceil(b))
	end
	
	for i, v in pairs(self.inputs) do
		v.t = tostring(v.t)
	end
	
	if self.lastinput and self.lastinput[3] then
		self.lastinput[3] = self.lastinput[3] - dt
		if self.lastinput[3] <= -1 then
			self.lastinput[3] = 1
		end
	end
	
	self.okay:update(dt)
	return true
end

function color:draw()
	if not self.active then return end
	love.graphics.setColor(0/255, 0/255, 0/255, 205/255)
	love.graphics.rectangle("fill", 0, 0, love.window.getWidth(), love.window.getHeight())
	love.graphics.setFont(gothic["12"])
	love.graphics.setColor(205/255, 235/255, 255/255, 135/255)
	local offset = 8
	love.graphics.rectangle("fill", self.x-self.radius-offset, self.y-self.radius-offset, self.radius*2+offset*2, self.radius*2+offset*4+(gothic["12"]:getHeight()+offset/2)*3)
	love.graphics.setColor(55/255, 55/255, 55/255, 255/255)
	love.graphics.setLineWidth(4)
	love.graphics.rectangle("line", self.x-self.radius-offset, self.y-self.radius-offset, self.radius*2+offset*2, self.radius*2+offset*4+(gothic["12"]:getHeight()+offset/2)*3)
	local aa = math.pi/2
	love.graphics.setColor(255/255, 255/255, 255/255, 255/255)
	love.graphics.draw(self.image, self.x-self.radius, self.y-self.radius)
	
	local r, g, b, a = self:getColor()
	love.graphics.setColor(color255to1(r, g, b, 255))
	love.graphics.circle("fill", self.x, self.y, self.radius/4, 32)
	love.graphics.setColor(0/255, 0/255, 0/255, 255/255)
	love.graphics.setLineWidth(1.5)
	love.graphics.circle("line", self.x, self.y, self.radius/4, 32)
	
	local a1, a2 = math.pi/2+aa/3, math.pi+aa/3*2
	local d1, d2 = self.radius/2, self.radius/2+self.thickness
	local s1 = d2*2
	local s2 = -math.sin(a2)*d2*2
	local r, g, b, a = self:getColor("!sat")
	love.graphics.setScissor(self.x-self.radius, self.y-self.radius, self.radius, self.radius*2)
	love.graphics.setColor(color255to1(r, g, b, 255))
	love.graphics.draw(self.saturback, self.x-s1/2, self.y-s2/2)
	--love.graphics.setColor(255*(1-self.brightangle), 255*(1-self.brightangle), 255*(1-self.brightangle), 255)
	love.graphics.setColor(.5, .5, .5, 1)
	love.graphics.draw(self.saturimage, self.x-s1/2, self.y-s2/2)
	love.graphics.setScissor()
	
	local r, g, b, a = self:getColor("!bri")
	love.graphics.setColor(color255to1(r, g, b, 255))
	love.graphics.setScissor(self.x, self.y-self.radius, self.radius, self.radius*2)
	love.graphics.draw(self.saturback, self.x-s1/2, self.y-s2/2)
	love.graphics.setColor(255/255, 255/255, 255/255, 255/255)
	love.graphics.draw(self.saturimage, self.x-s1/2, self.y-s2/2)
	love.graphics.setScissor()
	
	love.graphics.setColor(0/255, 0/255, 0/255, 255/255)
	local a1, a2 = math.pi/2+aa/3, math.pi+aa/3*2
	love.graphics.line(self.x + math.cos(a1)*self.radius/2, self.y - math.sin(a1)*self.radius/2, self.x + math.cos(a1)*(self.radius/2+self.thickness), self.y - math.sin(a1)*(self.radius/2+self.thickness))
	love.graphics.line(self.x + math.cos(a1)*self.radius/2, self.y + math.sin(a1)*self.radius/2, self.x + math.cos(a1)*(self.radius/2+self.thickness), self.y + math.sin(a1)*(self.radius/2+self.thickness))
	love.graphics.customarc("line", self.x, self.y, self.radius/2+self.thickness, a1, a2, 32)
	love.graphics.customarc("line", self.x, self.y, self.radius/2, a1, a2, 32)
	
	a1, a2 = a1 + math.pi, a2 + math.pi
	love.graphics.line(self.x + math.cos(a1)*self.radius/2, self.y - math.sin(a1)*self.radius/2, self.x + math.cos(a1)*(self.radius/2+self.thickness), self.y - math.sin(a1)*(self.radius/2+self.thickness))
	love.graphics.line(self.x + math.cos(a1)*self.radius/2, self.y + math.sin(a1)*self.radius/2, self.x + math.cos(a1)*(self.radius/2+self.thickness), self.y + math.sin(a1)*(self.radius/2+self.thickness))
	love.graphics.customarc("line", self.x, self.y, self.radius/2+self.thickness, a1, a2, 32)
	love.graphics.customarc("line", self.x, self.y, self.radius/2, a1, a2, 32)
	
	love.graphics.setColor(0/255, 0/255, 0/255, 255/255)
	love.graphics.setLineWidth(1.5)
	love.graphics.circle("line", self.x, self.y, self.radius, 64)
	love.graphics.circle("line", self.x, self.y, self.radius-self.thickness, 64)
	love.graphics.push()
		
		love.graphics.translate(self.x, self.y)
		love.graphics.rotate(-self.selectionangle)
		love.graphics.setLineWidth(4.5)
		love.graphics.polygon("line", self.radius-self.thickness, -self.thickness/4, self.radius-self.thickness-2, 0, self.radius-self.thickness, self.thickness/4, self.radius, self.thickness/4, self.radius, -self.thickness/4)
		love.graphics.setColor(255/255, 255/255, 255/255, 255/255)
		love.graphics.setLineWidth(2.5)
		love.graphics.polygon("line", self.radius-self.thickness, -self.thickness/4, self.radius-self.thickness-2, 0, self.radius-self.thickness, self.thickness/4, self.radius, self.thickness/4, self.radius, -self.thickness/4)
		
	love.graphics.pop()
	
	love.graphics.push()
		love.graphics.translate(self.x, self.y)
		love.graphics.rotate(math.pi/2+aa/3+aa/12+(1-self.saturangle)*(aa/3*4-aa/6))
		love.graphics.setLineWidth(4.5)
		love.graphics.setColor(0/255, 0/255, 0/255, 255/255)
		love.graphics.polygon("line", self.radius/2, -self.thickness/4, self.radius/2-2, 0, self.radius/2, self.thickness/4, self.radius/2+self.thickness, self.thickness/4, self.radius/2+self.thickness, -self.thickness/4)
		love.graphics.setColor(255/255, 255/255, 255/255, 255/255)
		love.graphics.setLineWidth(2.5)
		love.graphics.polygon("line", self.radius/2, -self.thickness/4, self.radius/2-2, 0, self.radius/2, self.thickness/4, self.radius/2+self.thickness, self.thickness/4, self.radius/2+self.thickness, -self.thickness/4)
	love.graphics.pop()
	
	love.graphics.push()
		love.graphics.translate(self.x, self.y)
		love.graphics.rotate(math.pi/2-aa/3-aa/12-(1-self.brightangle)*(aa/3*4-aa/6))
		love.graphics.setLineWidth(4.5)
		love.graphics.setColor(0/255, 0/255, 0/255, 255/255)
		love.graphics.polygon("line", self.radius/2, -self.thickness/4, self.radius/2-2, 0, self.radius/2, self.thickness/4, self.radius/2+self.thickness, self.thickness/4, self.radius/2+self.thickness, -self.thickness/4)
		love.graphics.setColor(255/255, 255/255, 255/255, 255/255)
		love.graphics.setLineWidth(2.5)
		love.graphics.polygon("line", self.radius/2, -self.thickness/4, self.radius/2-2, 0, self.radius/2, self.thickness/4, self.radius/2+self.thickness, self.thickness/4, self.radius/2+self.thickness, -self.thickness/4)
	love.graphics.pop()
	
	love.graphics.setLineWidth(1)
	love.graphics.setColor(0/255, 0/255, 0/255, 255/255)
	love.graphics.print("R:", self.x-self.radius+gothic["12"]:getHeight()-gothic["12"]:getWidth("R: "), self.y+self.radius+offset)
	love.graphics.print("G:", self.x-self.radius+gothic["12"]:getHeight()-gothic["12"]:getWidth("G: "), self.y+self.radius+offset*2+gothic["12"]:getHeight())
	love.graphics.print("B:", self.x-self.radius+gothic["12"]:getHeight()-gothic["12"]:getWidth("B: "), self.y+self.radius+offset*3+gothic["12"]:getHeight()*2)
	love.graphics.print("HUE:", self.x+self.radius-gothic["12"]:getHeight()*3-gothic["12"]:getWidth("HUE: "), self.y+self.radius+offset)
	love.graphics.print("SAT:", self.x+self.radius-gothic["12"]:getHeight()*3-gothic["12"]:getWidth("SAT: "), self.y+self.radius+offset*2+gothic["12"]:getHeight())
	love.graphics.print("BRI:", self.x+self.radius-gothic["12"]:getHeight()*3-gothic["12"]:getWidth("BRI: "), self.y+self.radius+offset*3+gothic["12"]:getHeight()*2)
	love.graphics.print("HEX:", self.x-gothic["12"]:getWidth("HEX:")/2, self.y+self.radius+offset-offset/4)
	
	for i, v in pairs(self.inputs) do
		love.graphics.setColor(255/255, 255/255, 255/255, 255/255)
		love.graphics.rectangle("fill", v.rec[1], v.rec[2], v.rec[3], v.rec[4])
		love.graphics.setColor(0/255, 0/255, 0/255, 255/255)
		love.graphics.rectangle("line", v.rec[1], v.rec[2], v.rec[3], v.rec[4])
		love.graphics.print(v.t, v.x, v.y)
		if self.lastinput and self.lastinput[1] == i and self.lastinput[3] > 0 then
			love.graphics.line(v.x+gothic["12"]:getWidth(v.t)+1, v.y+1, v.x+gothic["12"]:getWidth(v.t)+1, v.y+gothic["12"]:getHeight()-1)
		end
	end
	
	love.graphics.setLineWidth(2.5)
	self.okay:draw()
	love.graphics.setColor(15/255, 55/255, 0/255, 255/255)
	love.graphics.setFont(gothic["24"])
	love.graphics.print(" OK", self.okay.x, self.okay.y)
end

function color:mousepressed(x, y, button)
	if not self.active then return end
	if button == 1 then
		local aa = math.pi/2
		local a1, a2 = math.pi/2+aa/3, math.pi+aa/3*2
		local d1, d2 = self.radius/2, self.radius/2+self.thickness
		local s1 = d2*2
		local s2 = -math.sin(a2)*d2*2
		if distance(x, y, self.x, self.y) <= self.radius and distance(x, y, self.x, self.y) >= self.radius-self.thickness then
			self.clicking = true
		elseif distance(x, y, self.x, self.y) <= d2 and distance(x, y, self.x, self.y) >= d1 then
			local an = math.atan2(y-self.y, x-self.x)
			an = an + aa
			if an < -math.pi then an = an + math.pi*2
			elseif an > math.pi then an = an - math.pi*2 end
			
			if an <= -aa/3 and an >= -math.pi+aa/3 then
				self.saturclicking = true
			elseif an >= aa/3 and an <= math.pi-aa/3 then
				self.brightclicking = true
			end
		end
		
		local lst = self.lastinput
		self.lastinput = false
		for i, v in pairs(self.inputs) do
			if inside(x, y, 0, 0, unpack(v.rec)) then
				self.lastinput = {i}
				if i == "r" or i == "g" or i == "b" then
					self.lastinput[2] = 1
				elseif i == "hue" or i == "sat" or i == "bri" then
					self.lastinput[2] = 2
				else
					self.lastinput[2] = 3
				end
				self.lastinput[3] = 1
				break
			end
		end
		for i, v in pairs(self.inputs) do
			if v.t == "" and (self.lastinput == false or self.lastinput[1] ~= i) then
				v.t = "0"
			end
			if i == "hex" then
				while string.len(v.t) < 6 do v.t = v.t .. "0" end
			end
		end
		if not self.lastinput and not lst then
			self.okay:mousepressed(x, y, button)
		end
	elseif self.lastinput then
		if self.lastinput[1] ~= "hex" then
			local n = tonumber(self.inputs[ self.lastinput[1] ].t)
			if button == "wu" then
				n = n+1
			elseif button == "wd" then
				n = n-1
			end
			if n < 0 then n = 0 end
			if n >= 360 and self.lastinput[1] == "hue" then n = 359
			elseif n > 255 and self.lastinput[2] == 1 then n = 255
			elseif n > 100 and self.lastinput[2] == 2 and self.lastinput[1] ~= "hue" then n = 100 end
			self.inputs[ self.lastinput[1] ].t = tostring(n)
			self:input(self.lastinput[1], "")
		end
	end
	
	local offset = 8
	if not inside(x, y, 0, 0, self.x-self.radius-offset, self.y-self.radius-offset, self.radius*2+offset*2, self.radius*2+offset*4+(gothic["12"]:getHeight()+offset/2)*3) and button == 1 then
		self.active = false
		self:setColor(self.lastColor)
		self.lastColor = false
	end
	return true
end

function color:mousereleased(x, y, button)
	if not self.active then return end
	if button ~= 1 then return end
	self.clicking = false
	self.saturclicking = false
	self.brightclicking = false
	if self.okay.clicking and inside(x, y, 0, 0, self.okay.x, self.okay.y, self.okay.width, self.okay.height) then
		if self.func then
			self.func(self:getColor())
		end
		self.active = false
		self.lastColor = false
	end
	self.okay:mousereleased(x, y, button)
	return true
end

function color:wheelmoved(x, y)
	
end

function color:getColor(dat)
	local dat = dat or "all"
	local r, g, b = 0, 0, 0
	local aa = math.pi/2
	
			if dat == "hue" or dat == "all" or (string.sub(dat, 1, 1) == "!" and dat ~= "!hue") then
	--=====--
	-- HUE --
	--=====--
	if self.selectionangle >= aa/3 and self.selectionangle <= math.pi-aa/3 then
		r = 255
		if self.selectionangle >= aa then
			g = self.selectionangle-aa
			g = g/(aa/3*2)*255
		else
			b = self.selectionangle - aa/3
			b = (1-b/(aa/3*2))*255
		end
	elseif self.selectionangle > math.pi-aa/3 and self.selectionangle <= 3*aa then
		g = 255
		if self.selectionangle <= math.pi+aa/3 then
			r = self.selectionangle - (aa+aa/3*2)
			r = (1-r/(aa/3*2))*255
		else
			b = self.selectionangle - (math.pi+aa/3)
			b = b/(aa/3*2)*255
		end
	else
		b = 255
		if self.selectionangle <= math.pi+aa+aa/3*2 and self.selectionangle >= math.pi+aa then
			g = self.selectionangle - (math.pi+aa)
			g = (1-g/(aa/3*2))*255
		else
			r = self.selectionangle-aa/3
			if r < 0 then r = r + math.pi*2 end
			r = r - (math.pi+aa+aa/3)
			r = r/(aa/3*2)*255
		end
	end
	
			end
	
			if dat == "sat" or dat == "all" or (string.sub(dat, 1, 1) == "!" and dat ~= "!sat") then
	--============--
	-- SATURATION --
	--============--
	local sat = math.max(r, g, b)
		r = r + (sat-r)*self.saturangle
		g = g + (sat-g)*self.saturangle
		b = b + (sat-b)*self.saturangle
			end
	
			if dat == "bri" or dat == "all" or (string.sub(dat, 1, 1) == "!" and dat ~= "!bri") then
	--============--
	-- BRIGHTNESS --
	--============--
	
		r = r * (1-self.brightangle)
		g = g * (1-self.brightangle)
		b = b * (1-self.brightangle)
			end
	
	if r >= 255 then r = 255 elseif r <= 0 then r = 0 end
	if g >= 255 then g = 255 elseif g <= 0 then g = 0 end
	if b >= 255 then b = 255 elseif b <= 0 then b = 0 end
	return r, g, b, 255
end

function color:setColor(...)
	local args = {...}
	local c = {}
	if type(args[1]) == "table" then
		c = {unpack(args[1])}
	elseif type(args[1]) == "string" then
		c = self:hexrgb(args[1])
	else
		c = {unpack(args)}
	end
	
	while #c > 3 do
		table.remove(c)
	end
	
	
	self.saturangle =  math.min(unpack(c))/math.max(unpack(c))
	if math.max(unpack(c)) == 0 then
		self.saturangle = 0
	end
	self.brightangle = 1-math.max(unpack(c))/255
	
	local r, g, b = unpack(c)
	
	r, g, b = r-math.min(r, g, b), g-math.min(r, g, b), b-math.min(r, g, b)
	if math.max(r, g, b) > 0 then
		r, g, b = r/math.max(r, g, b), g/math.max(r, g, b), b/math.max(r, g, b)
	end
	
	if r <= 0 then r = 0 end
	if g <= 0 then g = 0 end
	if b <= 0 then b = 0 end
	
	--=====--
	-- HUE --
	--=====--
	local aa = math.pi/2
	if r == 1 then
		self.selectionangle = aa
		if g > 0 then
			self.selectionangle = self.selectionangle + g*(aa/3*2)
		else
			self.selectionangle = self.selectionangle - b*(aa/3*2)
		end
	elseif g == 1 then
		self.selectionangle = math.pi+aa/3
		if b > 0 then
			self.selectionangle = self.selectionangle + b*(aa/3*2)
		else
			self.selectionangle = self.selectionangle - r*(aa/3*2)
		end
	elseif b == 1 then
		self.selectionangle = math.pi*2-aa/3
		if r > 0 then
			self.selectionangle = self.selectionangle + r*(aa/3*2)
		else
			self.selectionangle = self.selectionangle - g*(aa/3*2)
		end
	end
	
	if self.selectionangle < 0 then
		self.selectionangle = self.selectionangle + math.pi*2
	elseif self.selectionangle >= math.pi*2 then
		self.selectionangle = self.selectionangle - math.pi*2
	end
	
	local r, g, b = self:getColor()
	if not self.lastinput or self.lastinput[1] ~= "r" then
		self.inputs.r.t = math.ceil(r)
	end
	if not self.lastinput or self.lastinput[1] ~= "g" then
		self.inputs.g.t = math.ceil(g)
	end
	if not self.lastinput or self.lastinput[1] ~= "b" then
		self.inputs.b.t = math.ceil(b)
	end
	
	if not self.lastinput or self.lastinput[1] ~= "hue" then
		local an = math.floor(self.selectionangle/(math.pi*2)*360)
		an = an - 90
		if an < 0 then an = an + 360 end
		self.inputs.hue.t = an
	end
	if not self.lastinput or self.lastinput[1] ~= "sat" then
		self.inputs.sat.t = math.floor((1-self.saturangle)*100)
	end
	if not self.lastinput or self.lastinput[1] ~= "bri" then
		self.inputs.bri.t = math.floor((1-self.brightangle)*100)
	end
	
	if not self.lastinput or self.lastinput[1] ~= "hex" then
		self.inputs.hex.t = self:hexrgb(math.ceil(r), math.ceil(g), math.ceil(b))
	end
end

function color:hexrgb(...)
	local args = {...}
	if type(args[1]) == "string" then
		local c = {}
		if string.sub(args[1], 1, 1) == "#" then
			args[1] = string.sub(args[1], 2, -1)
		end
		args[1] = string.upper(args[1])
		while string.len(args[1]) < 6 do
			args[1] = args[1] .. "0"
		end
		c[1] = string.sub(args[1], 1, 2)
		c[2] = string.sub(args[1], 3, 4)
		c[3] = string.sub(args[1], 5, 6)
		local t = {["A"] = 10, ["B"] = 11, ["C"] = 12, ["D"] = 13, ["E"] = 14, ["F"] = 15}
		for i = 0, 9 do
			t[tostring(i)] = i
		end
		c[1] = t[string.sub(c[1], 1, 1)]*16 + t[string.sub(c[1], 2, 2)]
		c[2] = t[string.sub(c[2], 1, 1)]*16 + t[string.sub(c[2], 2, 2)]
		c[3] = t[string.sub(c[3], 1, 1)]*16 + t[string.sub(c[3], 2, 2)]
		
		return c
	else
		local c = ""
		if type(args[1]) == "table" then
			args = {unpack(args[1])}
		end
		local t = {}
		for i = 0, 9 do
			t[tostring(i)] = tostring(i)
		end
		t["10"] = "A"; t["11"] = "B"; t["12"] = "C"; t["13"] = "D"; t["14"] = "E"; t["15"] = "F"
		
		if not args[1] or not args[2] or not args[3] then
			error(table.concat(args, ","))
		end
		
		c = c .. t[tostring(math.floor(args[1]/16))]
		c = c .. t[tostring(math.floor(math.mod(args[1], 16)))]
		c = c .. t[tostring(math.floor(args[2]/16))]
		c = c .. t[tostring(math.floor(math.mod(args[2], 16)))]
		c = c .. t[tostring(math.floor(args[3]/16))]
		c = c .. t[tostring(math.floor(math.mod(args[3], 16)))]
		
		return c
	end
end

function color:keypressed(key)
	if not self.active then return end
	local t = {"a", "b", "c", "d", "e", "f"}
	
	if key == "backspace" or tonumber(key) or (key == "v" and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl"))) or table.contains(t, key) then
		if self.lastinput then
			self.lastinput[3] = 1
			self:input(self.lastinput[1], key)
		end
	elseif key == "escape" or key == "enter" or key == "return" or key == "kpenter" then
		if not self.lastinput and self.func and key ~= "escape" then
			self.func(self:getColor())
			self.active = false
			self.lastColor = false
		elseif key == "escape" then
			self.active = false
			self:setColor(self.lastColor)
			self.lastColor = false
		end
		self.lastinput = false
		for i, v in pairs(self.inputs) do
			if v.t == "" and (self.lastinput == false or self.lastinput[1] ~= i) then
				v.t = "0"
			end
			if i == "hex" then
				while string.len(v.t) < 6 do v.t = v.t .. "0" end
			end
		end
	elseif key == "up" or key == "down" or key == "tab" then
		if self.lastinput then
			print(unpack(self.lastinput))
			if self.lastinput[2] == 1 then
				if key == "up" then
					if self.lastinput[1] == "g" then self.lastinput[1] = "r"
					elseif self.lastinput[1] == "b" then self.lastinput[1] = "g" end
				else
					if self.lastinput[1] == "r" then self.lastinput[1] = "g"
					elseif self.lastinput[1] == "g" then self.lastinput[1] = "b"
					elseif key == "tab" then
						self.lastinput[1] = "hue"
						self.lastinput[2] = 2
					end
				end
			elseif self.lastinput[2] == 2 then
				if key == "up" then
					if self.lastinput[1] == "sat" then self.lastinput[1] = "hue"
					elseif self.lastinput[1] == "bri" then self.lastinput[1] = "sat" end
				else
					if self.lastinput[1] == "hue" then self.lastinput[1] = "sat"
					elseif self.lastinput[1] == "sat" then self.lastinput[1] = "bri"
					elseif key == "tab" then
						self.lastinput[1] = "hex"
						self.lastinput[2] = 3
					end
				end
			elseif key == "tab" then
				self.lastinput[1] = "r"
				self.lastinput[2] = 1
			end
		end
		self.lastinput[3] = 1
	end
	return true
end

function color:input(i, k)
	local v = self.inputs[i]
	if k == "backspace" then
		if string.len(self.inputs[i].t) > 1 then
			self.inputs[i].t = string.sub(self.inputs[i].t, 1, -2)
		else
			self.inputs[i].t = ""
		end
	elseif tonumber(k) then
		if self.lastinput[2] == 1 or self.lastinput[2] == 2 then
			if string.len(v.t) < 3 then
				v.t = v.t .. k
			end
		elseif string.len(v.t) < 6 then
			v.t = v.t .. k
		end
		
		if self.lastinput[2] == 1 then
			if tonumber(v.t) > 255 then
				v.t = "255"
			end
		elseif self.lastinput[2] == 2 then
			if i == "hue" and tonumber(v.t) >= 360 then
				v.t = "359"
			elseif i ~= "hue" and tonumber(v.t) > 100 then
				v.t = "100"
			end
		end
	elseif k == "v" then
		local t = love.system.getClipboardText()
		if string.len(t) >= 1 then
			local s = ""
			for j = 1, string.len(t) do
				local w = string.sub(t, j, j)
				if tonumber(w) then
					s = s .. w
				elseif table.contains({"a", "b", "c", "d", "e", "f"}, string.lower(w)) and i == "hex" then
					s = s .. string.upper(w)
				end
			end
			v.t = v.t .. s
			if i == "hex"then
				if string.len(v.t) > 6 then
					v.t = string.sub(v.t, 1, 6)
				end
			elseif string.len(v.t) > 3 then
				v.t = string.sub(v.t, 1, 3)
			end
		end
	elseif i == "hex" then
		if string.len(v.t) < 6 then
			v.t = v.t .. string.upper(k)
		end
	end
	
	if self.lastinput[2] == 1 then --rgb
		local r, g, b = self:getColor()
		if i == "r" then
			r = tonumber(v.t)
			if v.t == "" then r = 0 end
		elseif i == "g" then
			g = tonumber(v.t)
			if v.t == "" then g = 0 end
		elseif i == "b" then
			b = tonumber(v.t)
			if v.t == "" then b = 0 end
		end
		self:setColor(r, g, b)
	elseif self.lastinput[2] == 2 then --hsb
		if i == "hue" then
			if v.t == "" then self.selectionangle = 0 else
			self.selectionangle = tonumber(v.t)/360*(math.pi*2) end
			
			self.selectionangle = self.selectionangle + math.pi/2
			if self.selectionangle >= math.pi*2 then self.selectionangle = self.selectionangle - math.pi*2
			elseif self.selectionangle < 0 then self.selectionangle = self.selectionangle + math.pi*2 end
		elseif i == "sat" then
			if v.t == "" then self.saturangle = 1 else
			self.saturangle = 1-(tonumber(v.t)/100) end
		elseif i == "bri" then
			if v.t == "" then self.brightangle = 1 else
			self.brightangle = 1-(tonumber(v.t)/100) end
		end
	else --hex
		if v.t == "" then
			self:setColor(0, 0, 0)
		else
			local rgb = v.t
			while string.len(rgb) < 6 do rgb = rgb .. "0" end
			self:setColor(rgb)
		end
	end
end
