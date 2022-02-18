scroll = class:new()

function scroll:init(x, y, w, h, bs, dir)
	self.x = x
	self.y = y
	self.width = w
	self.height = h
	self.dir = dir or "vertical"
	self.dir = string.lower(self.dir)
	self.barsize = bs
	if not bs and self.dir == "vertical" then
		self.barsize = self.height/4
	elseif not bs and self.dir == "horizontal" then
		self.barsize = self.width/4
	end
	
	self.active = true
	self.value = 0
	self.clicking = false
	self.hovering = false
	self.lastclick = false
	self.clickpos = false
	self.color = {255, 255, 255, 255}
	self.barcolor = {155, 155, 155, 255}
	self.clickcolor = {105, 135, 155, 255}
	self.hovercolor = {135, 135, 135, 255}
	self.outline = {0, 0, 0, 255}
	self.outclick = {0, 35, 55, 255}
	self.outhover = {35, 35, 35, 255}
end

function scroll:update(dt)
	if not self.active then return end
	local x, y = love.mouse.getPosition()
	
	self.hovering = false
	if self.dir == "horizontal" or self.dir == "hor" or self.dir == "h" then
		if inside(x, y, 0, 0, self.x+2+(self.width-self.barsize)*self.value, self.y+2, self.barsize-4, self.height-4) then
			self.hovering = true
		end
		
		if self.clicking then
			local x = x - (self.x+self.clickpos)
			x = math.max(0, x)
			x = math.min(self.width-self.barsize, x)
			
			self.value = x/(self.width-self.barsize-4)
		end
	elseif self.dir == "vertical" or self.dir == "ver" or self.dir == "v" then
		if inside(x, y, 0, 0, self.x+2, self.y+2+(self.height-self.barsize)*self.value, self.width-4, self.barsize-4) then
			self.hovering = true
		end
		
		if self.clicking then
			local y = y - (self.y+self.clickpos)
			y = math.max(0, y)
			y = math.min(self.height-self.barsize-4, y)
			
			self.value = y/(self.height-self.barsize-4)
		end
	end
end

function scroll:draw()
	if not self.active then return end
	love.graphics.setColor(self.color)
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
	
	love.graphics.setColor(self.outline)
	if self.hovering then
		love.graphics.setColor(self.outhover)
	end
	if self.clicking then
		love.graphics.setColor(self.outclick)
	end
	love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
	
	love.graphics.setColor(self.barcolor)
	if self.hovering then
		love.graphics.setColor(self.hovercolor)
	end
	if self.clicking then
		love.graphics.setColor(self.clickcolor)
	end
	
	if self.dir == "horizontal" or self.dir == "hor" or self.dir == "h" then
		love.graphics.rectangle("fill", self.x+2+(self.width-self.barsize)*self.value, self.y+2, self.barsize-4, self.height-4)
	elseif self.dir == "vertical" or self.dir == "ver" or self.dir == "v" then
		love.graphics.rectangle("fill", self.x+2, self.y+2+(self.height-self.barsize)*self.value, self.width-4, self.barsize-4)
	end
end

function scroll:mousepressed(x, y, button)
	if not self.active then return end
	if button == 1 then
		if self.dir == "horizontal" or self.dir == "hor" or self.dir == "h" then
			if inside(x, y, 0, 0, self.x+2+(self.width-self.barsize-4)*self.value, self.y+2, self.barsize-4, self.height-4) then
				self.lastclick = true
				self.clicking = true
				self.clickpos = x - self.x - self.value*(self.width-self.barsize - 4)
			end
		elseif self.dir == "vertical" or self.dir == "ver" or self.dir == "v" then
			if inside(x, y, 0, 0, self.x+2, self.y+2+(self.height-self.barsize-4)*self.value, self.width-4, self.barsize-4) then
				self.lastclick = true
				self.clicking = true
				self.clickpos = y - self.y - self.value*(self.height-self.barsize - 4)
			end
		end
	end
end

function scroll:wheelmoved(x, y)
	if y > 0 and self.lastclick then
		self.value = math.max(0, self.value - .05)
	elseif y < 0 and self.lastclick then
		self.value = math.min(1, self.value + .05)
	end
end

function scroll:mousereleased(x, y, button)
	if not self.active then return end
	if button == 1 then
		self.clicking = false
		self.clickpos = false
	end
end