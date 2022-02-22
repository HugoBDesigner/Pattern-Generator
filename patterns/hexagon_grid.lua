local self = {}

self.rateX = 32
self.rateY = 32
self.name = "Hexagon grid"
self.variables = {
	[1] = {t = "Show darker lines", value = false}
}
function self.draw(x, y, width, height, size, color)
	local ww, hh = self.rateX*size*math.sin(math.rad(45 + math.pi)), self.rateY*size*math.sin(math.rad(60))
	local yy = (y-1)*hh
	local xx = (x-1)*ww
	local mult = 1
	if size < 1 then
		mult = 1/(1/size)
	end
	if math.mod(x, 2) == 0 then
		yy = yy-hh/2
	end
	
	if self.variables[1].value then
		love.graphics.setLineWidth(mult)
		local c = {unpack(color)}
		for i = 1, 4 do c[i] = c[i]*.75 end
		love.graphics.setColor(c)
		
		for i = 1, 3 do
			local an = 360/3*i
			local rateX, rateY = self.rateX*size, self.rateY*size
			an = math.rad(an)
			love.graphics.dashedLine(xx+ww/2 + rateX/2*math.cos(an), yy - rateY/2*math.sin(an), xx+ww/2 - rateX/2*math.cos(an), yy + rateY/2*math.sin(an), 3*mult)
		end
	end
	
	love.graphics.setLineWidth(2*mult)
	love.graphics.setColor(color)
	
	love.graphics.circle("line", xx+ww/2, yy, self.rateX*size/2, 6)
end

function self.setRate(width, height, size)
	local ww, hh = self.rateX*size*math.sin(math.rad(48.5)), self.rateY*size*math.sin(math.rad(60))
	return math.ceil(width/ww*size)+1, math.ceil(height/hh*size)+1
end

return self
