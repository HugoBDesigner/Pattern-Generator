local self = {}

self.rateX = 32
self.rateY = 32
self.name = "Concentric Squares"
self.variables = {
	[1] = {t = "Show inwards lines", value = true},
	[2] = {t = "Total inwards lines", value = {"2p", "2d", 4, 8, 16, 32, 64, 128}, extra = 3}
}

function self.draw(x, y, width, height, size, color)
	if self.variables[1].value then
		local c = {unpack(color)}
		for i = 1, 4 do
			c[i] = c[i]*.75
		end
		love.graphics.setColor(c)
		
		local n = self.variables[2].value[self.variables[2].extra]
		if n == "2p" then
			love.graphics.dashedLine(width/2, 0, width/2, height, 4)
			love.graphics.dashedLine(0, height/2, width, height/2, 4)
		elseif n == "2d" then
			local d = distance(0, 0, width/2, height/2)
			love.graphics.dashedLine(width/2-d, height/2-d, width/2+d, height/2+d, 4)
			love.graphics.dashedLine(width/2-d, height/2+d, width/2+d, height/2-d, 4)
		else
			for i = 1, n do
				local an = math.pi/n*(i-1)
				local d = distance(0, 0, width/2, height/2)
				love.graphics.dashedLine(width/2 + math.cos(an)*d, height/2 - math.sin(an)*d, width/2 - math.cos(an)*d, height/2 + math.sin(an)*d, 4)
			end
		end
	end
	
	love.graphics.setColor(color)
	if x == 1 and y == 1 then
		for a = 1, math.max(math.ceil( width/2/(self.rateX*size) ), math.ceil( height/2/(self.rateY*size) )) do
			love.graphics.rectangle("line", width/2-a*self.rateX*size, height/2-a*self.rateY*size, 2*a*self.rateX*size, 2*a*self.rateY*size)
		end
	end
end

function self.setRate(width, height, size)
	return math.ceil((math.max(width, height)/size)/(self.rateX*size)), 1
end

function self.setIcon(w, h, c)
	local xx, yy = self.setRate(w, h, .4)
	for x = 1, xx do
		self.draw(x, 1, w, h, .4, c)
	end
end

return self
