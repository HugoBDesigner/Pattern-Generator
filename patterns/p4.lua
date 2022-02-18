local self = {}

self.rateX = 0
self.rateY = 0
self.name = "Storyboard set"

self.variables = {
	{t = "Horizontal Squares", value = 3, extra = {1, 20}},
	{t = "Vertical Squares", value = 4, extra = {1, 20}},
	{t = "Horizontal Space", value = 10, extra = {0, 100, 5}},
	{t = "Vertical Space", value = 30, extra = {0, 100, 5}},
	{t = "Show Underline", value = true},
	{t = "Interior Color", value = {255, 255, 255, 255}, extra = "color"}
}

function self.draw(x, y, width, height, size, color)
	love.graphics.setLineWidth(size)
	local ish = self.variables[3].value
	local isv = self.variables[4].value
	local ul = self.variables[5].value
	
	local hs = width/self.variables[1].value
	local vs = height/self.variables[2].value
	
	love.graphics.setColor(self.variables[6].value)
	love.graphics.rectangle("fill", (x-1)*hs + hs*(ish/100)/2, (y-1)*vs + vs*(isv/100)/4, hs - hs*(ish/100), vs - vs*(isv/100))
	love.graphics.setColor(color)
	love.graphics.rectangle("line", (x-1)*hs + hs*(ish/100)/2, (y-1)*vs + vs*(isv/100)/4, hs - hs*(ish/100), vs - vs*(isv/100))
	if ul and isv > 0 then
		love.graphics.line((x-1)*hs + hs*(ish/100)/2, y*vs - (vs*(isv/100))*.2, x*hs - hs*(ish/100)/2, y*vs - (vs*(isv/100))*.2)
	end
end

function self.setRate(width, height, size)
	return self.variables[1].value*size, self.variables[2].value*size
end

return self