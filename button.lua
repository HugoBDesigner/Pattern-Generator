button = class:new()

function button:init(x, y, w, h, clickfunc, clickargs, text)
	self.x = x
	self.y = y
	self.width = w
	self.height = h
	self.clickfunc = clickfunc
	self.clickargs = clickargs or {}
	self.active = true
	self.text = text or false
	self.font = love.graphics.getFont() or love.graphics.newFont(24)
	
	if self.text and not self.width then
		self.width = self.font:getWidth(self.text .. "  ")
	end
	
	if self.text and not self.height then
		self.height = self.font:getHeight()*1.2
	end
	
	self.clickmode = true --If true, clicking triggers it. If false, unclicking does
	self.holdmode = false --If true, calls the function in every update
	self.hovering = false
	self.clicking = false
	self.color = {255/255, 255/255, 255/255, 255/255}
	self.clickcolor = {205/255, 235/255, 255/255, 255/255}
	self.hovercolor = {235/255, 235/255, 235/255, 255/255}
	self.outline = {0/255, 0/255, 0/255, 255/255}
	self.outclick = {0/255, 35/255, 55/255, 255/255}
	self.outhover = {35/255, 35/255, 35/255, 255/255}
	
	self.innerline = {255/255, 255/255, 255/255, 0/255}
	self.textshadow = {0/255, 0/255, 0/255, 0/255}
end

function button:draw()
	if not self.active then return end
	love.graphics.setColor(self.color)
	if self.hovering then
		love.graphics.setColor(self.hovercolor)
		if self.clicking then
			love.graphics.setColor(self.clickcolor)
		end
	end
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
	
	love.graphics.setColor(self.innerline)
	love.graphics.rectangle("line", self.x+2, self.y+2, self.width-4, self.height-4)
	
	love.graphics.setColor(self.outline)
	if self.hovering then
		love.graphics.setColor(self.outhover)
		if self.clicking then
			love.graphics.setColor(self.outclick)
		end
	end
	love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
	
	if self.text then
		local f = love.graphics.getFont()
		love.graphics.setFont(self.font)
		
		love.graphics.setColor(self.textshadow)
		love.graphics.print(self.text, self.x+self.width/2-love.graphics.getFont():getWidth(self.text)/2 + 1.5, self.y+self.height/2-love.graphics.getFont():getHeight()/2 + 1)
		love.graphics.setColor(self.outline)
		love.graphics.print(self.text, self.x+self.width/2-love.graphics.getFont():getWidth(self.text)/2, self.y+self.height/2-love.graphics.getFont():getHeight()/2)
		love.graphics.setFont(f)
	end
end

function button:update(dt)
	if not self.active then return end
	local x, y = love.mouse.getPosition()
	self.hovering = false
	if inside(x, y, 0, 0, self.x, self.y, self.width, self.height) then
		self.hovering = true
		if self.holdmode and love.mouse.isDown(1) then
			if self.clickfunc then
				if type(self.clickfunc) == "string" then
					_G[self.clickfunc](unpack(self.clickargs))
				else
					self.clickfunc(unpack(self.clickargs))
				end
			end
		end
	end
end

function button:mousepressed(x, y, b)
	if not self.active then return end
	if inside(x, y, 0, 0, self.x, self.y, self.width, self.height) and b == 1 then
		self.clicking = true
		if self.clickmode then
			if self.clickfunc then
				if type(self.clickfunc) == "string" then
					_G[self.clickfunc](unpack(self.clickargs))
				else
					self.clickfunc(unpack(self.clickargs))
				end
			end
		end
	end
end

function button:mousereleased(x, y, b)
	if not self.active then return end
	if b == 1 then
		if self.clicking and self.clickmode == false then
			if inside(x, y, 0, 0, self.x, self.y, self.width, self.height) then
				if self.clickfunc then
					if type(self.clickfunc) == "string" then
						_G[self.clickfunc](unpack(self.clickargs))
					else
						self.clickfunc(unpack(self.clickargs))
					end
				end
			end
		end
		self.clicking = false
	end
end

function button:wheelmoved(x, y)
	
end
